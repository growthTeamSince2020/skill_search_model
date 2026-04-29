import 'dart:js_interop';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:skill_search_model/common/constData.dart';
import 'package:skill_search_model/engineerSeachDetail.dart';
import 'package:skill_search_model/seachDetail.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:skill_search_model/model/searchConditionsDto.dart';

final logger = Logger(); //ロガーの宣言

/// Example without a datasource
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final CollectionReference engineer =
      FirebaseFirestore.instance.collection('engineer');
  final CollectionReference utilData =
      FirebaseFirestore.instance.collection('utilData');

  final nonData = constData.searchAgeSelectStringDefault; //定数クラスの宣言
  late SearchConditionsDto searchConditions;

  /* 検索条件用　*/
  String codeLanguagesDropdownSelectedValue = ""; //言語選択条件値保持
  // List<String> codeLanguagesSelectItem = []; //言語選択条件リスト
  int ageDropdownSelectedValue = 0; //年齢選択条件値保持

  /* 検索一覧用　*/
  List<String> processItem = []; //工程取得リスト
  List<String> teamRoleItem = []; //チーム役割取得リスト
  List<String> codeLanguagesItem = []; //経験言語取得リスト
  List<String> dbExperienceItem = []; //DB取得リスト
  List<String> osExperienceItem = []; //OS取得リスト
  List<String> cloudTechnologyItem = []; //クラウド取得リスト
  List<String> toolItem = []; //ツール取得リスト
  List<String> experienceCategoryItem = []; //経験程度リスト
  List<String> yearsCategoryItem = []; //経験年リスト
  final ScrollController horizontalController =
      ScrollController(); // 水平スクロール用コントローラ
  final ScrollController verticalController =
      ScrollController(); // 垂直スクロール用コントローラ
  // bool _isCheckedOne = false;
  final designSize = Size(360, 690);
  int totalCount = 0;

  //詳細検索アイコン押下時
  void _detailSearchScreen() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const SeachDetailPage(),
      ),
    );
  }

  //エンジニア詳細ボタン押下時
  void _engineerDetailScreen(String engineerId) { // 引数を追加
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        // const を削除し、engineerId を渡す
        builder: (BuildContext context) => EngineerSeachDetailPage(engineerId: engineerId),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchData(); // 別メソッドで非同期処理を実行
  }

  @override
  Widget build(BuildContext context) {
    // searchConProviderのインスタンスを取得
    searchConditions = ref.watch(searchConditionsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // デフォルトの戻るボタンを非表示
        leadingWidth: 40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context)
                .popUntil((route) => route.isFirst);
          },
        ),
        backgroundColor: Colors.lightGreenAccent.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        titleSpacing: 0, // 左寄せにするために余白をゼロに
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1行目：アイコン、タイトル、件数
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Icon(Icons.pageview, color: Colors.white, size: 22),
                const SizedBox(width: 6),
                Text(
                  constData.engineerSearch, // 「技術者検索」
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18, // サイズを大きく
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                // 件数表示
                Text(
                  "$totalCount ${constData.engineerSearchKen}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // 2行目：補足説明
            const Text(
              "△:未経験~2年未満 ○:3~5年未満 ◎:5年以上",
              style: TextStyle(
                color: Colors.white,
                fontSize: 11, // 視認性のために少し拡大
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: IconButton(
              onPressed: () => _detailSearchScreen(),
              icon: const Icon(
                Icons.filter_list_alt,
                size: 28,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        // 1. アプリ側でフィルタリング済みのリストを取得する
          future: getStream(),
          builder: (context, snapshot) {
            // Case 1: データ取得中（待機中）の場合
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Case 2: エラーが発生した場合
            if (snapshot.hasError) {
              return Center(
                  child: Text('データの取得中にエラーが発生しました: ${snapshot.error}'));
            }

            // Case 3: データがない、またはリストが空の場合
            final docs = snapshot.data;
            if (docs == null || docs.isEmpty) {
              // 検索件数を0に更新
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && totalCount != 0) {
                  setState(() => totalCount = 0);
                }
              });
              return const Center(child: Text("該当するエンジニアが見つかりませんでした。"));
            }

            // 取得できた件数を totalCount に反映（AppBar表示用）
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && totalCount != docs.length) {
                setState(() => totalCount = docs.length);
              }
            });

            // Case 4: データが正常に取得できた場合、リストを表示する
            return ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                // 各ドキュメントのデータを取得
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;

                return Card(
                  color: Colors.white,
                  shadowColor: Colors.black,
                  child: ListTile(
                    iconColor: Colors.grey,
                    title: Text(
                      (data['last_name'] ?? '') +
                          (data['first_name'] ?? '') +
                          constData.space +
                          constData.rightBracket +
                          (data['age']?.toString() ?? '') +
                          constData.age +
                          constData.leftBracket,
                      style: const TextStyle(fontSize: 20),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //最寄駅
                        Row(
                          children: [
                            const Icon(Icons.linear_scale),
                            Container(
                                margin: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue),
                                ),
                                child: const Text(constData.space +
                                    constData.engineerSearchStation1 +
                                    constData.space)),
                            Flexible(
                              child: Text(constData.space +
                                  (data['nearest_station_line_name'] ?? '') +
                                  constData.space +
                                  (data['nearest_station_name'] ?? '') +
                                  '駅'),
                            ),
                          ],
                        ),
                        //チーム役割
                        Row(
                          children: [
                            const Icon(Icons.group),
                            Container(
                                margin: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue),
                                ),
                                child: const Text(constData.space +
                                    constData.engineerSearchTeamRole1 +
                                    constData.space)),
                            Flexible(
                              child: Text(constData.space +
                                  getUtilDateListGetterSimpleEvaluation(
                                      data['team_role'],
                                      teamRoleItem,
                                      data['team_role_years'],
                                      false)
                                      .toString()),
                            ),
                          ],
                        ),
                        //工程経験
                        Row(
                          children: [
                            const Icon(Icons.account_tree),
                            Container(
                                margin: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue),
                                ),
                                child: const Text(constData.space +
                                    constData.engineerSearchProcess1 +
                                    constData.space)),
                            Flexible(
                              child: Text(constData.space +
                                  getUtilDateListGetterSimpleEvaluation(
                                      data['process'],
                                      processItem,
                                      data['process_experience'],
                                      true)
                                      .toString()),
                            ),
                          ],
                        ),
                        //経験言語
                        Row(
                          children: [
                            const Icon(Icons.developer_mode),
                            Container(
                                margin: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue),
                                ),
                                child: const Text(constData.space +
                                    constData.engineerSearchCodeLanguages1 +
                                    constData.space)),
                            Flexible(
                              child: Text(constData.space +
                                  getUtilDateListGetterSimpleEvaluation(
                                      data['code_languages'],
                                      codeLanguagesItem,
                                      data['code_languages_years'],
                                      false)
                                      .toString()),
                            ),
                          ],
                        ),
                        //DB言語
                        Row(
                          children: [
                            const Icon(Icons.storage),
                            Container(
                                margin: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue),
                                ),
                                child: const Text(constData.space +
                                    constData.engineerSearchDb1 +
                                    constData.space)),
                            Flexible(
                              child: Text(constData.space +
                                  getUtilDateListGetterSimpleEvaluation(
                                      data['db_experience'],
                                      dbExperienceItem,
                                      data['db_experience_years'],
                                      false)
                                      .toString()),
                            ),
                          ],
                        ),
                      ],
                    ),
                    leading: const Icon(Icons.account_circle),
                    trailing: IconButton(
                        onPressed: () => _engineerDetailScreen(doc.id),
                        icon: const Icon(
                          Icons.article,
                          size: 30,
                        )),
                    onTap: () {
                      _engineerDetailScreen(doc.id);
                    },
                  ),
                );
              },
            );
          }),
    );
  }

  Future<List<DocumentSnapshot>> getStream() async {
    searchConditions = ref.watch(searchConditionsControllerProvider);

    // 1. 基本となるクエリ（年齢などの単純なフィルタのみFirestoreで行う）
    Query query = engineer.where(FieldPath.documentId, isNotEqualTo: "sequenceNo");

    if (searchConditions.getSearchSettingFlag == true) {
      // 年齢条件の適用
      if (searchConditions.getAgeDropdownSelectedValue! > 0) {
        int searchNum = (searchConditions.getAgeDropdownSelectedValue == 1) ? 30 :
        (searchConditions.getAgeDropdownSelectedValue == 2) ? 40 : 50;
        query = query.where("age", isLessThanOrEqualTo: searchNum);
      }
    }

    // 2. この時点でのデータを一旦すべて取得
    QuerySnapshot allDocs = await query.get();

    // 3. 詳細な条件（工程・チーム役割）でアプリ側でフィルタリング
    List<DocumentSnapshot> filteredList = allDocs.docs.where((doc) {
      var data = doc.data() as Map<String, dynamic>;

      // 詳細検索がオフなら全て通す
      if (searchConditions.getSearchSettingFlag != true) return true;

      // --- 工程経験の判定 ---
      bool processMatch = true;
      if (searchConditions.getSearchSettingProcessFlag == true) {
        processMatch = _checkExperience(
          userItems: data["process"] ?? [],
          userYears: data["process_experience"] ?? [],
          searchSettings: searchConditions.getProcessSearchItemChecked!,
        );
      }

      // --- チーム役割の判定 ---
      bool teamRoleMatch = true;
      if (searchConditions.getSearchSettingTeamRolesFlag == true) {
        teamRoleMatch = _checkExperience(
          userItems: data["team_role"] ?? [],
          userYears: data["team_role_years"] ?? [],
          searchSettings: searchConditions.getTeamRolesSearchItemChecked!,
        );
      }

      // --- 経験言語の判定 ---
      bool codeLanguagesMatch = true;
      if (searchConditions.getSearchSettingCodeLanguagesFlag == true) {
        codeLanguagesMatch = _checkExperience(
          userItems: data["code_languages"] ?? [],
          userYears: data["code_languages_years"] ?? [],
          searchSettings: searchConditions.getCodeLanguagesSearchItemChecked!,
        );
      }

      // --- DB経験の判定 ---
      bool dbExperienceMatch = true;
      if (searchConditions.getSearchSettingDbExperienceFlag == true) {
        dbExperienceMatch = _checkExperience(
          userItems: data["db_experience"] ?? [],
          userYears: data["db_experience_years"] ?? [],
          searchSettings: searchConditions.getDbExperienceSearchItemChecked!,
        );
      }

      // --- OS経験の判定 ---
      bool osExperienceMatch = true;
      if (searchConditions.getSearchSettingOsExperienceFlag == true) {
        osExperienceMatch = _checkExperience(
          userItems: data["os_experience"] ?? [],
          userYears: data["os_experience_years"] ?? [],
          searchSettings: searchConditions.getOsExperienceSearchItemChecked!,
        );
      }

      // --- クラウド技術の判定 ---
      bool cloudTechnologyMatch = true;
      if (searchConditions.getSearchSettingCloudTechnologyFlag == true) {
        cloudTechnologyMatch = _checkExperience(
          userItems: data["cloud_technology"] ?? [],
          userYears: data["cloud_technology_years"] ?? [],
          searchSettings: searchConditions.getCloudTechnologySearchItemChecked!,
        );
      }

      // --- ツールの判定 ---
      bool toolMatch = true;
      if (searchConditions.getSearchSettingToolFlag == true) {
        toolMatch = _checkExperience(
          userItems: data["tool"] ?? [],
          userYears: data["tool_years"] ?? [],
          searchSettings: searchConditions.getToolSearchItemChecked!,
        );
      }

      // AND検索（両方のフラグがONなら両方満たす必要がある）
      return processMatch && teamRoleMatch && codeLanguagesMatch && dbExperienceMatch && osExperienceMatch && cloudTechnologyMatch && toolMatch;
    }).toList();

    return filteredList;
  }

  /// 経験値判定用の共通ヘルパーメソッド（カテゴリ内AND検索版）
  bool _checkExperience({
    required List<dynamic> userItems,
    required List<dynamic> userYears,
    required List<List<bool>> searchSettings,
  }) {
    // 1. まず、検索条件が一つでも設定されているか確認
    bool hasAnyCondition = false;
    for (var setting in searchSettings) {
      if (setting.contains(true)) {
        hasAnyCondition = true;
        break;
      }
    }

    // 検索条件が一つも設定されていない場合は「マッチ」とみなして通す
    if (!hasAnyCondition) return true;

    // 2. 各項目（Java, PHPなど）ごとに判定
    for (int i = 0; i < searchSettings.length; i++) {
      // 項目 i に対して、どれか一つの年数でもチェックが入っているか
      bool isThisItemTarget = searchSettings[i].contains(true);

      if (isThisItemTarget) {
        // この項目（例：Java）にチェックがある場合、ユーザーがそれを持っているか確認
        int userIdx = userItems.indexOf(i);

        if (userIdx == -1) {
          // ユーザーがこの項目自体を持っていないので、その時点で不一致確定（AND条件失敗）
          return false;
        }

        // ユーザーが持っている場合、選択されたいずれかの年数条件に合致するか確認
        bool yearMatch = false;
        for (int j = 0; j < searchSettings[i].length; j++) {
          if (searchSettings[i][j] == true) {
            // 型の不一致を防ぐため .toString() で比較
            if (userYears[userIdx].toString() == j.toString()) {
              yearMatch = true;
              break; // 年数条件のどれかに合致すればその項目はクリア
            }
          }
        }

        if (!yearMatch) {
          // 指定された年数条件に一つも合致しなかったら不一致確定
          return false;
        }
      }
    }

    // すべてのチェック項目を一度も `return false` されずに通過できれば「合致」
    return true;
  }

  /* UtilDateのリストから文字列取得して各Listにして返す
   * @param なし
   * @return なし
  */
  Future<void> _fetchData() async {
    //プルダウン
    // List<String> codeLanguagesSelectItemsResult =
    //     await getStringListFromFirestore("utilData", "code_languages_item",
    //         "code_languages", true); //言語選択プルダウン
    //検索用
    List<String> codeLanguagesResult = await getStringListFromFirestore(
        "utilData", "code_languages_item", "code_languages", false); //言語リスト
    List<String> processItemResult = await getStringListFromFirestore(
        "utilData", "process_item", "process", false); //工程取得リスト
    List<String> teamRoleItemResult = await getStringListFromFirestore(
        "utilData", "team_role_item", "team_role", false); //チーム役割取得リスト
    List<String> dbExperienceItemResult = await getStringListFromFirestore(
        "utilData", "db_experience_item", "db_experience", false); //DB取得リスト
    List<String> osExperienceItemResult = await getStringListFromFirestore(
        "utilData", "os_experience_item", "os_experience", false); //OS取得リスト
    List<String> cloudTechnologyItemResult = await getStringListFromFirestore(
        "utilData",
        "cloud_technology_item",
        "cloud_technology",
        false); //クラウド取得リスト
    List<String> toolItemResult = await getStringListFromFirestore(
        "utilData", "tool_item", "tool", false); //ツール取得リスト
    List<String> experienceCategoryItemResult =
        await getStringListFromFirestore("utilData", "experience_category_item",
            "experience_category", false); //ツール取得リスト
    List<String> yearsCategoryItemResult = await getStringListFromFirestore(
        "utilData", "years_category_item", "years_category", false); //ツール取得リスト

    setState(() {
      // totalCount = codeLanguagesResult.length;
      // codeLanguagesSelectItem = codeLanguagesSelectItemsResult; //言語選択プルダウン
      codeLanguagesItem = codeLanguagesResult; //言語リスト
      processItem = processItemResult; //工程取得リスト
      teamRoleItem = teamRoleItemResult; //チーム役割取得リスト
      dbExperienceItem = dbExperienceItemResult; //DB取得リスト
      osExperienceItem = osExperienceItemResult; //OS取得リスト
      cloudTechnologyItem = cloudTechnologyItemResult; //クラウド取得リスト
      toolItem = toolItemResult; //ツール取得リスト
      experienceCategoryItem = experienceCategoryItemResult; //経験程度リスト
      yearsCategoryItem = yearsCategoryItemResult; //経験年リスト
    });
  }

  /* UtilDateのリストから文字列取得してListにして返す
   * @param List<dynamic> numberList 番号のリスト
   * @param List<String> utilDataArray utilDataのリスト
   * @return 選択肢文字列のList
  */
  List<String>? getUtilDateListGetter(
      List<dynamic> numberList, List<String> utilDataArray) {
    List<String> utilDataListForReturn = [];
    //logger.i("numberList: $numberList");
    //logger.i("utilDataArray: $utilDataArray");
    if (utilDataArray.isEmpty) {
      return [];
    }

    for (var item in numberList) {
      // utilDataListForReturn.add(utilDataArray[item]);
      if (item < utilDataArray.length) {
        // インデックスが範囲内か確認
        utilDataListForReturn.add(utilDataArray[item]);
      } else {
        logger.e("Index out of range: $item"); // 範囲外のインデックスをログに出力
      }
    }
    return utilDataListForReturn;
  }

