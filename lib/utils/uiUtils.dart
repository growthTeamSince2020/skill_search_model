import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:skill_search_model/common/constData.dart'; // ★ 追加

/**
 * 【ユーティリティ】画面表示系共通部品クラス
 *
 * 権限名称の日本語変換、共通テキストスタイルの提供、
 * およびアプリ全体で使用する共通ウィジェット（カード等）を定義します。
 */
class UIUtils {
  /**
   * ロール名の日本語変換 (constDataの定義を使用するように修正)
   */
  static String getRoleDisplayName(String? role) {
    // switch文から定数管理へ移行
    return constData.roleLabels[role] ?? '未設定';
  }

  /**
   * 権限表示用テキストスタイルの取得
   */
  static TextStyle getRoleTextStyle() {
    return TextStyle(
      fontSize: 11,
      color: Colors.green.shade700,
      fontWeight: FontWeight.bold,
    );
  }

  /**
   * 共通カードデザインの生成
   */
  static Widget buildCommonCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF2E7D32)),
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /**
   * 汎用メッセージダイアログの表示 (デザイン調整版)
   */
  static Future<void> showMessageDialog(
      BuildContext context, {
        required String title,
        required String message,
        bool isError = false,
      }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          title,
          style: TextStyle(
            color: isError ? Colors.red : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /**
   * アプリ標準のデザインを適用したテキストフィールドの構築
   */
  static Widget buildPrimaryTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = true,
    String? errorText,
    String? suffixText,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        label: RichText(
          text: TextSpan(
            text: label,
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            children: isRequired
                ? [
              const TextSpan(
                text: ' *',
                style: TextStyle(
                    color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ]
                : [],
          ),
        ),
        prefixIcon: Icon(icon, size: 20),
        suffixText: suffixText,
        errorText: errorText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  /**
   * フォームセクション用の装飾付きコンテナ
   */
  static Widget buildFormSection({required Widget child}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: child,
      ),
    );
  }

  /**
   * エラーリストのダイアログ表示
   */
  static void showErrorListDialog(BuildContext context, List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('入力内容を確認してください'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errors
                .map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('・ $e',
                  style: const TextStyle(color: Colors.redAccent)),
            ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('戻る'),
          ),
        ],
      ),
    );
  }

  /**
   * スキル選択用のエクスパンジョンタイル
   */
  static Widget buildSkillExpansionTile({
    required String title,
    required IconData icon,
    required List<String> items,
    required Map<String, String?> checkedMap,
    required List<String> categories,
    required Function(String item, String? value) onChanged,
  }) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: ExpansionTile(
        shape: const Border(),
        leading: Icon(icon, color: const Color(0xFF2E7D32)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        children: items.map((item) {
          final isChecked = checkedMap[item] != null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                title: Text(item,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                value: isChecked,
                onChanged: (val) => onChanged(item, val! ? '選択' : null),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              if (isChecked)
                Padding(
                  padding: const EdgeInsets.only(left: 48.0, bottom: 8.0),
                  child: Wrap(
                    spacing: 8.0,
                    runSpacing: 0.0,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: categories.map((cat) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Radio<String>(
                            value: cat,
                            groupValue: checkedMap[item],
                            materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                            onChanged: (String? val) => onChanged(item, val),
                          ),
                          GestureDetector(
                            onTap: () => onChanged(item, cat),
                            child: Text(cat,
                                style: const TextStyle(fontSize: 12.0)),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  /**
   * 処理結果（成功・失敗）を表示する共通ダイアログ
   */
  static Future<void> showResultDialog(
      BuildContext context, {
        required String title,
        required String message,
        required bool isError,
        VoidCallback? onNext,
      }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
                color: isError ? Colors.red : const Color(0xFF2E7D32)),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    color: isError ? Colors.red : const Color(0xFF2E7D32),
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                if (onNext != null) onNext();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isError ? Colors.red : const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  /**
   * アプリ標準のメインアクションボタン（大）
   */
  static Widget buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    Color color = const Color(0xFF2E7D32),
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  /**
   * 統計用：シンプルな横棒グラフ
   */
  static Widget buildSimpleBarChart({
    required String label,
    required int count,
    required int totalCount,
    required Color color,
  }) {
    final double percent = totalCount > 0 ? count / totalCount : 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('$count 名 (${(percent * 100).toStringAsFixed(1)}%)',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4)),
              ),
              FractionallySizedBox(
                widthFactor: percent,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /**
   * スキルと経験レベルを表示するバッジ（チップ）
   */
  static Widget buildSkillLevelBadge(String skill, String level) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(skill,
              style:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text(level, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  /**
   * Firestoreから次のシーケンスIDを取得・更新する
   */
  static Future<int> getNextSequenceId(FirebaseFirestore firestore) async {
    final counterRef = firestore.collection('engineer').doc('sequenceNo');

    return firestore.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(counterRef);
      final int currentId =
      snapshot.exists ? (snapshot.data()?['currentId'] as int? ?? 0) : 0;
      final int nextId = currentId + 1;

      transaction.set(
        counterRef,
        {'currentId': nextId},
        SetOptions(merge: true),
      );
      return nextId;
    });
  }

  /**
   * ダッシュボード上部の統計サマリーカード
   */
  static Widget buildStatCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.bold)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Text(unit,
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /**
   * 削除確認ダイアログの表示と削除実行
   */
  static Future<bool> showDeleteDialog(
      BuildContext context, {
        required String title,
        required String content,
        required String collectionPath,
        required String documentId,
      }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await FirebaseFirestore.instance
            .collection(collectionPath)
            .doc(documentId)
            .delete();
        showMessageDialog(context,
            title: '', message: '削除完了しました。');
        return true;
      } catch (e) {
        showMessageDialog(context,
            title: 'エラー', message: '削除に失敗しました: $e', isError: true);
        return false;
      }
    }
    return false;
  }

  /**
   * 複数ドキュメント削除確認ダイアログの表示と一括削除実行
   *
   * showDeleteDialog と同じ確認ダイアログUIを使い、
   * ユーザーが承認した場合に複数のFirestoreドキュメントを
   * WriteBatchでまとめて削除します。
   *
   * @param context コンテキスト
   * @param title ダイアログのタイトル
   * @param content ダイアログの本文
   * @param collectionPath 削除対象のコレクション名
   * @param documentIdList 削除対象のドキュメントIDのリスト
   * @return Future<bool> 実際に削除が行われた場合は true を返す
   */
  static Future<bool> deleteListData_confirmDialog(
      BuildContext context, {
        required String title,
        required String content,
        required String collectionPath,
        required List<String> documentIdList,
      }) async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (result != true) return false;
    if (documentIdList.isEmpty)

      return false;

    try {
      final firestore = FirebaseFirestore.instance;
      // WriteBatchは1回500件までのため、500件ずつに分割してcommitする
      const int chunkSize = 500;
      for (int i = 0; i < documentIdList.length; i += chunkSize) {
        final int end = (i + chunkSize > documentIdList.length)
            ? documentIdList.length
            : i + chunkSize;
        final chunk = documentIdList.sublist(i, end);

        final batch = firestore.batch();
        for (final docId in chunk) {
          batch.delete(firestore.collection(collectionPath).doc(docId));
        }
        await batch.commit();
      }
      showMessageDialog(context,
          title: '', message: '削除完了しました。');
      return true;
    } catch (e) {
      if (context.mounted) {
        showMessageDialog(context,
            title: 'エラー', message: '削除に失敗しました: $e', isError: true);
      }
      return false;
    }
  }
}