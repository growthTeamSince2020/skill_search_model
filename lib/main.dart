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

//test
class _MyWidgetState extends State<MyWidget> {
  // final Stream<QuerySnapshot> _usersStream =
  //     FirebaseFirestore.instance.collection('engineer').snapshots();
  CollectionReference<Map<String, dynamic>> userStream =
      FirebaseFirestore.instance.collection('engineer');

  final TextEditingController _controller = TextEditingController();
  final logger = Logger(); //ロガーの宣言
  final selectedIndex = <int>{};
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
                    items: <String>['', 'java', 'C', 'C#']
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
    final CollectionReference users = FirebaseFirestore.instance.collection('engineer');

    // 検索条件のリストを作成 (必要に応じて拡張)
    // List<Query> conditions = [];
    // 検索条件を元にクエリを作成
    Query query = users;
    if (codeLanguagesDropdownSelectedValue.isNotEmpty) {
      // conditions.add(where("code_languages", isEqualTo: codeLanguagesDropdownSelectedValue));
      query = query.where("code_languages", isEqualTo: codeLanguagesDropdownSelectedValue);
    }
    if (ageDropdownSelectedValue != 0) {
      query = query.where("age", isLessThanOrEqualTo: ageDropdownSelectedValue);
    }
    // 条件が一つもない場合は、全ドキュメントを取得
    // Query query = conditions.isEmpty ? users : users.where(conditions.first);
    // conditions.skip(1).forEach((condition) => query = query.where(condition));

    return query.snapshots();
  }
  // Stream<QuerySnapshot> getStream() {
    // Stream<QuerySnapshot> _usersStream = userStream.snapshots();
    // // newKeyWordに値が設定されていなかったら_userStreamを返す
    // // newKeyWordに値が設定されていたら、newKeyWordの値でDB検索を行い取得したデータを返す
    // //TODO:検索条件編集フラグをみて（編集されたらTURE）検索をかける
    // //条件がデェフォルトでないもののみを検索条件として追加したい
    // //それぞれの検索フォームの検索条件フラグをみて、ひとつ一つ確認して追加する？
    // //userStreamのwere文の追加の仕方が不明。。
    // bool serachFlag = false;
    // if (!codeLanguagesDropdownSelectedValue.isEmpty || ageDropdownSelectedValue != 0) {
    //   serachFlag = true;
    // }
    // if (serachFlag) {
    //   //TODO：検索条件複数パターンをここに記載したいが、そもそも可変式条件はできるのか？
    //
    //   _usersStream = userStream
    //       .where("code_languages", isEqualTo: codeLanguagesDropdownSelectedValue)
    //       .where("age", isEqualTo: ageDropdownSelectedValue)
    //       .snapshots();
    //   return _usersStream;
    // } else {
    //   _usersStream = userStream.snapshots();
    //   return _usersStream;
    // }

  //   if (newKeyWord != "") {
  //     //検索条件記載する
  //     // final Stream<QuerySnapshot> searchData = _engineer.where('last_name', isEqualTo: newKeyWord).snapshots();
  //     // _usersStream = userStream
  //     //     .orderBy("last_name")
  //     //     .startAt([textdata]).endAt([textdata + '\uf8ff']).snapshots();
  //     //検索条件フォームをとってきて、検索実行
  //     //プルダウンの
  //     return _usersStream;
  //   }
  //   return _usersStream;
  // }

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
    userStream.add({
      'id': idVal, //連番
      'first_name': first_nameVal, //名前
      'last_name': last_nameVal, //苗字
      'age': ageVal, //年齢
      'nearest_station_line_name': nearest_station_line_nameVal, //最寄沿線
      'nearest_station_name': nearest_station_nameVal, //最寄駅
      //'coding_languages': coding_languagesVal, //経験言語
      'code_languages': code_languagesVal, //経験言語
      'years_of_experience': years_of_experienceVal //エンジニア経験年数
    });
  }
}
