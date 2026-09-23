import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:skill_search_model/common/constData.dart';
import 'package:skill_search_model/utils/uiUtils.dart';

/// 画面幅に応じて拡大される列幅をまとめて持つ値オブジェクト。
class _ColWidths {
  final double screen;
  final double item;
  final double perm;
  final double action;

  const _ColWidths({required this.screen, required this.item, required this.perm, required this.action});
}

/// 権限設定画面
///
/// Firestore コレクション `permissionMatrix` は「画面単位で1ドキュメント」を持つ設計。
/// 画面が増えるたびに、このコレクションへドキュメントを1件追加するだけで表に反映される。
///
/// ドキュメント構造 (collection: permissionMatrix):
/// {
///   screenKey:  string,   // コードから参照する安定したID (例: "engineerInputForm")
///   screenName: string,   // 画面表示名 (例: "技術者登録フォーム")
///   order:      number,   // 画面の表示順（0始まり）
///   view: { member: bool, admin: bool, owner: bool },   // 画面全体の閲覧権限
///   items: [                                            // 画面内の項目一覧（配列。並び順=表示順）
///     {
///       itemName: string,
///       fieldKeys: array<string>,  // この項目が対応する実データ（例: engineerコレクション）の
///                                   // フィールド名。1項目が複数フィールドに対応する場合あり
///                                   // (例: "チーム役割" -> ["team_role","team_role_years"])。
///                                   // ボタン等、実データを持たない項目は空配列 []。
///       view: { member: bool, admin: bool, owner: bool },
///       edit: { member: bool, admin: bool, owner: bool },
///     },
///     ...
///   ],
/// }
///
/// 注意: items は配列のため、項目1件だけの更新であっても
///       Dart側で配列全体を作り直して `update({'items': newList})` する。
///
/// fieldKeys は「この画面項目の編集権限がないロールは、対応するフィールドを
/// 保存/更新できないようにする」といった、実データ側のアクセス制御と紐付ける
/// ためのキーであり、permissionMatrix 自体はあくまで「画面の表示・操作」に対する
/// 権限設定である点に注意（engineerコレクションのスキーマそのものではない）。
///
/// 表示仕様:
/// - 列は「画面」「画面項目」「閲覧権限(member/admin/owner)」「編集権限(member/admin/owner)」
/// - ログイン中のロールが owner でない場合（＝admin）、保守担当(owner)列は
///   閲覧・編集どちらも非表示にする（自分より上位ロールの権限設定を admin には見せない）
class PermissionSettingsScreen extends StatefulWidget {
  const PermissionSettingsScreen({super.key});

  @override
  State<PermissionSettingsScreen> createState() => _PermissionSettingsScreenState();
}

