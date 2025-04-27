
import 'package:logger/logger.dart';
class searchConditionsDto{
  final logger = Logger(); //ロガーの宣言

  /// 検索設定フラグ
  bool? _searchSettingFlag;
  // setter 検索設定フラグ
  set setSearchSettingFlag(bool? newValue) {
    _searchSettingFlag = newValue;
    logger.i('searchSettingFlag が更新されました: $_searchSettingFlag');
  }
  // getter
  bool? get getSearchSettingFlag => _searchSettingFlag;

  ///年齢選択条件値
  int? _ageDropdownSelectedValue;
  // setter
  set setAgeDropdownSelectedValue(int? newValue) {
    _ageDropdownSelectedValue = newValue;
    logger.i('ageDropdownSelectedValue が更新されました: $_ageDropdownSelectedValue');
  }
  int? get getAgeDropdownSelectedValue => _ageDropdownSelectedValue;

  /// 工程取得リスト
  List<List<bool>>? _processSearchItemChecked;
  // setter 工程取得リスト
  set setProcessSearchItemChecked(List<List<bool>>? newValue) {
    _processSearchItemChecked = newValue;
    logger.i('processSearchItemChecked が更新されました: $_processSearchItemChecked');
  }
  // getter 工程取得リスト
  List<List<bool>>? get getProcessSearchItemChecked => _processSearchItemChecked;
}
