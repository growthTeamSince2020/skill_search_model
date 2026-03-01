import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:logger/logger.dart';
import 'package:skill_search_model/model/searchConditionsNotifier.dart';


@immutable
class SearchConditionsDto {
  final logger = Logger(); //ロガーの宣言
  /// 検索設定フラグ
  final bool _searchSettingFlag;

  ///年齢選択条件値
  final int _ageDropdownSelectedValue;

  ///工程経験(フラグ状態)
  final bool _searchSettingProcessFlag;

  /// 工程取得リスト(大項目のチェック状態)
  final List<bool> _processSearchChecked;

  /// 工程取得リスト(子項目のチェック状態)
  final List<List<bool>> _processSearchItemChecked;

  /// チーム経験(フラグ状態)
  final bool _searchSettingTeamRolesFlag;

  /// チーム取得リスト(大項目のチェック状態)
  final List<bool> _teamRolesSearchChecked;

  /// チーム取得リスト(子項目のチェック状態)
  final List<List<bool>> _teamRolesSearchItemChecked;


  /// 検索設定フラグ 取得
  get getSearchSettingFlag => _searchSettingFlag;

  /// 年齢 取得
  get getAgeDropdownSelectedValue => _ageDropdownSelectedValue;

  ///工程経験(フラグ状態) 取得
  get getSearchSettingProcessFlag => _searchSettingProcessFlag;

  ///工程経験(大項目のチェック状態) 取得
  List<bool> get getProcessSearchChecked =>
      _processSearchChecked;

  ///工程経験(子項目のチェック状態) 取得
  List<List<bool>> get getProcessSearchItemChecked =>
      _processSearchItemChecked;

  ///チーム役割経験(フラグ状態) 取得
  get getSearchSettingTeamRolesFlag => _searchSettingTeamRolesFlag;

  ///チーム役割経験(大項目のチェック状態) 取得
  List<bool> get getTeamRolesSearchChecked =>
      _teamRolesSearchChecked;

  ///チーム役割経験(子項目のチェック状態) 取得
  List<List<bool>> get getTeamRolesSearchItemChecked =>
      _teamRolesSearchItemChecked;


  ///コンストラクタ
  SearchConditionsDto(this._searchSettingFlag, //検索設定フラグ
      this._ageDropdownSelectedValue, //年齢
      this._searchSettingProcessFlag, this._processSearchChecked, this._processSearchItemChecked, //工程関連
      this._searchSettingTeamRolesFlag, this._teamRolesSearchChecked, this._teamRolesSearchItemChecked //チーム役割関連
  );

  ///コピーコンストラクタ
  SearchConditionsDto copyWith(
      { bool? searchSettingFlag,
        int? ageDropdownSelectedValue,
        bool? searchSettingProcessFlag, //工程関連
        List<bool>? processSearchChecked,
        List<List<bool>>? processSearchItemChecked,
        bool? searchSettingTeamRolesFlag, //チーム役割関連
        List<bool>? teamRolesSearchChecked,
        List<List<bool>>? teamRolesSearchItemChecked,
      }) {
    return SearchConditionsDto(
      searchSettingFlag ?? _searchSettingFlag,
      ageDropdownSelectedValue ?? _ageDropdownSelectedValue,
      searchSettingProcessFlag ?? _searchSettingProcessFlag, //工程関連
      processSearchChecked ?? _processSearchChecked,
      processSearchItemChecked ??  _processSearchItemChecked,
      searchSettingTeamRolesFlag ?? _searchSettingTeamRolesFlag, //チーム役割関連
      teamRolesSearchChecked ?? _teamRolesSearchChecked,
      teamRolesSearchItemChecked ?? _teamRolesSearchItemChecked,
    );
  }
}
///検索条件のProvider
final searchConditionsControllerProvider =
    StateNotifierProvider<SearchConditionsNotifier, SearchConditionsDto>(
        (ref) {
  return SearchConditionsNotifier();
});
