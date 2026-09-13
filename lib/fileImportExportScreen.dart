import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_search_model/utils/uiUtils.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:skill_search_model/common/constData.dart'; // ★ 追加

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

  // --- エクスポート処理 (仕様維持) ---
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

  // --- ファイル選択処理 (仕様維持) ---
  Future<void> _pickAndImportFile() async {
    try {
      List<String> allowedExtensions = _selectedFormat == 0 ? ['csv'] : ['xlsx'];
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        withData: true,
      );

      if (result != null && result.files.single.bytes != null) {
        _importData(result.files.single.bytes!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ファイル選択エラー: $e")));
    }
  }

  // --- インポート実行処理 (仕様維持) ---
  Future<void> _importData(Uint8List fileBytes) async {
    setState(() {
      _isImporting = true;
      _importMessage = 'インポート中...';
    });

    try {
      String result;
      if (_selectedFormat == 0) {
        result = await CSVImporter.import(fileBytes);
      } else {
        result = await ExcelImporter.import(fileBytes);
      }

      setState(() => _importMessage = result);

      await UIUtils.showResultDialog(
        context,
        title: '処理完了',
        message: result,
        isError: false,
      );
    } catch (e) {
      setState(() => _importMessage = "エラー：$e");
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Row(
          children: [
            const Icon(Icons.swap_vert_rounded, color: constData.themeGreen, size: 24),
            const SizedBox(width: 12),
            Text(
              'データ連携',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.withOpacity(0.15), height: 1.0),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(constData.cardPadding),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                // フォーマット選択
                Container(
                  width: 300,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: SegmentedButton<int>(
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: constData.themeGreen.withOpacity(0.1),
                      selectedForegroundColor: constData.themeGreen,
                    ),
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
                const SizedBox(height: 10),

                // エクスポートカード
                _buildModernCard(
                  icon: Icons.cloud_download_rounded,
                  title: '${_selectedFormat == 0 ? "CSV" : "Excel"}でエクスポート',
                  description: '全ての技術者データを一括ダウンロードします。\nバックアップや二次利用にご活用ください。',
                  isLoading: _isExporting,
                  buttonLabel: 'ダウンロード開始',
                  onPressed: _exportData,
                  themeColor: constData.themeGreen,
                ),
                const SizedBox(height: 24),

                // インポートカード
                _buildModernCard(
                  icon: Icons.cloud_upload_rounded,
                  title: '${_selectedFormat == 0 ? "CSV" : "Excel"}からインポート',
                  description: 'ファイルを選択してデータを一括更新します。\n※技術者Noをキーにして上書き保存されます。',
                  isLoading: _isImporting,
                  buttonLabel: 'ファイルを選択',
                  onPressed: _pickAndImportFile,
                  message: _importMessage,
                  themeColor: Colors.blueGrey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Skirunデザインに合わせたカードビルダー
  Widget _buildModernCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isLoading,
    required String buttonLabel,
    required VoidCallback onPressed,
    required Color themeColor,
    String? message,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(constData.borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: themeColor.withOpacity(0.1),
              child: Icon(icon, size: 32, color: themeColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
            ),
            const SizedBox(height: 24),
            isLoading
                ? const CircularProgressIndicator()
                : UIUtils.buildPrimaryButton(
              label: buttonLabel,
              onPressed: onPressed,
              color: themeColor,
            ),
            if (message != null && message.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: themeColor),
                ),
              ),
          ],
        ),
      ),
    );
  }
}