import '../main.dart';
/**
 * 【ユーティリティ】オブジェクト操作・判定クラス
 *
 * アプリケーション内でのデータオブジェクトの比較や、
 * 権限に基づいたアクセス制御などのロジックを集約します。
 */
class ObjectUtils {

  /**
   * メニューアクセスの認可判定
   *
   * 指定されたユーザー [user] が、メニュー項目 [item] にアクセスする権限を
   * 持っているかどうかを検証します。
   *
   * @param user 現在ログイン中のユーザー情報。未ログイン時は null。
   * @param item 判定対象のメニュー項目データ（'roleRequired' キーを含む Map）。
   * @return アクセス可能な場合は true、それ以外は false。
   */
  static bool canAccessMenuItem(AppUser? appUser, Map<String, dynamic> item) {
    if (appUser == null) return false;

    final String? requiredRole = item['roleRequired'];
    final String title = item['title'];

    // 1. 管理者(admin)は何でもできる
    if (appUser.role == 'admin') return true;

    // 2. 「技術者登録」など、編集が必要な機能のチェック
    // タイトルや特定のフラグに基づいて、canEdit 権限があるか確認
    if (title == '技術者登録' || requiredRole == 'editor') {
      if (appUser.permissions['canEdit'] == true) return true;
    }

    // 3. 「エクスポート」機能のチェック
    if (title == 'エクスポート' || title == 'インポート') {
      if (appUser.permissions['canExport'] == true) return true;
    }

    // 4. ロールが直接一致する場合 (editorなど)
    if (requiredRole == null || appUser.role == requiredRole) {
      return true;
    }

    return false;
  }

  /**
   * 文字列のバリデーションチェック
   *
   * @param value 入力された値
   * @param patternType 'numeric'(数字のみ) or 'alphanumeric'(英数漢字)
   * @return エラーがない場合は true
   */
  static bool isValidPattern(String value, String patternType) {
    if (patternType == 'numeric') {
      return RegExp(r'^[0-9]+$').hasMatch(value);
    }
    // 英数漢字記号の汎用パターン
    return RegExp(
      r'^[a-zA-Z0-9\p{P}\s\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]+$',
      unicode: true,
    ).hasMatch(value);
  }
  /**
   * フィールドのバリデーション実行
   *
   * @param value 入力された文字列
   * @param label 項目名（「名」「年齢」など）
   * @return エラーメッセージ（正常時は null）
   */
  static String? validateField(String value, String label) {
    // 1. 必須チェック（全ての項目を必須とする場合）
    if (value.trim().isEmpty) {
      return '$labelを入力してください';
    }

    // 2. 形式チェック
    if (label == '年齢') {
      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
        return '数字で入力してください';
      }
    } else {
      // 名前や駅名などの汎用パターン（英数漢字）
      if (!RegExp(r'^[a-zA-Z0-9\p{P}\s\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]+$', unicode: true).hasMatch(value)) {
        return '使用できない文字が含まれています';
      }
    }

    return null; // エラーなし
  }
}
