import 'dart:convert';
import 'dart:typed_data';
// Web専用のHTML操作ライブラリをインポート（これがないとFileUploadInputElementが使えません）
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_search_model/utils/uiUtils.dart';
import 'package:csv/csv.dart';
import 'export_csv.dart';
import 'import_csv.dart';

class CsvImportExportScreen extends StatefulWidget {
  const CsvImportExportScreen({Key? key}) : super(key: key);

  @override
  _CsvImportExportScreenState createState() => _CsvImportExportScreenState();
}

class _CsvImportExportScreenState extends State<CsvImportExportScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  String _importMessage = '';

  // --- エクスポート処理 ---
  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final snapshot = await FirebaseFirestore.instance.collection('engineer').get();
      // sequenceNoドキュメントを除外
      final docs = snapshot.docs.where((doc) => doc.id != 'sequenceNo').toList();
      await CSVExporter.export(docs);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("エクスポートに失敗しました: $e")));
    } finally {
      setState(() => _isExporting = false);
    }
  }

  // --- インポート処理：ファイル選択 ---
  void _pickAndImportFile() {
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement()..accept = '.csv';
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

  // --- インポート処理：Firestore書き込み ---
  Future<void> _importData(Uint8List fileBytes) async {
    setState(() {
      _isImporting = true;
      _importMessage = 'インポート中...';
    });

    try {
      // 自分で解析せず、作成したロジック（CSVImporter）を呼び出す
      final result = await CSVImporter.import(fileBytes);

      setState(() {
        _importMessage = result; // CSVImporterが返したメッセージをそのまま表示
      });
    } catch (e) {
      setState(() => _importMessage = "エラー：$e");
    } finally {
      setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CSVインポート/エクスポート')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCard(
                icon: Icons.cloud_download,
                color: Colors.blue,
                title: 'データのエクスポート',
                description: '全ての技術者データをCSVとしてダウンロードします。',
                isLoading: _isExporting,
                buttonLabel: 'エクスポート実行',
                onPressed: _exportData,
              ),
              const SizedBox(height: 40),
              _buildCard(
                icon: Icons.cloud_upload,
                color: Colors.green,
                title: 'データのインポート',
                description: 'CSVファイルをアップロードして一括更新します。\n※更新は技術者Noをキーにして上書きします。\n存在しない技術者Noの場合は新規登録（最大500件まで）',
                isLoading: _isImporting,
                buttonLabel: 'ファイルを選択してインポート',
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