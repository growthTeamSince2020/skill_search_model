import 'dart:ui';

class constData{
  // システム全体のバージョン
  static const String systemVersion = "1.0.0";
  // エンジニアドキュメントのデータ構造バージョン
  // (将来、保存形式を大幅に変えた際のデータ移行判定に使用)
  static const double dataSchemaVersion = 1.0;
  // メインカラーを登録・編集画面と統一
  static const Color themeGreen = Color(0xFF2E7D32);

  static const String searchAgeSelectStringDefault = "" ;
  static const String searchAgeSelectStringUnder30 = "30歳以下" ;
  static const String searchAgeSelectStringUnder40 = "40歳以下" ;
  static const String searchAgeSelectStringUnder50 = "50歳以下" ;
  static const double rowItemfontsize = 7;

  // コレクション情報定義
  static const String engineerCollection = "技術者登録";
  static const String engineerSearch = "技術者検索一覧";
  static const String engineerSearchDitail = "技術者詳細検索";
  static const String engineerDetail = "技術者詳細";
  static const String engineerDetailEdit = "技術者詳細編集";

  ///画面使用文言
  /* 共通 */
  static const String hyphen = "-";
  static const String blank = "";
  static const String colon = ":";
  static const String slash= "/";
  static const String space = " ";
  static const String comma = ",";
  static const String rightBracket = "(";
  static const String leftBracket = ")";
  static const String triangle= "△";//experience_categoryで1以下、years_categoryで1以下
  static const String circle= "○";//experience_categoryで2、years_categoryで2or3以下
  static const String doubleCircle= "◎";//experience_categoryで３、years_categoryで４以上
  static const String experienced = "経験有";
  static const String noExperience = "経験無";
  static const String age = "歳";

  /* 検索画面 */
  static const String engineerSearchNumber  = "検索件数";
  static const String engineerSearchKen  = "件";
  static const String engineerSearchStation1  = "最寄駅";
  static const String engineerSearchStation2 = "駅";
  static const String engineerSearchCodeLanguages1  = "経験言語";
  static const String engineerSearchProcess1  = "工程経験";
  static const String engineerSearchDb1  = "DB経験";
  static const String engineerSearchTeamRole1  = "チーム役割経験";
  static const String engineerSearchOs1  = "OS経験";
  static const String engineerSearchCloud1  = "クラウド技術";
  static const String engineerSearchTool1  = "ツール経験";


  /* 登録画面 */
  /// Firestore 'utilData' コレクション内のドキュメント名リスト
  static const List<String> masterDocs = [
    'team_role_item',
    'process_item',
    'code_languages_item',
    'db_experience_item',
    'os_experience_item',
    'cloud_technology_item',
    'tool_item',
  ];
  // --- 経験年数・レベルの選択肢文言（これらはUI表示の比較に使うため残す） ---
  static const String yearsLabel0 = "1年未満";
  static const String yearsLabel1 = "1年〜2年未満";
  static const String yearsLabel2 = "2〜3年未満";
  static const String yearsLabel3 = "3〜5年未満";
  static const String yearsLabel4 = "5〜10年未満";
  static const String yearsLabel5 = "10年以上";

  static const String levelLabel0 = "未経験";
  static const String levelLabel1 = "経験あり作成サポート必要";
  static const String levelLabel2 = "サポートなくできる";
  static const String levelLabel3 = "経験豊富でレビューできる";

  static const String simpleYearsLabel0 = "未経験";
  static const String simpleYearsLabel1 = "1年未満";
  static const String simpleYearsLabel2 = "1年〜2年未満";
  static const String simpleYearsLabel3 = "2〜3年未満";
  static const String simpleYearsLabel4 = "5年以上";

  // ==========================================
  // 2. 外部公開用：一括データ変換メソッド
  // ==========================================

