import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:skill_search_model/common/constData.dart';
import 'package:skill_search_model/utils/uiUtils.dart';

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  // スクロール制御用
  final ScrollController _verticalControllerLeft = ScrollController();
  final ScrollController _verticalControllerRight = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  final Set<String> _selectedUids = {};

  final Map<String, TextEditingController> _filterControllers = {
    'name': TextEditingController(),
    'role': TextEditingController(),
    'company': TextEditingController(),
    'uid': TextEditingController(),
  };

  final Map<String, FocusNode> _filterFocusNodes = {
    'name': FocusNode(),
    'role': FocusNode(),
    'company': FocusNode(),
    'uid': FocusNode(),
  };

  Timer? _debounce;

  static const double colWidthName = 220.0;
  static const double colWidthRole = 160.0;
  static const double colWidthCompany = 120.0;
  static const double colWidthDate = 160.0;
  static const double colWidthUid = 200.0;
  static const double colWidthAction = 80.0;
  static const double rowHeight = 60.0;

  @override
  void initState() {
    super.initState();
    _verticalControllerLeft.addListener(() {
      if (_verticalControllerLeft.offset != _verticalControllerRight.offset) {
        _verticalControllerRight.jumpTo(_verticalControllerLeft.offset);
      }
    });
    _verticalControllerRight.addListener(() {
      if (_verticalControllerRight.offset != _verticalControllerLeft.offset) {
        _verticalControllerLeft.jumpTo(_verticalControllerRight.offset);
      }
    });
  }

  @override
  void dispose() {
    _verticalControllerLeft.dispose();
    _verticalControllerRight.dispose();
    _horizontalController.dispose();
    _filterControllers.forEach((k, v) => v.dispose());
    _filterFocusNodes.forEach((k, v) => v.dispose());
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String key) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      final controller = _filterControllers[key];
      if (controller != null && controller.value.composing.isValid) {
        return;
      }

      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(currentUid).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
        final String myRole = userData?['role'] ?? constData.roleMember;
        final String myCompanyCode = userData?['companyCode'] ?? '';

        if (myRole != constData.roleOwner && myRole != constData.roleAdmin) {
          return const Scaffold(body: Center(child: Text('アクセス権限がありません')));
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('アカウント管理', style: TextStyle(fontWeight: FontWeight.bold)),
            actions: [
              if (_selectedUids.isNotEmpty)
                TextButton.icon(
                  onPressed: () => _showBulkDeleteConfirm(context),
                  icon: const Icon(Icons.delete_sweep, color: Colors.red),
                  label: Text('一括削除 (${_selectedUids.length})', style: const TextStyle(color: Colors.red)),
                ),
              // 「ユーザー追加」ボタンを削除しました（招待画面へ統合済みのため）
              const SizedBox(width: 16),
            ],
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').orderBy('registrationDate', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('エラー: ${snapshot.error}'));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (myRole == constData.roleAdmin) {
                  if ((data['role'] ?? constData.roleMember) == constData.roleOwner) return false;
                  if ((data['companyCode'] ?? '') != myCompanyCode) return false;
                }
                return true;
              });

              final filteredUsers = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final nameText = (data['displayName'] ?? '').toString() + (data['email'] ?? '').toString();
                final roleText = UIUtils.getRoleDisplayName(data['role']);

                return nameText.toLowerCase().contains(_filterControllers['name']!.text.toLowerCase()) &&
                    roleText.toLowerCase().contains(_filterControllers['role']!.text.toLowerCase()) &&
                    (data['companyCode'] ?? '').toString().toLowerCase().contains(_filterControllers['company']!.text.toLowerCase()) &&
                    doc.id.toLowerCase().contains(_filterControllers['uid']!.text.toLowerCase());
              }).toList();

              return Column(
                children: [
                  _buildStickyHeader(),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: colWidthName,
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                            child: ListView.builder(
                              controller: _verticalControllerLeft,
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) => _buildFixedNameRow(filteredUsers[index]),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Scrollbar(
                            controller: _horizontalController,
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              controller: _horizontalController,
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: colWidthRole + colWidthCompany + colWidthDate + colWidthUid + colWidthAction,
                                child: Scrollbar(
                                  controller: _verticalControllerRight,
                                  child: ListView.builder(
                                    controller: _verticalControllerRight,
                                    itemCount: filteredUsers.length,
                                    itemBuilder: (context, index) => _buildScrollableRow(context, filteredUsers[index], myRole),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStickyHeader() {
    return Container(
      color: Colors.grey[100],
      child: Column(
        children: [
          Row(
            children: [
              _headerSearchCell(colWidthName, '氏名/メール', 'name'),
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    children: [
                      _headerSearchCell(colWidthRole, '権限', 'role'),
                      _headerSearchCell(colWidthCompany, '法人', 'company'),
                      const SizedBox(width: colWidthDate),
                      _headerSearchCell(colWidthUid, 'UID', 'uid'),
                      const SizedBox(width: colWidthAction),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1, thickness: 2, color: Colors.black26),
          Row(
            children: [
              _headerLabelCell(colWidthName, '氏名 / メールアドレス'),
              Expanded(
                child: SingleChildScrollView(
                  controller: _horizontalController,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    children: [
                      _headerLabelCell(colWidthRole, '権限レベル'),
                      _headerLabelCell(colWidthCompany, '法人コード'),
                      _headerLabelCell(colWidthDate, '登録日時'),
                      _headerLabelCell(colWidthUid, 'UID'),
                      _headerLabelCell(colWidthAction, '操作'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1, thickness: 1, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _headerSearchCell(double width, String hint, String key) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event.logicalKey == LogicalKeyboardKey.backspace || event.logicalKey == LogicalKeyboardKey.delete) {
            return KeyEventResult.ignored;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          key: ValueKey('search_field_$key'),
          controller: _filterControllers[key],
          focusNode: _filterFocusNodes[key],
          style: const TextStyle(fontSize: 12),
          autocorrect: false,
          enableSuggestions: false,
          enableInteractiveSelection: true,
          decoration: InputDecoration(
            hintText: '$hint 検索',
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.search, size: 14),
            suffixIcon: _filterControllers[key]!.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, size: 14),
              onPressed: () {
                _filterControllers[key]!.clear();
                _filterFocusNodes[key]!.requestFocus();
                setState(() {});
              },
            )
                : null,
          ),
          onChanged: (v) => _onSearchChanged(key),
        ),
      ),
    );
  }

  Widget _headerLabelCell(double width, String label) {
    return Container(
      width: width,
      height: 40,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
    );
  }

  Widget _buildFixedNameRow(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isSelected = _selectedUids.contains(doc.id);
    return Container(
      height: rowHeight,
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.withOpacity(0.05) : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (val) => setState(() => val! ? _selectedUids.add(doc.id) : _selectedUids.remove(doc.id)),
            activeColor: constData.themeGreen,
          ),
          CircleAvatar(
              radius: 14,
              backgroundImage: (data['photoURL'] != null && data['photoURL'] != "") ? NetworkImage(data['photoURL']) : null,
              child: (data['photoURL'] == null || data['photoURL'] == "") ? const Icon(Icons.person, size: 14) : null
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['displayName'] ?? '未設定', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                Text(data['email'] ?? '', style: const TextStyle(fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollableRow(BuildContext context, QueryDocumentSnapshot doc, String myRole) {
    final data = doc.data() as Map<String, dynamic>;
    final bool isSelected = _selectedUids.contains(doc.id);
    final String currentRole = data['role'] ?? constData.roleMember;
    List<String> availableRoles = List.from(constData.roleList);
    if (myRole == constData.roleAdmin) availableRoles.remove(constData.roleOwner);

    return Container(
      height: rowHeight,
      decoration: BoxDecoration(
        color: isSelected ? Colors.green.withOpacity(0.05) : Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Container(
            width: colWidthRole,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
              value: availableRoles.contains(currentRole) ? currentRole : null,
              isExpanded: true,
              items: availableRoles.map((r) => DropdownMenuItem(value: r, child: Text(UIUtils.getRoleDisplayName(r), style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: (val) => _updateUserField(context, doc.id, 'role', val),
              underline: const SizedBox(),
            ),
          ),
          Container(width: colWidthCompany, padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(data['companyCode'] ?? '-', style: const TextStyle(fontSize: 12))),
          Container(width: colWidthDate, padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(data['registrationDate'] is Timestamp ? DateFormat('yyyy/MM/dd HH:mm').format((data['registrationDate'] as Timestamp).toDate()) : '-', style: const TextStyle(fontSize: 12))),
          Container(width: colWidthUid, padding: const EdgeInsets.symmetric(horizontal: 12), child: SelectableText(doc.id, style: const TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace'))),
          SizedBox(
            width: colWidthAction,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () => _showDeleteConfirm(context, doc.id, data['displayName'] ?? '未設定'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserField(BuildContext context, String docId, String field, dynamic value) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({field: value, 'updateDate': FieldValue.serverTimestamp()});
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('更新しました')));
    } catch (e) {
      if (mounted) await UIUtils.showResultDialog(context, title: 'エラー', message: '更新失敗: $e', isError: true);
    }
  }

  void _showDeleteConfirm(BuildContext context, String docId, String name) async {
    final deleted = await UIUtils.showDeleteDialog(context, title: 'ユーザー削除', content: '$name さんのデータを削除しますか？', collectionPath: 'users', documentId: docId);
    if (deleted && mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('削除完了')));
  }

  void _showBulkDeleteConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('一括削除'),
        content: Text('${_selectedUids.length} 名のデータを削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          TextButton(onPressed: () async {
            final batch = FirebaseFirestore.instance.batch();
            for (var id in _selectedUids) batch.delete(FirebaseFirestore.instance.collection('users').doc(id));
            await batch.commit();
            setState(() => _selectedUids.clear());
            Navigator.pop(context);
          }, child: const Text('削除', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}