import 'dart:convert';
import 'dart:typed_data';
// Web専用のHTML操作ライブラリをインポート（これがないとFileUploadInputElementが使えません）
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_search_model/utils/uiUtils.dart';
import 'package:csv/csv.dart';
import 'exportCSV.dart';
import 'importCSV.dart';

class CsvImportExportScreen extends StatefulWidget {
  const CsvImportExportScreen({Key? key}) : super(key: key);

  @override
  _CsvImportExportScreenState createState() => _CsvImportExportScreenState();
}

class _CsvImportExportScreenState extends State<CsvImportExportScreen> {
  // 処理中かどうかを管理するフラグ
  bool _isExporting = false;
  bool _isImporting = false;
  // インポート結果を表示するメッセージ
  String _importMessage = '';

  // --- エクスポート処理：Firestoreからデータを取得してCSV出力する ---
  Future<void> _exportData() async {
    setState(() => _isExporting = true); // ローディング開始
    try {
      // 'engineer'コレクションの全データを取得
      final snapshot = await FirebaseFirestore.instance.collection('engineer').get();
      // 管理用の'sequenceNo'という名前のドキュメントを除外してリスト化
      final docs = snapshot.docs.where((doc) => doc.id != 'sequenceNo').toList();

      // 別ファイル(exportCSV.dart)で定義したロジックを使ってCSVファイルをダウンロード
      await CSVExporter.export(docs);
    } catch (e) {
      // エラーが発生した場合は画面下部に通知を表示
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("エクスポートに失敗しました: $e")));
    } finally {
      setState(() => _isExporting = false); // ローディング終了
    }
  }

  // --- インポート処理：ブラウザのファイル選択ダイアログを開く ---
  void _pickAndImportFile() {
    // HTMLのファイル入力要素を作成し、CSVファイルのみ許可する設定にする
    final html.FileUploadInputElement uploadInput = html.FileUploadInputElement()..accept = '.csv';

    // ファイルが選択された時のイベントリスナー
    uploadInput.onChange.listen((e) {
      final files = uploadInput.files;
      if (files!.isEmpty) return; // 選択されていなければ終了

      final reader = html.FileReader();
      // ファイルをバイトデータ(ArrayBuffer)として読み込む
      reader.readAsArrayBuffer(files[0]);
      // 読み込み完了後の処理
      reader.onLoadEnd.listen((e) {
        // 読み込んだデータをバイト配列に変換してインポート処理へ渡す
        _importData(reader.result as Uint8List);
      });
    });

    // 擬似的にクリックイベントを発生させてダイアログを表示
    uploadInput.click();
  }

  // --- インポート処理：読み込んだデータをFirestoreに書き込む ---
  Future<void> _importData(Uint8List fileBytes) async {
    setState(() {
      _isImporting = true;
      _importMessage = 'インポート中...';
    });

    try {
      // 別ファイル(importCSV.dart)で定義したロジックを呼び出し、Firestoreへの登録を実行
      final result = await CSVImporter.import(fileBytes);

      setState(() {
        // 実行結果（「〇件更新しました」など）を画面に表示
        _importMessage = result;
      });
    } catch (e) {
      setState(() => _importMessage = "エラー：$e");
    } finally {
      setState(() => _isImporting = false); // ローディング終了
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
              // エクスポート用のカード表示
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
              // インポート用のカード表示
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