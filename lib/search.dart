import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:skill_search_model/firebase_options.dart';

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final CollectionReference engineer = FirebaseFirestore.instance.collection('engineer');
  final CollectionReference utilData = FirebaseFirestore.instance.collection('utilData');

  final TextEditingController _controller = TextEditingController();
  final logger = Logger(); //ロガーの宣言
  final selectedIndex = <int>{};
  final String utilDataSelectedType = "code_languages";
  List<String> codeLanguagesItems = [];
  String newKeyWord = "";
  String textdata = "";
  String codeLanguagesDropdownSelectedValue = "";
  int ageDropdownSelectedValue = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  void initState() {
    super.initState();
    // Firestoreからデータを取得してcodeLanguagesItemsリストに格納
    FirebaseFirestore.instance
        .collection('utilData')
        .where("type", isEqualTo: utilDataSelectedType)
        .orderBy("sortNo")
        .get()
        .then((QuerySnapshot querySnapshot) {
      List<dynamic> allData = querySnapshot.docs.map((doc) => doc.data()).toList();
      setState(() {
        // 例: ドキュメントの"name"フィールドをプルダウンのアイテムとする
        codeLanguagesItems = allData.map((data) => data['val'] as String).toList();
        logger.d("チェック: ${codeLanguagesItems}'");
      });
    });
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
                    items: codeLanguagesItems
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
                      DropdownMenuItem(value: 0,child: Text('')),
                      DropdownMenuItem(value: 30,child: Text('30歳以下')),
                      DropdownMenuItem(value: 40,child: Text('40歳以下')),
                      DropdownMenuItem(value: 50,child: Text('50歳以下')),
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
                              ['PM', 'リーダー', '技術支援'],<int>[1, 5, 6],//チーム役割
                              ['C', 'JAVA', 'C#'] ,<int>[1, 5, 6],//経験言語
                              ['要件定義', '基本設計', '詳細設計', 'コ ーディング','単体テスト','結合テスト'] ,<int>[1, 5, 6, 5, 6],//工程　
                              ['Oracle', 'postgresql', 'MongoDB'],<int>[1, 5, 6],//DB経
                              ['Windows', 'macOS', 'Unix', 'Linux'],<int>[1, 5, 6, 5],//OS経験
                              ['AWS', 'Azure', 'GoogleCloud'],<int>[1, 5, 6],
                              ['Eclipse', 'VSCode', 'Git'],<int>[1, 5, 6]);//クラウド経験
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
                                  DataColumn(label: Text('言語経験')),
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
                                          children: (snapshot.data?.docs[index]['code_languages'] as List<dynamic>).map((language) => Text(language)).toList(),

                                        ),
                                      ),
                                      //TODO:!rows.any((DataRow row) => row.cells.length != columns.length)　のエラー箇所
                                      DataCell(
                                        // Column(
                                        //   crossAxisAlignment: CrossAxisAlignment.start,
                                        //   children: (snapshot.data?.docs[index]['code_languages_years'] as List<dynamic>).map((language) => Text(language.toString())).toList(),
                                        // ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children:
                                            getUtilDateListGetter((snapshot.data?.docs[index]['code_languages_years'] as List<dynamic>)).map((language) => Text(language.toString())).toList(),
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

  /* UtilDateのリストから文字列取得してListにして返す
   * @param int utilDataArrayNumber Listの番号
   * @param String field　ドキュメントのフィールド名
   * @return 選択肢文字列のList
  */
  List<String>? getUtilDateListGetter(List<dynamic> utilDataArrayNumberList,String field) {
    List<String>? utilDataListForReturn;
    for (var item in utilDataArrayNumberList) {
      utilDataListForReturn?.add(getUtilDateGetter(item,field));
    }
    return utilDataListForReturn;
  }

  /* UtilDateのリストから文字列取得し返す
   * @param int utilDataArrayNumber Listの番号
   * @param String field　ドキュメントのフィールド名
   * @return 選択肢文字列
  */
  String getUtilDateGetter(int utilDataArrayNumber,String field) {
    Query query = utilData;
    List<String> fieldList = query.where(field) as List<String>;
    return fieldList[utilDataArrayNumber];
  }

//サブコレクションを実装　code_languagesVal, //経験言語 String → ArrayList test
  Future<void> addUser(int idVal, String first_nameVal, String last_nameVal,
      int ageVal, String nearest_station_line_nameVal, String nearest_station_nameVal,

      //--追加中
      List<String> team_roleVal,List<int> team_role_yearsVal, List<String> code_languagesVal,List<int> code_languages_yearsVal,
      List<String> processVal,List<int> process_yearsVal, List<String> db_experienceVal,List<int> db_experience_yearsVal,
      List<String> os_experienceVal, List<int> os_experience_yearsVal,
      List<String> cloud_technologyVal,List<int> cloud_technology_yearsVal,
      List<String> toolVal, List<int> tool_yearsVal

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
