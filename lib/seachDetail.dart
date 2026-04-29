import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:skill_search_model/common/constData.dart';
import 'dart:async';
import 'package:skill_search_model/search.dart';
import 'package:skill_search_model/model/searchConditionsDto.dart';
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

  //工程取得リスト(小項目のチェック状態)などの初期化
  final List<List<bool>> _search4ItemCheckedInit = [
    [false, false, false, false], //要件定義
    [false, false, false, false], //基本設計
    [false, false, false, false], //詳細設計
    [false, false, false, false], //コーディング
    [false, false, false, false], //単体
    [false, false, false, false], //結合
    [false, false, false, false] //保守
  ];

  //工程取得(フラグ)リスト
  late bool _searchSettingFlagProcess;
  //工程取得(大項目のチェック状態)リスト
  late List<bool> _processSearchChecked;
  //工程取得(子項目のチェック状態)リスト
  late List<List<bool>> _processSearchItemChecked;

  //チーム役割取得(フラグ)リスト
  late bool _searchSettingFlagTeamRoles;
  //チーム役割取得(大項目のチェック状態)リスト
  late List<bool> _teamRolesSearchChecked;
  //チーム役割取得(子項目のチェック状態)リスト
  late List<List<bool>> _teamRolesSearchItemChecked;

  //経験言語取得リストリスト
  late bool _searchSettingFlagCodeLanguages;
  //経験言語取得リスト取得(大項目のチェック状態)リスト
  late List<bool> _codeLanguagesSearchChecked;
  //経験言語取得リスト取得(子項目のチェック状態)リスト
  late List<List<bool>> _codeLanguagesSearchItemChecked;

  //DB取得(フラグ)リスト
  late bool _searchSettingFlagDbExperience;
  //DB取得(大項目のチェック状態)リスト
  late List<bool> _dbExperienceSearchChecked;
  //DB取得(子項目のチェック状態)リスト
  late List<List<bool>> _dbExperienceSearchItemChecked;

  //OS取得(フラグ)リスト
  late bool _searchSettingFlagOsExperience;
  //OS取得(大項目のチェック状態)リスト
  late List<bool> _osExperienceSearchChecked;
  //OS取得(子項目のチェック状態)リスト
  late List<List<bool>> _osExperienceSearchItemChecked;

  //クラウド取得(フラグ)リスト
  late bool _searchSettingFlagCloudTechnology;
  //クラウド取得(大項目のチェック状態)リスト
  late List<bool> _cloudTechnologySearchChecked;
  //クラウド取得(子項目のチェック状態)リスト
  late List<List<bool>> _cloudTechnologySearchItemChecked;

  //ツール取得(フラグ)リスト
  late bool _searchSettingFlagTool;
  //ツール取得(大項目のチェック状態)リスト
  late List<bool> _toolSearchChecked;
  //ツール取得(子項目のチェック状態)リスト
  late List<List<bool>> _toolSearchItemChecked;


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
      //クリアにしてたので検索一覧に戻る
      Navigator.pop(context);
    });
  }
  void _searchEngineer(){
    // searchConProviderのインスタンスを取得
    searchConditions = ref.watch(searchConditionsControllerProvider);

    //工程経験(大項目チェックリスト、フラグ)の値の初期化　各フラグが全てfalse（初期値）だったらフラグをfalseにする
    bool processSearchItemCheckedAllFalse = _processSearchItemChecked.every((row) => row.every((element) => element == false));
    if(processSearchItemCheckedAllFalse) {
      ref.read(searchConditionsControllerProvider.notifier).processClear();
     }else{
      ref.read(searchConditionsControllerProvider.notifier).setSearchSettingProcessFlag(true);
    }

    //チーム経験(大項目チェックリスト、フラグ)の値の初期化　各フラグが全てfalse（初期値）だったらフラグをfalseにする
    bool teamRolesSearchItemCheckedAllFalse = _teamRolesSearchItemChecked.every((row) => row.every((element) => element == false));
    if(teamRolesSearchItemCheckedAllFalse) {
      ref.read(searchConditionsControllerProvider.notifier).teamRolesClear();
    }else{
      ref.read(searchConditionsControllerProvider.notifier).setSearchSettingTeamRolesFlag(true);
    }

    //経験言語(大項目チェックリスト、フラグ)の値の初期化　各フラグが全てfalse（初期値）だったらフラグをfalseにする
    bool codeLanguagesSearchItemCheckedAllFalse = _codeLanguagesSearchItemChecked.every((row) => row.every((element) => element == false));
    if(codeLanguagesSearchItemCheckedAllFalse) {
      ref.read(searchConditionsControllerProvider.notifier).codeLanguagesClear();
    }else{
      ref.read(searchConditionsControllerProvider.notifier).setSearchSettingCodeLanguagesFlag(true);
    }

    //DB経験(大項目チェックリスト、フラグ)の値の初期化　各フラグが全てfalse（初期値）だったらフラグをfalseにする
    bool dbExperienceSearchItemCheckedAllFalse = _dbExperienceSearchItemChecked.every((row) => row.every((element) => element == false));
    if(dbExperienceSearchItemCheckedAllFalse) {
      ref.read(searchConditionsControllerProvider.notifier).dbExperienceClear();
    }else{
      ref.read(searchConditionsControllerProvider.notifier).setSearchSettingDbExperienceFlag(true);
    }

    //OS経験(大項目チェックリスト、フラグ)の値の初期化　各フラグの全てがfalse（初期値）だったらフラグをfalseにする
    bool osExperienceSearchItemCheckedAllFalse = _osExperienceSearchItemChecked.every((row) => row.every((element) => element == false));
    if(osExperienceSearchItemCheckedAllFalse) {
      ref.read(searchConditionsControllerProvider.notifier).osExperienceClear();
    }else{
      ref.read(searchConditionsControllerProvider.notifier).setSearchSettingOsExperienceFlag(true);
    }

    //クラウド経験(大項目チェックリスト、フラグ)の値の初期値　各フラグの全てがfalse（初期値）だったらフラグをfalseにする
    bool cloudTechnologySearchItemCheckedAllFalse = _cloudTechnologySearchItemChecked.every((row) => row.every((element) => element == false));
    if(cloudTechnologySearchItemCheckedAllFalse) {
      ref
          .read(searchConditionsControllerProvider.notifier)
          .cloudTechnologyClear();
    }else{
      ref.read(searchConditionsControllerProvider.notifier).setSearchSettingCloudTechnologyFlag(true);
    }

    //ツール経験(大項目チェックリスト、フラグ)の値の初期値　各フラグの全てがfalse（初期値）だったらフラグをfalseにする
    bool toolSearchItemCheckedAllFalse = _toolSearchItemChecked.every((row) => row.every((element) => element == false));
    if(toolSearchItemCheckedAllFalse) {
      ref.read(searchConditionsControllerProvider.notifier).toolClear();
    }else{
      ref.read(searchConditionsControllerProvider.notifier).setSearchSettingToolFlag(true);
    }

    //検索設定フラグの値の初期化　各フラグが全てfalseだったら検索設定フラグをfalseにする
    if(searchConditions.getAgeDropdownSelectedValue == 0 //年齢が初期値
        && searchConditions.getSearchSettingProcessFlag == false //工程経験が初期値
        && searchConditions.getSearchSettingTeamRolesFlag == false //チーム経験が初期値
        && searchConditions.getSearchSettingCodeLanguagesFlag == false //経験言語が初期値
        && searchConditions.getSearchSettingDbExperienceFlag == false //DB経験が初期値
        && searchConditions.getSearchSettingOsExperienceFlag == false //OS経験が初期値
        && searchConditions.getSearchSettingCloudTechnologyFlag == false //クラウド経験が初期値
        && searchConditions.getSearchSettingToolFlag == false //ツール経験が初期値
    ){
      ref.read(searchConditionsControllerProvider.notifier).clear();
    }else{
      ref.read(searchConditionsControllerProvider.notifier).setSearchSettingFlag(true);
    }

    searchConditions = ref.watch(searchConditionsControllerProvider);

    logger.i("詳細検索画面側　getSearchSettingFlag: ${searchConditions.getSearchSettingFlag}");
    logger.i("詳細検索画面側　getAgeDropdownSelectedValue: ${searchConditions.getAgeDropdownSelectedValue}");
    logger.i("詳細検索画面側　getSearchSettingProcessFlag: ${searchConditions.getSearchSettingProcessFlag}");

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

    //年齢の値を取得
    _ageChecked = searchConditions.getAgeDropdownSelectedValue;
    //工程経験(フラグ)の値を取得
    _searchSettingFlagProcess = searchConditions.getSearchSettingProcessFlag!;
    //工程経験(大項目のチェック状態)の値を取得
    _processSearchChecked = searchConditions.getProcessSearchChecked!;
    //工程経験(小項目のチェック状態)の値を取得
    _processSearchItemChecked = searchConditions.getProcessSearchItemChecked!;
    //チーム経験(フラグ)の値を取得
    _searchSettingFlagTeamRoles = searchConditions.getSearchSettingTeamRolesFlag!;
    //チーム経験(大項目のチェック状態)の値を取得
    _teamRolesSearchChecked = searchConditions.getTeamRolesSearchChecked!;
    //チーム経験(小項目のチェック状態)の値を取得
    _teamRolesSearchItemChecked = searchConditions.getTeamRolesSearchItemChecked!;

    //経験言語(フラグ)の値を取得
    _searchSettingFlagCodeLanguages = searchConditions.getSearchSettingCodeLanguagesFlag!;
    //経験言語(大項目のチェック状態)の値を取得
    _codeLanguagesSearchChecked = searchConditions.getCodeLanguagesSearchChecked!;
    //経験言語(小項目のチェック状態)の値を取得
    _codeLanguagesSearchItemChecked = searchConditions.getCodeLanguagesSearchItemChecked!;

    //DB経験(フラグ)の値を取得
    _searchSettingFlagDbExperience = searchConditions.getSearchSettingDbExperienceFlag!;
    //DB経験(大項目のチェック状態)の値を取得
    _dbExperienceSearchChecked = searchConditions.getDbExperienceSearchChecked!;
    //DB経験(小項目のチェック状態)の値を取得
    _dbExperienceSearchItemChecked = searchConditions.getDbExperienceSearchItemChecked!;

    //OS経験(フラグ)の値を取得
    _searchSettingFlagOsExperience = searchConditions.getSearchSettingOsExperienceFlag!;
    //OS経験(大項目のチェック状態)の値を取得
    _osExperienceSearchChecked = searchConditions.getOsExperienceSearchChecked!;
    //OS経験(小項目のチェック状態)の値を取得
    _osExperienceSearchItemChecked = searchConditions.getOsExperienceSearchItemChecked!;

    //クラウド経験(フラグ)の値を取得
    _searchSettingFlagCloudTechnology = searchConditions.getSearchSettingCloudTechnologyFlag!;
    //クラウド経験(大項目のチェック状態)の値を取得
    _cloudTechnologySearchChecked = searchConditions.getCloudTechnologySearchChecked!;
    //クラウド経験(小項目のチェック状態)の値を取得
    _cloudTechnologySearchItemChecked = searchConditions.getCloudTechnologySearchItemChecked!;

    //ツール経験(フラグ)の値を取得
    _searchSettingFlagTool = searchConditions.getSearchSettingToolFlag!;
    //ツール経験(大項目のチェック状態)の値を取得
    _toolSearchChecked = searchConditions.getToolSearchChecked!;
    //ツール経験(小項目のチェック状態)の値を取得
    _toolSearchItemChecked = searchConditions.getToolSearchItemChecked!;

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
              initiallyExpanded: _ageChecked == 0 ? false : true, //初期値０以外ならtrueで自動で開く
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
                      if(_ageChecked != 0){
                        ref.read(searchConditionsControllerProvider.notifier).setSearchSettingFlag(true); //検索設定フラグを更新
                      }
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
              initiallyExpanded: _searchSettingFlagTeamRoles, //trueだと自動で開く
              childrenPadding: EdgeInsets.only(left: 16.0, bottom: 16.0),
              children: _teamRoles.map((teamRoles) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CheckboxListTile(
                      title: Text(teamRoles),
                      //1 value: _teamRolesChecked[teamRoles] != null,
                      value: _teamRolesSearchChecked[_teamRoles.indexOf(teamRoles)],
                      onChanged: (value) {
                        setState(() {
                          //2
                          _teamRolesSearchChecked[_teamRoles.indexOf(teamRoles)] = value!;
                          ref.read(searchConditionsControllerProvider.notifier).setTeamRolesSearchChecked(_teamRolesSearchChecked);
                          if(value == false){
                            //大項目がチェックがFALSEになったら小項目もFALSEにする
                            _teamRolesSearchItemChecked[_teamRoles.indexOf(teamRoles)] = [false,false,false,false,false,false];
                            ref.read(searchConditionsControllerProvider.notifier).setTeamRolesSearchItemChecked(_teamRolesSearchItemChecked);
                          }
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_teamRolesSearchChecked[_teamRoles.indexOf(teamRoles)] == true)
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Wrap(
                          spacing: 8.0,
                          children: _yearsCategories.map((yearsCategory) {
                            return CheckboxListTile(
                              title: Text(yearsCategory),
                              value: _teamRolesSearchItemChecked[_teamRoles.indexOf(teamRoles)][_yearsCategories.indexOf(yearsCategory)],
                              onChanged: (value) {
                                setState(() {
                                  _teamRolesSearchItemChecked[_teamRoles.indexOf(teamRoles)][_yearsCategories.indexOf(yearsCategory)] = value!;
                                  ref.read(searchConditionsControllerProvider.notifier).setTeamRolesSearchItemChecked(_teamRolesSearchItemChecked);
                                  ref.read(searchConditionsControllerProvider.notifier).setSearchSettingTeamRolesFlag(true);
                                  ref.read(searchConditionsControllerProvider.notifier).setSearchSettingFlag(true);
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
              initiallyExpanded: _searchSettingFlagProcess, //trueだと自動で開く
              children: _processes.map((process) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        title: Text(process),
                        value: _processSearchChecked[_processes.indexOf(process)],
                        onChanged: (value) {
                          setState(() {
                            _processSearchChecked[_processes.indexOf(process)] = value!;
                            ref.read(searchConditionsControllerProvider.notifier).setProcessSearchChecked(_processSearchChecked);
                            if(value == false){
                              //大項目がチェックがFALSEになったら小項目もFALSEにする
                              _processSearchItemChecked[_processes.indexOf(process)] = [false,false,false,false];
                              ref.read(searchConditionsControllerProvider.notifier).setProcessSearchItemChecked(_processSearchItemChecked);
                            }else{
                              ref.read(searchConditionsControllerProvider.notifier).setSearchSettingProcessFlag(true);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_processSearchChecked[_processes.indexOf(process)] == true)
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
                                    setState(() {
                                      _processSearchItemChecked[_processes.indexOf(process)][_experienceCategories.indexOf(experienceCategory)] = value!;
                                      ref.read(searchConditionsControllerProvider.notifier).setProcessSearchItemChecked(_processSearchItemChecked);
                                      ref.read(searchConditionsControllerProvider.notifier).setSearchSettingProcessFlag(true);
                                      ref.read(searchConditionsControllerProvider.notifier).setSearchSettingFlag(true);
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
              initiallyExpanded: _searchSettingFlagCodeLanguages, //trueだと自動で開く
              childrenPadding: EdgeInsets.only(left: 16.0, bottom: 16.0),
              children: _codeLanguages.map((codeLanguages) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        title: Text(codeLanguages),
                        value: _codeLanguagesSearchChecked[_codeLanguages.indexOf(codeLanguages)],
                        onChanged: (value) {
                          setState(() {
                            _codeLanguagesSearchChecked[_codeLanguages.indexOf(codeLanguages)] = value!;
                            ref.read(searchConditionsControllerProvider.notifier).setCodeLanguagesSearchChecked(_codeLanguagesSearchChecked);
                            if(value == false){
                              //大項目がチェックがFALSEになったら小項目もFALSEにする
                              _codeLanguagesSearchItemChecked[_codeLanguages.indexOf(codeLanguages)] = [false,false,false,false,false,false];
                              ref.read(searchConditionsControllerProvider.notifier).setCodeLanguagesSearchItemChecked(_codeLanguagesSearchItemChecked);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                       if (_codeLanguagesSearchChecked[_codeLanguages.indexOf(codeLanguages)] == true)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Wrap(
                            spacing: 8.0,
                            children: _yearsCategories.map((yearsCategory) {
                              return CheckboxListTile(
                                title: Text(yearsCategory),
                                value: _codeLanguagesSearchItemChecked[_codeLanguages.indexOf(codeLanguages)][_yearsCategories.indexOf(yearsCategory)],
                                onChanged: (value) {
                                  setState(() {

                                    _codeLanguagesSearchItemChecked[_codeLanguages.indexOf(codeLanguages)][_yearsCategories.indexOf(yearsCategory)] = value!;
                                    // ここでフラグを更新すると、次回表示時や再ビルド時に反映されます
                                    if (value == true) {
                                      _searchSettingFlagCodeLanguages = true;
                                    }
                                    _codeLanguagesSearchItemChecked[_codeLanguages.indexOf(codeLanguages)][_yearsCategories.indexOf(yearsCategory)] = value!;
                                    ref.read(searchConditionsControllerProvider.notifier).setCodeLanguagesSearchItemChecked(_codeLanguagesSearchItemChecked);
                                    ref.read(searchConditionsControllerProvider.notifier).setSearchSettingCodeLanguagesFlag(true);
                                    ref.read(searchConditionsControllerProvider.notifier).setSearchSettingFlag(true);
                                  });
                                },
                                controlAffinity: ListTileControlAffinity.leading,
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
                  Icon(Icons.storage),
                  SizedBox(width: 8),
                  Text('DB言語'),
                ],
              ),
              initiallyExpanded: _searchSettingFlagDbExperience, //trueだと自動で開く
              childrenPadding: EdgeInsets.only(left: 16.0, bottom: 16.0),
              children: _dbExperience.map((dbExperience) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        title: Text(dbExperience),
                        value: _dbExperienceSearchChecked[_dbExperience.indexOf(dbExperience)],
                        onChanged: (value) {
                          setState(() {
                            _dbExperienceSearchChecked[_dbExperience.indexOf(dbExperience)] = value!;
                            ref.read(searchConditionsControllerProvider.notifier).setDbExperienceSearchChecked(_dbExperienceSearchChecked);
                            if(value == false){
                              //大項目がチェックがFALSEになったら小項目もFALSEにする
                              _dbExperienceSearchItemChecked[_dbExperience.indexOf(dbExperience)] = [false,false,false,false,false,false];
                              ref.read(searchConditionsControllerProvider.notifier).setDbExperienceSearchItemChecked(_dbExperienceSearchItemChecked);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                       if (_dbExperienceSearchChecked[_dbExperience.indexOf(dbExperience)] == true)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Wrap(
                            spacing: 8.0,
                            children: _yearsCategories.map((yearsCategory) {
                              return CheckboxListTile(
                                title: Text(yearsCategory),
                                value: _dbExperienceSearchItemChecked[_dbExperience.indexOf(dbExperience)][_yearsCategories.indexOf(yearsCategory)],
                                onChanged: (value) {
                                  setState(() {
                                    _dbExperienceSearchItemChecked[_dbExperience.indexOf(dbExperience)][_yearsCategories.indexOf(yearsCategory)] = value!;
                                    ref.read(searchConditionsControllerProvider.notifier).setDbExperienceSearchItemChecked(_dbExperienceSearchItemChecked);
                                    ref.read(searchConditionsControllerProvider.notifier).setSearchSettingDbExperienceFlag(true);
                                    ref.read(searchConditionsControllerProvider.notifier).setSearchSettingFlag(true);
                                  });
                                },
                                controlAffinity: ListTileControlAffinity.leading,
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
                  Icon(Icons.memory), // Icons.code アイコンを使用
                  SizedBox(width: 8),
                  Text('OS言語'),
                ],
              ),
              initiallyExpanded: _searchSettingFlagOsExperience, //trueだと自動で開く
              childrenPadding: EdgeInsets.only(left: 16.0, bottom: 16.0),
              children: _osExperience.map((osExperience) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        title: Text(osExperience),
                        // value: _osExperienceChecked[osExperience] != null,
                        value: _osExperienceSearchChecked[_osExperience.indexOf(osExperience)],
                        onChanged: (value) {
                          setState(() {
                            _osExperienceSearchChecked[_osExperience.indexOf(osExperience)] = value!;
                            ref.read(searchConditionsControllerProvider.notifier).setOsExperienceSearchChecked(_osExperienceSearchChecked);
                            if(value == false){
                              //大項目がチェックがFALSEになったら小項目もFALSEにする
                              _osExperienceSearchItemChecked[_osExperience.indexOf(osExperience)] = [false,false,false,false,false,false];
                              ref.read(searchConditionsControllerProvider.notifier).setOsExperienceSearchItemChecked(_osExperienceSearchItemChecked);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_osExperienceSearchChecked[_osExperience.indexOf(osExperience)] == true)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Wrap(
                            spacing: 8.0,
                            children: _yearsCategories.map((yearsCategory) {
                              return CheckboxListTile(
                                title: Text(yearsCategory),
                                value: _osExperienceSearchItemChecked[_osExperience.indexOf(osExperience)][_yearsCategories.indexOf(yearsCategory)],
                                onChanged: (value) {
                                  setState(() {
                                    _osExperienceSearchItemChecked[_osExperience.indexOf(osExperience)][_yearsCategories.indexOf(yearsCategory)] = value!;
                                    ref.read(searchConditionsControllerProvider.notifier).setOsExperienceSearchItemChecked(_osExperienceSearchItemChecked);
                                    ref.read(searchConditionsControllerProvider.notifier).setSearchSettingOsExperienceFlag(true);
                                    ref.read(searchConditionsControllerProvider.notifier).setSearchSettingFlag(true);
                                  });
                                },
                                controlAffinity: ListTileControlAffinity.leading,
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
                  Icon(Icons.cloud), // Icons.code アイコンを使用
                  SizedBox(width: 8),
                  Text('クラウド技術'),
                ],
              ),
              initiallyExpanded: _searchSettingFlagCloudTechnology, //trueだと自動で開く
              childrenPadding: EdgeInsets.only(left: 16.0, bottom: 16.0),
              children: _cloudTech.map((cloudTech) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        title: Text(cloudTech),
                        value: _cloudTechnologySearchChecked[_cloudTech.indexOf(cloudTech)],
                        onChanged: (value) {
                          setState(() {
                            _cloudTechnologySearchChecked[_cloudTech.indexOf(cloudTech)] = value!;
                            ref.read(searchConditionsControllerProvider.notifier).setCloudTechnologySearchChecked(_cloudTechnologySearchChecked);
                            if(value == false){
                              //大項目がチェックがFALSEになったら小項目もFALSEにする
                              _cloudTechnologySearchItemChecked[_cloudTech.indexOf(cloudTech)] = [false,false,false,false,false,false];
                              ref.read(searchConditionsControllerProvider.notifier).setCloudTechnologySearchItemChecked(_cloudTechnologySearchItemChecked);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_cloudTechnologySearchChecked[_cloudTech.indexOf(cloudTech)] == true)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Wrap(
                            spacing: 8.0,
                            children: _yearsCategories.map((yearsCategory) {
                              return CheckboxListTile(
                                title: Text(yearsCategory),
                                value: _cloudTechnologySearchItemChecked[_cloudTech.indexOf(cloudTech)][_yearsCategories.indexOf(yearsCategory)],
                                onChanged: (value) {
                                  setState(() {
                                    _cloudTechnologySearchItemChecked[_cloudTech.indexOf(cloudTech)][_yearsCategories.indexOf(yearsCategory)] = value!;
                                    ref.read(searchConditionsControllerProvider.notifier).setCloudTechnologySearchItemChecked(_cloudTechnologySearchItemChecked);
                                    ref.read(searchConditionsControllerProvider.notifier).setSearchSettingCloudTechnologyFlag(true);
                                    ref.read(searchConditionsControllerProvider.notifier).setSearchSettingFlag(true);
                                  });
                                },
                                controlAffinity: ListTileControlAffinity.leading,
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
                  Icon(Icons.build), // Icons.code アイコンを使用
                  SizedBox(width: 8),
                  Text('ツール'),
                ],
              ),
              initiallyExpanded: _searchSettingFlagTool, //trueだと自動で開く
              childrenPadding: EdgeInsets.only(left: 16.0, bottom: 16.0),
              children: _tool.map((tool) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        title: Text(tool),
                        value: _toolSearchChecked[_tool.indexOf(tool)],
                        onChanged: (value) {
                          setState(() {
                            _toolSearchChecked[_tool.indexOf(tool)] = value!;
                            ref.read(searchConditionsControllerProvider.notifier).setToolSearchChecked(_toolSearchChecked);
                            if(value == false){
                              //大項目がチェックがFALSEになったら小項目もFALSEにする
                              _toolSearchItemChecked[_tool.indexOf(tool)] = [false,false,false,false,false,false];
                              ref.read(searchConditionsControllerProvider.notifier).setToolSearchItemChecked(_toolSearchItemChecked);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_toolSearchChecked[_tool.indexOf(tool)] == true)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0),
                          child: Wrap(
                            spacing: 8.0,
                            children: _yearsCategories.map((yearsCategory) {
                              return CheckboxListTile(
                                title: Text(yearsCategory),
                                value: _toolSearchItemChecked[_tool.indexOf(tool)][_yearsCategories.indexOf(yearsCategory)],
                                onChanged: (value) {
                                  setState(() {
                                    _toolSearchItemChecked[_tool.indexOf(tool)][_yearsCategories.indexOf(yearsCategory)] = value!;
                                    ref.read(searchConditionsControllerProvider.notifier).setToolSearchItemChecked(_toolSearchItemChecked);
                                    ref.read(searchConditionsControllerProvider.notifier).setSearchSettingToolFlag(true);
                                    ref.read(searchConditionsControllerProvider.notifier).setSearchSettingFlag(true);
                                  });
                                  },
                                  controlAffinity: ListTileControlAffinity.leading,
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



