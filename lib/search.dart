import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:skill_search_model/constData.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final CollectionReference engineer = FirebaseFirestore.instance.collection('engineer');
  final CollectionReference utilData = FirebaseFirestore.instance.collection('utilData');
  // FireStoreの'arrays'コレクションのすべてのドキュメントを取得するプロバイダー。初回に全件分、あとは変更があるたびStreamに通知される。
  final TextEditingController _controller = TextEditingController();
  final logger = Logger(); //ロガーの宣言

  /* 検索条件用　*/
  String codeLanguagesDropdownSelectedValue = "";//言語選択条件値保持
  List<String> codeLanguagesSelectItem = [];//言語選択条件リスト
  int ageDropdownSelectedValue = 0;//年齢選択条件値保持

  /* 検索一覧用　*/
  List<String> processItem = [];//工程取得リスト
  List<String> teamRoleItem = [];//チーム役割取得リスト
  List<String> codeLanguagesItem = [];//経験言語取得リスト
  List<String> dbExperienceItem = [];//DB取得リスト
  List<String> osExperienceItem = [];//OS取得リスト
  List<String> cloudTechnologyItem = [];//クラウド取得リスト
  List<String> toolItem = [];//ツール取得リスト
  List<String> experienceCategoryItem = [];//経験程度リスト
  List<String> yearsCategoryItem = [];//経験年リスト



  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    _fetchData(); // 別メソッドで非同期処理を実行
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size; // 画面サイズ取得
    debugPrint('画面サイズ：${size.width} x ${size.height}');
    return Scaffold(
      appBar: AppBar(
        title: const Text('エンジニア検索'),
      ),
      body: Container(
        // width: 2500,
        margin: const EdgeInsets.all(50),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: [
                  //プルダウン　経験言語
                  const SizedBox(width: 80,child: Text("経験言語 : "),),
                  DropdownButton<String>(
                    value: codeLanguagesDropdownSelectedValue,
                    onChanged: (String? value) {
                      setState(() {
                        codeLanguagesDropdownSelectedValue = value!;
                        logger.d("'プルダウン押下　値変更: $value'");
                      });
                    },
                    items: codeLanguagesSelectItem
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(width: 10),
                  const SizedBox(width: 120,child: Text("エンジニア年齢 : "),),
                  //プルダウン　年齢
                  DropdownButton<int>(
                    value: ageDropdownSelectedValue,
                    items: const [
                      DropdownMenuItem(value: 0,child: Text(constData.searchAgeSelectStringDefault)),
                      DropdownMenuItem(value: 30,child: Text(constData.searchAgeSelectStringUnder30)),
                      DropdownMenuItem(value: 40,child: Text(constData.searchAgeSelectStringUnder40)),
                      DropdownMenuItem(value: 50,child: Text(constData.searchAgeSelectStringUnder50)),
                    ],
                    onChanged: (int? ageValue) {
                      // selectedValue = value!;
                      setState(() {
                        ageDropdownSelectedValue = ageValue!;
                        logger.d("'プルダウン押下　値変更: ${ageValue}'");
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  //キーワード検索は一旦封印
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        fixedSize: const Size(75, 25)),
                    child: const Text('検索'),
                    onPressed: () {
                      setState(() {

                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    //テスト作成ボタン
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        fixedSize: const Size(75, 25)),
                    child: const Text('登録'),
                    onPressed: () {
                      setState(() {
                        for (int i = 4; i < 201; i++) {
                          addUser(i, '太郎', '遠藤', 30, '西武新宿線', '所沢',
                            // ['PM', 'リーダー', '技術支援'],<int>[1, 5, 6],//チーム役割
                            <int>[0, 1, 2, 3, 4],<int>[0, 1, 2, 3],//チーム役割
                            // ['C', 'JAVA', 'C#'] ,<int>[1, 5, 6],//経験言語
                            <int>[0, 1, 2] ,<int>[0, 1, 2],//経験言語
                            // ['要件定義', '基本設計', '詳細設計', 'コ ーディング','単体テスト','結合テスト'] ,<int>[1, 5, 6, 5, 6],//工程　
                            <int>[0, 1, 2, 3, 4] ,<int>[0, 1, 2, 3, 3],//工程　
                            // ['Oracle', 'postgresql', 'MongoDB'],<int>[1, 5, 6],//DB経験
                            <int>[0, 1, 2] ,<int>[0, 1, 2],//DB経
                            // ['Windows', 'macOS', 'Unix', 'Linux'],<int>[1, 5, 6, 5],//OS経験
                            <int>[0, 1, 2, 3, 4] ,<int>[0, 1, 2, 3, 1],//OS経験
                            // ['AWS', 'Azure', 'GoogleCloud'],<int>[1, 5, 6],//クラウド経験
                            <int>[0, 1, 2, 3] ,<int>[0, 1, 2, 3],//クラウド経験
                            // ['Eclipse', 'VSCode', 'Git'],<int>[1, 5, 6]);//ツール経験
                            <int>[0, 1, 2, 3, 4] ,<int>[0, 1, 2, 3, 3],);//ツール経験
                        }
                        logger.d("テストデータインサート");
                      });
                    },
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        fixedSize: const Size(75, 25)),
                    child: const Text('クリア'),
                    onPressed: () {
                      //TODO;
                      logger.d("クリアボタンを押下");
                      _controller.clear();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                    height: double.infinity,
                    alignment: Alignment.topCenter,
                    child: StreamBuilder<QuerySnapshot>(
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

                          return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child:
                                SingleChildScrollView(
                                    scrollDirection: Axis.vertical,
                              child: DataTable(
                                border: TableBorder.all(width: 1, color: Colors.grey),
                                //columnSpacing: 10.0,
                                headingRowColor: MaterialStateProperty.all(Colors.black),
                                headingTextStyle: const TextStyle(color: Colors.white),
                                headingRowHeight: 30.0,
                                dataRowMinHeight: 25.0,
                                dataRowMaxHeight: 100.0,
                                columns: const [
                                  DataColumn(label: Text('氏名')),
                                  DataColumn(label: Text('年齢')),
                                  DataColumn(label: Text('最寄駅')),
                                  DataColumn(label: Text('工程')),
                                  DataColumn(label: Text('工程経験')),
                                  DataColumn(label: Text('チーム')),
                                  DataColumn(label: Text('チーム経験')),
                                  DataColumn(label: Text('言語')),
                                  DataColumn(label: Text('言語経験')),
                                  DataColumn(label: Text('DB')),
                                  DataColumn(label: Text('DB経験')),
                                  DataColumn(label: Text('OS')),
                                  DataColumn(label: Text('OS経験')),
                                  DataColumn(label: Text('クラウド')),
                                  DataColumn(label: Text('クラウド経験')),
                                  DataColumn(label: Text('クラウド')),
                                  DataColumn(label: Text('クラウド経験')),
                                  DataColumn(label: Text('クラウド')),
                                  DataColumn(label: Text('クラウド経験')),
                                  DataColumn(label: Text('クラウド')),
                                  DataColumn(label: Text('クラウド経験')),
                                ],
                                rows: List<DataRow>.generate(
                                    snapshot.data?.size as int,
                                        (index) => DataRow(cells: [
                                      DataCell(Text(snapshot.data
                                          ?.docs[index]['last_name'] +
                                          snapshot.data?.docs[index]
                                          ['first_name'])),
                                      DataCell(Text(snapshot
                                          .data!.docs[index]['age']
                                          .toString())),
                                      DataCell(Text(snapshot
                                          .data?.docs[index][
                                      'nearest_station_line_name'] +
                                          snapshot.data?.docs[index]
                                          ['nearest_station_name'])),

                                      //工程
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: (getUtilDateListGetter(snapshot.data?.docs[index]['process'], processItem) as List<String>)
                                              .map((language) => Text(language.toString(), style: const TextStyle(fontSize: constData.rowItemfontsize))) // フォントサイズを小さくする
                                              .toList(),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children:
                                          (getUtilDateListGetter(snapshot.data?.docs[index]['process_experience'], experienceCategoryItem)  as List<String>)
                                              .map((language) => Text(language.toString(), style: const TextStyle(fontSize: constData.rowItemfontsize)))
                                              .toList(),
                                        ),
                                      ),
                                      //チーム
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: (getUtilDateListGetter(snapshot.data?.docs[index]['team_role'], teamRoleItem) as List<String>)
                                              .map((language) => Text(language.toString(), style: const TextStyle(fontSize: constData.rowItemfontsize))) // フォントサイズを小さくする
                                              .toList(),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children:
                                          (getUtilDateListGetter(snapshot.data?.docs[index]['team_role_years'], yearsCategoryItem)  as List<String>)
                                              .map((language) => Text(language.toString(), style: const TextStyle(fontSize: constData.rowItemfontsize)))
                                              .toList(),
                                        ),
                                      ),
                                      //プログラミング言語
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: (getUtilDateListGetter(snapshot.data?.docs[index]['code_languages'], codeLanguagesItem) as List<String>)
                                              .map((language) => Text(language.toString(), style: const TextStyle(fontSize: constData.rowItemfontsize))) // フォントサイズを小さくする
                                              .toList(),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children:
                                          (getUtilDateListGetter(snapshot.data?.docs[index]['code_languages_years'], yearsCategoryItem)  as List<String>)
                                              .map((language) => Text(language.toString(), style: const TextStyle(fontSize: constData.rowItemfontsize)))
                                              .toList(),
                                        ),
                                      ),
                                      //DB
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children:
                                          (getUtilDateListGetter(snapshot.data?.docs[index]['db_experience'], dbExperienceItem)  as List<String>)
                                              .map((language) => Text(language.toString(), style: const TextStyle(fontSize: constData.rowItemfontsize)))
                                              .toList(),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children:
                                          (getUtilDateListGetter(snapshot.data?.docs[index]['db_experience_years'], yearsCategoryItem)  as List<String>)
                                              .map((language) => Text(language.toString(), style: const TextStyle(fontSize: constData.rowItemfontsize)))
                                              .toList(),
                                        ),
                                      ),
                                      //OS
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children:
                                          (getUtilDateListGetter(snapshot.data?.docs[index]['os_experience'], osExperienceItem)  as List<String>)
                                              .map((language) => Text(language.toString(), style: const TextStyle(fontSize: constData.rowItemfontsize)))
                                              .toList(),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children:
                                          (getUtilDateListGetter(snapshot.data?.docs[index]['os_experience_years'], yearsCategoryItem)  as List<String>)
                                              .map((language) => Text(language.toString(), style: const TextStyle(fontSize: constData.rowItemfontsize)))
                                              .toList(),
                                        ),
                                      ),

                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children:
                                          (getUtilDateListGetter(snapshot.data?.docs[index]['cloud_technology'], cloudTechnologyItem)  as List<String>)
                                              .map((language) => Text(language.toString(), style: const TextStyle(fontSize: constData.rowItemfontsize)))
                                              .toList(),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children:
                                          (getUtilDateListGetter(snapshot.data?.docs[index]['cloud_technology_years'], yearsCategoryItem)  as List<String>)
                                              .map((language) => Text(language.toString(), style: const TextStyle(fontSize: constData.rowItemfontsize)))
                                              .toList(),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children:
                                          (getUtilDateListGetter(snapshot.data?.docs[index]['cloud_technology'], cloudTechnologyItem)  as List<String>)
                                              .map((language) => Text(language.toString(), style: const TextStyle(fontSize: constData.rowItemfontsize)))
                                              .toList(),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children:
                                          (getUtilDateListGetter(snapshot.data?.docs[index]['cloud_technology_years'], yearsCategoryItem)  as List<String>)
                                              .map((language) => Text(language.toString(), style: const TextStyle(fontSize: constData.rowItemfontsize)))
                                              .toList(),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children:
                                          (getUtilDateListGetter(snapshot.data?.docs[index]['cloud_technology'], cloudTechnologyItem)  as List<String>)
                                              .map((language) => Text(language.toString(), style: const TextStyle(fontSize: constData.rowItemfontsize)))
                                              .toList(),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children:
                                          (getUtilDateListGetter(snapshot.data?.docs[index]['cloud_technology_years'], yearsCategoryItem)  as List<String>)
                                              .map((language) => Text(language.toString(), style: const TextStyle(fontSize: constData.rowItemfontsize)))
                                              .toList(),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children:
                                          (getUtilDateListGetter(snapshot.data?.docs[index]['cloud_technology'], cloudTechnologyItem)  as List<String>)
                                              .map((language) => Text(language.toString(), style: const TextStyle(fontSize: constData.rowItemfontsize)))
                                              .toList(),
                                        ),
                                      ),
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children:
                                          (getUtilDateListGetter(snapshot.data?.docs[index]['cloud_technology_years'], yearsCategoryItem)  as List<String>)
                                              .map((language) => Text(language.toString(), style: const TextStyle(fontSize: constData.rowItemfontsize)))
                                              .toList(),
                                        ),
                                      ),
                                    ])),
                              )));
                        })),
              ),
            ],
          ),
        ),
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
      query = query.where("code_languages", isEqualTo: codeLanguagesDropdownSelectedValue);
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
    List<String> codeLanguagesSelectItemsResult = await getStringListFromFirestore("utilData", "code_languages_item", "code_languages", true);//言語選択プルダウン
    //検索用
    List<String> codeLanguagesResult = await getStringListFromFirestore("utilData", "code_languages_item", "code_languages", false);//言語リスト
    List<String> processItemResult = await getStringListFromFirestore("utilData", "process_item", "process", false);//工程取得リスト
    List<String> teamRoleItemResult = await getStringListFromFirestore("utilData", "team_role_item", "team_role", false);//チーム役割取得リスト
    List<String> dbExperienceItemResult = await getStringListFromFirestore("utilData", "db_experience_item", "db_experience", false);//DB取得リスト
    List<String> osExperienceItemResult = await getStringListFromFirestore("utilData", "os_experience_item", "os_experience", false);//OS取得リスト
    List<String> cloudTechnologyItemResult = await getStringListFromFirestore("utilData", "cloud_technology_item", "cloud_technology", false);//クラウド取得リスト
    List<String> toolItemResult = await getStringListFromFirestore("utilData", "tool_item", "tool", false);//ツール取得リスト
    List<String> experienceCategoryItemResult = await getStringListFromFirestore("utilData", "experience_category_item", "experience_category", false);//ツール取得リスト
    List<String> yearsCategoryItemResult = await getStringListFromFirestore("utilData", "years_category_item", "years_category", false);//ツール取得リスト

    setState(() {
      codeLanguagesSelectItem = codeLanguagesSelectItemsResult;//言語選択プルダウン
      codeLanguagesItem = codeLanguagesResult;//言語リスト
      processItem = processItemResult;//工程取得リスト
      teamRoleItem = teamRoleItemResult;//チーム役割取得リスト
      dbExperienceItem = dbExperienceItemResult;//DB取得リスト
      osExperienceItem = osExperienceItemResult;//OS取得リスト
      cloudTechnologyItem = cloudTechnologyItemResult;//クラウド取得リスト
      toolItem = toolItemResult;//ツール取得リスト
      experienceCategoryItem = experienceCategoryItemResult;//経験程度リスト
      yearsCategoryItem = yearsCategoryItemResult;//経験年リスト
    });
  }
  /* UtilDateのリストから文字列取得してListにして返す
   * @param List<dynamic> numberList 番号のリスト
   * @param List<String> utilDataArray utilDataのリスト
   * @return 選択肢文字列のList
  */
  Future<List<String>> getStringListFromFirestore(String collectionName, String documentId, String field, bool isSelector) async {
    final docRef = FirebaseFirestore.instance.collection(collectionName).doc(documentId);

    try {
      final doc = await docRef.get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;

        if (data != null) {
          // 'code_languages'フィールドの値を取得
          List<dynamic> codeLanguagesDynamic = data[field];
          // dynamic型のリストをString型のリストに変換
          List<String> codeLanguagesString = codeLanguagesDynamic.map((item) => item.toString()).toList();
          if(isSelector) {
            codeLanguagesString.insert(0, "");
          }
          return codeLanguagesString;
        }
      } else {
      }
    } catch (e) {
    }
    return []; // エラーまたはドキュメントが存在しない場合は空のリストを返す
  }

  /* UtilDateのリストから文字列取得してListにして返す
   * @param List<dynamic> numberList 番号のリスト
   * @param List<String> utilDataArray utilDataのリスト
   * @return 選択肢文字列のList
  */
  List<String>? getUtilDateListGetter(List<dynamic> numberList, List<String> utilDataArray) {
    List<String> utilDataListForReturn = [];

    for (var item in numberList) {
      utilDataListForReturn.add(utilDataArray[item]);
    }
    return utilDataListForReturn;
  }

