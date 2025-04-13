import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:skill_search_model/common/constData.dart';
import 'dart:async';


/// Example without a datasource
class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final CollectionReference engineer = FirebaseFirestore.instance.collection(
      'engineer');
  final CollectionReference utilData = FirebaseFirestore.instance.collection(
      'utilData');

  // FireStoreの'arrays'コレクションのすべてのドキュメントを取得するプロバイダー。初回に全件分、あとは変更があるたびStreamに通知される。
  // final TextEditingController _controller = TextEditingController();
  final logger = Logger(); //ロガーの宣言
  final nonData = constData.searchAgeSelectStringDefault; //定数クラスの宣言

  /* 検索条件用　*/
  String codeLanguagesDropdownSelectedValue = ""; //言語選択条件値保持
  List<String> codeLanguagesSelectItem = []; //言語選択条件リスト
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
  final ScrollController horizontalController = ScrollController(); // 水平スクロール用コントローラ
  final ScrollController verticalController = ScrollController(); // 垂直スクロール用コントローラ
  // bool _isCheckedOne = false;
  final designSize = Size(360, 690);
  int totalCount = 0;


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

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green,
          title:
          Column(
            children: [
              const Text(constData.engineerSearch,style: TextStyle(color: Colors.white),),
              Text(constData.engineerSearchNumber+constData.space+totalCount.toString()+constData.engineerSearchKen,style: const TextStyle(color: Colors.white,fontSize:15),),
            ],
          ),
          actions: [Container(
              margin: const EdgeInsets.only(right: 40),
              child: Icon(Icons.search,size: 30,)),]
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: getStream(),
          builder: (BuildContext context,
              AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              logger.w("'Error: ${snapshot.error}'");
              return const Text('Something went wrong');
            }

            if (snapshot.connectionState ==
                ConnectionState.waiting) {
              return const Text("Loading");
            }
            return ListView.builder(
              itemCount: snapshot.data?.size as int,
              itemBuilder: (context, index) {
                return Card(
                  color: Colors.white,
                  shadowColor: Colors.black,
                  child: ListTile(
                    iconColor: Colors.grey,
                    title: Text(snapshot.data
                        ?.docs[index]['last_name'] +
                        snapshot.data?.docs[index]
                        ['first_name'],style: const TextStyle(fontSize: 20),),
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
                                child: const Text(constData.space+constData.engineerSearchStation1+constData.space)),
                            Text(constData.space+snapshot
                                .data?.docs[index][
                            'nearest_station_line_name'] +constData.space+
                                snapshot.data?.docs[index]
                                ['nearest_station_name']+'駅'),
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
                                  border: Border.all(color: Colors.blue),),
                                child: const Text(constData.space+constData.engineerSearchTeamRole1+constData.space)),
                            Text(constData.space
                                + getUtilDateListGetterSimpleEvaluation(snapshot.data?.docs[index]['team_role'],
                                    teamRoleItem,snapshot.data?.docs[index]['team_role_years'],false).toString()),
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
                                  border: Border.all(color: Colors.blue),),
                                child: const Text(constData.space+constData.engineerSearchProcess1+constData.space)),
                            Text(constData.space
                                + getUtilDateListGetterSimpleEvaluation(snapshot.data?.docs[index]['process'],
                                    processItem,snapshot.data?.docs[index]['process_experience'],true).toString()),
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
                                  border: Border.all(color: Colors.blue),),
                                child: const Text(constData.space+constData.engineerSearchCodeLanguages1+constData.space)),
                            Text(constData.space
                                + getUtilDateListGetterSimpleEvaluation(snapshot.data?.docs[index]['code_languages'],
                                    codeLanguagesItem,snapshot.data?.docs[index]['code_languages_years'],false).toString()),
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
                                  border: Border.all(color: Colors.blue),),
                                child: const Text(constData.space+constData.engineerSearchDb1+constData.space)),
                            Text(constData.space
                                + getUtilDateListGetterSimpleEvaluation(snapshot.data?.docs[index]['db_experience'],
                                    dbExperienceItem,snapshot.data?.docs[index]['db_experience_years'],false).toString()),
                          ],
                        ),
                      ],
                    ),
                    leading: const Icon(Icons.account_circle),
                    trailing: Text("詳細ボタンを実装予定"),

                    onTap: () {
                      print('タップされました');
                    },
                  ),
                );
              },
            );
          }
        ),
      );
  }

  /* 検索条件を指定してクエリを作成して返す
   * @param なし
   * @return なし
  */
  Stream<QuerySnapshot> getStream() {
    // 検索条件を元にクエリを作成
    Query query = engineer;
    if (codeLanguagesDropdownSelectedValue.isNotEmpty) {
      query = query.where(
          "code_languages", isEqualTo: codeLanguagesDropdownSelectedValue);
    }
    if (ageDropdownSelectedValue != 0) {
      query = query.where("age", isLessThanOrEqualTo: ageDropdownSelectedValue);
    }
    return query.snapshots();
  }

  /* UtilDateのリストから文字列取得して各Listにして返す
   * @param なし
   * @return なし
  */
  Future<void> _fetchData() async {
    //プルダウン
    List<
        String> codeLanguagesSelectItemsResult = await getStringListFromFirestore(
        "utilData", "code_languages_item", "code_languages", true); //言語選択プルダウン
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
        "utilData", "cloud_technology_item", "cloud_technology",
        false); //クラウド取得リスト
    List<String> toolItemResult = await getStringListFromFirestore(
        "utilData", "tool_item", "tool", false); //ツール取得リスト
    List<
        String> experienceCategoryItemResult = await getStringListFromFirestore(
        "utilData", "experience_category_item", "experience_category",
        false); //ツール取得リスト
    List<String> yearsCategoryItemResult = await getStringListFromFirestore(
        "utilData", "years_category_item", "years_category", false); //ツール取得リスト


    setState(() {
      totalCount = codeLanguagesResult.length;
      codeLanguagesSelectItem = codeLanguagesSelectItemsResult; //言語選択プルダウン
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
  Future<List<String>> getStringListFromFirestore(String collectionName,
      String documentId, String field, bool isSelector) async {
    final docRef = FirebaseFirestore.instance.collection(collectionName).doc(
        documentId);

    try {
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data();

        if (data != null) {
          // 'code_languages'フィールドの値を取得
          List<dynamic> codeLanguagesDynamic = data[field];
          // dynamic型のリストをString型のリストに変換
          List<String> codeLanguagesString = codeLanguagesDynamic.map((item) =>
              item.toString()).toList();
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

  /* UtilDateのリストから文字列取得してListにして返す(三角丸二重丸で評価)
   * @param List<dynamic> numberList 番号のリスト
   * @param List<String> utilDataArray utilDataのリスト
   * @return 選択肢文字列のList
  */
  List<String>? getUtilDateListGetterSimpleEvaluation(List<dynamic> numberList,
      List<String> utilDataArray, List<dynamic> numberList2,bool experienceCategory) {
    //工程だけexperience_category
    String simpleEvaluationWord;

    List<String> utilDataListForReturn = [];
    logger.i("numberList: $numberList");
    logger.i("utilDataArray: $utilDataArray");
    logger.i("numberList2: $numberList2");
    if (utilDataArray.isEmpty || numberList.isEmpty || numberList2.isEmpty ||numberList.length!=numberList2.length) {
      return ["No Data"];
    }

    for(int i=0;i<numberList.length;i++){
      if(i<utilDataArray.length){

        if(numberList2[i]<2){
          simpleEvaluationWord = constData.triangle;
        }else if(numberList2[i]<4){
          if(experienceCategory && numberList2[i]==3){
            simpleEvaluationWord = constData.doubleCircle;
          }else{
            simpleEvaluationWord = constData.circle;
          }
        }else{
          simpleEvaluationWord = constData.doubleCircle;
        }
        utilDataListForReturn.add(utilDataArray[i]+constData.space+simpleEvaluationWord+constData.space);
      } else {
        logger.e("Index out of range: $i"); // 範囲外のインデックスをログに出力
      }

    }

    // for (var item in numberList) {
    //   // utilDataListForReturn.add(utilDataArray[item]);
    //   if (item < utilDataArray.length) { // インデックスが範囲内か確認
    //     utilDataListForReturn.add(utilDataArray[item]);
    //   } else {
    //     logger.e("Index out of range: $item"); // 範囲外のインデックスをログに出力
    //   }
    // }
    return utilDataListForReturn;
  }

  /* UtilDateのリストから文字列取得してListにして返す
   * @param List<dynamic> numberList 番号のリスト
   * @param List<String> utilDataArray utilDataのリスト
   * @return 選択肢文字列のList
  */
  List<String>? getUtilDateListGetter(List<dynamic> numberList,
      List<String> utilDataArray) {
    List<String> utilDataListForReturn = [];
    //logger.i("numberList: $numberList");
    //logger.i("utilDataArray: $utilDataArray");
    if (utilDataArray.isEmpty) {
      return [];
    }

    for (var item in numberList) {
      // utilDataListForReturn.add(utilDataArray[item]);
      if (item < utilDataArray.length) { // インデックスが範囲内か確認
        utilDataListForReturn.add(utilDataArray[item]);
      } else {
        logger.e("Index out of range: $item"); // 範囲外のインデックスをログに出力
      }
    }
    return utilDataListForReturn;
  }

//サブコレクションを実装　code_languagesVal, //経験言語 String → ArrayList test
  Future<void> addUser(int idVal, String first_nameVal, String last_nameVal,
      int ageVal, String nearest_station_line_nameVal,
      String nearest_station_nameVal,
      List<int> team_roleVal, List<int> team_role_yearsVal,
      List<int> code_languagesVal, List<int> code_languages_yearsVal,
      List<int> processVal, List<int> process_experienceVal,
      List<int> db_experienceVal, List<int> db_experience_yearsVal,
      List<int> os_experienceVal, List<int> os_experience_yearsVal,
      List<int> cloud_technologyVal, List<int> cloud_technology_yearsVal,
      List<int> toolVal, List<int> tool_yearsVal) async {
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
      await newEngineer.update(
          {'process_experience': process_experienceVal}); //工程経験
      await newEngineer.update({'code_languages': code_languagesVal}); //経験言語
      await newEngineer.update(
          {'code_languages_years': code_languages_yearsVal}); //経験言語年数
      await newEngineer.update({'db_experience': db_experienceVal}); //DB経験
      await newEngineer.update(
          {'db_experience_years': db_experience_yearsVal}); //DB工程
      await newEngineer.update({'os_experience': os_experienceVal}); //OS経験
      await newEngineer.update(
          {'os_experience_years': os_experience_yearsVal}); //OS工程
      await newEngineer.update(
          {'cloud_technology': cloud_technologyVal}); //クラウド技術
      await newEngineer.update(
          {'cloud_technology_years': cloud_technology_yearsVal}); //クラウド技術経験
      await newEngineer.update({'tool': toolVal}); //ツール
      await newEngineer.update({'tool_years': tool_yearsVal}); //ツール経験

    } catch (e) {
      logger.d("Error adding document: $e");
    }
  }

}
