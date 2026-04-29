import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_search_model/common/constData.dart';
import 'package:skill_search_model/engineerEditPage.dart';
import 'package:skill_search_model/utils/uiUtils.dart';

class EngineerSeachDetailPage extends StatefulWidget {
  final String engineerId;

  const EngineerSeachDetailPage({super.key, required this.engineerId});

  @override
  State<EngineerSeachDetailPage> createState() =>
      _EngineerSeachDetailPageState();
}

class _EngineerSeachDetailPageState extends State<EngineerSeachDetailPage> {

  late Future<DocumentSnapshot> _future;

  // masters を constData から取得するように変更
  final Map<String, List<String>> masters = constData.engineerMasters;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _future = FirebaseFirestore.instance
          .collection('engineer')
          .doc(widget.engineerId)
          .get();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: false,
        title: Row(
          children: [
            const Icon(
              Icons.assignment_ind,
              color: constData.themeGreen,
              size: 24,
            ),
            const SizedBox(width: 10),
            const Text(
              constData.engineerDetail,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        actions: [
          // 削除アイコン
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () async {
              // UIUtilsの共通メソッドを呼び出す
              final bool deleted = await UIUtils.showDeleteDialog(
                context,
                title: '技術者情報の削除',
                content: 'この技術者の情報を完全に削除しますか？\nこの操作は取り消せません。',
                collectionPath: 'engineer',
                documentId: widget.engineerId,
                //showIcon: true, // もし引数を追加した場合
              );

              // 削除が成功（true）した場合は、前の画面（一覧画面）へ戻る
              if (deleted && mounted) {
                Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('削除が完了しました')),
                );
              }
            },
          ),
          // 編集アイコン
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: constData.themeGreen),
            onPressed: () async {
              final snapshot = await _future;
              if (!snapshot.exists) return;
              final data = snapshot.data() as Map<String, dynamic>;

              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EngineerEditPage(
                    engineerId: widget.engineerId,
                    currentData: data,
                  ),
                ),
              );

              if (result == true) {
                _refreshData();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("エラーが発生しました"));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator(color: constData.themeGreen));
          if (!snapshot.hasData || !snapshot.data!.exists)
            return const Center(child: Text("データが見つかりません"));

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(data),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      _buildInfoCard(context, Icons.assignment_outlined, '役割・担当工程', [
                        _buildArrayList(context, '担当役割', data['team_role'], data['team_role_years'], 'team_role', 'team_role_years'),
                        const Divider(),
                        _buildArrayList(context, '経験工程', data['process'], data['process_experience'], 'process', 'process_experience'),
                      ]),
                      _buildInfoCard(context, Icons.code_outlined, '開発スキル詳細', [
                        _buildArrayList(context, 'プログラミング言語', data['code_languages'], data['code_languages_years'], 'code_languages', 'code_languages_years'),
                        _buildArrayList(context, 'データベース', data['db_experience'], data['db_experience_years'], 'db_experience', 'db_experience_years'),
                        _buildArrayList(context, 'クラウド技術', data['cloud_technology'], data['cloud_technology_years'], 'cloud_technology', 'cloud_technology_years'),
                        _buildArrayList(context, 'OS', data['os_experience'], data['os_experience_years'], 'os_experience', 'os_experience_years'),
                      ]),
                      _buildInfoCard(context, Icons.build_outlined, '使用ツール', [
                        _buildArrayList(context, 'ツール', data['tool'], data['tool_years'], 'tool', 'tool_years'),
                      ]),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    final double topPadding = MediaQuery.of(context).padding.top + kToolbarHeight;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 10, 20, 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: constData.themeGreen.withOpacity(0.2), width: 3),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: constData.themeGreen.withOpacity(0.05),
              child: const Icon(Icons.person, size: 50, color: constData.themeGreen),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data['last_name'] ?? ''} ${data['first_name'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: constData.themeGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'No.${data['id'] ?? '-'}  /  ${data['age'] ?? '-'}歳',
                        style: const TextStyle(
                          fontSize: 12,
                          color: constData.themeGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildHeaderInfoItem(Icons.map_outlined, data['nearest_station_line_name'] ?? '-'),
                    _buildHeaderInfoItem(
                      Icons.train_outlined,
                      data['nearest_station_name'] != null ? '${data['nearest_station_name']}駅' : '-',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: constData.themeGreen.withOpacity(0.7)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(BuildContext context, IconData icon, String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: constData.themeGreen, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(thickness: 0.5),
            ),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildArrayList(BuildContext context, String title, dynamic nameIndices, dynamic valueIndices, String nameMasterKey, String valueMasterKey) {
    if (nameIndices == null || nameIndices is! List || nameIndices.isEmpty) return const SizedBox.shrink();

    final nameMasterList = masters[nameMasterKey];
    final valueMasterList = masters[valueMasterKey];
    if (nameMasterList == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(nameIndices.length, (i) {
              final int nameIdx = (nameIndices[i] as num).toInt();
              if (nameIdx >= nameMasterList.length) return const SizedBox.shrink();

              String label = nameMasterList[nameIdx];
              String subLabel = "";

              if (valueIndices != null && valueIndices is List && i < valueIndices.length) {
                final int valIdx = (valueIndices[i] as num).toInt();
                if (valueMasterList != null && valIdx < valueMasterList.length) {
                  subLabel = valueMasterList[valIdx];
                }
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: constData.themeGreen.withOpacity(0.05),
                  border: Border.all(color: constData.themeGreen.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
                    if (subLabel.isNotEmpty && subLabel != '未経験')
                      Text(subLabel, style: const TextStyle(fontSize: 10, color: constData.themeGreen, fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}