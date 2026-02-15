import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'common/constData.dart';

class EngineerRegistrationScreen extends StatefulWidget {
  final Map<String, dynamic> engineerData;
  const EngineerRegistrationScreen({super.key, required this.engineerData});

  @override
  State<EngineerRegistrationScreen> createState() => _EngineerRegistrationScreenState();
}

class _EngineerRegistrationScreenState extends State<EngineerRegistrationScreen> {
  bool _isRegistering = false;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 登録メイン処理
  Future<void> _registerEngineer() async {
    FocusScope.of(context).unfocus();
    setState(() => _isRegistering = true);

    try {
      // 1. マスターデータとシーケンスIDを並列/一括取得（高速化）
      final masterDataMap = await _fetchAllMasters();
      final nextId = await _getNextSequenceId();

      // 2. 保存データの構築
      final dataToSave = _buildSaveData(nextId, masterDataMap);

      // 3. Firestore保存
      await _db.collection('engineer').add(dataToSave);

      if (!mounted) return;
      _showSnackBar('登録が完了しました');
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      debugPrint("Registration Error: $e");
      if (mounted) {
        setState(() => _isRegistering = false);
        _showSnackBar('登録に失敗しました: $e');
      }
    }
  }

  /// 必要なマスタードキュメントを1回の通信でまとめて取得
  Future<Map<String, List<String>>> _fetchAllMasters() async {
    const docsToFetch = constData.masterDocs;

    // 各ドキュメントへの参照を作成
    final refs = docsToFetch.map((id) => _db.collection('utilData').doc(id)).toList();

    // まとめて取得
    final snapshots = await Future.wait(refs.map((ref) => ref.get()));

    final Map<String, List<String>> result = {};
    for (var i = 0; i < docsToFetch.length; i++) {
      final data = snapshots[i].data();
      // 最初に見つかったList型フィールドを抽出
      result[docsToFetch[i]] = data?.values.firstWhere((v) => v is List, orElse: () => [])?.cast<String>() ?? [];
    }
    return result;
  }

  /// シーケンスID取得（engineerコレクション内のsequenceNoドキュメントで管理）
  Future<int> _getNextSequenceId() async {
    // 参照先を 'counters/engineer' から 'engineer/sequenceNo' に変更
    final counterRef = _db.collection('engineer').doc('sequenceNo');

    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      // ドキュメントが存在しない場合は 0 から開始して +1 する
      final currentId = snapshot.exists ? (snapshot.get('currentId') as int) : 0;
      final newId = currentId + 1;

      // カウンタを更新（merge: true で初回作成時も対応）
      transaction.set(
        counterRef,
        {'currentId': newId},
        SetOptions(merge: true),
      );

      return newId;
    });
  }

  /// 送信用Mapの組み立て
  Map<String, dynamic> _buildSaveData(int id, Map<String, List<String>> masters) {
    final d = widget.engineerData;

    // 変換ヘルパーをクロージャ化して短縮
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

  void _showSnackBar(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  @override
  Widget build(BuildContext context) {
    final d = widget.engineerData;
    return Scaffold(
      appBar: AppBar(title: const Text('登録内容確認'), backgroundColor: Colors.green, foregroundColor: Colors.white),
      body: _isRegistering
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainCard(d),
                  _buildSkillSection('チーム役割', d['team_role']),
                  _buildSkillSection('工程', d['processes']),
                  _buildSkillSection('経験言語', d['code_languages']),
                  _buildSkillSection('DB経験', d['db_experience']),
                  _buildSkillSection('OS経験', d['os_experience']),
                  _buildSkillSection('クラウド技術', d['cloud_technology']),
                  _buildSkillSection('ツール', d['tool']),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    color: Colors.green.withValues(alpha: 0.1),
    child: const Text('以下の内容で登録しますか？', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  );

  Widget _buildMainCard(Map d) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _infoRow('氏名', '${d['first_name']} ${d['last_name']}'),
          _infoRow('年齢', '${d['age']} 歳'),
          _infoRow('最寄', '${d['nearest_station_line_name'] ?? ''} ${d['nearest_station_name'] ?? ''}'),
        ],
      ),
    ),
  );

  Widget _infoRow(String label, String val) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
      Text(val, style: const TextStyle(fontSize: 16)),
    ]),
  );

  Widget _buildSkillSection(String title, dynamic data) {
    if (data is! Map || data.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsets.only(top: 16, bottom: 4), child: Text(title, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
        const Divider(),
        Wrap(spacing: 8, children: data.entries.map((e) => Chip(label: Text('${e.key} (${e.value})', style: const TextStyle(fontSize: 12)))).toList()),
      ],
    );
  }

  Widget _buildActionButtons() => Column(
    children: [
      SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _registerEngineer,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          child: const Text('登録を実行する', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('修正する')),
    ],
  );
}