import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // ★ 追加
import 'package:flutter/foundation.dart'; // ★ kIsWeb のために追加
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

class CSVExporter {
  // マスタデータ（変更なし）
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

  static dynamic _parseValue(String key, dynamic value) {
    if (value == null) return "";
    if (value is Timestamp) {
      return DateFormat('yyyy/MM/dd HH:mm').format(value.toDate());
    }
    if (value is List) {
      if (_masters.containsKey(key)) {
        final master = _masters[key]!;
        return value.map((v) {
          int? idx = (v is int) ? v : int.tryParse(v.toString());
          if (idx != null && idx >= 0 && idx < master.length) return master[idx];
          return v.toString();
        }).join(", ");
      }
      return value.join(", ");
    }
    return value;
  }

  static Future<void> export(List<QueryDocumentSnapshot> docs) async {
    if (docs.isEmpty) return;

    final List<String> header = [
      'currentId', 'last_name', 'first_name', 'age', 'nearest_station_line_name',
      'nearest_station_name', 'team_role', 'team_role_years', 'process',
      'process_experience', 'code_languages', 'code_languages_years', 'db_experience',
      'db_experience_years', 'os_experience', 'os_experience_years',
      'cloud_technology', 'cloud_technology_years', 'tool', 'tool_years',
      'registration_date', 'update_date'
    ];

    List<List<dynamic>> rows = [];
    rows.add([
      '技術者No', '苗字', '名', '年齢', '最寄沿線', '最寄駅', 'チーム役割', '役割年数', '工程',
      '工程経験レベル', '経験言語', '言語年数', 'DB経験', 'DB年数', 'OS経験', 'OS年数',
      'クラウド技術', 'クラウド年数', 'ツール', 'ツール年数', '登録日時', '更新日時'
    ]);

    docs.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;
      final aId = int.tryParse((aData['id'] ?? aData['currentId'] ?? '0').toString()) ?? 0;
      final bId = int.tryParse((bData['id'] ?? bData['currentId'] ?? '0').toString()) ?? 0;
      return aId.compareTo(bId);
    });

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      List<dynamic> row = [];
      for (var key in header) {
        if (key == 'currentId') {
          row.add(data['id'] ?? data['currentId'] ?? "");
        } else {
          row.add(_parseValue(key, data[key]));
        }
      }
      rows.add(row);
    }

    // 3. CSV変換
    String csvData = const ListToCsvConverter().convert(rows);

    // 4. Excel用BOM付きUTF-8
    final List<int> excelBom = [0xEF, 0xBB, 0xBF];
    final List<int> combinedBytes = [...excelBom, ...utf8.encode(csvData)];

    // 5. 保存 (Web / デスクトップ両対応版)
    try {
      final timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
      final fileName = "engineer_export_$timestamp.csv";

      // FilePickerに bytes を渡すことで Web/デスクトップ 両方で自動書き込み・ダウンロードが行われます
      String? outputFile = await FilePicker.saveFile(
        dialogTitle: 'CSVファイルの保存先を選択してください',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
        bytes: Uint8List.fromList(combinedBytes), // ★ Web環境および自動保存のために必須
      );

      // Web環境では dart:io の File クラスを触るとエラーになるため、kIsWeb でガード
      if (!kIsWeb && outputFile != null) {
        print("CSV保存完了: $outputFile");
      }
    } catch (e) {
      print("CSV保存エラー: $e");
    }
  }
}