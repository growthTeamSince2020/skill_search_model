import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

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

class _MyWidgetState extends State<MyWidget> {
  final TextEditingController _controller = TextEditingController();

  final labels = List<DataColumn>.generate(5, (int index) =>
      DataColumn(label: Text("ラベル$index")
      ), growable: false);

  final values = List<DataRow>.generate(20, (int index) {
    return DataRow(cells: [
      DataCell(Text("山田$index郎")),
      const DataCell(Text("男性")),
      const DataCell(Text("2000/10/30")),
      const DataCell(Text("東京都港区")),
      const DataCell(Text("会社員")),
    ]);
  }, growable: false);

  get columnList => labels;

  get rowList => values;

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
              const TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'キーワードを入力してください。',
                ),
              ),
              Row(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        fixedSize: const Size(75, 25)
                    ),
                    child: const Text('検索'),
                    onPressed: () {
                      //TODO;
                      //  _table(labels,values);
                      ListView(
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(columns: columnList, rows: rowList),
                          )
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
                        fixedSize: const Size(75, 25)
                    ),
                    child: const Text('クリア'),
                    onPressed: () {
                      //TODO;
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  @override
  Widget _table(List<DataColumn> columnList, List<DataRow> rowList) {
    return ListView(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(columns: columnList, rows: rowList),
        )
      ],
    );
  }
}