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

  //工程取得リスト１(大項目のチェック状態)の初期化
  final List<bool> _searchItemProcessInit = [false, false, false, false, false, false, false];
  //工程取得リスト(子項目のチェック状態)などの初期化
  final List<List<bool>> _search4ItemCheckedInit = [
    [false, false, false, false], //要件定義
    [false, false, false, false], //基本設計
    [false, false, false, false], //詳細設計
    [false, false, false, false], //コーディング
    [false, false, false, false], //単体
    [false, false, false, false], //結合
    [false, false, false, false]
  ]; //保守

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
      [false, false, false, false]
    ], //工程取得リスト
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

  /// 検索設定フラグ 設定
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
  ///processClearメソッド
  void processClear() {
    setSearchSettingProcessFlag(_searchSettingFlagProcessInit);
    setProcessSearchChecked(_searchItemProcessInit);
  }
  ///clearメソッド
  void clear() {
    setSearchSettingFlag(_searchSettingFlagInit);
    setAgeDropdownSelectedValue(_ageDropdownSelectedValueInit);
    setSearchSettingProcessFlag(_searchSettingFlagProcessInit);
    setProcessSearchChecked(_searchItemProcessInit);
    setProcessSearchItemChecked(_search4ItemCheckedInit);
  }

}
