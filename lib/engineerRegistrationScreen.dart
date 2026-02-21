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

  /// 登録完了・失敗時のモーダル表示
  void _showResultDialog({
    required String title,
    required String message,
    required bool isError,
    VoidCallback? onNext,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false, // 枠外タップで閉じない
      barrierColor: Colors.black.withOpacity(0.7), // 背景を暗くする
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.red : Colors.green,
            ),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(color: isError ? Colors.red : Colors.green, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // モーダルを閉じる
                if (onNext != null) onNext();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isError ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ),
        ],
      ),
    );
  }

  /// 登録メイン処理
  Future<void> _registerEngineer() async {
    FocusScope.of(context).unfocus();
    setState(() => _isRegistering = true);

    try {
      // 1. マスターデータとシーケンスIDを並列/一括取得
      final masterDataMap = await _fetchAllMasters();
      final nextId = await _getNextSequenceId();

      // 2. 保存データの構築
      final dataToSave = _buildSaveData(nextId, masterDataMap);

      // 3. Firestore保存
      await _db.collection('engineer').add(dataToSave);

      if (!mounted) return;

      // 成功モーダルを表示
      _showResultDialog(
        title: '登録完了',
        message: '技術者情報の登録が完了しました。',
        isError: false,
        onNext: () {
          Navigator.popUntil(context, (route) => route.isFirst);
        },
      );
    } catch (e) {
      debugPrint("Registration Error: $e");
      if (mounted) {
        setState(() => _isRegistering = false);
        // 失敗モーダルを表示
        _showResultDialog(
          title: '登録失敗',
          message: '登録中にエラーが発生しました。\n$e',
          isError: true,
        );
      }
    }
  }

  /// 必要なマスタードキュメントを取得
  Future<Map<String, List<String>>> _fetchAllMasters() async {
    const docsToFetch = constData.masterDocs;
    final refs = docsToFetch.map((id) => _db.collection('utilData').doc(id)).toList();
    final snapshots = await Future.wait(refs.map((ref) => ref.get()));

    final Map<String, List<String>> result = {};
    for (var i = 0; i < docsToFetch.length; i++) {
      final data = snapshots[i].data();
      result[docsToFetch[i]] = data?.values.firstWhere((v) => v is List, orElse: () => [])?.cast<String>() ?? [];
    }
    return result;
  }

  /// シーケンスID取得
  Future<int> _getNextSequenceId() async {
    final counterRef = _db.collection('engineer').doc('sequenceNo');
    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);
      // ここで snapshot.get('currentId') を行う。
      // もし sequenceNo ドキュメントに別のフィールドがあると稀にエラーになる場合がある
      final currentId = snapshot.exists ? (snapshot.get('currentId') as int) : 0;
      final newId = currentId + 1;

      transaction.set(counterRef, {'currentId': newId}, SetOptions(merge: true));
      return newId;
    });
  }

  /// 送信用Mapの組み立て
  Map<String, dynamic> _buildSaveData(int id, Map<String, List<String>> masters) {
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
      'last_name': d['last_name']?.toString() ?? '', // ← ここで値が取れているか再確認
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
      appBar: AppBar(
        title: const Text('登録内容確認'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      // 画面全体をColumnで構成
      body: _isRegistering
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // 1. 固定ヘッダー部分
          _buildHeader(),

          // 2. スクロール可能部分（ここがExpandedなのが正解）
          Expanded(
            child: SingleChildScrollView(
              // コンテンツが少なくてもスクロール可能にする設定
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
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
                    const SizedBox(height: 50), // 下に十分な余白
                  ],
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
    padding: const EdgeInsets.all(16),
    // 背景色と境界線の設定
    decoration: BoxDecoration(
      color: Colors.green[50],
      border: const Border(
        bottom: BorderSide(color: Colors.green, width: 1),
      ),
    ),
    child: const Row( // Rowを使って横に並べる
      children: [
        Icon(Icons.info, color: Colors.orangeAccent), // 指定のアイコン
        SizedBox(width: 12), // アイコンと文字の間の隙間
        Expanded( // テキストが長くなっても折り返せるようにする
          child: Text(
            '以下の内容で登録しますか？',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ),
      ],
    ),
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

  Widget _buildActionButtons() => Container(
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Colors.white, // ボタンの背景を白くして、コンテンツと分ける
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, -5), // 上方向に少し影をつける
        ),
      ],
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min, // 余計なスペースを取らない
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _registerEngineer,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('登録', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('修正', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    ),
  );
}