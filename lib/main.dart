import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:skill_search_model/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    const MyApp(),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyWidget(),
    );
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  final CollectionReference engineer = FirebaseFirestore.instance.collection('engineer');

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
                          addUser(i, "太郎", "遠藤", 30, "西武新宿線", "所沢", "java", 4);
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
                              scrollDirection: Axis.horizontal, //スクロールの方向、水平
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('氏名')),
                                  DataColumn(label: Text('年齢')),
                                  DataColumn(label: Text('最寄駅')),
                                  // DataColumn(label: Text('使用言語 経験年数')),
                                  DataColumn(label: Text('使用言語')),
                                  DataColumn(label: Text('経験年数')),
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
                                          DataCell(Text(
                                              snapshot.data?.docs[index]
                                                  ['code_languages'])),
                                          DataCell(Text(snapshot
                                                  .data!
                                                  .docs[index]
                                                      ['years_of_experience']
                                                  .toString() +
                                              "年")),
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

  Future<void> addUser(
      int idVal,
      String first_nameVal,
      String last_nameVal,
      int ageVal,
      String nearest_station_line_nameVal,
      String nearest_station_nameVal,
      // String coding_languagesVal,
      String code_languagesVal,
      int years_of_experienceVal) async {
    engineer.add({
      'id': idVal, //連番
      'first_name': first_nameVal, //名前
      'last_name': last_nameVal, //苗字
      'age': ageVal, //年齢
      'nearest_station_line_name': nearest_station_line_nameVal, //最寄沿線
      'nearest_station_name': nearest_station_nameVal, //最寄駅
      'code_languages': code_languagesVal, //経験言語
      'years_of_experience': years_of_experienceVal //エンジニア経験年数
    });
  }
}