//サブコレクションを実装　code_languagesVal, //経験言語 String → ArrayList test
  Future<void> addUser(int idVal, String first_nameVal, String last_nameVal,
      int ageVal, String nearest_station_line_nameVal, String nearest_station_nameVal,
      List<int> team_roleVal,List<int> team_role_yearsVal, List<int> code_languagesVal,List<int> code_languages_yearsVal,
      List<int> processVal,List<int> process_experienceVal, List<int> db_experienceVal,List<int> db_experience_yearsVal,
      List<int> os_experienceVal, List<int> os_experience_yearsVal,
      List<int> cloud_technologyVal,List<int> cloud_technology_yearsVal,
      List<int> toolVal, List<int> tool_yearsVal

      ) async {
    try {
      DocumentReference newEngineer = await engineer.add({
        'id': idVal, //連番
        'first_name': first_nameVal, //名前
        'last_name': last_nameVal, //苗字
        'age': ageVal, //年齢
        'nearest_station_line_name': nearest_station_line_nameVal, //最寄沿線
        'nearest_station_name': nearest_station_nameVal, //最寄駅
      });
      await newEngineer.update({'team_role':team_roleVal}); //チーム役割
      await newEngineer.update({'team_role_years':team_role_yearsVal}); //チーム工程
      await newEngineer.update({'process':processVal}); //工程
      await newEngineer.update({'process_experience':process_experienceVal}); //工程経験
      await newEngineer.update({'code_languages': code_languagesVal}); //経験言語
      await newEngineer.update({'code_languages_years': code_languages_yearsVal}); //経験言語年数
      await newEngineer.update({'db_experience':db_experienceVal}); //DB経験
      await newEngineer.update({'db_experience_years':db_experience_yearsVal}); //DB工程
      await newEngineer.update({'os_experience':os_experienceVal}); //OS経験
      await newEngineer.update({'os_experience_years':os_experience_yearsVal}); //OS工程
      await newEngineer.update({'cloud_technology':cloud_technologyVal}); //クラウド技術
      await newEngineer.update({'cloud_technology_years':cloud_technology_yearsVal}); //クラウド技術経験
      await newEngineer.update({'tool':toolVal}); //ツール
      await newEngineer.update({'tool_years':tool_yearsVal}); //ツール経験

    } catch (e) {
      logger.d("Error adding document: $e");
    }
  }
}
