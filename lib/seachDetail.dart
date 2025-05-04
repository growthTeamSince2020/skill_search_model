import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:skill_search_model/common/constData.dart';
import 'dart:async';
import 'package:skill_search_model/search.dart';
import 'package:skill_search_model/searchConditionsDto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class SeachDetailPage extends ConsumerStatefulWidget{
// StatefulWidget {
  const SeachDetailPage({super.key});

  @override
  ConsumerState<SeachDetailPage> createState() => _SeachDetailPageState();
}

class _SeachDetailPageState extends ConsumerState<SeachDetailPage> {

  // searchConProviderのインスタンスを取得
  late SearchConditionsDto searchConditions;

  final logger = Logger(); //ロガーの宣言
  //編集フラグ
  List<String> _teamRoles = []; // Changed to _teamRoles for clarity
  List<String> _processes = [];
  List<String> _codeLanguages = [];
  List<String> _dbExperience = [];
  List<String> _osExperience = [];
  List<String> _cloudTech = [];
  List<String> _tool = [];
  List<String> _experienceCategories = [];
  List<String> _yearsCategories = [];
  List<String> _ageList = [
    "条件を指定しない",
    constData.searchAgeSelectStringUnder30,
    constData.searchAgeSelectStringUnder40,
    constData.searchAgeSelectStringUnder50
  ];

  final Map<String, String?> _teamRolesChecked = {};
  final Map<String, String?> _processesChecked = {};
  final Map<String, String?> _codeLanguagesChecked = {};
  final Map<String, String?> _dbExperienceChecked = {};
  final Map<String, String?> _osExperienceChecked = {};
  final Map<String, String?> _cloudTechChecked = {};
  final Map<String, String?> _toolChecked = {};
  int? _ageChecked;

  //工程取得リスト
  List<List<bool>> _processSearchItemChecked
  = [[false,false,false,false], //要件定義
  [false,false,false,false], //基本設計
  [false,false,false,false], //詳細設計
  [false,false,false,false], //コーディング
  [false,false,false,false], //単体
  [false,false,false,false], //結合
  [false,false,false,false]]; //保守

  @override
  void initState() {
    super.initState();

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
  }

  void _clear(){
    //クリアボタン押下時
    logger.i("クリアボタン押下されました");
    setState(() {
      ref.read(searchConditionsControllerProvider.notifier).clear();
      logger.i('編集フラグ：　'+searchConditions.getSearchSettingFlag.toString());
      logger.i('年齢：　'+searchConditions.getAgeDropdownSelectedValue.toString());
    });
  }
  void _searchEngineer(){
    Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
        builder: (BuildContext context) => const SearchPage(),
    ),
    );
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
  @override
  Widget build(BuildContext context) {
    // searchConProviderのインスタンスを取得
    searchConditions = ref.watch(searchConditionsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightGreenAccent.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            Container(
                margin: const EdgeInsets.only(right: 10),
                child: const Icon(Icons.filter_list_alt,color: Colors.white,)),
            const Text(constData.engineerSearchDitail,style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
      body: ListView(
        children: <Widget>[
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
                  Text("年齢"),
                ],
              ),
              childrenPadding: EdgeInsets.only(left: 16.0, bottom: 16.0),
              children: _ageList.map((ageKey) {
                return
                RadioListTile<String>(
                  title: Padding(
                    padding:
                    const EdgeInsets.only(left: 16.0 * 4),
                    child: Text(ageKey),
                  ),
                  value: ageKey,
                  groupValue: _ageList[searchConditions.getAgeDropdownSelectedValue as int],
                  // groupValue: _ageList[_ageChecked!],
                  onChanged: (value) {
                    setState(() {
                      logger.i('value: ${_ageList.indexOf(value!)}');
                      ref.read(searchConditionsControllerProvider.notifier).setAgeDropdownSelectedValue(_ageList.indexOf(value!));
                      ref.read(searchConditionsControllerProvider.notifier).setSearchSettingFlag(true);
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity:
                  ListTileControlAffinity.trailing,
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
                            return CheckboxListTile(
                              title: Text(yearsCategory),
                              value: false,
                              onChanged: (value) {
                                setState(() {
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
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
                                return CheckboxListTile(
                                  title: Text(experienceCategory),
                                  value: _processSearchItemChecked[_processes.indexOf(process)][_experienceCategories.indexOf(experienceCategory)],
                                  onChanged: (value) {
                                    //のちログ消す
                                    logger.i("'hako1: ${_processes.indexOf(process)}','hako2: ${_experienceCategories.indexOf(experienceCategory)}");
                                    logger.i("'前フラグ: ${_processSearchItemChecked[_processes.indexOf(process)][_experienceCategories.indexOf(experienceCategory)]}'");

                                    setState(() {
                                      _processSearchItemChecked[_processes.indexOf(process)][_experienceCategories.indexOf(experienceCategory)] = value!;
                                      logger.i("'後フラグ: ${_processSearchItemChecked[_processes.indexOf(process)][_experienceCategories.indexOf(experienceCategory)]}'");
                                    });
                                  },
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  contentPadding: EdgeInsets.zero,
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
            onPressed: _searchEngineer,
            child: Text('検索'),
            style: ElevatedButton.styleFrom(
              side: const BorderSide(
              color: Colors.black, //枠線!
              width: 0.2, //枠線！
            ),),
          ),
          ElevatedButton(
            onPressed: _clear,
            child: Text('クリア'),
            style: ElevatedButton.styleFrom(
              side: const BorderSide(
                color: Colors.black, //枠線!
                width: 0.2, //枠線！
              ),),
          ),
        ],
    ));
  }

}