class _PermissionSettingsScreenState extends State<PermissionSettingsScreen> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  late final Future<DocumentSnapshot> _userFuture;

  @override
  void initState() {
    super.initState();
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    // ロール取得を1回だけ行い、Future をキャッシュする。
    // build() のたびに再取得しない & Scaffold/AppBarの骨格を常に一定に保つことで、
    // 「ロール判定完了後にボタンが出現して周辺が動く」というレイアウトシフトを避ける。
    _userFuture = FirebaseFirestore.instance.collection('users').doc(currentUid).get();
  }

  static const String _collection = 'permissionMatrix';

  // 列幅（基準値。画面幅が広い場合はこれを基準に比例拡大する）
  static const double _baseWScreen = 140;
  static const double _baseWItem = 180;
  static const double _baseWPerm = 96;
  static const double _wAction = 56; // 操作列はボタンサイズ固定のため拡大しない

  static const List<String> _allRoles = [
    constData.roleMember,
    constData.roleAdmin,
    constData.roleOwner,
  ];

  /// ログイン中のロールに応じて表示するロール列を決定する。
  /// owner でログインしている場合のみ、保守担当(owner)列を表示する。
  List<String> _visibleRoles(String myRole) {
    if (myRole == constData.roleOwner) return _allRoles;
    return _allRoles.where((r) => r != constData.roleOwner).toList();
  }

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
  }

  /// 画面幅（availableWidth）に応じた列幅を計算する。
  /// テーブル本来の幅（自然幅）より画面が広い場合は、操作列(action)以外を
  /// 比例的に引き伸ばして画面幅にぴったり合わせる（PCで右側が余るのを防ぐ）。
  /// 画面が狭い場合（スマホ等）は自然幅のまま返し、横スクロールで対応する。
  _ColWidths _calcColWidths(double availableWidth, int roleCount) {
    final double naturalWithoutAction = _baseWScreen + _baseWItem + _baseWPerm * roleCount * 2;
    final double naturalTotal = naturalWithoutAction + _wAction;

    if (availableWidth <= naturalTotal) {
      return _ColWidths(screen: _baseWScreen, item: _baseWItem, perm: _baseWPerm, action: _wAction);
    }

    final double scale = (availableWidth - _wAction) / naturalWithoutAction;
    return _ColWidths(
      screen: _baseWScreen * scale,
      item: _baseWItem * scale,
      perm: _baseWPerm * scale,
      action: _wAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: _userFuture,
      builder: (context, userSnapshot) {
        final bool roleLoaded = userSnapshot.connectionState == ConnectionState.done;
        final userData = userSnapshot.data?.data() as Map<String, dynamic>?;
        final String myRole = userData?['role'] ?? constData.roleMember;
        final bool hasAccess = roleLoaded && (myRole == constData.roleOwner || myRole == constData.roleAdmin);
        // ○/―の切替（書き込み）は owner・admin 双方に許可
        // （owner列自体は admin ログイン時には非表示になるため、
        //   admin が実際に編集できるのは member/admin 列のみ）
        final bool canEdit = hasAccess;
        final List<String> visibleRoles = _visibleRoles(myRole);

        // Scaffold/AppBar は常に同じ骨格で返す（ロード中・エラー・表示中で
        // ウィジェットツリーの形自体が変わらないようにし、レイアウトシフトを防ぐ）。
        return Scaffold(
          appBar: AppBar(
            title: const Text('権限設定', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87),
            actions: [
              // ロール判定が完了する前から領域を確保しておくことで、
              // ボタンが後から出現して周辺のレイアウトが動く（CLS）のを防ぐ。
              Visibility(
                visible: canEdit,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: _smallIconButton(
                  icon: Icons.add_to_photos_outlined,
                  color: Colors.black87,
                  size: 22,
                  tooltip: '画面を追加',
                  onPressed: canEdit ? () => _showAddScreenDialog(context) : null,
                ),
              ),
            ],
          ),
          body: !roleLoaded
              ? const Center(child: CircularProgressIndicator())
              : !hasAccess
              ? const Center(child: Text('この画面にアクセスする権限がありません。'))
              : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection(_collection).orderBy('order').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return _buildEmptyState(context, canEdit);
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final cw = _calcColWidths(constraints.maxWidth, visibleRoles.length);
                  return SingleChildScrollView(
                    controller: _verticalController,
                    child: SingleChildScrollView(
                      controller: _horizontalController,
                      scrollDirection: Axis.horizontal,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(visibleRoles, cw),
                          for (final doc in docs) ..._buildScreenBlock(context, doc, canEdit, visibleRoles, cw),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------
  // ヘッダー（二段: 「閲覧権限/編集権限」グループ行 + ロール名行）
  // ---------------------------------------------------------------------
  Widget _buildHeader(List<String> visibleRoles, _ColWidths cw) {
    const groupColor = Color(0xFF1B3A5C);
    const roleRowColor = Color(0xFF2E5A8C);
    final double permGroupWidth = cw.perm * visibleRoles.length;

    Widget groupCell(String text, double width, {Color? bg}) => Container(
      width: width,
      height: 32,
      alignment: Alignment.center,
      color: bg ?? groupColor,
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
    );

    Widget roleCell(String text, double width) => Container(
      width: width,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: roleRowColor,
        border: Border.all(color: Colors.white24, width: 0.5),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
    );

    return Column(
      children: [
        Row(
          children: [
            groupCell('画面', cw.screen),
            groupCell('画面項目', cw.item),
            groupCell('閲覧権限', permGroupWidth, bg: const Color(0xFF1B5C4A)),
            groupCell('編集権限', permGroupWidth, bg: const Color(0xFF5C1B2E)),
            groupCell('', cw.action),
          ],
        ),
        Row(
          children: [
            roleCell('', cw.screen),
            roleCell('', cw.item),
            for (final r in visibleRoles) roleCell(UIUtils.getRoleDisplayName(r), cw.perm),
            for (final r in visibleRoles) roleCell(UIUtils.getRoleDisplayName(r), cw.perm),
            roleCell('', cw.action),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------
  // 画面ブロック（見出し行 + その画面の項目行たち）
  // ---------------------------------------------------------------------
  List<Widget> _buildScreenBlock(
      BuildContext context,
      QueryDocumentSnapshot doc,
      bool canEdit,
      List<String> visibleRoles,
      _ColWidths cw,
      ) {
    final data = doc.data() as Map<String, dynamic>;
    final String screenName = data['screenName'] ?? '';
    final Map<String, dynamic> screenView = Map<String, dynamic>.from(data['view'] ?? {});
    final List<dynamic> items = List<dynamic>.from(data['items'] ?? []);

    final List<Widget> rows = [];

    // --- 画面ヘッダー行 ---
    rows.add(_row(
      leadingCells: [
        _textCell(screenName, cw.screen, bold: true, bg: const Color(0xFFD9E6F2)),
        _textCell('画面の閲覧権限', cw.item, bg: const Color(0xFFD9E6F2)),
      ],
      viewCells: [
        for (final r in visibleRoles)
          _permCell(
            value: screenView[r] ?? false,
            editable: canEdit,
            bg: const Color(0xFFD9E6F2),
            width: cw.perm,
            onTap: () => _toggleScreenView(doc.reference, r, screenView[r] ?? false),
          ),
      ],
      editCells: [
        for (final _ in visibleRoles)
          _permCell(value: false, editable: false, bg: const Color(0xFFD9E6F2), width: cw.perm, onTap: () {}),
      ],
      action: canEdit
          ? Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _smallIconButton(
            icon: Icons.add,
            color: Colors.black54,
            tooltip: '項目を追加',
            onPressed: () => _showAddItemDialog(context, doc.reference, items),
          ),
          _smallIconButton(
            icon: Icons.close,
            color: Colors.redAccent,
            tooltip: '画面ごと削除',
            onPressed: () => _confirmDeleteScreen(context, doc.reference, screenName),
          ),
        ],
      )
          : null,
      bg: const Color(0xFFD9E6F2),
    ));

    // --- 項目行 ---
    for (int i = 0; i < items.length; i++) {
      final item = Map<String, dynamic>.from(items[i]);
      final String itemName = item['itemName'] ?? '';
      final Map<String, dynamic> view = Map<String, dynamic>.from(item['view'] ?? {});
      final Map<String, dynamic> edit = Map<String, dynamic>.from(item['edit'] ?? {});

      rows.add(_row(
        leadingCells: [
          _textCell('', cw.screen, bg: Colors.white),
          _textCell(itemName, cw.item, bg: Colors.white, indent: true),
        ],
        viewCells: [
          for (final r in visibleRoles)
            _permCell(
              value: view[r] ?? false,
              editable: canEdit,
              bg: Colors.white,
              width: cw.perm,
              onTap: () => _toggleItemField(doc.reference, items, i, 'view', r, view[r] ?? false),
            ),
        ],
        editCells: [
          for (final r in visibleRoles)
            _permCell(
              value: edit[r] ?? false,
              editable: canEdit,
              bg: Colors.white,
              width: cw.perm,
              onTap: () => _toggleItemField(doc.reference, items, i, 'edit', r, edit[r] ?? false),
            ),
        ],
        action: canEdit
            ? _smallIconButton(
          icon: Icons.close,
          color: Colors.redAccent,
          onPressed: () => _confirmDeleteItem(context, doc.reference, items, i, itemName),
        )
            : null,
        bg: Colors.white,
      ));
    }

    return rows;
  }

  /// タップ時のホバー/リップルなどで見た目のサイズが変わらないよう、
  /// 明示的にサイズを固定した小さいアイコンボタン。
  Widget _smallIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    String? tooltip,
    double size = 16,
  }) {
    return IconButton(
      icon: Icon(icon, size: size, color: color),
      onPressed: onPressed,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
    );
  }

  Widget _row({
    required List<Widget> leadingCells,
    required List<Widget> viewCells,
    required List<Widget> editCells,
    required Widget? action,
    required Color bg,
  }) {
    return Row(
      children: [
        ...leadingCells,
        ...viewCells,
        ...editCells,
        Container(
          width: _wAction,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, border: Border.all(color: Colors.grey[300]!, width: 0.5)),
          child: action,
        ),
      ],
    );
  }

  Widget _textCell(String text, double width, {bool bold = false, required Color bg, bool indent = false}) {
    return Container(
      width: width,
      height: 44,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.only(left: indent ? 20 : 8, right: 8),
      decoration: BoxDecoration(color: bg, border: Border.all(color: Colors.grey[300]!, width: 0.5)),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.bold : FontWeight.normal),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _permCell({
    required bool value,
    required bool editable,
    required Color bg,
    required double width,
    required VoidCallback onTap,
  }) {
    final child = Container(
      width: width,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, border: Border.all(color: Colors.grey[300]!, width: 0.5)),
      child: value
          ? Icon(Icons.circle, size: 12, color: constData.themeGreen)
          : Text('―', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
    );
    if (!editable) return child;
    return InkWell(onTap: onTap, child: child);
  }

  // ---------------------------------------------------------------------
  // 更新系
  // ---------------------------------------------------------------------

  /// 画面全体の閲覧権限（ドキュメント直下の view）をトグル
  Future<void> _toggleScreenView(DocumentReference ref, String role, bool current) async {
    try {
      await ref.update({'view.$role': !current});
    } catch (e) {
      if (mounted) UIUtils.showResultDialog(context, title: 'エラー', message: '更新に失敗しました: $e', isError: true);
    }
  }

  /// items 配列内の特定要素の view/edit をトグル（配列を作り直して書き戻す）
  Future<void> _toggleItemField(
      DocumentReference ref,
      List<dynamic> items,
      int index,
      String kind, // 'view' or 'edit'
      String role,
      bool current,
      ) async {
    final newItems = items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final target = Map<String, dynamic>.from(newItems[index][kind] ?? {});
    target[role] = !current;
    newItems[index][kind] = target;
    try {
      await ref.update({'items': newItems});
    } catch (e) {
      if (mounted) UIUtils.showResultDialog(context, title: 'エラー', message: '更新に失敗しました: $e', isError: true);
    }
  }

  Future<void> _confirmDeleteScreen(BuildContext context, DocumentReference ref, String screenName) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('画面の削除'),
        content: Text('「$screenName」の設定を画面ごと削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('削除', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok == true) await ref.delete();
  }

  Future<void> _confirmDeleteItem(
      BuildContext context,
      DocumentReference ref,
      List<dynamic> items,
      int index,
      String itemName,
      ) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('項目の削除'),
        content: Text('「$itemName」を削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('削除', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (ok != true) return;
    final newItems = items.map((e) => Map<String, dynamic>.from(e as Map)).toList()..removeAt(index);
    await ref.update({'items': newItems});
  }

  Future<void> _showAddScreenDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final keyController = TextEditingController();
    final bulkItemsController = TextEditingController();
    final int currentCount = (await FirebaseFirestore.instance.collection(_collection).count().get()).count ?? 0;
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('画面を追加'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: '画面名 (例: 技術者登録フォーム)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: keyController,
                decoration: const InputDecoration(
                  labelText: '画面キー（コードから参照するID）',
                  hintText: '例: engineerInputForm',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '対象画面のウィジェットクラス名など、コード上で一意になる文字列を入れてください。',
                style: TextStyle(fontSize: 11, color: Colors.black38),
              ),
              const SizedBox(height: 16),
              const Text(
                '画面項目の一括入力（任意・1行に1項目）',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              const Text(
                '書式: 項目名  または  項目名|フィールドキー1,フィールドキー2\n'
                    '例: チーム役割|team_role,team_role_years',
                style: TextStyle(fontSize: 11, color: Colors.black38),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bulkItemsController,
                maxLines: 8,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '苗字|last_name\nチーム役割|team_role,team_role_years\n登録内容を確認するボタン',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final screenKey = keyController.text.trim();

              final items = _parseBulkItemsText(bulkItemsController.text);

              await FirebaseFirestore.instance.collection(_collection).add({
                'screenKey': screenKey,
                'screenName': name,
                'order': currentCount,
                'view': {for (final r in _allRoles) r: true},
                'items': items,
              });
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  /// 「項目名」または「項目名|フィールドキー1,フィールドキー2」形式のテキスト（1行1項目）を
  /// items 配列 (List<Map<String, dynamic>>) にパースする。
  /// view はデフォルト全ロールtrue、edit はデフォルト全ロールfalseで生成し、
  /// 詳細な権限は投入後に表からタップして調整する想定。
  List<Map<String, dynamic>> _parseBulkItemsText(String raw) {
    final lines = raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    return lines.map((line) {
      final parts = line.split('|');
      final itemName = parts[0].trim();
      final fieldKeys = parts.length > 1
          ? parts[1].split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
          : <String>[];
      return {
        'itemName': itemName,
        'fieldKeys': fieldKeys,
        'view': {for (final r in _allRoles) r: true},
        'edit': {for (final r in _allRoles) r: false},
      };
    }).toList();
  }

  Future<void> _showAddItemDialog(BuildContext context, DocumentReference ref, List<dynamic> items) async {
    final nameController = TextEditingController();
    final fieldKeysController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('項目を追加'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: '画面項目名 (例: 苗字)')),
            const SizedBox(height: 12),
            TextField(
              controller: fieldKeysController,
              decoration: const InputDecoration(
                labelText: '対応フィールド名（カンマ区切り、任意）',
                hintText: '例: last_name もしくは team_role,team_role_years',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final fieldKeys = fieldKeysController.text
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
              final newItems = items.map((e) => Map<String, dynamic>.from(e as Map)).toList();
              newItems.add({
                'itemName': name,
                'fieldKeys': fieldKeys,
                'view': {for (final r in _allRoles) r: true},
                'edit': {for (final r in _allRoles) r: false},
              });
              await ref.update({'items': newItems});
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------
  // 初期データ投入（コレクションが空のとき）— 技術者登録の2画面をベースに投入
  // ---------------------------------------------------------------------
  Widget _buildEmptyState(BuildContext context, bool canEdit) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('権限マトリクスのデータがまだありません。'),
          const SizedBox(height: 12),
          if (canEdit)
            ElevatedButton(
              onPressed: () => _seedInitialData(context),
              child: const Text('技術者登録の2画面を投入する'),
            ),
        ],
      ),
    );
  }

  /// engineerInputForm.dart / engineerRegistrationScreen.dart の実装に準拠した初期データ。
  /// 今後、新しい画面を作った際はこの関数のパターンを参考に
  /// 「1画面 = 1ドキュメント（screenName / order / view / items）」を追加していく。
  Future<void> _seedInitialData(BuildContext context) async {
    Map<String, bool> allTrue() => {for (final r in _allRoles) r: true};

    Map<String, dynamic> item(String name, {bool editableByAll = true, List<String> fieldKeys = const []}) => {
      'itemName': name,
      'fieldKeys': fieldKeys,
      'view': allTrue(),
      'edit': editableByAll ? allTrue() : {for (final r in _allRoles) r: false},
    };

    final screens = <Map<String, dynamic>>[
      {
        'screenKey': 'engineerInputForm',
        'screenName': '技術者登録フォーム',
        'order': 0,
        'view': allTrue(),
        'items': [
          item('苗字', fieldKeys: ['last_name']),
          item('名', fieldKeys: ['first_name']),
          item('年齢', fieldKeys: ['age']),
          item('最寄沿線', fieldKeys: ['nearest_station_line_name']),
          item('最寄駅', fieldKeys: ['nearest_station_name']),
          item('チーム役割', fieldKeys: ['team_role', 'team_role_years']),
          item('工程', fieldKeys: ['process', 'process_experience']),
          item('経験言語', fieldKeys: ['code_languages', 'code_languages_years']),
          item('DB言語', fieldKeys: ['db_experience', 'db_experience_years']),
          item('OS', fieldKeys: ['os_experience', 'os_experience_years']),
          item('クラウド技術', fieldKeys: ['cloud_technology', 'cloud_technology_years']),
          item('ツール', fieldKeys: ['tool', 'tool_years']),
          item('登録内容を確認するボタン'),
        ],
      },
      {
        'screenKey': 'engineerRegistrationScreen',
        'screenName': '登録内容確認',
        'order': 1,
        'view': allTrue(),
        'items': [
          item('氏名', editableByAll: false, fieldKeys: ['last_name', 'first_name']),
          item('年齢', editableByAll: false, fieldKeys: ['age']),
          item('最寄', editableByAll: false, fieldKeys: ['nearest_station_line_name', 'nearest_station_name']),
          item('チーム役割', editableByAll: false, fieldKeys: ['team_role', 'team_role_years']),
          item('工程', editableByAll: false, fieldKeys: ['process', 'process_experience']),
          item('経験言語', editableByAll: false, fieldKeys: ['code_languages', 'code_languages_years']),
          item('DB経験', editableByAll: false, fieldKeys: ['db_experience', 'db_experience_years']),
          item('OS経験', editableByAll: false, fieldKeys: ['os_experience', 'os_experience_years']),
          item('クラウド技術', editableByAll: false, fieldKeys: ['cloud_technology', 'cloud_technology_years']),
          item('ツール', editableByAll: false, fieldKeys: ['tool', 'tool_years']),
          item('この内容で登録するボタン',
              fieldKeys: ['id', 'companyCode', 'registration_date', 'update_date']),
          item('入力をやり直すボタン'),
        ],
      },
    ];

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('初期データ投入'),
        content: const Text('技術者登録フォーム・登録内容確認の2画面分を投入します。よろしいですか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('キャンセル')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('投入する')),
        ],
      ),
    );
    if (confirmed != true) return;

    final col = FirebaseFirestore.instance.collection(_collection);
    final batch = FirebaseFirestore.instance.batch();
    for (final s in screens) {
      batch.set(col.doc(), s);
    }
    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('初期データを投入しました')));
    }
  }
}