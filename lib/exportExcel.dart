import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:html' as html;

import 'common/constData.dart';

class ExcelExporter {
  static Future<void> export(List<QueryDocumentSnapshot> docs) async {
    var excel = Excel.createExcel();
    String sheetName = excel.tables.keys.first;
    var sheet = excel[sheetName];

    // --- 1. ヘッダー作成 (結合なしの2重書き) ---
    _setDoubleHeader(sheet, 0, "技術者No");
    _setDoubleHeader(sheet, 1, "苗字");
    _setDoubleHeader(sheet, 2, "名");
    _setDoubleHeader(sheet, 3, "年齢");
    _setDoubleHeader(sheet, 4, "最寄沿線");
    _setDoubleHeader(sheet, 5, "最寄駅");

    int col = 6;
    col = _setCategoryHeaders(sheet, col, "チーム役割", constData.teamRoleItems);
    col = _setCategoryHeaders(sheet, col, "工程", constData.processItems);
    col = _setCategoryHeaders(sheet, col, "経験言語", constData.langItems);
    col = _setCategoryHeaders(sheet, col, "DB経験", constData.dbItems);
    col = _setCategoryHeaders(sheet, col, "OS経験", constData.osItems);
    col = _setCategoryHeaders(sheet, col, "クラウド技術", constData.cloudItems);
    col = _setCategoryHeaders(sheet, col, "ツール", constData.toolItems);

    // --- 2. データ書き込み ---
    for (int i = 0; i < docs.length; i++) {
      var data = docs[i].data() as Map<String, dynamic>;
      int rowIndex = i + 2;

      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex), IntCellValue(data['id'] ?? 0));
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex), TextCellValue(data['last_name'] ?? ""));
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex), TextCellValue(data['first_name'] ?? ""));
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex), IntCellValue(data['age'] ?? 0));
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex), TextCellValue(data['nearest_station_line_name'] ?? ""));
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex), TextCellValue(data['nearest_station_name'] ?? ""));

      int cCol = 6;
      cCol = _writeData(sheet, rowIndex, cCol, constData.teamRoleItems, data['team_role'], data['team_role_years'], constData.yearsList);
      cCol = _writeData(sheet, rowIndex, cCol, constData.processItems, data['process'], data['process_experience'], constData.processLevelList);
      cCol = _writeData(sheet, rowIndex, cCol, constData.langItems, data['code_languages'], data['code_languages_years'], constData.yearsList);
      cCol = _writeData(sheet, rowIndex, cCol, constData.dbItems, data['db_experience'], data['db_experience_years'], constData.yearsList);
      cCol = _writeData(sheet, rowIndex, cCol, constData.osItems, data['os_experience'], data['os_experience_years'], constData.yearsList);
      cCol = _writeData(sheet, rowIndex, cCol, constData.cloudItems, data['cloud_technology'], data['cloud_technology_years'], constData.yearsList);
      cCol = _writeData(sheet, rowIndex, cCol, constData.toolItems, data['tool'], data['tool_years'], constData.toolYearsList);
    }

    // --- 3. ダウンロード ---
    var fileBytes = excel.save();
    if (fileBytes != null) {
      final blob = html.Blob([fileBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "engineer_export.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

// 修正：1行目に項目名を書き、2行目は空欄にする
// これにより、インポート時は1行目の項目名が正しく参照されます
  static void _setDoubleHeader(Sheet sheet, int col, String title) {
    // 1行目 (rowIndex: 0) に項目名を書き込む
    sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        TextCellValue(title)
    );
    // 2行目 (rowIndex: 1) はあえて空欄（TextCellValue("")）にする
    // インポートロジックは「2行目が空なら1行目を見る」ので、これで正しく「年齢」等が認識されます
    sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 1),
        TextCellValue("")
    );
  }

  static int _setCategoryHeaders(Sheet sheet, int startCol, String categoryName, List<String> items) {
    sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: startCol, rowIndex: 0), TextCellValue(categoryName));
    if (items.length > 1) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: startCol, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: startCol + items.length - 1, rowIndex: 0),
      );
    }
    for (int i = 0; i < items.length; i++) {
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: startCol + i, rowIndex: 1), TextCellValue(items[i]));
    }
    return startCol + items.length;
  }

  static int _writeData(Sheet sheet, int rowIndex, int startCol, List<String> masterItems, List<dynamic>? names, List<dynamic>? values, List<String> labelList) {
    for (int i = 0; i < masterItems.length; i++) {
      String cellValueText = "";
      if (names != null && values != null) {
        int idx = names.indexOf(i);
        if (idx != -1 && idx < values.length) {
          int valIdx = values[idx];
          if (valIdx >= 0 && valIdx < labelList.length) {
            cellValueText = labelList[valIdx];
          }
        }
      }
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: startCol + i, rowIndex: rowIndex), TextCellValue(cellValueText));
    }
    return startCol + masterItems.length;
  }
}