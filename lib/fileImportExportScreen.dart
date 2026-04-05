import 'dart:convert';
import 'dart:typed_data';
// Web専用のHTML操作ライブラリをインポート（これがないとFileUploadInputElementが使えません）
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_search_model/utils/uiUtils.dart';
import 'package:csv/csv.dart';
import 'exportCSV.dart';
import 'exportExcel.dart';
import 'importCSV.dart';
import 'importExcel.dart';

class CsvImportExportScreen extends StatefulWidget {
  const CsvImportExportScreen({Key? key}) : super(key: key);

  @override
  _CsvImportExportScreenState createState() => _CsvImportExportScreenState();
}

class _CsvImportExportScreenState extends State<CsvImportExportScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  String _importMessage = '';

  // ★ 追加：現在選択されているフォーマット (0: CSV, 1: Excel)
  int _selectedFormat = 0;

  // --- エクスポート処理 ---
  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('engineer').orderBy('id').get();
      final docs = snapshot.docs.where((doc) => doc.id != 'sequenceNo').toList();

      if (_selectedFormat == 0) {
        // CSVエクスポート (既存)
        await CSVExporter.export(docs);
      } else {
        // ★ Excelエクスポートを実行
        await ExcelExporter.export(docs);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("エラー: $e")));
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // --- ファイル選択処理 ---
  void _pickAndImportFile() {
    // ★ 選択中のフォーマットによって許可する拡張子を変える
    String acceptType = _selectedFormat == 0 ? '.csv' : '.xlsx';
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement()..accept = acceptType;

    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files!.isEmpty) return;

      final reader = html.FileReader();
      reader.readAsArrayBuffer(files[0]);
      reader.onLoadEnd.listen((e) {
        _importData(reader.result as Uint8List);
      });
    });
    uploadInput.click();
  }

  // --- インポート実行処理 ---
  Future<void> _importData(Uint8List fileBytes) async {
    setState(() {
      _isImporting = true;
      _importMessage = 'インポート中...';
    });

    try {
      String result;
      if (_selectedFormat == 0) {
        // CSVインポート
        result = await CSVImporter.import(fileBytes);
      } else {
        // Excelインポート
        result = await ExcelImporter.import(fileBytes);
      }

      setState(() => _importMessage = result);

      // ★ UIUtils の共通ダイアログを使用
      UIUtils.showResultDialog(
        context,
        title: '処理完了',
        message: result,
        isError: false, // 成功なので false
      );

    } catch (e) {
      setState(() => _importMessage = "エラー：$e");

      // ★ エラー時も UIUtils を使用
      UIUtils.showResultDialog(
        context,
        title: 'エラー',
        message: e.toString(),
        isError: true, // エラーなので true
      );
    } finally {
      setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('データ インポート/エクスポート')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // ★ フォーマット選択スイッチ
              Container(
                width: 300,
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('CSV'), icon: Icon(Icons.description)),
                    ButtonSegment(value: 1, label: Text('Excel'), icon: Icon(Icons.table_chart)),
                  ],
                  selected: {_selectedFormat},
                  onSelectionChanged: (Set<int> newSelection) {
                    setState(() {
                      _selectedFormat = newSelection.first;
                      _importMessage = ''; // フォーマットを変えたらメッセージをクリア
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),

              _buildCard(
                icon: Icons.cloud_download,
                color: _selectedFormat == 0 ? Colors.blue : Colors.teal,
                title: '${_selectedFormat == 0 ? "CSV" : "Excel"}でエクスポート',
                description: '全ての技術者データをダウンロードします。',
                isLoading: _isExporting,
                buttonLabel: 'ダウンロード開始',
                onPressed: _exportData,
              ),
              const SizedBox(height: 30),

              _buildCard(
                icon: Icons.cloud_upload,
                color: _selectedFormat == 0 ? Colors.green : Colors.orange,
                title: '${_selectedFormat == 0 ? "CSV" : "Excel"}からインポート',
                description: 'ファイルを選択して一括更新します。\n※技術者Noをキーにして上書きします。',
                isLoading: _isImporting,
                buttonLabel: 'ファイルを選択',
                onPressed: _pickAndImportFile,
                message: _importMessage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // インポート/エクスポートそれぞれの操作パネルを作るための共通UI部品
  Widget _buildCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required bool isLoading,
    required String buttonLabel,
    required VoidCallback onPressed,
    String? message,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            // 処理中ならぐるぐるを表示、そうでなければボタンを表示
            isLoading
                ? const CircularProgressIndicator()
                : UIUtils.buildPrimaryButton(
              label: buttonLabel,
              onPressed: onPressed,
              color: color,
            ),
            // 処理完了後のメッセージがあれば表示
            if (message != null && message.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}