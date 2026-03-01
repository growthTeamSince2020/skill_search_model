import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_search_model/utils/objectsUtils.dart';
import 'package:skill_search_model/utils/uiUtils.dart';

import 'common/messageManager.dart';
import 'engineerRegistrationScreen.dart';

class EngineerInputForm extends StatefulWidget {
  @override
  _EngineerInputFormState createState() => _EngineerInputFormState();
}

class _EngineerInputFormState extends State<EngineerInputForm> {
  // フィールド名から対応するコントローラーを返すヘルパー関数
  TextEditingController _getControllerByName(String name) {
    switch (name) {
      case '名':
        return _firstNameController;
      case '苗字':
        return _lastNameController;
      case '年齢':
        return _ageController;
      case '最寄沿線':
        return _nearestStationLineNameController;
      case '最寄駅':
        return _nearestStationNameController;
      default:
        return TextEditingController(); // 基本的には到達しない
    }
  }

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
    // メインカラーを定義
    const themeGreen = Color(0xFF2E7D32);

    return Scaffold(
      // 背景色をMainShellと同じ薄いグレーに設定
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        // AppBarを白背景、影なしのスッキリしたデザインに変更
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        // 戻るボタンのアイコン色を黒系に変更
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Row(
          children: [
            Padding(
              padding: EdgeInsets.only(right: 12.0),
              child:
                  Icon(Icons.person_add_alt_1, color: themeGreen, size: 24.0),
            ),
            Text(
              '技術者登録',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        centerTitle: false,
        // 下に細い線を入れて境界をはっきりさせる
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.withOpacity(0.2), height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900), // Webで見やすく幅を制限
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 必須入力の注釈
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                        children: [
                          TextSpan(
                              text: '*',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold)),
                          TextSpan(text: ' は必須入力項目です'),
                        ],
                      ),
                    ),
                  ),

                  // --- 基本情報カード ---
                  UIUtils.buildFormSection(
                    child: Column(
                      children: [
                        // 名・苗字・年齢
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: UIUtils.buildPrimaryTextField(
                                controller: _lastNameController,
                                label: '苗字',
                                icon: Icons.person_outline,
                                errorText: _validationResults['苗字'],
                                onChanged: (val) {
                                  setState(() {
                                    // ObjectUtilsを使って一括判定
                                    _validationResults['苗字'] =
                                        ObjectUtils.validateField(val, '苗字');
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),

                            Expanded(
                              flex: 3,
                              child: UIUtils.buildPrimaryTextField(
                                controller: _firstNameController,
                                label: '名',
                                icon: Icons.person_outline,
                                errorText: _validationResults['名'],
                                // setStateで管理しているエラーを渡す
                                onChanged: (val) {
                                  setState(() {
                                    // ObjectUtilsを使って一括判定
                                    _validationResults['名'] =
                                        ObjectUtils.validateField(val, '名');
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: UIUtils.buildPrimaryTextField(
                                controller: _ageController,
                                label: '年齢',
                                icon: Icons.cake_outlined,
                                keyboardType: TextInputType.number,
                                errorText: _validationResults['年齢'],
                                onChanged: (val) {
                                  setState(() {
                                    // ObjectUtilsを使って一括判定
                                    _validationResults['年齢'] =
                                        ObjectUtils.validateField(val, '年齢');
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // 最寄沿線・最寄駅
                        Row(
                          children: [
                            Expanded(
                              child: UIUtils.buildPrimaryTextField(
                                controller: _nearestStationLineNameController,
                                label: '最寄沿線',
                                icon: Icons.map_outlined,
                                errorText: _validationResults['最寄沿線'],
                                onChanged: (val) {
                                  setState(() {
                                    // ObjectUtilsを使って一括判定
                                    _validationResults['最寄沿線'] =
                                        ObjectUtils.validateField(val, '最寄沿線');
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: UIUtils.buildPrimaryTextField(
                                controller: _nearestStationNameController,
                                label: '最寄駅',
                                icon: Icons.train_outlined,
                                suffixText: '駅',
                                errorText: _validationResults['最寄駅'],
                                onChanged: (val) {
                                  setState(() {
                                    // ObjectUtilsを使って一括判定
                                    _validationResults['最寄駅'] =
                                        ObjectUtils.validateField(val, '最寄駅');
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // --- スキル・経験カード ---
                  UIUtils.buildFormSection(
                    child: Column(
                      children: [
                        UIUtils.buildSkillExpansionTile(
                          title: 'チーム役割',
                          icon: Icons.groups_outlined,
                          items: _teamRoles,
                          checkedMap: _teamRolesChecked,
                          categories: _yearsCategories,
                          onChanged: (item, val) =>
                              setState(() => _teamRolesChecked[item] = val),
                        ),
                        UIUtils.buildSkillExpansionTile(
                          title: '工程',
                          icon: Icons.account_tree_outlined,
                          items: _processes,
                          checkedMap: _processesChecked,
                          categories: _experienceCategories,
                          onChanged: (item, val) =>
                              setState(() => _processesChecked[item] = val),
                        ),
                        UIUtils.buildSkillExpansionTile(
                          title: '経験言語',
                          icon: Icons.code_rounded,
                          items: _codeLanguages,
                          checkedMap: _codeLanguagesChecked,
                          categories: _yearsCategories,
                          onChanged: (item, val) =>
                              setState(() => _codeLanguagesChecked[item] = val),
                        ),
                        UIUtils.buildSkillExpansionTile(
                          title: 'DB言語',
                          icon: Icons.storage_rounded,
                          items: _dbExperience,
                          checkedMap: _dbExperienceChecked,
                          categories: _yearsCategories,
                          onChanged: (item, val) =>
                              setState(() => _dbExperienceChecked[item] = val),
                        ),
                        UIUtils.buildSkillExpansionTile(
                          title: 'OS',
                          icon: Icons.memory_rounded,
                          items: _osExperience,
                          checkedMap: _osExperienceChecked,
                          categories: _yearsCategories,
                          onChanged: (item, val) =>
                              setState(() => _osExperienceChecked[item] = val),
                        ),
                        UIUtils.buildSkillExpansionTile(
                          title: 'クラウド技術',
                          icon: Icons.cloud_queue_rounded,
                          items: _cloudTech,
                          checkedMap: _cloudTechChecked,
                          categories: _yearsCategories,
                          onChanged: (item, val) =>
                              setState(() => _cloudTechChecked[item] = val),
                        ),
                        UIUtils.buildSkillExpansionTile(
                          title: 'ツール',
                          icon: Icons.build_circle_outlined,
                          items: _tool,
                          checkedMap: _toolChecked,
                          categories: _yearsCategories,
                          onChanged: (item, val) =>
                              setState(() => _toolChecked[item] = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 登録ボタン
                  UIUtils.buildPrimaryButton(
                    label: '登録内容を確認する',
                    onPressed: () async {
                      List<String> errors = [];

                      // 【修正点】Mapのkeysではなく、チェックすべき必須項目を直接定義する
                      final requiredFields = ['苗字', '名', '年齢', '最寄沿線', '最寄駅'];

                      for (var fieldName in requiredFields) {
                        // コントローラーから現在の値を直接取得してバリデーション
                        final msg = ObjectUtils.validateField(
                            _getControllerByName(fieldName).text, fieldName);

                        // 画面上の赤字表示を更新
                        setState(() => _validationResults[fieldName] = msg);

                        // エラーメッセージがあればリストに追加
                        if (msg != null) {
                          errors.add(msg);
                        }
                      }

                      if (errors.isNotEmpty) {
                        // 一つでもエラーがあればダイアログ表示
                        UIUtils.showErrorListDialog(context, errors);
                      } else {
                        // 全てOKなら遷移
                        final data = _getInputData();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                EngineerRegistrationScreen(engineerData: data),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
