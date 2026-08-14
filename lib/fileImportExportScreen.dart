import 'dart:convert';
import 'dart:io'; // 追加
import 'dart:typed_data';
// import 'dart:html' as html; // ← 削除（ビルドエラーの原因）
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_search_model/utils/uiUtils.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart'; // 追加
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

  int _selectedFormat = 0; // 0: CSV, 1: Excel

  // --- エクスポート処理 ---
  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('engineer').orderBy('id').get();
      final docs = snapshot.docs.where((doc) => doc.id != 'sequenceNo').toList();

      if (_selectedFormat == 0) {
        await CSVExporter.export(docs);
      } else {
        await ExcelExporter.export(docs);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("エラー: $e")));
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // --- ファイル選択処理 (macOS/デスクトップ対応版) ---
  Future<void> _pickAndImportFile() async {
    try {
      // 選択中のフォーマットによって許可する拡張子を変える
      List<String> allowedExtensions = _selectedFormat == 0 ? ['csv'] : ['xlsx'];

      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        // インポート実行
        _importData(result.files.single.bytes!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ファイル選択エラー: $e")));
    }
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
        // CSVExporter ではなく CSVImporter を呼ぶ
        result = await CSVImporter.import(fileBytes);
      } else {
        // ExcelExporter ではなく ExcelImporter を呼ぶ
        result = await ExcelImporter.import(fileBytes);
      }

      setState(() => _importMessage = result);

      // ★ await を追加
      await UIUtils.showResultDialog(
        context,
        title: '処理完了',
        message: result,
        isError: false,
      );

    } catch (e) {
      setState(() => _importMessage = "エラー：$e");
      // ★ await を追加
      await UIUtils.showResultDialog(
        context,
        title: 'エラー',
        message: e.toString(),
        isError: true,
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
                      _importMessage = '';
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
            isLoading
                ? const CircularProgressIndicator()
                : UIUtils.buildPrimaryButton(
              label: buttonLabel,
              onPressed: onPressed,
              color: color,
            ),
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