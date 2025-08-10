import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:skill_search_model/model/searchConditionsNotifier.dart';


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
      processSearchItemChecked ??  _processSearchItemChecked,
    );
  }
}
///検索条件のProvider
final searchConditionsControllerProvider =
    StateNotifierProvider<SearchConditionsNotifier, SearchConditionsDto>(
        (ref) {
  return SearchConditionsNotifier();
});
