import 'dart:convert';
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart'; // 日付フォーマット用（必要に応じてpubspec.yamlに追加）

class CSVExporter {
  // マスタデータ（ご提示いただいた設定値に完全準拠）
  static const Map<String, List<String>> _masters = {
    'team_role': ["PM経験", "PM補佐経験", "リーダ経験", "技術支援経験", "コンサル経験"],
    'team_role_years': [
      "1年未満",
      "1年〜2年未満",
      "2〜3年未満",
      "3〜5年未満",
      "5〜10年未満",
      "10年以上"
    ],
    'process': ["要件定義", "基本設計", "詳細設計", "コーディング", "単体", "結合", "保守"],
    'process_experience': ["未経験", "経験あり作成サポート必要", "サポートなくできる", "経験豊富でレビューできる"],
    'code_languages': [
      "C",
      "JAVA",
      "C#",
      "Go",
      "C++",
      "Python",
      "PHP",
      "Cobol",
      "JavaScript",
      "TypeScript",
      "Dart"
    ],
    'code_languages_years': [
      "1年未満",
      "1年〜2年未満",
      "2〜3年未満",
      "3〜5年未満",
      "5〜10年未満",
      "10年以上"
    ],
    'db_experience': ["Oracle", "MySQL", "PostgresSQL", "SQLite", "MongoDB"],
    'db_experience_years': [
      "1年未満",
      "1年〜2年未満",
      "2〜3年未満",
      "3〜5年未満",
      "5〜10年未満",
      "10年以上"
    ],
    'os_experience': [
      "Windows",
      "macOS",
      "Linux",
      "Android",
      "iOS",
      "WindowsServer"
    ],
    'os_experience_years': [
      "1年未満",
      "1年〜2年未満",
      "2〜3年未満",
      "3〜5年未満",
      "5〜10年未満",
      "10年以上"
    ],
    'cloud_technology': ["AWS", "Firebase", "GoogleCloud", "Azure"],
    'cloud_technology_years': [
      "1年未満",
      "1年〜2年未満",
      "2〜3年未満",
      "3〜5年未満",
      "5〜10年未満",
      "10年以上"
    ],
    'tool': [
      "Git",
      "svn",
      "Backlog",
      "Docker",
      "Jenkins",
      "Ansible",
      "androidStadio",
      "Visual Studio Code",
      "Eclipse",
      "IntelliJ IDEA",
      "Xcode"
    ],
    'tool_years': ["未経験", "1年未満", "1年〜2年未満", "2〜3年未満", "5年以上"],
  };

  /// データをCSV用文字列に変換
  /// データをCSV用文字列に変換
  static dynamic _parseValue(String key, dynamic value) {
    if (value == null) return "";

    // Timestampの変換
    if (value is Timestamp) {
      return DateFormat('yyyy/MM/dd HH:mm').format(value.toDate());
    }

    // Array (List) 型の変換
    if (value is List) {
      if (_masters.containsKey(key)) {
        final master = _masters[key]!;
        return value.map((v) {
          // --- 修正：数値型と文字列型の両方を確実に処理する ---
          int? idx;
          if (v is int) {
            idx = v;
          } else {
            idx = int.tryParse(v.toString());
          }

          // idxがnullでなく、かつマスタの範囲内（0〜5）であれば文言に変換
          if (idx != null && idx >= 0 && idx < master.length) {
            return master[idx];
          }

          // 変換できない場合はそのままの値を返す（ここで数字の 5 や 6 が出る）
          return v.toString();
        }).join(", ");
      }
      return value.join(", ");
    }

    return value;
  }

  static Future<void> export(List<QueryDocumentSnapshot> docs) async {
    if (docs.isEmpty) return;

    // 1. 出力フィールドの定義（ご提示の表の順番に準拠）
    // 固定にすることで、CSVの列順を保証します
    final List<String> header = [
      'currentId',
      'last_name',
      'first_name',
      'age',
      'nearest_station_line_name',
      'nearest_station_name',
      'team_role',
      'team_role_years',
      'process',
      'process_experience',
      'code_languages',
      'code_languages_years',
      'db_experience',
      'db_experience_years',
      'os_experience',
      'os_experience_years',
      'cloud_technology',
      'cloud_technology_years',
      'tool',
      'tool_years',
      'registration_date',
      'update_date'
    ];

    List<List<dynamic>> rows = [];

    // ヘッダー（日本語表示にしたい場合はここを書き換える）
    rows.add([
      '技術者No',
      '苗字',
      '名',
      '年齢',
      '最寄沿線',
      '最寄駅',
      'チーム役割',
      '役割年数',
      '工程',
      '工程経験レベル',
      '経験言語',
      '言語年数',
      'DB経験',
      'DB年数',
      'OS経験',
      'OS年数',
      'クラウド技術',
      'クラウド年数',
      'ツール',
      'ツール年数',
      '登録日時',
      '更新日時'
    ]);

    // idフィールドで昇順ソート
    docs.sort((a, b) {
      final aData = a.data() as Map<String, dynamic>;
      final bData = b.data() as Map<String, dynamic>;

      // idまたはcurrentIdを取得（どちらもなければ0として扱う）
      final aId = int.tryParse((aData['id'] ?? aData['currentId'] ?? '0').toString()) ?? 0;
      final bId = int.tryParse((bData['id'] ?? bData['currentId'] ?? '0').toString()) ?? 0;

      return aId.compareTo(bId);
    });
    // 2. データ行の作成
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      List<dynamic> row = [];
      for (var key in header) {
        // --- 修正箇所：ランダムなドキュメントIDではなく、フィールド内の'id'を取得する ---
        if (key == 'currentId') {
          // Firebase内のフィールド名が 'id' であるものを優先して取得
          // もし 'id' がなければ 'currentId' フィールドを見る
          final idValue = data['id'] ?? data['currentId'] ?? "";
          row.add(idValue);
        } else {
          row.add(_parseValue(key, data[key]));
        }
        // ---------------------------------------------------------
      }
      rows.add(row);
    }

    // 3. CSV変換
    String csvData = const ListToCsvConverter().convert(rows);

    // 4. Excel用BOM付きUTF-8
    final List<int> excelBom = [0xEF, 0xBB, 0xBF];
    final List<int> combinedBytes = [...excelBom, ...utf8.encode(csvData)];

    // 5. ダウンロード
    final base64 = base64Encode(combinedBytes);
    final anchor = html.AnchorElement(href: 'data:text/csv;base64,$base64')
      ..setAttribute("download",
          "engineer_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv")
      ..click();
  }
}
