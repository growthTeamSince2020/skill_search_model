import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_search_model/common/constData.dart';

/// 特定の画面（screenKey）に対する、現在ログイン中ユーザーの権限をまとめたスナップショット。
/// [PermissionService.loadForScreen] の戻り値。
class ScreenPermissions {
  /// 画面そのものを見てよいか（permissionMatrixドキュメントの view）
  final bool canViewScreen;

  final Map<String, _ItemPermission> _byItemName;
  final Map<String, _ItemPermission> _byFieldKey;

  const ScreenPermissions._(this.canViewScreen, this._byItemName, this._byFieldKey);

  /// permissionMatrix に登録されていない画面（未設定）の場合に使う、
  /// 安全側（何も見せない・編集させない）のデフォルト値。
  factory ScreenPermissions.deny() => const ScreenPermissions._(false, {}, {});

  /// 画面項目名（itemName）で閲覧可否を判定する。
  /// permissionMatrix に登録が無い項目は false（安全側）を返す。
  bool canViewItem(String itemName) => _byItemName[itemName]?.view ?? false;

  /// 画面項目名（itemName）で編集可否を判定する。
  bool canEditItem(String itemName) => _byItemName[itemName]?.edit ?? false;

  /// 実データのフィールドキー（例: "last_name"）で閲覧可否を判定する。
  /// 該当するfieldKeysを持つ項目が見つからない場合は false（安全側）を返す。
  bool canViewField(String fieldKey) => _byFieldKey[fieldKey]?.view ?? false;

  /// 実データのフィールドキーで編集可否を判定する。
  bool canEditField(String fieldKey) => _byFieldKey[fieldKey]?.edit ?? false;
}

class _ItemPermission {
  final bool view;
  final bool edit;
  const _ItemPermission(this.view, this.edit);
}