  /// sourceData: UIからのMapデータ
  /// masterList: Firebase(utilData)から取得した項目のリスト
  /// type: 'years' | 'level' | 'simple'
  static Map<String, List<int>> convertDataToNumericArrays(
      dynamic sourceData, List<String> masterList, String type) {
    List<int> nameIndices = [];
    List<int> valueIndices = [];

    if (sourceData is Map) {
      sourceData.forEach((key, value) {
        // Firebaseから取得したマスターリスト内でのインデックスを探す
        int nameIdx = masterList.indexOf(key.toString());
        if (nameIdx != -1) {
          nameIndices.add(nameIdx);

          int valIdx;
          switch (type) {
            case 'level':
              valIdx = _getLevelValue(value?.toString());
              break;
            case 'simple':
              valIdx = _getToolYearsValue(value?.toString());
              break;
            default:
              valIdx = _getYearsValue(value?.toString());
          }
          valueIndices.add(valIdx);
        }
      });
    }
    return {'names': nameIndices, 'values': valueIndices};
  }

  /* 登録項目マスタ（Excelインポ・エクスポート用） */
  static const List<String> teamRoleItems = ["PM経験", "PM補佐経験", "リーダ経験", "技術支援経験", "コンサル経験"];
  static const List<String> processItems = ["要件定義", "基本設計", "詳細設計", "コーディング", "単体", "結合", "保守"];
  static const List<String> langItems = ["C", "JAVA", "C#", "Go", "C++", "Python", "PHP", "Cobol", "JavaScript", "TypeScript", "Dart"];
  static const List<String> dbItems = ["Oracle", "MySQL", "PostgresSQL", "SQLite", "MongoDB"];
  static const List<String> osItems = ["Windows", "macOS", "Linux", "Android", "iOS", "WindowsServer"];
  static const List<String> cloudItems = ["AWS", "Firebase", "GoogleCloud", "Azure"];
  static const List<String> toolItems = ["Git", "svn", "Backlog", "Docker", "Jenkins", "Ansible", "androidStadio", "Visual Studio Code", "Eclipse", "IntelliJ IDEA", "Xcode"];

  // 選択肢のリスト化（indexOf で数値変換するため）
  static const List<String> yearsList = [yearsLabel0, yearsLabel1, yearsLabel2, yearsLabel3, yearsLabel4, yearsLabel5];
  static const List<String> processLevelList = [levelLabel0, levelLabel1, levelLabel2, levelLabel3];
  static const List<String> toolYearsList = [simpleYearsLabel0, simpleYearsLabel1, simpleYearsLabel2, simpleYearsLabel3, simpleYearsLabel4];

  // ==========================================
  // 3. 内部用プライベートメソッド
  // ==========================================
  // チーム役割,経験言語,DB,OS,クラウドの変換値
  static int _getYearsValue(String? label) {
    if (label == yearsLabel0) return 0;
    if (label == yearsLabel1) return 1;
    if (label == yearsLabel2) return 2;
    if (label == yearsLabel3) return 3;
    if (label == yearsLabel4) return 4;
    if (label == yearsLabel5) return 5;
    return 0;
  }
  // 工程の変換値
  static int _getLevelValue(String? label) {
    if (label == levelLabel0) return 0;
    if (label == levelLabel1) return 1;
    if (label == levelLabel2) return 2;
    if (label == levelLabel3) return 3;
    return 0;
  }

  // ツールの変換値
  static int _getToolYearsValue(String? label) {
    if (label == simpleYearsLabel0) return 0;
    if (label == simpleYearsLabel1) return 1;
    if (label == simpleYearsLabel2) return 2;
    if (label == simpleYearsLabel3) return 3;
    if (label == simpleYearsLabel4) return 4;
    return 0;
  }

  // constData.dart のクラス内に追加してください
  static Map<String, List<String>> get engineerMasters => {
    'team_role': teamRoleItems,
    'team_role_years': yearsList,
    'process': processItems,
    'process_experience': processLevelList,
    'code_languages': langItems,
    'code_languages_years': yearsList,
    'db_experience': dbItems,
    'db_experience_years': yearsList,
    'os_experience': osItems,
    'os_experience_years': yearsList,
    'cloud_technology': cloudItems,
    'cloud_technology_years': yearsList,
    'tool': toolItems,
    'tool_years': toolYearsList,
  };
}