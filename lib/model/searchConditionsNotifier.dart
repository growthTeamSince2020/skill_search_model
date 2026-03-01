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
  //工程取得リストの検索フラグの初期化
  bool _searchSettingFlagProcessInit = false;
  //チーム役割リストの検索フラグの初期化
  bool _searchSettingTeamRolesFlagInit = false;

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
  //チーム役割リスト(子項目のチェック状態)などの初期化
  final List<List<bool>> _searchItemTeamRolesCheckedInit = [
    [false, false, false, false, false], //1年未満
    [false, false, false, false, false], //1年-2年未満
    [false, false, false, false, false], //2年-3年未満
    [false, false, false, false, false], //3年-5年未満
    [false, false, false, false, false]  //10年未満
  ];

  SearchConditionsNotifier()
      : super(SearchConditionsDto(
    false, //検索設定フラグ
    0, //年齢
    false, //工程経験(フラグ状態)
    [false, false, false, false, false, false, false],
    [
      [false, false, false, false], //要件定義
      [false, false, false, false], //基本設計
      [false, false, false, false], //詳細設計
      [false, false, false, false], //コーディング
      [false, false, false, false], //単体
      [false, false, false, false], //結合
      [false, false, false, false]  //保守
    ], //工程取得リスト
    false, //チーム経験(フラグ状態)
    [false, false, false, false, false,],//チーム経験(大項目)
    [
      [false, false, false, false, false, false], //1年未満
      [false, false, false, false, false, false], //1年-2年未満
      [false, false, false, false, false, false], //2年-3年未満
      [false, false, false, false, false, false], //3年-5年未満
      [false, false, false, false, false, false]  //10年未満
    ],
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
  /// チーム経験 設定
  void setTeamRolesSearchChecked(List<bool> newValue) {
    logger.i(
        'teamRolesSearchChecked が更新されました: ${state.getTeamRolesSearchChecked}');
    state = state.copyWith(teamRolesSearchChecked: newValue);
  }
  /// チーム経験 設定
  void setTeamRolesSearchItemChecked(List<List<bool>> newValue) {
    logger.i(
        'teamRolesSearchItemChecked が更新されました: ${state.getTeamRolesSearchItemChecked}');
    state = state.copyWith(teamRolesSearchItemChecked: newValue);
  }

  ///processClearメソッド
  void processClear() {
    setSearchSettingProcessFlag(_searchSettingFlagProcessInit);
    setProcessSearchChecked(_searchItemProcessInit);
  }

  ///teamRolesClearメソッド
  void teamRolesClear() {
    setSearchSettingTeamRolesFlag(_searchSettingTeamRolesFlagInit);
    setTeamRolesSearchChecked(_searchItemTeamRolesInit);
  }

  ///clearメソッド
  void clear() {
    setSearchSettingFlag(_searchSettingFlagInit);
    setAgeDropdownSelectedValue(_ageDropdownSelectedValueInit);
    setSearchSettingProcessFlag(_searchSettingFlagProcessInit);
    setProcessSearchChecked(_searchItemProcessInit);
    setProcessSearchItemChecked(_searchItemProcessCheckedInit);
    setSearchSettingTeamRolesFlag(_searchSettingTeamRolesFlagInit);
    setTeamRolesSearchChecked(_searchItemTeamRolesInit);
    setTeamRolesSearchItemChecked(_searchItemTeamRolesCheckedInit);
  }

}