/// `permissionMatrix` コレクションを読み取り、各画面が自分自身の表示・編集制御に
/// 利用するためのサービス。
///
/// 使い方（各画面のState内）:
/// ```dart
/// ScreenPermissions? _perm;
///
/// @override
/// void initState() {
///   super.initState();
///   PermissionService.instance.loadForScreen('engineerInputForm').then((p) {
///     if (mounted) setState(() => _perm = p);
///   });
/// }
///
/// @override
/// Widget build(BuildContext context) {
///   if (_perm == null) {
///     return const Scaffold(body: Center(child: CircularProgressIndicator()));
///   }
///   if (!_perm!.canViewScreen) {
///     return const Scaffold(body: Center(child: Text('この画面にアクセスする権限がありません。')));
///   }
///   return Scaffold(
///     body: Column(
///       children: [
///         if (_perm!.canViewItem('苗字'))
///           TextField(
///             enabled: _perm!.canEditItem('苗字'),
///             decoration: const InputDecoration(labelText: '苗字'),
///           ),
///       ],
///     ),
///   );
/// }
/// ```
///
/// 注意: これはあくまで「UI上の見た目・操作可否」を制御するものであり、
/// 悪意あるクライアントは無視して直接Firestoreへ書き込める。
/// 本当に守りたいデータは、必ずFirestoreセキュリティルール側でも
/// 二重にチェックすること（このファイルの末尾コメント参照）。
class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  static const String _collection = 'permissionMatrix';

  String? _cachedRole;
  Future<String>? _roleFuture;

  /// スクリーン単位の permissionMatrix ドキュメントのキャッシュ。
  /// screenKey -> 取得済みドキュメントデータ
  final Map<String, Map<String, dynamic>?> _screenDataCache = {};

  /// テスト・ログアウト時などにキャッシュをクリアしたい場合に呼ぶ。
  void clearCache() {
    _cachedRole = null;
    _roleFuture = null;
    _screenDataCache.clear();
  }

  Future<String> _getMyRole() {
    if (_cachedRole != null) return Future.value(_cachedRole);
    _roleFuture ??= _fetchRole();
    return _roleFuture!;
  }

  Future<String> _fetchRole() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return constData.roleMember;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final role = (doc.data()?['role'] as String?) ?? constData.roleMember;
    _cachedRole = role;
    return role;
  }

  Future<Map<String, dynamic>?> _fetchScreenData(String screenKey) async {
    if (_screenDataCache.containsKey(screenKey)) {
      return _screenDataCache[screenKey];
    }
    final query = await FirebaseFirestore.instance
        .collection(_collection)
        .where('screenKey', isEqualTo: screenKey)
        .limit(1)
        .get();

    final data = query.docs.isEmpty ? null : query.docs.first.data();
    _screenDataCache[screenKey] = data;
    return data;
  }

  /// 指定した [screenKey] に対応する permissionMatrix ドキュメントを取得し、
  /// 現在ログイン中ユーザーのロールに基づいた [ScreenPermissions] を返す。
  ///
  /// permissionMatrix にその画面がまだ登録されていない場合は、
  /// [ScreenPermissions.deny]（閲覧・編集どちらも不可）を返す＝安全側に倒す。
  /// これにより「権限設定に登録し忘れている画面が誰でも見られてしまう」事故を防ぐ。
  Future<ScreenPermissions> loadForScreen(String screenKey) async {
    final role = await _getMyRole();
    final data = await _fetchScreenData(screenKey);

    if (data == null) {
      return ScreenPermissions.deny();
    }

    final viewMap = Map<String, dynamic>.from(data['view'] ?? {});
    final bool canViewScreen = viewMap[role] ?? false;

    final byItemName = <String, _ItemPermission>{};
    final byFieldKey = <String, _ItemPermission>{};

    for (final raw in List<dynamic>.from(data['items'] ?? [])) {
      final item = Map<String, dynamic>.from(raw as Map);
      final String itemName = item['itemName'] ?? '';
      final bool view = Map<String, dynamic>.from(item['view'] ?? {})[role] ?? false;
      final bool edit = Map<String, dynamic>.from(item['edit'] ?? {})[role] ?? false;
      final perm = _ItemPermission(view, edit);

      byItemName[itemName] = perm;
      for (final fk in List<dynamic>.from(item['fieldKeys'] ?? [])) {
        byFieldKey[fk as String] = perm;
      }
    }

    return ScreenPermissions._(canViewScreen, byItemName, byFieldKey);
  }
}

/// ---------------------------------------------------------------------
/// Firestoreセキュリティルールについて（重要）
/// ---------------------------------------------------------------------
/// PermissionService はあくまでクライアント側のUI制御用。
/// ここでの canEdit* が false でも、悪意あるクライアントは直接Firestore APIを
/// 叩いて `engineer` コレクションを書き換えられてしまう。
///
/// そのため、実データを守るには最低限、Firestoreセキュリティルール側で
/// 「member/adminロールごとに、そもそもそのコレクションへの書き込みを許可するか」
/// を role ベースで制御することを推奨する（rules.example.txt などに分離推奨）。
///
/// 例（rules.example）:
/// ```
/// function getRole(uid) {
///   return get(/databases/$(database)/documents/users/$(uid)).data.role;
/// }
///
/// match /engineer/{doc} {
///   allow read: if request.auth != null;
///   allow create, update: if request.auth != null
///     && getRole(request.auth.uid) in ['member', 'admin', 'owner'];
///   allow delete: if request.auth != null
///     && getRole(request.auth.uid) in ['admin', 'owner'];
/// }
/// ```
///
/// permissionMatrix の項目単位（fieldKeys単位）の編集可否まで
/// セキュリティルールで動的にチェックすることも技術的には可能だが
/// （ルール内から `get()` で permissionMatrix ドキュメントを読み、
/// items配列をループしてfieldKeysを突き合わせる）、
/// ルールの実行コスト・複雑さ・保守性の面で現実的ではないことが多い。
/// 「member/adminという大枠の権限」はルールで守り、
/// 「画面のどの項目を見せる/編集させるか」というきめ細かい制御は
/// このPermissionServiceによるUI制御に任せる、という役割分担を推奨する。
