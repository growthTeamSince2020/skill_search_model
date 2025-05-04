import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

@immutable
class SearchConditionsDto {
  final logger = Logger(); //ロガーの宣言
  /// 検索設定フラグ
  final bool? _searchSettingFlag;

  ///年齢選択条件値
  final int? _ageDropdownSelectedValue;

  /// 工程取得リスト
  final List<List<bool>>? _processSearchItemChecked;

  /// 検索設定フラグ 取得
  bool? get getSearchSettingFlag => _searchSettingFlag;

  /// 年齢 取得
  int? get getAgeDropdownSelectedValue => _ageDropdownSelectedValue;

  ///工程経験 取得
  List<List<bool>>? get getProcessSearchItemChecked =>
      _processSearchItemChecked;

  ///コンストラクタ
  SearchConditionsDto(this._searchSettingFlag, this._ageDropdownSelectedValue,
      this._processSearchItemChecked);

  ///コピーコンストラクタ
  SearchConditionsDto copyWith(
      {bool? searchSettingFlag,
      int? ageDropdownSelectedValue,
      List<List<bool>>? processSearchItemChecked}) {
    return SearchConditionsDto(
      searchSettingFlag ?? _searchSettingFlag,
      ageDropdownSelectedValue ?? _ageDropdownSelectedValue,
      processSearchItemChecked ?? _processSearchItemChecked,
    );
  }
}
///検索条件のProvider
final searchConditionsControllerProvider =
    StateNotifierProvider<SearchConditionsNotifier, SearchConditionsDto>(
        (ref) {
  return SearchConditionsNotifier();
});

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
    logger.i('searchSettingFlag が更新されました: ${state._searchSettingFlag}');
  }

  /// 年齢 設定
  void setAgeDropdownSelectedValue(int newValue) {
    state = state.copyWith(ageDropdownSelectedValue: newValue);
    logger.i(
        'ageDropdownSelectedValue が更新されました: ${state._ageDropdownSelectedValue}');
  }

  ///工程経験 設定
  void setProcessSearchItemChecked(List<List<bool>> newValue) {
    logger.i(
        'processSearchItemChecked が更新されました: ${state._processSearchItemChecked}');
    state = state.copyWith(processSearchItemChecked: newValue);
  }

  ///clearメソッド
  void clear() {
    setSearchSettingFlag(false);
    setAgeDropdownSelectedValue(0);
    setProcessSearchItemChecked(_search4ItemCheckedInit);
  }
}
