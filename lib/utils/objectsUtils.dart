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
  static bool canAccessMenuItem(AppUser? user, Map<String, dynamic> item) {
    // 管理者は全てのメニューに対してアクセス権を持つ
    if (user?.role == 'admin') return true;

    final String? required = item['roleRequired'];

    // 権限設定がない（null）項目は、全てのユーザーがアクセス可能
    if (required == null) return true;

    // インポート/エクスポート等の管理者専用項目の判定
    if (required == 'admin') return user?.role == 'admin';

    // 技術者登録等の編集者（または編集権限保持者）用項目の判定
    if (required == 'editor') {
      return user?.role == 'editor' || (user?.permissions['canEdit'] ?? false);
    }

    // 上記の条件に合致しない場合はアクセスを拒否
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
