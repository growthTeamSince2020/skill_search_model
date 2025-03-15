import 'dart:async';
import 'dart:js_util';
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
  String newKeyWord = "";//キーワードテキスト入力
  String textdata = "";//キーワードテキスト入力保持
  String codeLanguagesDropdownSelectedValue = "";//言語選択条件値保持
  List<String> codeLanguagesSelectItems = [];//言語選択条件リスト
  int ageDropdownSelectedValue = 0;//年齢選択条件値保持

  /* 検索一覧用　*/
  List<String> processItem = [];//工程取得リスト
  List<String> teamRoleItem = [];//チーム役割取得リスト
  List<String> codeLanguagesItems = [];//経験言語取得リスト
  List<String> dbExperienceItem = [];//DB取得リスト
  List<String> osExperienceItem = [];//OS取得リスト
  List<String> cloudTechnologyItems = [];//クラウド取得リスト
  List<String> toolItem = [];//ツール取得リスト

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  void initState() {
    _fetchData(); // 別メソッドで非同期処理を実行
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スキル検索モデル'),
      ),
      body: Container(
        margin: EdgeInsets.all(50),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'キーワードを入力してください。',
                ),
                // 入力内容をtextに格納
                onChanged: (value) {
                  newKeyWord = value;
                },
              ),
              Row(
                children: [
                  //プルダウン　経験言語
                  DropdownButton<String>(
                    value: codeLanguagesDropdownSelectedValue,
                    onChanged: (String? value) {
                      // selectedValue = value!;
                      setState(() {
                        codeLanguagesDropdownSelectedValue = value!;
                        logger.d("'プルダウン押下　値変更: ${value}'");
                      });
                    },

                    //TODO:別リストをどこかで持ちたい→テーブル化→汎用テーブル
                    items: codeLanguagesSelectItems
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(width: 10),
                  //プルダウン　年齢
                  DropdownButton<int>(
                    value: ageDropdownSelectedValue,
                    //TODO:別リストをどこかで持ちたい→テーブル化→汎用テーブル　
                    items: [
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
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        fixedSize: const Size(75, 25)),
                    child: const Text('検索'),
                    onPressed: () {
                      setState(() {
                        textdata = newKeyWord;
                        logger.d("'検索ボタン押下　キーワード: ${textdata}'");
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
                            return Text('Something went wrong');
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text("Loading");
                          }

                          return SingleChildScrollView(
                              scrollDirection: Axis.vertical, //スクロールの方向、垂直

                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('氏名')),
                                  DataColumn(label: Text('年齢')),
                                  DataColumn(label: Text('最寄駅')),
                                  // DataColumn(label: Text('使用言語 経験年数')),
                                  DataColumn(label: Text('言語')),
                                  // DataColumn(label: Text('言語経験')),
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
                                      DataCell(
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children:
                                          (getUtilDateListGetter(snapshot.data?.docs[index]['code_languages'], codeLanguagesItems)  as List<String>).map((language) => Text(language.toString())).toList(),
                                        ),
                                      ),
                                    ])),
                              ));
                        })),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Stream<QuerySnapshot> getStream() {
    // 検索条件を元にクエリを作成
    // TODO:Firebaseのインデックス管理は下記の記載順と同じにする
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
    List<String> processItemResult = await getStringListFromFirestore("utilData", "code_languages_item", "code_languages", false);//工程取得リスト
    List<String> teamRoleItemResult = await getStringListFromFirestore("utilData", "code_languages_item", "code_languages", false);//チーム役割取得リスト
    List<String> codeLanguagesItemResults = await getStringListFromFirestore("utilData", "code_languages_item", "code_languages", false);//経験言語取得リスト
    List<String> dbExperienceItemResult = await getStringListFromFirestore("utilData", "code_languages_item", "code_languages", false);//DB取得リスト
    List<String> osExperienceItemResult = await getStringListFromFirestore("utilData", "code_languages_item", "code_languages", false);//OS取得リスト
    List<String> cloudTechnologyItemResults = await getStringListFromFirestore("utilData", "code_languages_item", "code_languages", false);//クラウド取得リスト
    List<String> toolItemResult = await getStringListFromFirestore("utilData", "code_languages_item", "code_languages", false);//ツール取得リスト
    setState(() {
      codeLanguagesSelectItems = codeLanguagesSelectItemsResult;//言語選択プルダウン
      codeLanguagesItems = codeLanguagesResult;//言語リスト


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
        print("Document does not exist");
      }
    } catch (e) {
      print("Error getting document: $e");
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
      print(utilDataArray[item]);
      utilDataListForReturn.add(utilDataArray[item]);
    }
    return utilDataListForReturn;
  }

//サブコレクションを実装　code_languagesVal, //経験言語 String → ArrayList test
  Future<void> addUser(int idVal, String first_nameVal, String last_nameVal,
      int ageVal, String nearest_station_line_nameVal, String nearest_station_nameVal,
      List<int> team_roleVal,List<int> team_role_yearsVal, List<int> code_languagesVal,List<int> code_languages_yearsVal,
      List<int> processVal,List<int> process_yearsVal, List<int> db_experienceVal,List<int> db_experience_yearsVal,
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
      await newEngineer.update({'process_years':process_yearsVal}); //工程経験
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
      print('Error adding code_language or code_languages: $e');
    }
  }

}
