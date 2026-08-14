import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:skill_search_model/common/constData.dart';
import 'package:skill_search_model/utils/uiUtils.dart';

class PermissionSettingsScreen extends StatefulWidget {
  const PermissionSettingsScreen({super.key});

  @override
  State<PermissionSettingsScreen> createState() => _PermissionSettingsScreenState();
}

class _PermissionSettingsScreenState extends State<PermissionSettingsScreen> {
  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _verticalController.dispose();
    _horizontalController.dispose();
    super.dispose();
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

        // 権限チェック: owner または admin 以外はアクセス拒否
        if (myRole != constData.roleOwner && myRole != constData.roleAdmin) {
          return const Scaffold(body: Center(child: Text('この画面にアクセスする権限がありません。')));
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('権限設定', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black87),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('registrationDate', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

              final filteredUsers = snapshot.data!.docs.where((doc) {
                final targetData = doc.data() as Map<String, dynamic>;
                final targetRole = targetData['role'] ?? constData.roleMember;
                final targetCompanyCode = targetData['companyCode'] ?? '';

                // admin権限の場合、自社のユーザー（かつowner以外）のみ表示
                if (myRole == constData.roleAdmin) {
                  if (targetRole == constData.roleOwner) return false;
                  if (targetCompanyCode != myCompanyCode) return false;
                }
                return true;
              }).toList();

              return Scrollbar(
                controller: _verticalController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _verticalController,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Scrollbar(
                      controller: _horizontalController,
                      thumbVisibility: true,
                      notificationPredicate: (notif) => notif.depth == 1,
                      child: SingleChildScrollView(
                        controller: _horizontalController,
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.grey[200]),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(Colors.grey[100]),
                              dataRowMaxHeight: 65,
                              columns: [
                                const DataColumn(label: Text('表示名 / メールアドレス')),
                                const DataColumn(label: Text('権限レベル')),
                                if (myRole == constData.roleOwner) const DataColumn(label: Text('法人コード')),
                                const DataColumn(label: Text('編集可否')),
                                const DataColumn(label: Text('書出可否')),
                                const DataColumn(label: Text('登録日時')),
                                const DataColumn(label: Text('操作')),
                              ],
                              rows: filteredUsers.map((doc) => _buildDataRow(context, doc, myRole)).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  DataRow _buildDataRow(BuildContext context, QueryDocumentSnapshot doc, String myRole) {
    final data = doc.data() as Map<String, dynamic>;
    final permissions = data['permissions'] as Map<String, dynamic>? ?? {};
    final String currentRole = data['role'] ?? constData.roleMember;
    final String photoUrl = data['photoURL'] ?? "";
    final String companyCode = data['companyCode'] ?? '';

    List<String> availableRoles = List.from(constData.roleList);
    if (myRole == constData.roleAdmin) {
      availableRoles.remove(constData.roleOwner);
    }

    return DataRow(cells: [
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: (photoUrl.isNotEmpty) ? NetworkImage(photoUrl) : null,
              child: (photoUrl.isEmpty) ? const Icon(Icons.person, size: 16) : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(data['displayName'] ?? '未設定', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(data['email'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
      DataCell(
        DropdownButton<String>(
          value: availableRoles.contains(currentRole) ? currentRole : null,
          items: availableRoles.map((roleKey) => DropdownMenuItem(
              value: roleKey,
              child: Text(UIUtils.getRoleDisplayName(roleKey), style: const TextStyle(fontSize: 13))
          )).toList(),
          onChanged: (val) => _updateUserField(context, doc.id, 'role', val),
          underline: const SizedBox(),
        ),
      ),
      if (myRole == constData.roleOwner)
        DataCell(Text(companyCode.isEmpty ? '-' : companyCode, style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
      DataCell(
        Switch(
          value: permissions['canEdit'] ?? false,
          activeColor: constData.themeGreen,
          onChanged: (val) => _updatePermissionField(context, doc.id, 'canEdit', val),
        ),
      ),
      DataCell(
        Switch(
          value: permissions['canExport'] ?? false,
          activeColor: constData.themeGreen,
          onChanged: (val) => _updatePermissionField(context, doc.id, 'canExport', val),
        ),
      ),
      DataCell(Text(_formatDate(data['registrationDate']), style: const TextStyle(fontSize: 12))),
      DataCell(
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
          onPressed: () => _showDeleteConfirm(context, doc.id, data['displayName'] ?? data['email']),
        ),
      ),
    ]);
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) return DateFormat('yyyy/MM/dd HH:mm').format(timestamp.toDate());
    return '-';
  }

  Future<void> _updateUserField(BuildContext context, String docId, String field, dynamic value) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        field: value,
        'updateDate': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('設定を保存しました'), duration: Duration(seconds: 1)));
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showResultDialog(context, title: 'エラー', message: '保存に失敗しました: $e', isError: true);
      }
    }
  }

  Future<void> _updatePermissionField(BuildContext context, String docId, String field, bool value) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'permissions.$field': value,
        'updateDate': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('権限を更新しました'), duration: Duration(seconds: 1)));
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showResultDialog(context, title: 'エラー', message: '保存に失敗しました: $e', isError: true);
      }
    }
  }

  void _showDeleteConfirm(BuildContext context, String docId, String name) async {
    final bool deleted = await UIUtils.showDeleteDialog(
        context,
        title: 'ユーザー削除',
        content: '$name さんのデータを削除しますか？\n(Firestoreからドキュメントが削除されます)',
        collectionPath: 'users',
        documentId: docId
    );

    if (deleted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('削除しました')));
    }
  }
}