//サブコレクションを実装　code_languagesVal, //経験言語 String → ArrayList test
  Future<void> addUser(
      int idVal,
      String first_nameVal,
      String last_nameVal,
      int ageVal,
      String nearest_station_line_nameVal,
      String nearest_station_nameVal,
      List<int> team_roleVal,
      List<int> team_role_yearsVal,
      List<int> code_languagesVal,
      List<int> code_languages_yearsVal,
      List<int> processVal,
      List<int> process_experienceVal,
      List<int> db_experienceVal,
      List<int> db_experience_yearsVal,
      List<int> os_experienceVal,
      List<int> os_experience_yearsVal,
      List<int> cloud_technologyVal,
      List<int> cloud_technology_yearsVal,
      List<int> toolVal,
      List<int> tool_yearsVal) async {
    try {
      DocumentReference newEngineer = await engineer.add({
        'id': idVal, //連番
        'first_name': first_nameVal, //名前
        'last_name': last_nameVal, //苗字
        'age': ageVal, //年齢
        'nearest_station_line_name': nearest_station_line_nameVal, //最寄沿線
        'nearest_station_name': nearest_station_nameVal, //最寄駅
      });
      await newEngineer.update({'team_role': team_roleVal}); //チーム役割
      await newEngineer.update({'team_role_years': team_role_yearsVal}); //チーム工程
      await newEngineer.update({'process': processVal}); //工程
      await newEngineer
          .update({'process_experience': process_experienceVal}); //工程経験
      await newEngineer.update({'code_languages': code_languagesVal}); //経験言語
      await newEngineer
          .update({'code_languages_years': code_languages_yearsVal}); //経験言語年数
      await newEngineer.update({'db_experience': db_experienceVal}); //DB経験
      await newEngineer
          .update({'db_experience_years': db_experience_yearsVal}); //DB工程
      await newEngineer.update({'os_experience': os_experienceVal}); //OS経験
      await newEngineer
          .update({'os_experience_years': os_experience_yearsVal}); //OS工程
      await newEngineer
          .update({'cloud_technology': cloud_technologyVal}); //クラウド技術
      await newEngineer.update(
          {'cloud_technology_years': cloud_technology_yearsVal}); //クラウド技術経験
      await newEngineer.update({'tool': toolVal}); //ツール
      await newEngineer.update({'tool_years': tool_yearsVal}); //ツール経験
    } catch (e) {
      logger.d("Error adding document: $e");
    }
  }
}

