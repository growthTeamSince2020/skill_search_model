import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PermissionSettingsScreen extends StatelessWidget {
  const PermissionSettingsScreen({super.key});

  // ロールの論理名マップ
  static const Map<String, String> roleLabels = {
    'admin': '管理者(admin)',
    'editor': '編集者(editor)',
    'viewer': '閲覧者(viewer)',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('権限設定', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          TextButton.icon(
            onPressed: () => _showAddUserDialog(context),
            icon: const Icon(Icons.person_add, color: Color(0xFF2E7D32)),
            label: const Text('ユーザー追加', style: TextStyle(color: Color(0xFF2E7D32))),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('registrationDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs;

          // 1. 垂直スクロールバー
          return Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Padding(
                padding: const EdgeInsets.all(8.0), // 余白を少し調整
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 2. 水平スクロールバー
                    Scrollbar(
                      notificationPredicate: (notif) => notif.depth == 1,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: ConstrainedBox(
                          // ★スマホで「見切れ」を防ぐため、テーブルの最低横幅を強制する
                          constraints: BoxConstraints(
                            minWidth: MediaQuery.of(context).size.width,
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(dividerColor: Colors.grey[200]),
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
                              dataRowHeight: 65,
                              columnSpacing: 24,
                              // ★重要：横幅が狭い時に自動で詰めすぎないように設定
                              horizontalMargin: 12,
                              columns: const [
                                DataColumn(label: Text('表示名 / メールアドレス')),
                                DataColumn(label: Text('権限レベル')),
                                DataColumn(label: Text('編集可否')),
                                DataColumn(label: Text('書出可否')),
                                DataColumn(label: Text('登録日時')),
                                DataColumn(label: Text('ユーザID(UID)')),
                                DataColumn(label: Text('操作')),
                              ],
                              rows: users.map((doc) => _buildDataRow(context, doc)).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // テーブルの各行を作成するメソッド
  DataRow _buildDataRow(BuildContext context, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final permissions = data['permissions'] as Map<String, dynamic>? ?? {};
    final String currentRole = data['role'] ?? 'viewer';
    final String photoUrl = data['photoURL'] ?? "";

    return DataRow(cells: [
      // 表示名 / メールアドレス
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              // null または 空文字 "" の場合はアイコンを表示
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
      // 権限レベル
      DataCell(
        DropdownButton<String>(
          value: roleLabels.containsKey(currentRole) ? currentRole : 'viewer',
          items: roleLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (val) => _updateUserField(doc.id, 'role', val),
          underline: const SizedBox(),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ),
      // 編集可否
      DataCell(
        Switch(
          value: permissions['canEdit'] ?? false,
          activeColor: const Color(0xFF2E7D32),
          onChanged: (val) => _updatePermissionField(doc.id, 'canEdit', val),
        ),
      ),
      // 書出可否
      DataCell(
        Switch(
          value: permissions['canExport'] ?? false,
          activeColor: const Color(0xFF2E7D32),
          onChanged: (val) => _updatePermissionField(doc.id, 'canExport', val),
        ),
      ),
      // 登録日時
      DataCell(Text(_formatDate(data['registrationDate']), style: const TextStyle(fontSize: 12))),
      // UID
      DataCell(
        SelectableText(
            data['uid'] ?? '',
            style: const TextStyle(fontSize: 10, fontFamily: 'monospace', color: Colors.grey)
        ),
      ),
      // 削除
      DataCell(
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
          onPressed: () => _showDeleteConfirm(context, doc.id, data['displayName'] ?? data['email']),
        ),
      ),
    ]);
  }

  // --- 共通ロジック ---

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('yyyy/MM/dd HH:mm').format(timestamp.toDate());
    }
    return '-';
  }

  Future<void> _updateUserField(String docId, String field, dynamic value) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).update({
      field: value,
      'updateDate': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _updatePermissionField(String docId, String field, bool value) async {
    await FirebaseFirestore.instance.collection('users').doc(docId).update({
      'permissions.$field': value,
      'updateDate': FieldValue.serverTimestamp(),
    });
  }

  void _showAddUserDialog(BuildContext context) {
    final emailController = TextEditingController();
    final nameController = TextEditingController();
    final uidController = TextEditingController();
    final photoController = TextEditingController();
    String selectedRole = 'viewer';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('新規ユーザー追加', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: uidController,
                    decoration: const InputDecoration(labelText: 'ユーザID (UID) *必須', hintText: 'FirebaseのUIDを入力'),
                    validator: (value) => (value == null || value.isEmpty) ? 'ユーザIDを入力してください' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: '表示名', hintText: '例：山田 太郎'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'メールアドレス', hintText: 'example@gmail.com'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: photoController,
                    decoration: const InputDecoration(labelText: 'プロフィール画像URL', hintText: 'https://example.com/image.png'),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: '初期権限'),
                    items: roleLabels.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (val) => setState(() => selectedRole = val!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  await FirebaseFirestore.instance.collection('users').doc(uidController.text.trim()).set({
                    'uid': uidController.text.trim(),
                    'email': emailController.text.trim(),
                    'displayName': nameController.text.trim().isEmpty ? '未設定' : nameController.text.trim(),
                    'photoURL': photoController.text.trim().isEmpty ? "" : photoController.text.trim(),
                    'role': selectedRole,
                    'permissions': {'canEdit': false, 'canExport': false},
                    'registrationDate': FieldValue.serverTimestamp(),
                    'updateDate': FieldValue.serverTimestamp(),
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('追加', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, String docId, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ユーザー削除'),
        content: Text('$name さんの権限データを削除しますか？\n（本人のアカウント自体は削除されません）'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(docId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}