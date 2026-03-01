import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/**
 * 【ユーティリティ】画面表示系共通部品クラス
 *
 * 権限名称の日本語変換、共通テキストスタイルの提供、
 * およびアプリ全体で使用する共通ウィジェット（カード等）を定義します。
 */
class UIUtils {
  /**
   * ロール名の日本語変換
   *
   * システム内部のロール名（admin/editor/viewer）を、
   * 画面表示用の日本語名称に変換します。
   *
   * @param role 変換対象のロール文字列（null許容）
   * @return 対応する日本語名称（未設定時は「未設定」を返す）
   */
  static String getRoleDisplayName(String? role) {
    switch (role) {
      case 'admin':
        return '管理者';
      case 'editor':
        return '編集者';
      case 'viewer':
        return '閲覧者';
      default:
        return '未設定';
    }
  }

  /**
   * 権限表示用テキストスタイルの取得
   *
   * ユーザー名の下などに表示する権限ラベル用の
   * 共通テキストスタイル（緑色の太字、サイズ11）を返します。
   *
   * @return TextStyle 権限表示用の装飾オブジェクト
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
   *
   * ダッシュボードやメインメニューで使用する、
   * アイコンとタイトル付きの共通カードウィジェットを構築します。
   *
   * @param title カードに表示するタイトル
   * @param icon 表示するアイコンデータ
   * @param onTap タップ時のコールバック処理
   * @return Widget 装飾済みのカードウィジェット
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
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /**
   * 汎用メッセージダイアログの表示
   *
   * @param context コンテキスト
   * @param title タイトル
   * @param message 本文
   * @param isError エラー表示かどうか（色味の切り替え用）
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
        title: Text(title,
            style: TextStyle(color: isError ? Colors.red : Colors.black87)),
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
   *
   * @param controller コントローラー
   * @param label ラベル名
   * @param icon 左側に表示するアイコン
   * @param errorText エラーメッセージ（ある場合）
   * @param suffixText 右側に表示する補助テキスト（「駅」など）
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
   *
   * 複数のバリデーションエラーをリスト形式で表示します。
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
   *
   * チェックボックスと、選択時に表示されるラジオボタン群をセットにした
   * 標準的なスキル入力UIを構築します。
   *
   * @param title タイトル
   * @param icon アイコン
   * @param items 選択肢リスト
   * @param checkedMap 選択状態を管理するマップ
   * @param categories ラジオボタンのカテゴリーリスト（「1年」「3年」など）
   * @param onChanged 状態変更時のコールバック
   * @return Widget 構築されたタイル
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
  static void showResultDialog(
    BuildContext context, {
    required String title,
    required String message,
    required bool isError,
    VoidCallback? onNext,
  }) {
    showDialog(
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
   *
   * @param label 項目名（「20代」など）
   * @param count 該当件数
   * @param totalCount 全体件数（割合計算用）
   * @param color バーの色
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
   *
   * ダッシュボードの年齢層別スキル分布などで使用します。
   *
   * @param skill スキル名（「Java」など）
   * @param level 経験レベル（「3年以上」など）
   */
  static Widget buildSkillLevelBadge(String skill, String level) {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        // Border.sideのエラーを修正: Border.allを使用
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
   *
   * 「engineer/sequenceNo」ドキュメントの「currentId」を参照し、
   * トランザクションを用いて安全にインクリメントした値を返します。
   * ドキュメントが存在しない場合は、初期値 0 として作成されます。
   *
   * @param firestore Firestoreのインスタンス
   * @return Future<int> 更新後の新しいID（1から開始）
   */
  static Future<int> getNextSequenceId(FirebaseFirestore firestore) async {
    final counterRef = firestore.collection('engineer').doc('sequenceNo');

    return firestore.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(counterRef);

      // ドキュメントが存在しない場合は 0 とみなす
      final int currentId =
      snapshot.exists ? (snapshot.data()?['currentId'] as int? ?? 0) : 0;

      final int nextId = currentId + 1;

      // 新しいIDで更新（ドキュメントがない場合は自動作成される）
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
   *
   * レイアウトの柔軟性を高めるため、内部の Expanded を削除しました。
   * 呼び出し側の Row 内などで Expanded や Flexible を使用して包んでください。
   *
   * @param label 統計項目名
   * @param value 統計数値
   * @param unit 単位（「名」など）
   * @param icon アイコン
   * @param color アイコンおよび装飾色
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

}
