import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:skill_search_model/utils/uiUtils.dart';

class CSVImporter {
  static const Map<String, List<String>> _masters = {
    'team_role': ["PM経験", "PM補佐経験", "リーダ経験", "技術支援経験", "コンサル経験"],
    'team_role_years': ["1年未満", "1年〜2年未満", "2〜3年未満", "3〜5年未満", "5〜10年未満", "10年以上"],
    'process': ["要件定義", "基本設計", "詳細設計", "コーディング", "単体", "結合", "保守"],
    'process_experience': ["未経験", "経験あり作成サポート必要", "サポートなくできる", "経験豊富でレビューできる"],
    'code_languages': ["C", "JAVA", "C#", "Go", "C++", "Python", "PHP", "Cobol", "JavaScript", "TypeScript", "Dart"],
    'code_languages_years': ["1年未満", "1年〜2年未満", "2〜3年未満", "3〜5年未満", "5〜10年未満", "10年以上"],
    'db_experience': ["Oracle", "MySQL", "PostgresSQL", "SQLite", "MongoDB"],
    'db_experience_years': ["1年未満", "1年〜2年未満", "2〜3年未満", "3〜5年未満", "5〜10年未満", "10年以上"],
    'os_experience': ["Windows", "macOS", "Linux", "Android", "iOS", "WindowsServer"],
    'os_experience_years': ["1年未満", "1年〜2年未満", "2〜3年未満", "3〜5年未満", "5〜10年未満", "10年以上"],
    'cloud_technology': ["AWS", "Firebase", "GoogleCloud", "Azure"],
    'cloud_technology_years': ["1年未満", "1年〜2年未満", "2〜3年未満", "3〜5年未満", "5〜10年未満", "10年以上"],
    'tool': ["Git", "svn", "Backlog", "Docker", "Jenkins", "Ansible", "androidStadio", "Visual Studio Code", "Eclipse", "IntelliJ IDEA", "Xcode"],
    'tool_years': ["未経験", "1年未満", "1年〜2年未満", "2〜3年未満", "5年以上"],
  };

  /// 値をパースしてマスタのINDEXに変換
  static dynamic _unparseValue(String key, String value) {
    if (value.isEmpty) {
      return _masters.containsKey(key) ? [] : "";
    }

    // 表記ゆれ（波ダッシュ・チルダ・ハイフン系）を統一する
    String norm(String s) => s.replaceAll('～', '〜').replaceAll('~', '〜').replaceAll('-', '〜').trim();

    if (_masters.containsKey(key)) {
      final masterList = _masters[key]!;
      final items = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

      return items.map((item) {
        final normalizedItem = norm(item);
        for (int i = 0; i < masterList.length; i++) {
          if (norm(masterList[i]) == normalizedItem) {
            return i;
          }
        }
        return item;
      }).toList();
    }

    if (key == 'age') return int.tryParse(value);
    return value;
  }

  /**
   * CSVデータを取り込みFirestoreに保存する
   *
   * 大量データに対応するためWriteBatchを使用し、1件でも不備があれば全ロールバックします。
   * シーケンス番号(sequenceNo)の取得にはUIUtilsの共通メソッドを使用します。
   */
  static Future<String> import(Uint8List fileBytes) async {
    try {
      String csvData = utf8.decode(fileBytes, allowMalformed: true);
      if (csvData.startsWith('\uFEFF')) csvData = csvData.substring(1);

      final List<List<dynamic>> rows = const CsvToListConverter(
        shouldParseNumbers: false,
        allowInvalid: true,
      ).convert(csvData);

      if (rows.length < 2) return "エラー: データがありません。";

      final Map<String, String> jpToKey = {
        '苗字': 'last_name', '名': 'first_name', '年齢': 'age',
        '最寄沿線': 'nearest_station_line_name', '最寄駅': 'nearest_station_name',
        'チーム役割': 'team_role', '役割年数': 'team_role_years',
        '工程': 'process', '工程経験レベル': 'process_experience',
        '経験言語': 'code_languages', '言語年数': 'code_languages_years',
        'DB経験': 'db_experience', 'DB年数': 'db_experience_years',
        'OS経験': 'os_experience', 'OS年数': 'os_experience_years',
        'クラウド技術': 'cloud_technology', 'クラウド年数': 'cloud_technology_years',
        'ツール': 'tool', 'ツール年数': 'tool_years',
      };

      final headerJp = rows[0].map((e) {
        return e.toString().trim().replaceAll(RegExp(r'[\u0000-\u001F\u007F-\u009F\uFEFF]'), '');
      }).toList();

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      // --- sequenceNo の取得（共通ユーティリティを使用） ---
      // UIUtils.getNextSequenceId は内部でトランザクションを行い、ドキュメントがなければ作成します。
      // インポート開始時のベースとなる番号を取得します。
      int startId = await UIUtils.getNextSequenceId(firestore);
      int currentSeq = startId;

      int importCount = 0;
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.isEmpty || row.every((cell) => cell.toString().trim().isEmpty)) continue;

        final Map<String, dynamic> data = {};
        for (int j = 0; j < headerJp.length; j++) {
          if (j >= row.length) break;
          final key = jpToKey[headerJp[j]];
          if (key == null) continue;

          String value = row[j].toString().trim().replaceAll('\r', '');

          if (key == 'nearest_station_name') {
            value = value.replaceAll('駅', '').trim();
          }
          data[key] = _unparseValue(key, value);
        }

        // 必須項目チェック
        if (_isFieldEmpty(data['last_name'])) throw "${i + 1}行目の「苗字」が取得できません。";
        if (_isFieldEmpty(data['first_name'])) throw "${i + 1}行目の「名」が空欄です。";
        if (data['age'] == null) throw "${i + 1}行目の「年齢」が不正です。";
        if (_isFieldEmpty(data['nearest_station_line_name'])) throw "${i + 1}行目の「最寄沿線」が空欄です。";
        if (_isFieldEmpty(data['nearest_station_name'])) throw "${i + 1}行目の「最寄駅」が空欄です。";

        // 1件目は startId を使い、2件目以降から加算
        if (importCount > 0) {
          currentSeq++;
        }

        data['id'] = currentSeq;
        data['registration_date'] = FieldValue.serverTimestamp();
        data['update_date'] = FieldValue.serverTimestamp();

        final newDocRef = firestore.collection('engineer').doc();
        batch.set(newDocRef, data);
        importCount++;
      }

      // 最後に sequenceNo ドキュメントの最終値を更新
      final seqRef = firestore.collection('engineer').doc('sequenceNo');
      batch.update(seqRef, {'currentId': currentSeq});

      // 一括書き込み（ここで失敗すれば、ここまでの設定は一切反映されない）
      await batch.commit();

      return "成功: $importCount 件のデータを取り込みました。";
    } catch (e) {
      return "インポート失敗 (全件ロールバックしました): $e";
    }
  }

  static bool _isFieldEmpty(dynamic val) {
    if (val == null) return true;
    if (val is String && val.isEmpty) return true;
    if (val is List && val.isEmpty) return true;
    return false;
  }
}