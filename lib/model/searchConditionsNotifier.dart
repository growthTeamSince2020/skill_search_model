import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:skill_search_model/model/searchConditionsDto.dart';

///検索条件のStateNotifier
class SearchConditionsNotifier extends StateNotifier<SearchConditionsDto> {
  final logger = Logger(); //ロガーの宣言
  //工程取得リストなどの初期化
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
    [
      [false, false, false, false], //要件定義
      [false, false, false, false], //基本設計
      [false, false, false, false], //詳細設計
      [false, false, false, false], //コーディング
      [false, false, false, false], //単体
      [false, false, false, false], //結合
      [false, false, false, false]
    ], //工程取得リスト
  )); //保守

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

  ///工程経験 設定
  void setProcessSearchItemChecked(List<List<bool>> newValue) {
    logger.i(
        'processSearchItemChecked が更新されました: ${state.getProcessSearchItemChecked}');
    state = state.copyWith(processSearchItemChecked: newValue);
  }

  ///clearメソッド
  void clear() {
    setSearchSettingFlag(false);
    setAgeDropdownSelectedValue(0);
    setProcessSearchItemChecked(_search4ItemCheckedInit);
  }
}
