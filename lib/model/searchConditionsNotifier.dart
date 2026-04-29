import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:logger/logger.dart';
import 'package:skill_search_model/model/searchConditionsDto.dart';

///検索条件のStateNotifier
class SearchConditionsNotifier extends StateNotifier<SearchConditionsDto> {
  final logger = Logger(); //ロガーの宣言

  //検索設定フラグの初期化
  bool _searchSettingFlagInit = false;
  //年齢の初期化
  int _ageDropdownSelectedValueInit = 0;
  //リストの検索フラグの初期化
  bool _searchSettingInit = false;



  //工程取得リスト(大項目のチェック状態)の初期化
  final List<bool> _searchItemProcessInit = [false, false, false, false, false, false, false];
  //工程取得リスト(子項目のチェック状態)などの初期化
  final List<List<bool>> _searchItemProcessCheckedInit = [
    [false, false, false, false], //要件定義
    [false, false, false, false], //基本設計
    [false, false, false, false], //詳細設計
    [false, false, false, false], //コーディング
    [false, false, false, false], //単体
    [false, false, false, false], //結合
    [false, false, false, false]
  ]; //保守

  //チーム役割リスト(大項目のチェック状態)の初期化
  final List<bool> _searchItemTeamRolesInit = [false, false, false, false, false];
  //チーム役割リスト(子項目のチェック状態)の初期化
  final List<List<bool>> _searchItemTeamRolesCheckedInit = [
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false]
  ];
  //経験言語リスト(大項目のチェック状態)の初期化
  final List<bool> _searchItemCodeLanguagesInit = [false, false, false, false, false, false, false, false, false, false, false];
  //経験言語リスト(子項目のチェック状態)の初期化
  final List<List<bool>> _searchItemCodeLanguagesCheckedInit = [
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false]
  ];
  //DB経験リスト(大項目のチェック状態)の初期化
  final List<bool> _searchItemDbExperienceInit = [false, false, false, false, false];
  //DB経験リスト(子項目のチェック状態)の初期化
  final List<List<bool>> _searchItemDbExperienceCheckedInit = [
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false]
  ];
  //OS経験リスト(大項目のチェック状態)の初期化
  final List<bool> _searchItemOsExperienceInit = [false, false, false, false, false, false];
  //OS経験リスト(子項目のチェック状態)の初期化
  final List<List<bool>> _searchItemOsExperienceCheckedInit = [
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false]
  ];
  //クラウド経験リスト(大項目のチェック状態)の初期化
  final List<bool> _searchItemCloudTechnologyInit = [false, false, false, false];
  //クラウド経験リスト(子項目のチェック状態)の初期化
  final List<List<bool>> _searchItemCloudTechnologyCheckedInit = [
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false]
  ];
  //ツール経験リスト(大項目のチェック状態)の初期化
  final List<bool> _searchItemToolInit = [false, false, false, false, false, false, false, false, false, false, false];
  //ツール経験リスト(子項目のチェック状態)の初期化
  final List<List<bool>> _searchItemToolCheckedInit = [
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false],
    [false, false, false, false, false, false]
  ];


  SearchConditionsNotifier()
      : super(SearchConditionsDto(
    false, //検索設定フラグ
    0, //年齢
    false, //工程経験(フラグ状態)
    [false, false, false, false, false, false, false],
    [ //大項目分　experience_category
      [false, false, false, false], //要件定義
      [false, false, false, false], //基本設計
      [false, false, false, false], //詳細設計
      [false, false, false, false], //コーディング
      [false, false, false, false], //単体
      [false, false, false, false], //結合
      [false, false, false, false]  //保守
    ], //工程取得リスト
    false, //チーム経験(フラグ状態)
    [false, false, false, false, false],//チーム経験(大項目)
    [ //大項目分　years_category
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false]
    ], //チーム経験(子項目)
    false, //言語経験(フラグ状態)
    [false, false, false, false, false, false, false, false, false, false, false],//言語経験(大項目)
    [ //大項目分　years_category
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false]
    ], //言語経験(子項目)
    false, //DB経験(フラグ状態)
    [false, false, false, false, false],//DB経験(大項目)
    [ //大項目分　years_category
        [false, false, false, false, false, false],
        [false, false, false, false, false, false],
        [false, false, false, false, false, false],
        [false, false, false, false, false, false],
        [false, false, false, false, false, false]
    ],     //DB経験(子項目)
    false, //OS経験(フラグ状態)
    [false, false, false, false, false, false],//OS経験(大項目)
      [ //大項目分　years_category
        [false, false, false, false, false, false],
        [false, false, false, false, false, false],
        [false, false, false, false, false, false],
        [false, false, false, false, false, false],
        [false, false, false, false, false, false],
        [false, false, false, false, false, false]
      ],     //OS経験(子項目)
    false, //クラウド経験(フラグ状態)
    [false, false, false, false],    //クラウド経験(大項目)
    [ //大項目分　years_category
        [false, false, false, false, false, false],
        [false, false, false, false, false, false],
        [false, false, false, false, false, false],
        [false, false, false, false, false, false]
    ], //クラウド経験(子項目)
    false, //ツール経験(フラグ状態)
    [false, false, false, false, false, false, false, false, false, false, false],//ツール経験(大項目)
    [ //大項目分　years_category
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false],
      [false, false, false, false, false, false]
    ] //ツール経験(子項目)
  ));

  /// 検索設定フラグ 設定
  void setSearchSettingFlag(bool newValue) {
    state = state.copyWith(searchSettingFlag: newValue);
    logger.i('searchSettingFlag が更新されました: ${state.getSearchSettingFlag}');
  }

  /// 年齢 設定
  void setAgeDropdownSelectedValue(int newValue) {
    state = state.copyWith(ageDropdownSelectedValue: newValue);
    logger.i(
        'ageDropdownSelectedValue が更新されました: ${state.getAgeDropdownSelectedValue}');
  }

  /// 工程検索設定フラグ 設定
  void setSearchSettingProcessFlag(bool newValue) {
    state = state.copyWith(searchSettingProcessFlag: newValue);
    logger.i('searchSettingProcessFlag が更新されました: ${state.getSearchSettingProcessFlag}');
  }

  ///工程経験 設定
  void setProcessSearchChecked(List<bool> newValue) {
    logger.i(
        'processSearchChecked が更新されました: ${state.getProcessSearchChecked}');
    state = state.copyWith(processSearchChecked: newValue);
  }

  ///工程経験 設定
  void setProcessSearchItemChecked(List<List<bool>> newValue) {
    logger.i(
        'processSearchItemChecked が更新されました: ${state.getProcessSearchItemChecked}');
    state = state.copyWith(processSearchItemChecked: newValue);
  }

  /// チーム経験設定検索設定フラグ 設定
  void setSearchSettingTeamRolesFlag(bool newValue) {
    logger.i('searchSettingTeamRolesFlag が更新されました: ${state.getSearchSettingTeamRolesFlag}');
    state = state.copyWith(searchSettingTeamRolesFlag: newValue);
  }
  /// チーム経験 設定(大項目)
  void setTeamRolesSearchChecked(List<bool> newValue) {
    logger.i(
        'teamRolesSearchChecked が更新されました: ${state.getTeamRolesSearchChecked}');
    state = state.copyWith(teamRolesSearchChecked: newValue);
  }
  /// チーム経験 設定(小項目)
  void setTeamRolesSearchItemChecked(List<List<bool>> newValue) {
    logger.i(
        'teamRolesSearchItemChecked が更新されました: ${state.getTeamRolesSearchItemChecked}');
    state = state.copyWith(teamRolesSearchItemChecked: newValue);
  }

  /// 言語経験設定検索設定フラグ 設定
  void setSearchSettingCodeLanguagesFlag(bool newValue) {
    logger.i('searchSettingCodeLanguagesFlag が更新されました: ${state.getSearchSettingCodeLanguagesFlag}');
    state = state.copyWith(searchSettingCodeLanguagesFlag: newValue);
  }
  /// 言語経験 設定(大項目)
  void setCodeLanguagesSearchChecked(List<bool> newValue) {
    logger.i(
        'codeLanguagesSearchChecked が更新されました: ${state.getCodeLanguagesSearchChecked}');
    state = state.copyWith(codeLanguagesSearchChecked: newValue);
  }
  /// 言語経験 設定(小項目)
  void setCodeLanguagesSearchItemChecked(List<List<bool>> newValue) {
    logger.i(
        'codeLanguagesSearchItemChecked が更新されました: ${state
            .getCodeLanguagesSearchItemChecked}');
    state = state.copyWith(codeLanguagesSearchItemChecked: newValue);
  }

  /// DB経験設定検索設定フラグ 設定
  void setSearchSettingDbExperienceFlag(bool newValue) {
    logger.i('searchSettingDbExperience が更新されました: ${state.getSearchSettingDbExperienceFlag}');
    state = state.copyWith(searchSettingDbExperienceFlag: newValue);
  }
  /// DB経験 設定(大項目)
  void setDbExperienceSearchChecked(List<bool> newValue) {
    logger.i(
        'dbExperienceSearchChecked が更新されました: ${state.getDbExperienceSearchChecked}');
    state = state.copyWith(dbExperienceSearchChecked: newValue);
  }
  /// DB経験 設定(小項目)
  void setDbExperienceSearchItemChecked(List<List<bool>> newValue) {
    logger.i(
        'dbExperienceSearchItemChecked が更新されました: ${state.getDbExperienceSearchItemChecked}');
    state = state.copyWith(dbExperienceSearchItemChecked: newValue);
  }

  /// OS経験設定検索設定フラグ 設定
  void setSearchSettingOsExperienceFlag(bool newValue) {
    logger.i('searchSettingOsExperienceFlag が更新されました: ${state.getSearchSettingOsExperienceFlag}');
    state = state.copyWith(searchSettingOsExperienceFlag: newValue);
  }
  /// OS経験 設定(大項目)
  void setOsExperienceSearchChecked(List<bool> newValue) {
    logger.i(
        'osExperienceSearchChecked が更新されました: ${state.getOsExperienceSearchChecked}');
    state = state.copyWith(osExperienceSearchChecked: newValue);
  }
  /// OS経験 設定(小項目)
  void setOsExperienceSearchItemChecked(List<List<bool>> newValue) {
    logger.i(
        'osExperienceSearchItemChecked が更新されました: ${state.getOsExperienceSearchItemChecked}');
    state = state.copyWith(osExperienceSearchItemChecked: newValue);
  }

  /// クラウド経験設定検索設定フラグ 設定
  void setSearchSettingCloudTechnologyFlag(bool newValue) {
    logger.i('searchSettingCloudTechnologyFlag が更新されました: ${state
        .getSearchSettingCloudTechnologyFlag}');
    state = state.copyWith(searchSettingCloudTechnologyFlag: newValue);
  }
  /// クラウド経験 設定(大項目)
  void setCloudTechnologySearchChecked(List<bool> newValue) {
    logger.i(
        'cloudTechnologySearchChecked が更新されました: ${state.getCloudTechnologySearchChecked}');
    state = state.copyWith(cloudTechnologySearchChecked: newValue);
  }
  /// クラウド経験 設定(小項目)
  void setCloudTechnologySearchItemChecked(List<List<bool>> newValue) {
    logger.i(
        'cloudTechnologySearchItemChecked が更新されました: ${state.getCloudTechnologySearchItemChecked}');
    state = state.copyWith(cloudTechnologySearchItemChecked: newValue);
  }

  /// ツール経験設定検索設定フラグ 設定
  void setSearchSettingToolFlag(bool newValue) {
    logger.i('searchSettingToolFlag が更新されました: ${state.getSearchSettingToolFlag}');
    state = state.copyWith(searchSettingToolFlag: newValue);
  }
  /// ツール経験 設定(大項目)
  void setToolSearchChecked(List<bool> newValue) {
    logger.i(
        'toolSearchChecked が更新されました: ${state.getToolSearchChecked}');
    state = state.copyWith(toolSearchChecked: newValue);
  }
  /// ツール経験 設定(小項目)
  void setToolSearchItemChecked(List<List<bool>> newValue) {
    logger.i(
        'toolSearchItemChecked が更新されました: ${state.getToolSearchItemChecked}');
    state = state.copyWith(toolSearchItemChecked: newValue);
  }

  ///processClearメソッド
  void processClear() {
    setSearchSettingProcessFlag(_searchSettingInit);
    setProcessSearchChecked(_searchItemProcessInit);
  }

  ///teamRolesClearメソッド
  void teamRolesClear() {
    setSearchSettingTeamRolesFlag(_searchSettingInit);
    setTeamRolesSearchChecked(_searchItemTeamRolesInit);
  }

  ///codeLanguagesClearメソッド
  void codeLanguagesClear() {
    setSearchSettingCodeLanguagesFlag(_searchSettingInit);
    setCodeLanguagesSearchChecked(_searchItemCodeLanguagesInit);
  }

  ///dbExperienceClearメソッド
  void dbExperienceClear() {
    setSearchSettingDbExperienceFlag(_searchSettingInit);
    setDbExperienceSearchChecked(_searchItemDbExperienceInit);
  }

  ///osExperienceClearメソッド
  void osExperienceClear() {
    setSearchSettingOsExperienceFlag(_searchSettingInit);
    setOsExperienceSearchChecked(_searchItemOsExperienceInit);
  }

  ///cloudTechnologyClearメソッド
  void cloudTechnologyClear() {
    setSearchSettingCloudTechnologyFlag(_searchSettingInit);
    setCloudTechnologySearchChecked(_searchItemCloudTechnologyInit);
  }

  ///toolClearメソッド
  void toolClear(){
    setSearchSettingToolFlag(_searchSettingInit);
    setToolSearchChecked(_searchItemToolInit);
  }

  ///clearメソッド
  void clear() {
    setSearchSettingFlag(_searchSettingFlagInit);
    setAgeDropdownSelectedValue(_ageDropdownSelectedValueInit);
    setSearchSettingProcessFlag(_searchSettingInit);
    setProcessSearchChecked(_searchItemProcessInit);
    setProcessSearchItemChecked(_searchItemProcessCheckedInit);
    setSearchSettingTeamRolesFlag(_searchSettingInit);
    setTeamRolesSearchChecked(_searchItemTeamRolesInit);
    setTeamRolesSearchItemChecked(_searchItemTeamRolesCheckedInit);
    setSearchSettingCodeLanguagesFlag(_searchSettingInit);
    setCodeLanguagesSearchChecked(_searchItemCodeLanguagesInit);
    setCodeLanguagesSearchItemChecked(_searchItemCodeLanguagesCheckedInit);
    setSearchSettingDbExperienceFlag(_searchSettingInit);
    setDbExperienceSearchChecked(_searchItemDbExperienceInit);
    setDbExperienceSearchItemChecked(_searchItemDbExperienceCheckedInit);
    setSearchSettingOsExperienceFlag(_searchSettingInit);
    setOsExperienceSearchChecked(_searchItemOsExperienceInit);
    setOsExperienceSearchItemChecked(_searchItemOsExperienceCheckedInit);
    setSearchSettingCloudTechnologyFlag(_searchSettingInit);
    setCloudTechnologySearchChecked(_searchItemCloudTechnologyInit);
    setCloudTechnologySearchItemChecked(_searchItemCloudTechnologyCheckedInit);
    setSearchSettingToolFlag(_searchSettingInit);
    setToolSearchChecked(_searchItemToolInit);
    setToolSearchItemChecked(_searchItemToolCheckedInit);
  }

}
