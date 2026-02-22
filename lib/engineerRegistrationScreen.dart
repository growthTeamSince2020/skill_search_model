import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_search_model/utils/uiUtils.dart';
import 'common/constData.dart';

class EngineerRegistrationScreen extends StatefulWidget {
  final Map<String, dynamic> engineerData;

  const EngineerRegistrationScreen({super.key, required this.engineerData});

  @override
  State<EngineerRegistrationScreen> createState() =>
      _EngineerRegistrationScreenState();
}

class _EngineerRegistrationScreenState
    extends State<EngineerRegistrationScreen> {
  bool _isRegistering = false;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // メインカラー
  static const themeGreen = Color(0xFF2E7D32);

  Future<void> _registerEngineer() async {
    FocusScope.of(context).unfocus();
    setState(() => _isRegistering = true);
    try {
      final masterDataMap = await _fetchAllMasters();
      final nextId = await _getNextSequenceId();
      final dataToSave = _buildSaveData(nextId, masterDataMap);
      await _db.collection('engineer').add(dataToSave);
      if (!mounted) return;
      UIUtils.showResultDialog(
        context,
        title: '登録完了',
        message: '技術者情報の登録が完了しました。',
        isError: false,
        onNext: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isRegistering = false);
        UIUtils.showResultDialog(
          context,
          title: '登録失敗',
          message: '登録中にエラーが発生しました。\n$e',
          isError: true,
        );
      }
    }
  }

  Future<Map<String, List<String>>> _fetchAllMasters() async {
    const docsToFetch = constData.masterDocs;
    final refs =
        docsToFetch.map((id) => _db.collection('utilData').doc(id)).toList();
    final snapshots = await Future.wait(refs.map((ref) => ref.get()));
    final Map<String, List<String>> result = {};
    for (var i = 0; i < docsToFetch.length; i++) {
      final data = snapshots[i].data();
      result[docsToFetch[i]] = data?.values
              .firstWhere((v) => v is List, orElse: () => [])
              ?.cast<String>() ??
          [];
    }
    return result;
  }

  Future<int> _getNextSequenceId() async {
    final counterRef = _db.collection('engineer').doc('sequenceNo');
    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);
      final currentId =
          snapshot.exists ? (snapshot.get('currentId') as int) : 0;
      final newId = currentId + 1;
      transaction.set(
          counterRef, {'currentId': newId}, SetOptions(merge: true));
      return newId;
    });
  }

  Map<String, dynamic> _buildSaveData(
      int id, Map<String, List<String>> masters) {
    final d = widget.engineerData;
    Map<String, List<int>> convert(String key, String masterKey, String type) =>
        constData.convertDataToNumericArrays(d[key], masters[masterKey]!, type);
    final team = convert('team_role', 'team_role_item', 'years');
    final proc = convert('processes', 'process_item', 'level');
    final lang = convert('code_languages', 'code_languages_item', 'years');
    final db = convert('db_experience', 'db_experience_item', 'years');
    final os = convert('os_experience', 'os_experience_item', 'years');
    final cloud = convert('cloud_technology', 'cloud_technology_item', 'years');
    final tool = convert('tool', 'tool_item', 'simple');
    return {
      'id': id,
      'first_name': d['first_name']?.toString() ?? '',
      'last_name': d['last_name']?.toString() ?? '',
      'age': int.tryParse(d['age']?.toString() ?? '') ?? 0,
      'nearest_station_line_name': d['nearest_station_line_name'] ?? '',
      'nearest_station_name': d['nearest_station_name'] ?? '',
      'team_role': team['names'],
      'team_role_years': team['values'],
      'process': proc['names'],
      'process_experience': proc['values'],
      'code_languages': lang['names'],
      'code_languages_years': lang['values'],
      'db_experience': db['names'],
      'db_experience_years': db['values'],
      'os_experience': os['names'],
      'os_experience_years': os['values'],
      'cloud_technology': cloud['names'],
      'cloud_technology_years': cloud['values'],
      'tool': tool['names'],
      'tool_years': tool['values'],
      'registration_date': FieldValue.serverTimestamp(),
      'update_date': FieldValue.serverTimestamp(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.engineerData;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        // スクロール時に色が変わるのを防ぐ
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Row(
          children: [
            Icon(Icons.fact_check_outlined, color: themeGreen, size: 24),
            SizedBox(width: 12),
            Text(
              '登録内容の確認',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        // 下部にうっすらと境界線を入れる
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.withOpacity(0.15),
            height: 1.0,
          ),
        ),
      ),
      body: _isRegistering
          ? const Center(child: CircularProgressIndicator(color: themeGreen))
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 800),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildMainCard(d),
                            const SizedBox(height: 24),
                            _buildSkillSection(
                                'チーム役割', d['team_role'], Icons.groups_outlined),
                            _buildSkillSection('工程', d['processes'],
                                Icons.account_tree_outlined),
                            _buildSkillSection('経験言語', d['code_languages'],
                                Icons.code_rounded),
                            _buildSkillSection('DB経験', d['db_experience'],
                                Icons.storage_rounded),
                            _buildSkillSection('OS経験', d['os_experience'],
                                Icons.memory_rounded),
                            _buildSkillSection('クラウド技術', d['cloud_technology'],
                                Icons.cloud_queue_rounded),
                            _buildSkillSection(
                                'ツール', d['tool'], Icons.build_circle_outlined),
                            const SizedBox(height: 40),
                            _buildActionButtons(),
                            const SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        color: themeGreen.withOpacity(0.05),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: themeGreen, size: 20),
            SizedBox(width: 12),
            Text(
              '以下の内容で登録します。よろしいですか？',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: themeGreen),
            ),
          ],
        ),
      );

  Widget _buildMainCard(Map d) {
    // 駅名の取得
    String stationName = d['nearest_station_name']?.toString() ?? '';
    // 空でなく、かつ末尾が「駅」で終わっていない場合のみ「駅」を付与
    if (stationName.isNotEmpty && !stationName.endsWith('駅')) {
      stationName += '駅';
    }

    return UIUtils.buildFormSection(
      child: Column(
        children: [
          _infoRow(Icons.person_outline, '氏名',
              '${d['first_name']} ${d['last_name']}'),
          const Divider(height: 24),
          _infoRow(Icons.cake_outlined, '年齢', '${d['age']} 歳'),
          const Divider(height: 24),
          _infoRow(
            Icons.train_outlined,
            '最寄',
            '${d['nearest_station_line_name'] ?? ''} $stationName',
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String val) => Row(
        children: [
          Icon(icon, size: 20, color: themeGreen),
          const SizedBox(width: 12),
          SizedBox(
              width: 60,
              child: Text(label,
                  style: const TextStyle(
                      color: Colors.black54, fontWeight: FontWeight.bold))),
          Expanded(
              child: Text(val,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500))),
        ],
      );

  Widget _buildSkillSection(String title, dynamic data, IconData icon) {
    if (data is! Map || data.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: UIUtils.buildFormSection(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: themeGreen),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(
                        color: themeGreen, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: data.entries
                  .map((e) => Chip(
                        label: Text('${e.key} (${e.value})',
                            style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: themeGreen, width: 0.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() => Column(
        children: [
          // 共通部品のボタンを使用
          UIUtils.buildPrimaryButton(
            label: 'この内容で登録する',
            onPressed: _registerEngineer,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('入力をやり直す',
                  style: TextStyle(
                      color: Colors.black54, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
}
