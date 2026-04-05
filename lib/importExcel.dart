import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_search_model/utils/uiUtils.dart';
import 'common/constData.dart';
class ExcelImporter {
  // ★ クラス内にあった static const List<String> ... はすべて削除します

  static Future<String> import(Uint8List bytes) async {
    final excel = Excel.decodeBytes(bytes);
    final db = FirebaseFirestore.instance;
    int count = 0;

    var sheet = excel.tables[excel.tables.keys.first];
    if (sheet == null || sheet.maxRows < 3) return "データが不足しています";

    List<String> headers = [];
    var row1 = sheet.rows[0];
    var row2 = sheet.rows[1];

    int maxCols = row1.length > row2.length ? row1.length : row2.length;

    for (int j = 0; j < maxCols; j++) {
      String h1 = (j < row1.length && row1[j]?.value != null)
          ? row1[j]!.value.toString().trim() : "";
      String h2 = (j < row2.length && row2[j]?.value != null)
          ? row2[j]!.value.toString().trim() : "";
      headers.add(h2.isNotEmpty ? h2 : h1);
    }

    for (int i = 2; i < sheet.maxRows; i++) {
      var row = sheet.rows[i];
      if (row.isEmpty || row.length < 1 || row[0] == null || row[0]?.value == null) continue;
      if (row[0]!.value.toString().trim().isEmpty) continue;

      Map<String, List<int>> teamRole = {'names': [], 'values': []};
      Map<String, List<int>> process = {'names': [], 'values': []};
      Map<String, List<int>> languages = {'names': [], 'values': []};
      Map<String, List<int>> dbs = {'names': [], 'values': []};
      Map<String, List<int>> oss = {'names': [], 'values': []};
      Map<String, List<int>> clouds = {'names': [], 'values': []};
      Map<String, List<int>> tools = {'names': [], 'values': []};

      String lastName = "";
      String firstName = "";
      int age = 0;
      String line = "";
      String station = "";

      for (int j = 0; j < row.length; j++) {
        if (j >= headers.length) break;

        String header = headers[j];
        var cell = row[j];
        if (cell == null || cell.value == null) continue;
        String val = cell.value.toString().trim();
        if (val.isEmpty) continue;

        if (header == "苗字") {
          lastName = val;
        } else if (header == "名") {
          firstName = val;
        } else if (header == "年齢") {
          age = int.tryParse(val.split('.')[0]) ?? 0;
        } else if (header == "最寄沿線") {
          line = val;
        } else if (header == "最寄駅") {
          station = val;
        }
        // --- ★ B. スキル判定（constDataのリストを参照するように変更） ---
        else if (constData.teamRoleItems.contains(header)) {
          _addSkill(teamRole, constData.teamRoleItems.indexOf(header), constData.yearsList.indexOf(val));
        } else if (constData.processItems.contains(header)) {
          _addSkill(process, constData.processItems.indexOf(header), constData.processLevelList.indexOf(val));
        } else if (constData.langItems.contains(header)) {
          _addSkill(languages, constData.langItems.indexOf(header), constData.yearsList.indexOf(val));
        } else if (constData.dbItems.contains(header)) {
          _addSkill(dbs, constData.dbItems.indexOf(header), constData.yearsList.indexOf(val));
        } else if (constData.osItems.contains(header)) {
          _addSkill(oss, constData.osItems.indexOf(header), constData.yearsList.indexOf(val));
        } else if (constData.cloudItems.contains(header)) {
          _addSkill(clouds, constData.cloudItems.indexOf(header), constData.yearsList.indexOf(val));
        } else if (constData.toolItems.contains(header)) {
          _addSkill(tools, constData.toolItems.indexOf(header), constData.toolYearsList.indexOf(val));
        }
      }

      int nextId = await UIUtils.getNextSequenceId(db);

      await db.collection('engineer').add({
        'id': nextId,
        'last_name': lastName,
        'first_name': firstName,
        'age': age,
        'nearest_station_line_name': line,
        'nearest_station_name': station,
        'team_role': teamRole['names'],
        'team_role_years': teamRole['values'],
        'process': process['names'],
        'process_experience': process['values'],
        'code_languages': languages['names'],
        'code_languages_years': languages['values'],
        'db_experience': dbs['names'],
        'db_experience_years': dbs['values'],
        'os_experience': oss['names'],
        'os_experience_years': oss['values'],
        'cloud_technology': clouds['names'],
        'cloud_technology_years': clouds['values'],
        'tool': tools['names'],
        'tool_years': tools['values'],
        'registration_date': FieldValue.serverTimestamp(),
        'update_date': FieldValue.serverTimestamp(),
      });
      count++;
    }
    return "$count 件の技術者を登録しました";
  }

  static void _addSkill(Map<String, List<int>> map, int nameIdx, int valIdx) {
    if (nameIdx != -1 && valIdx != -1) {
      map['names']!.add(nameIdx);
      map['values']!.add(valIdx);
    }
  }
}