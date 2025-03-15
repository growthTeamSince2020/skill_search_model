import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EngineerRegistrationForm extends StatefulWidget {
  @override
  _EngineerRegistrationFormState createState() =>
      _EngineerRegistrationFormState();
}

class _EngineerRegistrationFormState extends State<EngineerRegistrationForm> {
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
  final Map<String, String?> _processChecked = {};
  final Map<String, String?> _codeLanguagesChecked = {};
  final Map<String, String?> _dbExperienceChecked = {};
  final Map<String, String?> _osExperienceChecked = {};
  final Map<String, String?> _cloudTechChecked = {};
  final Map<String, String?> _toolChecked = {};

  @override
  void initState() {
    super.initState();
    _fetchUtilData().then((data) {
      setState(() {
        _teamRoles =
            List<String>.from(data['team_role'] ?? []); // Updated to _teamRoles
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
        _processChecked.clear();
        _codeLanguagesChecked.clear();
        _dbExperienceChecked.clear();
        _osExperienceChecked.clear();
        _cloudTechChecked.clear();
        _toolChecked.clear();
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
      final docTeamRole =
          await FirebaseFirestore.instance // Add fetching for team_role
              .collection('utilData')
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
        // Add check for docTeamRole
        return {
          'team_role': docTeamRole.data()!['team_role'] as List<dynamic>,
          'process': docProcess.data()!['process'] as List<dynamic>,
          'code_languages': docCodeLanguages.data()!['code_languages'] as List<dynamic>,
          'experience_category': docExperienceCategory
              .data()!['experience_category'] as List<dynamic>,
          'years_category':
              docYearsCategory.data()!['years_category'] as List<dynamic>,
          'db_experience': docDbExperience.data()!['db_experience'] as List<dynamic>,
          'os_experience': docOsExperience.data()!['os_experience'] as List<dynamic>,
          'cloud_technology': docCloudTech.data()!['cloud_technology'] as List<dynamic>,
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

  Future<void> _registerEngineer() async {
    if (_formKey.currentState!.validate()) {
      try {
        Map<String, String> selectedTeamRoles = {};
        _teamRolesChecked.forEach((teamRole, level) {
          if (level != null) {
            selectedTeamRoles[teamRole] = level;
          }
        });
        Map<String, String> selectedProcesses = {};
        _processChecked.forEach((process, level) {
          if (level != null) {
            selectedProcesses[process] = level;
          }
        });
        Map<String, String> selectedCodeLanguages = {};
        _codeLanguagesChecked.forEach((codeLanguages, level) {
          if (level != null) {
            selectedCodeLanguages[codeLanguages] = level;
          }
        });
        Map<String, String> selectedDbExperience = {};
        _dbExperienceChecked.forEach((dbExperience, level) {
          if (level != null) {
            selectedDbExperience[dbExperience] = level;
          }
        });
        Map<String, String> selectedOsExperience = {};
        _osExperienceChecked.forEach((osExperience, level) {
          if (level != null) {
            selectedOsExperience[osExperience] = level;
          }
        });
        Map<String, String> selectedCloudTech = {};
        _cloudTechChecked.forEach((cloudTech, level) {
          if (level != null) {
            selectedCloudTech[cloudTech] = level;
          }
        });
        Map<String, String> selectedTool = {};
        _toolChecked.forEach((tool, level) {
          if (level != null) {
            selectedTool[tool] = level;
          }
        });
        await FirebaseFirestore.instance.collection('engineers').add({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'age': int.parse(_ageController.text),
          'nearest_station_line_name': _nearestStationLineNameController.text,
          'nearest_station_name': _nearestStationNameController.text,
          // Update to get text

          'team_role': selectedTeamRoles,
          'processes': selectedProcesses,
          'code_languages': selectedCodeLanguages,
          'db_experience': selectedDbExperience,
          'os_experience': selectedOsExperience,
          'cloud_tech': selectedCloudTech,
          'tool': selectedTool,
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
                      decoration: InputDecoration(labelText: '名'),
                      validator: (value) =>
                          value == null || value.isEmpty ? '名前を入力してください' : null,
                    ),
                  ),
                  SizedBox(width: 16), // 間にスペースを設ける
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(labelText: '苗字'),
                      validator: (value) =>
                          value == null || value.isEmpty ? '苗字を入力してください' : null,
                    ),
                  ),
                  SizedBox(width: 16), // 間にスペースを設ける
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _ageController,
                      decoration: InputDecoration(labelText: '年齢'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) return '年齢を入力してください';
                        return int.tryParse(value) == null ? '有効な年齢を入力してください' : null;
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
                      decoration: InputDecoration(labelText: '最寄沿線'),
                      validator: (value) => value == null || value.isEmpty ? '最寄沿線を入力してください' : null,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _nearestStationNameController,
                      decoration: InputDecoration(labelText: '最寄駅'),
                      validator: (value) => value == null || value.isEmpty ? '最寄駅を入力してください' : null,
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
                  title: Text('チーム役割'),
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
                  title: Text('▼工程'),
                  children: _processes.map((process) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            title: Text(process),
                            value: _processChecked[process] != null,
                            onChanged: (value) {
                              setState(() {
                                _processChecked[process] = value! ? '選択' : null;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_processChecked[process] != null)
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
                                    groupValue: _processChecked[process],
                                    onChanged: (value) {
                                      setState(() {
                                        _processChecked[process] = value;
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
                  title: Text('▼経験言語'),
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
                                _codeLanguagesChecked[codeLanguages] = value! ? '選択' : null;
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
                                children: _yearsCategories
                                    .map((yearsCategory) {
                                  return RadioListTile<String>(
                                    title: Padding(
                                      padding:
                                      const EdgeInsets.only(left: 16.0 * 4),
                                      child: Text(yearsCategory),
                                    ),
                                    value: yearsCategory,
                                    groupValue: _codeLanguagesChecked[codeLanguages],
                                    onChanged: (value) {
                                      setState(() {
                                        _codeLanguagesChecked[codeLanguages] = value;
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
                  title: Text('▼DB言語'),
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
                                _dbExperienceChecked[dbExperience]  = value! ? '選択' : null;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_dbExperienceChecked[dbExperience]  != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Wrap(
                                spacing: 8.0,
                                children: _yearsCategories
                                    .map((yearsCategory) {
                                  return RadioListTile<String>(
                                    title: Padding(
                                      padding:
                                      const EdgeInsets.only(left: 16.0 * 4),
                                      child: Text(yearsCategory),
                                    ),
                                    value: yearsCategory,
                                    groupValue: _dbExperienceChecked[dbExperience] ,
                                    onChanged: (value) {
                                      setState(() {
                                        _dbExperienceChecked[dbExperience] = value;
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
                  title: Text('▼OS経験'),
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
                                _osExperienceChecked[osExperience] = value! ? '選択' : null;
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
                                children: _yearsCategories
                                    .map((yearsCategory) {
                                  return RadioListTile<String>(
                                    title: Padding(
                                      padding:
                                      const EdgeInsets.only(left: 16.0 * 4),
                                      child: Text(yearsCategory),
                                    ),
                                    value: yearsCategory,
                                    groupValue: _osExperienceChecked[osExperience],
                                    onChanged: (value) {
                                      setState(() {
                                        _osExperienceChecked[osExperience] = value;
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
                  title: Text('▼クラウド技術'),
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
                                _cloudTechChecked[cloudTech] = value! ? '選択' : null;
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
                                children: _yearsCategories
                                    .map((yearsCategory) {
                                  return RadioListTile<String>(
                                    title: Padding(
                                      padding:
                                      const EdgeInsets.only(left: 16.0 * 4),
                                      child: Text(yearsCategory),
                                    ),
                                    value: yearsCategory,
                                    groupValue:_cloudTechChecked[cloudTech] ,
                                    onChanged: (value) {
                                      setState(() {
                                        _cloudTechChecked[cloudTech]  = value;
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
                  title: Text('▼ツール'),
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
                                children: _yearsCategories
                                    .map((yearsCategory) {
                                  return RadioListTile<String>(
                                    title: Padding(
                                      padding:
                                      const EdgeInsets.only(left: 16.0 * 4),
                                      child: Text(yearsCategory),
                                    ),
                                    value: yearsCategory,
                                    groupValue:_toolChecked[tool] ,
                                    onChanged: (value) {
                                      setState(() {
                                        _toolChecked[tool]  = value;
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
