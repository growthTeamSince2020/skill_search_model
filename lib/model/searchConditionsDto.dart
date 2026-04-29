import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// 経験言語経験(フラグ状態)
  final bool _searchSettingCodeLanguagesFlag;

  /// 経験言語リスト(大項目のチェック状態)
  final List<bool> _codeLanguagesSearchChecked;

  /// 経験言語リスト(子項目のチェック状態)
  final List<List<bool>> _codeLanguagesSearchItemChecked;

  /// DB経験(フラグ状態)
  final bool _searchSettingDbExperienceFlag;

  /// DB取得リスト(大項目のチェック状態)
  final List<bool> _dbExperienceSearchChecked;

  /// DB取得リスト(子項目のチェック状態)
  final List<List<bool>> _dbExperienceSearchItemChecked;

  /// OS経験(フラグ状態)
  final bool _searchSettingOsExperienceFlag;

  /// OS取得リスト(大項目のチェック状態)
  final List<bool> _osExperienceSearchChecked;

  /// OS取得リスト(子項目のチェック状態)
  final List<List<bool>> _osExperienceSearchItemChecked;

  /// クラウド経験(フラグ状態)
  final bool _searchSettingCloudTechnologyFlag;

  /// クラウド取得リスト(大項目のチェック状態)
  final List<bool> _cloudTechnologySearchChecked;

  /// クラウド取得リスト(子項目のチェック状態)
  final List<List<bool>> _cloudTechnologySearchItemChecked;

  /// ツール経験(フラグ状態)
  final bool _searchSettingToolFlag;

  /// ツール取得リスト(大項目のチェック状態)
  final List<bool> _toolRolesSearchChecked;

  /// ツール取得リスト(子項目のチェック状態)
  final List<List<bool>> _tooleamRolesSearchItemChecked;


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

  ///経験言語経験(フラグ状態) 取得
  get getSearchSettingCodeLanguagesFlag => _searchSettingCodeLanguagesFlag;
  ///経験言語経験(大項目のチェック状態) 取得
  List<bool> get getCodeLanguagesSearchChecked =>
      _codeLanguagesSearchChecked;
  ///経験言語経験(子項目のチェック状態) 取得
  List<List<bool>> get getCodeLanguagesSearchItemChecked =>
      _codeLanguagesSearchItemChecked;

  ///DB経験(フラグ状態) 取得
  get getSearchSettingDbExperienceFlag => _searchSettingDbExperienceFlag;
  ///DB経験(大項目のチェック状態) 取得
  List<bool> get getDbExperienceSearchChecked =>
      _dbExperienceSearchChecked;
  ///DB経験(子項目のチェック状態) 取得
  List<List<bool>> get getDbExperienceSearchItemChecked =>
      _dbExperienceSearchItemChecked;

  ///OS経験(フラグ状態) 取得
  get getSearchSettingOsExperienceFlag => _searchSettingOsExperienceFlag;
  ///OS経験(大項目のチェック状態) 取得
  List<bool> get getOsExperienceSearchChecked =>
      _osExperienceSearchChecked;
  ///OS経験(子項目のチェック状態) 取得
  List<List<bool>> get getOsExperienceSearchItemChecked =>
      _osExperienceSearchItemChecked;

  ///クラウド経験(フラグ状態) 取得
  get getSearchSettingCloudTechnologyFlag => _searchSettingCloudTechnologyFlag;
  ///クラウド経験(大項目のチェック状態) 取得
  List<bool> get getCloudTechnologySearchChecked =>
      _cloudTechnologySearchChecked;
  ///クラウド経験(子項目のチェック状態) 取得
  List<List<bool>> get getCloudTechnologySearchItemChecked =>
      _cloudTechnologySearchItemChecked;

  ///チーム役割経験(フラグ状態) 取得
  get getSearchSettingToolFlag => _searchSettingToolFlag;
  ///チーム役割経験(大項目のチェック状態) 取得
  List<bool> get getToolSearchChecked =>
      _toolRolesSearchChecked;
  ///チーム役割経験(子項目のチェック状態) 取得
  List<List<bool>> get getToolSearchItemChecked =>
      _tooleamRolesSearchItemChecked;


  ///コンストラクタ
  SearchConditionsDto(this._searchSettingFlag, //検索設定フラグ
      this._ageDropdownSelectedValue, //年齢
      this._searchSettingProcessFlag, this._processSearchChecked, this._processSearchItemChecked, //工程関連
      this._searchSettingTeamRolesFlag, this._teamRolesSearchChecked, this._teamRolesSearchItemChecked, //チーム役割関連
      this._searchSettingCodeLanguagesFlag, this._codeLanguagesSearchChecked, this._codeLanguagesSearchItemChecked, //経験言語
      this._searchSettingDbExperienceFlag, this._dbExperienceSearchChecked, this._dbExperienceSearchItemChecked, //DB経験
      this._searchSettingOsExperienceFlag, this._osExperienceSearchChecked, this._osExperienceSearchItemChecked, //OS経験
      this._searchSettingCloudTechnologyFlag, this._cloudTechnologySearchChecked, this._cloudTechnologySearchItemChecked, //クラウド経験
      this._searchSettingToolFlag, this._toolRolesSearchChecked, this._tooleamRolesSearchItemChecked //ツール
  );

  ///コピーコンストラクタ
  SearchConditionsDto copyWith(
      { bool? searchSettingFlag,
        int? ageDropdownSelectedValue,
        bool? searchSettingProcessFlag, List<bool>? processSearchChecked, List<List<bool>>? processSearchItemChecked,  //工程関連
        bool? searchSettingTeamRolesFlag, List<bool>? teamRolesSearchChecked, List<List<bool>>? teamRolesSearchItemChecked,  //チーム役割関連
        bool? searchSettingCodeLanguagesFlag, List<bool>? codeLanguagesSearchChecked, List<List<bool>>? codeLanguagesSearchItemChecked,  // 経験言語
        bool? searchSettingDbExperienceFlag, List<bool>? dbExperienceSearchChecked, List<List<bool>>? dbExperienceSearchItemChecked,  // DB経験
        bool? searchSettingOsExperienceFlag, List<bool>? osExperienceSearchChecked, List<List<bool>>? osExperienceSearchItemChecked,  // OS経験
        bool? searchSettingCloudTechnologyFlag, List<bool>? cloudTechnologySearchChecked, List<List<bool>>? cloudTechnologySearchItemChecked, // クラウド経験
        bool? searchSettingToolFlag, List<bool>? toolSearchChecked, List<List<bool>>? toolSearchItemChecked // ツール
      }) {
    return SearchConditionsDto(
      searchSettingFlag ?? _searchSettingFlag,
      ageDropdownSelectedValue ?? _ageDropdownSelectedValue,
      searchSettingProcessFlag ?? _searchSettingProcessFlag, processSearchChecked ?? _processSearchChecked, processSearchItemChecked ??  _processSearchItemChecked,  //工程関連
      searchSettingTeamRolesFlag ?? _searchSettingTeamRolesFlag, teamRolesSearchChecked ?? _teamRolesSearchChecked, teamRolesSearchItemChecked ?? _teamRolesSearchItemChecked, //チーム役割関連
      searchSettingCodeLanguagesFlag ?? _searchSettingCodeLanguagesFlag, codeLanguagesSearchChecked ?? _codeLanguagesSearchChecked, codeLanguagesSearchItemChecked ?? _codeLanguagesSearchItemChecked,// 経験言語
      searchSettingDbExperienceFlag ?? _searchSettingDbExperienceFlag, dbExperienceSearchChecked ?? _dbExperienceSearchChecked, dbExperienceSearchItemChecked ?? _dbExperienceSearchItemChecked,// DB経験
      searchSettingOsExperienceFlag ?? _searchSettingOsExperienceFlag, osExperienceSearchChecked ?? _osExperienceSearchChecked, osExperienceSearchItemChecked ?? _osExperienceSearchItemChecked,// OS経験
      searchSettingCloudTechnologyFlag ?? _searchSettingCloudTechnologyFlag, cloudTechnologySearchChecked ?? _cloudTechnologySearchChecked, cloudTechnologySearchItemChecked ?? _cloudTechnologySearchItemChecked, // クラウド経験
      searchSettingToolFlag ?? _searchSettingToolFlag, toolSearchChecked ?? _toolRolesSearchChecked, toolSearchItemChecked ?? _tooleamRolesSearchItemChecked // ツール
    );
  }
}
///検索条件のProvider
final searchConditionsControllerProvider =
    StateNotifierProvider<SearchConditionsNotifier, SearchConditionsDto>(
        (ref) {
  return SearchConditionsNotifier();
});