List<String>? getUtilDateListGetterSimpleEvaluation(numberList,
    List<String> utilDataArray, numberList2, bool experienceCategory) {
  //工程だけexperience_category
  String simpleEvaluationWord;

  List<String> utilDataListForReturn = [];
  if (utilDataArray.isEmpty ||
      numberList.isEmpty ||
      numberList2.isEmpty ||
      numberList.length != numberList2.length) {
    return ["No Data"];
  }

  for (int i = 0; i < numberList.length; i++) {
    if (i < utilDataArray.length) {
      if (numberList2[i] < 2) {
        simpleEvaluationWord = constData.triangle;
      } else if (numberList2[i] < 4) {
        if (experienceCategory && numberList2[i] == 3) {
          simpleEvaluationWord = constData.doubleCircle;
        } else {
          simpleEvaluationWord = constData.circle;
        }
      } else {
        simpleEvaluationWord = constData.doubleCircle;
      }
      utilDataListForReturn.add(utilDataArray[i] +
          constData.space +
          simpleEvaluationWord +
          constData.space);
    } else {
      logger.e("Index out of range: $i"); // 範囲外のインデックスをログに出力
    }
  }
  return utilDataListForReturn;
}

/* UtilDateのリストから文字列取得してListにして返す
   * @param List<dynamic> numberList 番号のリスト
   * @param List<String> utilDataArray utilDataのリスト
   * @return 選択肢文字列のList
  */
Future<List<String>> getStringListFromFirestore(String collectionName,
    String documentId, String field, bool isSelector) async {
  final docRef =
      FirebaseFirestore.instance.collection(collectionName).doc(documentId);

  try {
    final doc = await docRef.get();
    if (doc.exists) {
      final data = doc.data();

      if (data != null) {
        // 'code_languages'フィールドの値を取得
        List<dynamic> codeLanguagesDynamic = data[field];
        // dynamic型のリストをString型のリストに変換
        List<String> codeLanguagesString =
            codeLanguagesDynamic.map((item) => item.toString()).toList();
        if (isSelector) {
          codeLanguagesString.insert(0, "");
        }
        return codeLanguagesString;
      }
    } else {
      logger.e("Document does not exist");
    }
  } catch (e) {
    logger.e("Error getting document: $e");
  }
  return []; // エラーまたはドキュメントが存在しない場合は空のリストを返す
}
