import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skill_search_model/utils/objectsUtils.dart';
import 'package:skill_search_model/utils/uiUtils.dart';
import 'package:skill_search_model/common/constData.dart';
import 'package:skill_search_model/permissionService.dart'; // ★ 権限サービスをインポート

import 'common/messageManager.dart';
import 'engineerRegistrationScreen.dart';

class EngineerInputForm extends StatefulWidget {
  const EngineerInputForm({super.key});

  @override
  State<EngineerInputForm> createState() => _EngineerInputFormState();
}

class _EngineerInputFormState extends State<EngineerInputForm> {
  // フィールド名から対応するコントローラーを返すヘルパー関数 (仕様維持)
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
        return TextEditingController();
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

  // ★ 画面権限状態を保持する変数
  ScreenPermissions? _perm;

  @override
  void initState() {
    super.initState();

    // ★ 画面に対する権限マトリクスを非同期でロード
    PermissionService.instance.loadForScreen('engineerInputForm').then((p) {
      if (mounted) {
        setState(() => _perm = p);
      }
    });

    messageManager.loadMessages(assetPath: 'assets/messages.json').then((_) {
      _fetchUtilData().then((data) {
        if (mounted) {
          setState(() {
            _teamRoles = List<String>.from(data['team_role'] ?? []);
            _processes = List<String>.from(data['process'] ?? []);
            _codeLanguages = List<String>.from(data['code_languages'] ?? []);
            _dbExperience = List<String>.from(data['db_experience'] ?? []);
            _osExperience = List<String>.from(data['os_experience'] ?? []);
            _cloudTech = List<String>.from(data['cloud_technology'] ?? []);
            _tool = List<String>.from(data['tool'] ?? []);
            _experienceCategories = List<String>.from(data['experience_category'] ?? []);
            _yearsCategories = List<String>.from(data['years_category'] ?? []);

            _teamRolesChecked.clear();
            _processesChecked.clear();
            _codeLanguagesChecked.clear();
            _dbExperienceChecked.clear();
            _osExperienceChecked.clear();
            _cloudTechChecked.clear();
            _toolChecked.clear();
          });
        }
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
      final utilCollection = FirebaseFirestore.instance.collection('utilData');
      final docs = await Future.wait([
        utilCollection.doc('team_role_item').get(),
        utilCollection.doc('process_item').get(),
        utilCollection.doc('code_languages_item').get(),
        utilCollection.doc('db_experience_item').get(),
        utilCollection.doc('os_experience_item').get(),
        utilCollection.doc('cloud_technology_item').get(),
        utilCollection.doc('tool_item').get(),
        utilCollection.doc('experience_category_item').get(),
        utilCollection.doc('years_category_item').get(),
      ]);

      return {
        'team_role': docs[0].data()?['team_role'] ?? [],
        'process': docs[1].data()?['process'] ?? [],
        'code_languages': docs[2].data()?['code_languages'] ?? [],
        'db_experience': docs[3].data()?['db_experience'] ?? [],
        'os_experience': docs[4].data()?['os_experience'] ?? [],
        'cloud_technology': docs[5].data()?['cloud_technology'] ?? [],
        'tool': docs[6].data()?['tool'] ?? [],
        'experience_category': docs[7].data()?['experience_category'] ?? [],
        'years_category': docs[8].data()?['years_category'] ?? [],
      };
    } catch (e) {
      print('データの取得に失敗しました: $e');
      return {};
    }
  }

  // 入力データをまとめる関数 (仕様維持)
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
      'registration_date': FieldValue.serverTimestamp(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ★ 1. 権限読込中の制御
    if (_perm == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: constData.themeGreen)));
    }

    // ★ 2. 画面自体の表示権限がない場合のブロック制御
    if (!_perm!.canViewScreen) {
      return const Scaffold(
        body: Center(
          child: Text('この画面にアクセスする権限がありません。', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Row(
          children: [
            const Icon(Icons.person_add_alt_1, color: constData.themeGreen, size: 24.0),
            const SizedBox(width: 12),
            Text(
              '技術者登録',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.withOpacity(0.2), height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.black54, fontSize: constData.fontSizeSmall),
                        children: const [
                          TextSpan(text: '*', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          TextSpan(text: ' は必須入力項目です'),
                        ],
                      ),
                    ),
                  ),

                  // --- 基本情報カード ---
                  UIUtils.buildFormSection(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            if (_perm!.canViewItem('苗字'))
                              Expanded(
                                flex: 3,
                                child: Opacity(
                                  opacity: _perm!.canEditItem('苗字') ? 1.0 : 0.5,
                                  child: AbsorbPointer(
                                    absorbing: !_perm!.canEditItem('苗字'),
                                    child: UIUtils.buildPrimaryTextField(
                                      controller: _lastNameController,
                                      label: '苗字',
                                      icon: Icons.person_outline,
                                      errorText: _validationResults['苗字'],
                                      onChanged: (val) => setState(() => _validationResults['苗字'] = ObjectUtils.validateField(val, '苗字')),
                                    ),
                                  ),
                                ),
                              ),
                            if (_perm!.canViewItem('苗字') && _perm!.canViewItem('名'))
                              const SizedBox(width: 16),
                            if (_perm!.canViewItem('名'))
                              Expanded(
                                flex: 3,
                                child: Opacity(
                                  opacity: _perm!.canEditItem('名') ? 1.0 : 0.5,
                                  child: AbsorbPointer(
                                    absorbing: !_perm!.canEditItem('名'),
                                    child: UIUtils.buildPrimaryTextField(
                                      controller: _firstNameController,
                                      label: '名',
                                      icon: Icons.person_outline,
                                      errorText: _validationResults['名'],
                                      onChanged: (val) => setState(() => _validationResults['名'] = ObjectUtils.validateField(val, '名')),
                                    ),
                                  ),
                                ),
                              ),
                            if ((_perm!.canViewItem('苗字') || _perm!.canViewItem('名')) && _perm!.canViewItem('年齢'))
                              const SizedBox(width: 16),
                            if (_perm!.canViewItem('年齢'))
                              Expanded(
                                flex: 2,
                                child: Opacity(
                                  opacity: _perm!.canEditItem('年齢') ? 1.0 : 0.5,
                                  child: AbsorbPointer(
                                    absorbing: !_perm!.canEditItem('年齢'),
                                    child: UIUtils.buildPrimaryTextField(
                                      controller: _ageController,
                                      label: '年齢',
                                      icon: Icons.cake_outlined,
                                      keyboardType: TextInputType.number,
                                      errorText: _validationResults['年齢'],
                                      onChanged: (val) => setState(() => _validationResults['年齢'] = ObjectUtils.validateField(val, '年齢')),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (_perm!.canViewItem('最寄沿線') || _perm!.canViewItem('最寄駅'))
                          const SizedBox(height: 24),
                        Row(
                          children: [
                            if (_perm!.canViewItem('最寄沿線'))
                              Expanded(
                                child: Opacity(
                                  opacity: _perm!.canEditItem('最寄沿線') ? 1.0 : 0.5,
                                  child: AbsorbPointer(
                                    absorbing: !_perm!.canEditItem('最寄沿線'),
                                    child: UIUtils.buildPrimaryTextField(
                                      controller: _nearestStationLineNameController,
                                      label: '最寄沿線',
                                      icon: Icons.map_outlined,
                                      errorText: _validationResults['最寄沿線'],
                                      onChanged: (val) => setState(() => _validationResults['最寄沿線'] = ObjectUtils.validateField(val, '最寄沿線')),
                                    ),
                                  ),
                                ),
                              ),
                            if (_perm!.canViewItem('最寄沿線') && _perm!.canViewItem('最寄駅'))
                              const SizedBox(width: 16),
                            if (_perm!.canViewItem('最寄駅'))
                              Expanded(
                                child: Opacity(
                                  opacity: _perm!.canEditItem('最寄駅') ? 1.0 : 0.5,
                                  child: AbsorbPointer(
                                    absorbing: !_perm!.canEditItem('最寄駅'),
                                    child: UIUtils.buildPrimaryTextField(
                                      controller: _nearestStationNameController,
                                      label: '最寄駅',
                                      icon: Icons.train_outlined,
                                      suffixText: '駅',
                                      errorText: _validationResults['最寄駅'],
                                      onChanged: (val) => setState(() => _validationResults['最寄駅'] = ObjectUtils.validateField(val, '最寄駅')),
                                    ),
                                  ),
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
                        if (_perm!.canViewItem('チーム役割'))
                          AbsorbPointer(
                            absorbing: !_perm!.canEditItem('チーム役割'),
                            child: UIUtils.buildSkillExpansionTile(
                              title: 'チーム役割',
                              icon: Icons.groups_outlined,
                              items: _teamRoles,
                              checkedMap: _teamRolesChecked,
                              categories: _yearsCategories,
                              onChanged: (item, val) => setState(() => _teamRolesChecked[item] = val),
                            ),
                          ),
                        if (_perm!.canViewItem('工程'))
                          AbsorbPointer(
                            absorbing: !_perm!.canEditItem('工程'),
                            child: UIUtils.buildSkillExpansionTile(
                              title: '工程',
                              icon: Icons.account_tree_outlined,
                              items: _processes,
                              checkedMap: _processesChecked,
                              categories: _experienceCategories,
                              onChanged: (item, val) => setState(() => _processesChecked[item] = val),
                            ),
                          ),
                        if (_perm!.canViewItem('経験言語'))
                          AbsorbPointer(
                            absorbing: !_perm!.canEditItem('経験言語'),
                            child: UIUtils.buildSkillExpansionTile(
                              title: '経験言語',
                              icon: Icons.code_rounded,
                              items: _codeLanguages,
                              checkedMap: _codeLanguagesChecked,
                              categories: _yearsCategories,
                              onChanged: (item, val) => setState(() => _codeLanguagesChecked[item] = val),
                            ),
                          ),
                        if (_perm!.canViewItem('DB言語'))
                          AbsorbPointer(
                            absorbing: !_perm!.canEditItem('DB言語'),
                            child: UIUtils.buildSkillExpansionTile(
                              title: 'DB言語',
                              icon: Icons.storage_rounded,
                              items: _dbExperience,
                              checkedMap: _dbExperienceChecked,
                              categories: _yearsCategories,
                              onChanged: (item, val) => setState(() => _dbExperienceChecked[item] = val),
                            ),
                          ),
                        if (_perm!.canViewItem('OS'))
                          AbsorbPointer(
                            absorbing: !_perm!.canEditItem('OS'),
                            child: UIUtils.buildSkillExpansionTile(
                              title: 'OS',
                              icon: Icons.memory_rounded,
                              items: _osExperience,
                              checkedMap: _osExperienceChecked,
                              categories: _yearsCategories,
                              onChanged: (item, val) => setState(() => _osExperienceChecked[item] = val),
                            ),
                          ),
                        if (_perm!.canViewItem('クラウド技術'))
                          AbsorbPointer(
                            absorbing: !_perm!.canEditItem('クラウド技術'),
                            child: UIUtils.buildSkillExpansionTile(
                              title: 'クラウド技術',
                              icon: Icons.cloud_queue_rounded,
                              items: _cloudTech,
                              checkedMap: _cloudTechChecked,
                              categories: _yearsCategories,
                              onChanged: (item, val) => setState(() => _cloudTechChecked[item] = val),
                            ),
                          ),
                        if (_perm!.canViewItem('ツール'))
                          AbsorbPointer(
                            absorbing: !_perm!.canEditItem('ツール'),
                            child: UIUtils.buildSkillExpansionTile(
                              title: 'ツール',
                              icon: Icons.build_circle_outlined,
                              items: _tool,
                              checkedMap: _toolChecked,
                              categories: _yearsCategories,
                              onChanged: (item, val) => setState(() => _toolChecked[item] = val),
                            ),
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
                      final requiredFields = ['苗字', '名', '年齢', '最寄沿線', '最寄駅'];

                      for (var fieldName in requiredFields) {
                        // ★ 表示かつ編集権限を両方持っている項目のみバリデーションチェックの対象にする
                        if (_perm!.canViewItem(fieldName) && _perm!.canEditItem(fieldName)) {
                          final msg = ObjectUtils.validateField(_getControllerByName(fieldName).text, fieldName);
                          setState(() => _validationResults[fieldName] = msg);
                          if (msg != null) errors.add(msg);
                        }
                      }

                      if (errors.isNotEmpty) {
                        UIUtils.showErrorListDialog(context, errors);
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EngineerRegistrationScreen(engineerData: _getInputData()),
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