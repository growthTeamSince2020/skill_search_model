import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'firebase_options.dart';

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
  final Stream<QuerySnapshot> _usersStream =
      FirebaseFirestore.instance.collection('engineer').snapshots();
  final TextEditingController _controller = TextEditingController();
  final logger = Logger();//ロガーの宣言
  final selectedIndex = <int>{};
  String newKeyWord = "";
  String textdata = "";

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
        child: SizedBox(
          width: double.infinity,
          child: Column(
            children: <Widget>[
              TextField(
                controller: _controller,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'キーワードを入力してください。',
                ),
                // 入力内容をtextに格納
                onChanged: (value){
                  newKeyWord = value;
                },
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
                        stream: _usersStream,
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
                              DataColumn(label: Text('使用言語 経験年数')),
                            ],
                            rows: List<DataRow>.generate(
                                snapshot.data?.size as int,
                                (index) => DataRow(cells: [
                                      DataCell(Text(snapshot.data?.docs[index]
                                              ['last_name'] +
                                          snapshot.data?.docs[index]
                                              ['first_name'])),
                                      DataCell(Text(snapshot
                                          .data!.docs[index]['age']
                                          .toString())),
                                      DataCell(Text(snapshot.data?.docs[index]
                                              ['nearest_station_line_name'] +
                                          snapshot.data?.docs[index]
                                              ['nearest_station_name'])),
                                      DataCell(Text(snapshot.data?.docs[index]
                                              ['coding_languages'] +
                                          " " +
                                          snapshot
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
}
