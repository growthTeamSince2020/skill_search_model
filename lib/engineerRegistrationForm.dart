import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'common/constData.dart';
import 'common/messageManager.dart';

class EngineerRegistrationForm extends StatefulWidget {
  @override
  _EngineerRegistrationFormState createState() =>
      _EngineerRegistrationFormState();
}

class _EngineerRegistrationFormState extends State<EngineerRegistrationForm> {
  // MessageManager のインスタンスを作成
  final MessageManager messageManager = MessageManager();
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _nearestStationLineNameController = TextEditingController();
  final _nearestStationNameController = TextEditingController();
  final _codeLanguagesController = TextEditingController();
  final _dbExperienceController = TextEditingController();
  final _osExperienceController = TextEditingController();
  final _cloudTechController = TextEditingController();
  final _toolController = TextEditingController();

  List<String> _teamRoles = []; // Changed to _teamRoles for clarity
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

  @override
  void initState() {
    super.initState();
    // MessageManager を初期化してメッセージを読み込む
    messageManager.loadMessages(assetPath: 'assets/messages.json').then((_) {
      _fetchUtilData().then((data) {
        setState(() {
          _teamRoles =
          List<String>.from(data['team_role'] ?? []);
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
    _codeLanguagesController.dispose();
    _dbExperienceController.dispose();
    _osExperienceController.dispose();
    _cloudTechController.dispose();
    _toolController.dispose();
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
          'experience_category':
          docExperienceCategory.data()!['experience_category'] as List<dynamic>,
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
      return {

      };
    }
  }

  Future<void> _registerEngineer() async {
    // メソッド開始のログを出力
    messageManager.info("1000I",constData.engineerCollection);

    // エラーチェック用の関数を定義
    List<String> _checkRadioButtons() {
      //エラーリストを初期化
      List<String> errors = [];
      _teamRolesChecked.forEach((teamRole, level) {
        if (level == '選択') {
          errors.add('チーム役割：$teamRole');
        }
      });
      _processesChecked.forEach((process, level) {
        if (level == '選択') {
          errors.add('工程：$process');
        }
      });
      _codeLanguagesChecked.forEach((codeLanguage, level) {
        if (level == '選択') {
          errors.add('経験言語：$codeLanguage');
        }
      });
      _dbExperienceChecked.forEach((dbExperience, level) {
        if (level == '選択') {
          errors.add('DB経験：$dbExperience');
        }
      });
      _osExperienceChecked.forEach((osExperience, level) {
        if (level == '選択') {
          errors.add('OS経験：$osExperience');
        }
      });
      _cloudTechChecked.forEach((cloudTech, level) {
        if (level == '選択') {
          errors.add('クラウド技術：$cloudTech');
        }
      });
      _toolChecked.forEach((tool, level) {
        if (level == '選択') {
          errors.add('ツール：$tool');
        }
      });
      return errors;
    }

    //フォームがvalidateされた場合のみ実行
    if (_formKey.currentState!.validate()) {
      //ラジオボタンが未選択の状態で登録ボタン押した場合
      List<String> errors = _checkRadioButtons();
      if (errors.isNotEmpty) {
        // 各エラー項目に対応するメッセージを生成
        List<String> errorMessages = errors.map((error) => messageManager.getMessage("2001E", [error])).toList();
        // メッセージを改行で連結
        String combinedErrorMessage = errorMessages.join('\n');
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('入力エラー'),
              content: Text(combinedErrorMessage),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        return;
      }
      try {
        // utilData から team_role 配列を取得
        final docTeamRole = await FirebaseFirestore.instance
            .collection('utilData')
            .doc('team_role_item')
            .get();
        List<String> docTeamRoleList =
        List<String>.from(docTeamRole.data()!['team_role'] ?? []);

        List<int> selectedTeamRole = [];
        List<int> selectedTeamRoleYears= [];
        _teamRolesChecked.forEach((teamRole, level) {
          if (level != null) {
            selectedTeamRole.add(docTeamRoleList.indexOf(teamRole));
            selectedTeamRoleYears
                .add(_yearsCategories.indexOf(level));
          }
        });

        // utilData から process 配列を取得
        final docProcess = await FirebaseFirestore.instance
            .collection('utilData')
            .doc('process_item')
            .get();
        List<String> docProcessList =
        List<String>.from(docProcess.data()!['process'] ?? []);

        List<int> selectedProcess = [];
        List<int> selectedProcessExperience = [];
        _processesChecked.forEach((process, level) {
          if (level != null) {
            selectedProcess.add(docProcessList.indexOf(process));
            selectedProcessExperience.add(_experienceCategories.indexOf(level));
          }
        });

        // utilData から code_languages 配列を取得
        final docCodeLanguages = await FirebaseFirestore.instance
            .collection('utilData')
            .doc('code_languages_item')
            .get();
        List<String> codeLanguagesList =
            List<String>.from(docCodeLanguages.data()!['code_languages'] ?? []);

        // 変更点: 各技術要素の選択された要素と年数を配列で登録
        List<int> selectedCodeLanguages = [];
        List<int> selectedCodeLanguagesYears = [];
        _codeLanguagesChecked.forEach((codeLanguage, level) {
          if (level != null) {
            selectedCodeLanguages.add(codeLanguagesList.indexOf(codeLanguage));
            selectedCodeLanguagesYears.add(_yearsCategories.indexOf(level));
          }
        });

        // utilData から DbExperience 配列を取得
        final docDbExperience = await FirebaseFirestore.instance
            .collection('utilData')
            .doc('db_experience_item')
            .get();
        List<String> dbExperienceList =
            List<String>.from(docDbExperience.data()!['db_experience'] ?? []);

        List<int> selectedDbExperience = [];
        List<int> selectedDbExperienceYears = [];
        _dbExperienceChecked.forEach((dbExperience, level) {
          if (level != null) {
            selectedDbExperience.add(dbExperienceList.indexOf(dbExperience));
            selectedDbExperienceYears.add(_yearsCategories.indexOf(level));
          }
        });

        // utilData から OsExperience 配列を取得
        final docOsExperience = await FirebaseFirestore.instance
            .collection('utilData')
            .doc('os_experience_item')
            .get();
        List<String> docOsExperienceList =
            List<String>.from(docOsExperience.data()!['os_experience'] ?? []);

        List<int> selectedOsExperience = [];
        List<int> selectedOsExperienceYears = [];
        _osExperienceChecked.forEach((osExperience, level) {
          if (level != null) {
            selectedOsExperience.add(docOsExperienceList.indexOf(osExperience));
            selectedOsExperienceYears.add(_yearsCategories.indexOf(level));
          }
        });

        // utilData から cloudTechnology 配列を取得
        final docCloudTechnology = await FirebaseFirestore.instance
            .collection('utilData')
            .doc('cloud_technology_item')
            .get();
        List<String> docCloudTechnologyList = List<String>.from(
            docCloudTechnology.data()!['cloud_technology'] ?? []);

        List<int> selectedCloudTech = [];
        List<int> selectedCloudTechYears = [];
        _cloudTechChecked.forEach((cloudTech, level) {
          if (level != null) {
            selectedCloudTech.add(docCloudTechnologyList.indexOf(cloudTech));
            selectedCloudTechYears.add(_yearsCategories.indexOf(level));
          }
        });

        // utilData から tool 配列を取得
        final docTool = await FirebaseFirestore.instance
            .collection('utilData')
            .doc('tool_item')
            .get();
        List<String> docToolList =
            List<String>.from(docTool.data()!['tool'] ?? []);

        List<int> selectedTool = [];
        List<int> selectedToolYears = [];
        _toolChecked.forEach((tool, level) {
          if (level != null) {
            selectedTool.add(docToolList.indexOf(tool));
            selectedToolYears.add(_yearsCategories.indexOf(level));
          }
        });


        await FirebaseFirestore.instance.collection('engineer').add({
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'age': int.parse(_ageController.text),
          'nearest_station_line_name': _nearestStationLineNameController.text,
          'nearest_station_name': _nearestStationNameController.text,
          'team_role': selectedTeamRole,
          'team_role_years': selectedTeamRoleYears,
          'process': selectedProcess,
          'process_experience': selectedProcessExperience,
          'code_languages': selectedCodeLanguages,
          'code_languages_years': selectedCodeLanguagesYears,
          'db_experience': selectedDbExperience,
          'db_experience_years': selectedDbExperienceYears,
          'os_experience': selectedOsExperience,
          'os_experience_years': selectedOsExperienceYears,
          'cloud_technology': selectedCloudTech,
          'cloud_technology_years': selectedCloudTechYears,
          'tool': selectedTool,
          'tool_years': selectedToolYears,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('技術者登録が完了しました')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登録に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('技術者登録')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: '名',
                        prefixIcon: Icon(Icons.person), // ここにアイコンを追加
                      ),
                      validator: (value) =>
                          value == null || value.isEmpty ? '名前を入力してください' : null,
                    ),
                  ),
                  SizedBox(width: 16), // 間にスペースを設ける
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: '苗字',
                        prefixIcon: Icon(Icons.person),
                      ), // ここにアイコンを追加),
                      validator: (value) =>
                          value == null || value.isEmpty ? '苗字を入力してください' : null,
                    ),
                  ),
                  SizedBox(width: 16), // 間にスペースを設ける
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _ageController,
                      decoration: InputDecoration(
                        labelText: '年齢',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return '年齢を入力してください';
                        return int.tryParse(value) == null
                            ? '有効な年齢を入力してください'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _nearestStationLineNameController,
                      decoration: InputDecoration(
                          labelText: '最寄沿線',
                          prefixIcon: Icon(Icons.linear_scale)),
                      validator: (value) => value == null || value.isEmpty
                          ? '最寄沿線を入力してください'
                          : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _nearestStationNameController,
                      decoration: InputDecoration(
                          labelText: '最寄駅', prefixIcon: Icon(Icons.train)),
                      validator: (value) => value == null || value.isEmpty
                          ? '最寄駅を入力してください'
                          : null,
                    ),
                  ),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                ),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Icon(Icons.group), // ここに表示したいアイコンを指定します
                      SizedBox(width: 8), // アイコンとテキストの間にスペースを追加
                      Text('チーム役割'),
                    ],
                  ),
                  childrenPadding: EdgeInsets.only(left: 16.0, bottom: 16.0),
                  children: _teamRoles.map((teamRoles) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          title: Text(teamRoles),
                          value: _teamRolesChecked[teamRoles] != null,
                          onChanged: (value) {
                            setState(() {
                              _teamRolesChecked[teamRoles] =
                                  value! ? '選択' : null;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (_teamRolesChecked[teamRoles] != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Wrap(
                              spacing: 8.0,
                              children: _yearsCategories.map((yearsCategory) {
                                return RadioListTile<String>(
                                  title: Padding(
                                    padding:
                                        const EdgeInsets.only(left: 16.0 * 4),
                                    child: Text(yearsCategory),
                                  ),
                                  value: yearsCategory,
                                  groupValue: _teamRolesChecked[teamRoles],
                                  onChanged: (value) {
                                    setState(() {
                                      _teamRolesChecked[teamRoles] = value;
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity:
                                      ListTileControlAffinity.trailing,
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                ),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Icon(Icons.account_tree), // Icons.build アイコンを使用
                      SizedBox(width: 8),
                      Text('工程'),
                    ],
                  ),
                  children: _processes.map((process) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            title: Text(process),
                            value: _processesChecked[process] != null,
                            onChanged: (value) {
                              setState(() {
                                _processesChecked[process] = value! ? '選択' : null;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_processesChecked[process] != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Wrap(
                                spacing: 8.0,
                                children: _experienceCategories
                                    .map((experienceCategory) {
                                  return RadioListTile<String>(
                                    title: Padding(
                                      padding:
                                          const EdgeInsets.only(left: 16.0 * 4),
                                      child: Text(experienceCategory),
                                    ),
                                    value: experienceCategory,
                                    groupValue: _processesChecked[process],
                                    onChanged: (value) {
                                      setState(() {
                                        _processesChecked[process] = value;
                                      });
                                    },
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity:
                                        ListTileControlAffinity.trailing,
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                ),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Icon(Icons.developer_mode), // Icons.code アイコンを使用
                      SizedBox(width: 8),
                      Text('経験言語'),
                    ],
                  ),
                  children: _codeLanguages.map((codeLanguages) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            title: Text(codeLanguages),
                            value: _codeLanguagesChecked[codeLanguages] != null,
                            onChanged: (value) {
                              setState(() {
                                _codeLanguagesChecked[codeLanguages] =
                                    value! ? '選択' : null;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_codeLanguagesChecked[codeLanguages] != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Wrap(
                                spacing: 8.0,
                                children: _yearsCategories.map((yearsCategory) {
                                  return RadioListTile<String>(
                                    title: Padding(
                                      padding:
                                          const EdgeInsets.only(left: 16.0 * 4),
                                      child: Text(yearsCategory),
                                    ),
                                    value: yearsCategory,
                                    groupValue:
                                        _codeLanguagesChecked[codeLanguages],
                                    onChanged: (value) {
                                      setState(() {
                                        _codeLanguagesChecked[codeLanguages] =
                                            value;
                                      });
                                    },
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity:
                                        ListTileControlAffinity.trailing,
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                ),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Icon(Icons.storage),
                      SizedBox(width: 8),
                      Text('DB言語'),
                    ],
                  ),
                  children: _dbExperience.map((dbExperience) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            title: Text(dbExperience),
                            value: _dbExperienceChecked[dbExperience] != null,
                            onChanged: (value) {
                              setState(() {
                                _dbExperienceChecked[dbExperience] =
                                    value! ? '選択' : null;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_dbExperienceChecked[dbExperience] != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Wrap(
                                spacing: 8.0,
                                children: _yearsCategories.map((yearsCategory) {
                                  return RadioListTile<String>(
                                    title: Padding(
                                      padding:
                                          const EdgeInsets.only(left: 16.0 * 4),
                                      child: Text(yearsCategory),
                                    ),
                                    value: yearsCategory,
                                    groupValue:
                                        _dbExperienceChecked[dbExperience],
                                    onChanged: (value) {
                                      setState(() {
                                        _dbExperienceChecked[dbExperience] =
                                            value;
                                      });
                                    },
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity:
                                        ListTileControlAffinity.trailing,
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                ),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Icon(Icons.memory), // Icons.code アイコンを使用
                      SizedBox(width: 8),
                      Text('OS言語'),
                    ],
                  ),
                  children: _osExperience.map((osExperience) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            title: Text(osExperience),
                            value: _osExperienceChecked[osExperience] != null,
                            onChanged: (value) {
                              setState(() {
                                _osExperienceChecked[osExperience] =
                                    value! ? '選択' : null;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_osExperienceChecked[osExperience] != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Wrap(
                                spacing: 8.0,
                                children: _yearsCategories.map((yearsCategory) {
                                  return RadioListTile<String>(
                                    title: Padding(
                                      padding:
                                          const EdgeInsets.only(left: 16.0 * 4),
                                      child: Text(yearsCategory),
                                    ),
                                    value: yearsCategory,
                                    groupValue:
                                        _osExperienceChecked[osExperience],
                                    onChanged: (value) {
                                      setState(() {
                                        _osExperienceChecked[osExperience] =
                                            value;
                                      });
                                    },
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity:
                                        ListTileControlAffinity.trailing,
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                ),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Icon(Icons.cloud), // Icons.code アイコンを使用
                      SizedBox(width: 8),
                      Text('クラウド技術'),
                    ],
                  ),
                  children: _cloudTech.map((cloudTech) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            title: Text(cloudTech),
                            value: _cloudTechChecked[cloudTech] != null,
                            onChanged: (value) {
                              setState(() {
                                _cloudTechChecked[cloudTech] =
                                    value! ? '選択' : null;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_cloudTechChecked[cloudTech] != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Wrap(
                                spacing: 8.0,
                                children: _yearsCategories.map((yearsCategory) {
                                  return RadioListTile<String>(
                                    title: Padding(
                                      padding:
                                          const EdgeInsets.only(left: 16.0 * 4),
                                      child: Text(yearsCategory),
                                    ),
                                    value: yearsCategory,
                                    groupValue: _cloudTechChecked[cloudTech],
                                    onChanged: (value) {
                                      setState(() {
                                        _cloudTechChecked[cloudTech] = value;
                                      });
                                    },
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity:
                                        ListTileControlAffinity.trailing,
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                  ),
                ),
                child: ExpansionTile(
                  title: Row(
                    children: [
                      Icon(Icons.build), // Icons.code アイコンを使用
                      SizedBox(width: 8),
                      Text('ツール'),
                    ],
                  ),
                  children: _tool.map((tool) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            title: Text(tool),
                            value: _toolChecked[tool] != null,
                            onChanged: (value) {
                              setState(() {
                                _toolChecked[tool] = value! ? '選択' : null;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_toolChecked[tool] != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Wrap(
                                spacing: 8.0,
                                children: _yearsCategories.map((yearsCategory) {
                                  return RadioListTile<String>(
                                    title: Padding(
                                      padding:
                                          const EdgeInsets.only(left: 16.0 * 4),
                                      child: Text(yearsCategory),
                                    ),
                                    value: yearsCategory,
                                    groupValue: _toolChecked[tool],
                                    onChanged: (value) {
                                      setState(() {
                                        _toolChecked[tool] = value;
                                      });
                                    },
                                    contentPadding: EdgeInsets.zero,
                                    controlAffinity:
                                        ListTileControlAffinity.trailing,
                                  );
                                }).toList(),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              ElevatedButton(
                onPressed: _registerEngineer,
                child: Text('登録'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
