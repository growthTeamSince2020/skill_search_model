import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'common/messageManager.dart';
import 'engineerRegistrationScreen.dart';

class EngineerInputForm extends StatefulWidget {
  @override
  _EngineerInputFormState createState() => _EngineerInputFormState();
}

class _EngineerInputFormState extends State<EngineerInputForm> {
  final MessageManager messageManager = MessageManager();
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _nearestStationLineNameController = TextEditingController();
  final _nearestStationNameController = TextEditingController();

  List<String> _teamRoles = [];
  List<String> _processes = [];
  List<String> _codeLanguages = [];
  List<String> _dbExperience = [];
  List<String> _osExperience = [];
  List<String> _cloudTech = [];
  List<String> _tool = [];
  List<String> _experienceCategories = [];
  List<String> _yearsCategories = [];

  final Map<String, String?> _teamRolesChecked = {};
  final Map<String, String?> _processesChecked = {};
  final Map<String, String?> _codeLanguagesChecked = {};
  final Map<String, String?> _dbExperienceChecked = {};
  final Map<String, String?> _osExperienceChecked = {};
  final Map<String, String?> _cloudTechChecked = {};
  final Map<String, String?> _toolChecked = {};

  final _validationResults = <String, String?>{};

  @override
  void initState() {
    super.initState();
    messageManager.loadMessages(assetPath: 'assets/messages.json').then((_) {
      _fetchUtilData().then((data) {
        setState(() {
          _teamRoles = List<String>.from(data['team_role'] ?? []);
          _processes = List<String>.from(data['process'] ?? []);
          _codeLanguages = List<String>.from(data['code_languages'] ?? []);
          _dbExperience = List<String>.from(data['db_experience'] ?? []);
          _osExperience = List<String>.from(data['os_experience'] ?? []);
          _cloudTech = List<String>.from(data['cloud_technology'] ?? []);
          _tool = List<String>.from(data['tool'] ?? []);
          _experienceCategories =
              List<String>.from(data['experience_category'] ?? []);
          _yearsCategories = List<String>.from(data['years_category'] ?? []);

          _teamRolesChecked.clear();
          _processesChecked.clear();
          _codeLanguagesChecked.clear();
          _dbExperienceChecked.clear();
          _osExperienceChecked.clear();
          _cloudTechChecked.clear();
          _toolChecked.clear();
        });
      });
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _nearestStationLineNameController.dispose();
    _nearestStationNameController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchUtilData() async {
    try {
      final docTeamRole = await FirebaseFirestore.instance
          .collection('utilData') // コレクション名修正
          .doc('team_role_item')
          .get();
      final docProcess = await FirebaseFirestore.instance
          .collection('utilData')
          .doc('process_item')
          .get();
      final docCodeLanguages = await FirebaseFirestore.instance
          .collection('utilData')
          .doc('code_languages_item')
          .get();
      final docDbExperience = await FirebaseFirestore.instance
          .collection('utilData')
          .doc('db_experience_item')
          .get();
      final docOsExperience = await FirebaseFirestore.instance
          .collection('utilData')
          .doc('os_experience_item')
          .get();
      final docCloudTech = await FirebaseFirestore.instance
          .collection('utilData')
          .doc('cloud_technology_item')
          .get();
      final docTool = await FirebaseFirestore.instance
          .collection('utilData')
          .doc('tool_item')
          .get();
      final docExperienceCategory = await FirebaseFirestore.instance
          .collection('utilData')
          .doc('experience_category_item')
          .get();
      final docYearsCategory = await FirebaseFirestore.instance
          .collection('utilData')
          .doc('years_category_item')
          .get();

      if (docProcess.exists &&
          docExperienceCategory.exists &&
          docTeamRole.exists &&
          docYearsCategory.exists &&
          docCodeLanguages.exists &&
          docDbExperience.exists &&
          docOsExperience.exists &&
          docCloudTech.exists &&
          docTool.exists) {
        return {
          'team_role': docTeamRole.data()!['team_role'] as List<dynamic>,
          'process': docProcess.data()!['process'] as List<dynamic>,
          'code_languages':
              docCodeLanguages.data()!['code_languages'] as List<dynamic>,
          'experience_category': docExperienceCategory
              .data()!['experience_category'] as List<dynamic>,
          'years_category':
              docYearsCategory.data()!['years_category'] as List<dynamic>,
          'db_experience':
              docDbExperience.data()!['db_experience'] as List<dynamic>,
          'os_experience':
              docOsExperience.data()!['os_experience'] as List<dynamic>,
          'cloud_technology':
              docCloudTech.data()!['cloud_technology'] as List<dynamic>,
          'tool': docTool.data()!['tool'] as List<dynamic>,
        };
      } else {
        throw Exception('必要なドキュメントが見つかりませんでした。');
      }
    } catch (e) {
      print('データの取得に失敗しました: $e');
      return {};
    }
  }

  Future<String?> _validateName(String? value, String labelText) async {
    final fieldMessages = {
      '名': {
        // ここでは純粋にメッセージだけを取得（項目名は check 関数側で付与）
        'required': messageManager.getMessage('2003E', ['名']),
        'pattern': messageManager.getMessage('2004E', ['名']),
      },
      '苗字': {
        'required': messageManager.getMessage('2003E', ['苗字']),
        'pattern': messageManager.getMessage('2004E', ['苗字']),
      },
      '年齢': {
        'required': messageManager.getMessage('2003E', ['年齢']),
        'pattern': messageManager.getMessage('2005E', ['年齢']),
      },
      '最寄沿線': {
        'required': messageManager.getMessage('2003E', ['最寄沿線']),
        'pattern': messageManager.getMessage('2004E', ['最寄沿線']),
      },
      '最寄駅': {
        'required': messageManager.getMessage('2003E', ['最寄駅']),
        'pattern': messageManager.getMessage('2004E', ['最寄駅']),
      },
    };
    final validationMessages = fieldMessages[labelText];
    if (validationMessages == null) {
      return null; // 定義されていない labelText の場合はバリデーションしない
    }
    if (value == null || value.isEmpty) {
      return validationMessages['required'];
    }
    if (labelText == '年齢') {
      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
        return validationMessages['pattern'];
      }
    } else {
      if (!RegExp(
              r'^[a-zA-Z0-9\p{P}\s\u3040-\u309F\u30A0-\u30FF\u4E00-\u9FFF]+$',
              unicode: true)
          .hasMatch(value)) {
        return validationMessages['pattern'];
      }
    }
    return null;
  }

  Future<void> _validateField(String fieldName, String? value) async {
    final errorMessage = await _validateName(value, fieldName);
    setState(() {
      _validationResults[fieldName] = errorMessage;
    });
  }

  // 入力データをまとめる関数
  Map<String, dynamic> _getInputData() {
    return {
      'first_name': _firstNameController.text,
      'last_name': _lastNameController.text,
      'age': _ageController.text,
      'nearest_station_line_name': _nearestStationLineNameController.text,
      'nearest_station_name': _nearestStationNameController.text,

      'team_role': _teamRolesChecked.entries
          .where((entry) => entry.value != null && entry.value != '選択')
          .fold<Map<String, String>>(<String, String>{}, (map, entry) {
        map[entry.key] = entry.value!;
        return map;
      }),

      'processes': _processesChecked.entries
          .where((entry) => entry.value != null && entry.value != '選択')
          .fold<Map<String, String>>(<String, String>{}, (map, entry) {
        map[entry.key] = entry.value!;
        return map;
      }),

      'code_languages': _codeLanguagesChecked.entries
          .where((entry) => entry.value != null && entry.value != '選択')
          .fold<Map<String, String>>(<String, String>{}, (map, entry) {
        map[entry.key] = entry.value!;
        return map;
      }),

      'db_experience': _dbExperienceChecked.entries
          .where((entry) => entry.value != null && entry.value != '選択')
          .fold<Map<String, String>>(<String, String>{}, (map, entry) {
        map[entry.key] = entry.value!;
        return map;
      }),

      'os_experience': _osExperienceChecked.entries
          .where((entry) => entry.value != null && entry.value != '選択')
          .fold<Map<String, String>>(<String, String>{}, (map, entry) {
        map[entry.key] = entry.value!;
        return map;
      }),

      'cloud_technology': _cloudTechChecked.entries
          .where((entry) => entry.value != null && entry.value != '選択')
          .fold<Map<String, String>>(<String, String>{}, (map, entry) {
        map[entry.key] = entry.value!;
        return map;
      }),

      'tool': _toolChecked.entries
          .where((entry) => entry.value != null && entry.value != '選択')
          .fold<Map<String, String>>(<String, String>{}, (map, entry) {
        map[entry.key] = entry.value!;
        return map;
      }),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 8.0),
              child: Icon(Icons.person_add, color: Colors.white, size: 24.0),
            ),
            const Text('技術者登録', style: TextStyle(color: Colors.white)),
          ],
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              // 名・苗字・年齢
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _firstNameController,
                      onChanged: (value) => _validateField('名', value),
                      decoration: InputDecoration(
                        labelText: '名',
                        prefixIcon: const Icon(Icons.person),
                        errorText: _validationResults['名'],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _lastNameController,
                      onChanged: (value) => _validateField('苗字', value),
                      decoration: InputDecoration(
                        labelText: '苗字',
                        prefixIcon: const Icon(Icons.person),
                        errorText: _validationResults['苗字'],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2, // flexを少し広げました
                    child: TextFormField(
                      controller: _ageController,
                      onChanged: (value) => _validateField('年齢', value),
                      decoration: InputDecoration(
                        labelText: '年齢',
                        prefixIcon: const Icon(Icons.person_outline),
                        errorText: _validationResults['年齢'],
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              // 最寄沿線・最寄駅
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _nearestStationLineNameController,
                      onChanged: (value) => _validateField('最寄沿線', value),
                      decoration: InputDecoration(
                        labelText: '最寄沿線',
                        prefixIcon: const Icon(Icons.linear_scale),
                        errorText: _validationResults['最寄沿線'],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _nearestStationNameController,
                      onChanged: (value) => _validateField('最寄駅', value),
                      decoration: InputDecoration(
                        labelText: '最寄駅',
                        prefixIcon: const Icon(Icons.train),
                        errorText: _validationResults['最寄駅'],
                      ),
                    ),
                  ),
                ],
              ),

              // 各 ExpansionTile (共通の構造のため一部省略しつつツールまで記載)
              _buildExpansionTile('チーム役割', Icons.group, _teamRoles, _teamRolesChecked, _yearsCategories),
              _buildExpansionTile('工程', Icons.account_tree, _processes, _processesChecked, _experienceCategories),
              _buildExpansionTile('経験言語', Icons.developer_mode, _codeLanguages, _codeLanguagesChecked, _yearsCategories),
              _buildExpansionTile('DB言語', Icons.storage, _dbExperience, _dbExperienceChecked, _yearsCategories),
              _buildExpansionTile('OS言語', Icons.memory, _osExperience, _osExperienceChecked, _yearsCategories),
              _buildExpansionTile('クラウド技術', Icons.cloud, _cloudTech, _cloudTechChecked, _yearsCategories),
              _buildExpansionTile('ツール', Icons.build, _tool, _toolChecked, _yearsCategories),

              const SizedBox(height: 30),

              // 修正の要：確認ボタン
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  // 1. エラーを一時的に保存するリスト
                  List<String> errors = [];

                  // 2. バリデーションを実行する内部関数
                  Future<void> check(String label, String value) async {
                    final msg = await _validateName(value, label);
                    setState(() {
                      _validationResults[label] = msg;
                    });
                    if (msg != null) {
                      // ここで [名] を付与して追加
                      errors.add('$msg');
                    }
                  }

                  // 3. 全てのフィールドを「待機(await)」しながらチェック
                  await check('名', _firstNameController.text);
                  await check('苗字', _lastNameController.text);
                  await check('年齢', _ageController.text);
                  await check('最寄沿線', _nearestStationLineNameController.text);
                  await check('最寄駅', _nearestStationNameController.text);

                  // 4. 全てのチェックが終わった後に判定
                  if (errors.isNotEmpty) {
                    // エラーがあればモーダルを表示
                    _showErrorDialog(errors);
                  } else {
                    // エラーがなければ初めて画面遷移
                    final data = _getInputData();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EngineerRegistrationScreen(engineerData: data),
                      ),
                    );
                  }
                },
                child: const Text('登録内容を確認する',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // リファクタリング用：共通の ExpansionTile ビルダー
  Widget _buildExpansionTile(String title, IconData icon, List<String> items, Map<String, String?> checkedMap, List<String> categories) {
    return Container(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey, width: 1.0))),
      child: ExpansionTile(
        title: Row(children: [Icon(icon), const SizedBox(width: 8), Text(title)]),
        children: items.map((item) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CheckboxListTile(
                title: Text(item, style: const TextStyle(fontWeight: FontWeight.bold)),
                value: checkedMap[item] != null,
                onChanged: (val) => setState(() => checkedMap[item] = val! ? '選択' : null),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              // チェックが入っている場合のみ横並びのラジオボタンを表示
              if (checkedMap[item] != null)
                Padding(
                  padding: const EdgeInsets.only(left: 48.0, bottom: 8.0), // 左側にインデント
                  child: Wrap(
                    spacing: 8.0, // 横の間隔
                    runSpacing: 0.0, // 縦の間隔
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: categories.map((cat) {
                      return IntrinsicWidth( // 中身に合わせて最小限の幅にする
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Radio<String>(
                              value: cat,
                              groupValue: checkedMap[item],
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // 余白を詰める
                              onChanged: (String? val) {
                                if (val != null) {
                                  setState(() => checkedMap[item] = val);
                                }
                              },
                            ),
                            GestureDetector(
                              onTap: () => setState(() => checkedMap[item] = cat),
                              child: Text(
                                cat,
                                style: const TextStyle(fontSize: 12.0), // 文字を少し小さく
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
  // エラーメッセージをモーダルで表示するための共通メソッド
  // エラーメッセージをモーダルで表示するための共通メソッド
  void _showErrorDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[50], // ★ ここで背景色を指定（例：薄い赤）
        surfaceTintColor: Colors.white, // Material3の場合、これを白にすると背景色が綺麗に出ます
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text(
              '入力内容を確認してください',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold), // タイトル文字も赤くすると統一感が出ます
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: errors.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text('・ $e', style: const TextStyle(fontSize: 14, color: Colors.black87)),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる', style: TextStyle(color: Colors.black)), // ボタンも赤系に
          ),
        ],
      ),
    );
  }
}
