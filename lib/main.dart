import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:skill_search_model/search.dart';

import 'engineerRegistrationForm.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> menuItems = [
    {'icon': Icons.person_add, 'title': '技術者登録','page':EngineerRegistrationForm(), 'color': Colors.red}, // 色を追加
    {'icon': Icons.person_remove, 'title': '技術者削除', 'color': Colors.green}, // 色を追加
    {'icon': Icons.search, 'title': '検索一覧', 'page': SearchPage(), 'color': Colors.blue}, // 色を追加
    {'icon': Icons.dashboard, 'title': 'ダッシュボード', 'color': Colors.orange}, // 色を追加
    {'icon': Icons.hail_outlined, 'title': '予備1', 'color': Colors.purple}, // 色を追加
    {'icon': Icons.ac_unit, 'title': '予備2', 'color': Colors.teal}, // 色を追加
    {'icon': Icons.access_alarm, 'title': '予備3', 'color': Colors.brown}, // 色を追加
    {'icon': Icons.file_download, 'title': 'ファイルのエクスポート', 'color': Colors.cyan}, // 色を追加
    {'icon': Icons.file_upload, 'title': 'ファイルのインポート', 'color': Colors.lime}, // 色を追加
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('スキル検索モデル'),
        backgroundColor: Colors.blueAccent,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.black),
              child: Text(
                'メニュー',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            // ドロワー内のリストアイテムは変更なし
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.grey),
              title: const Text('設定'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.orange),
              title: const Text('ヘルプ/バージョン情報'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            // InkWell(
            //   onTap: () {
            //     Navigator.pop(context);
            //   },
            //   child: ListTile(
            //     leading: const Icon(Icons.save, color: Colors.purple),
            //     title: const Text('検索条件の保存'),
            //   ),
            // ),
            // ListTile(
            //   leading: const Icon(Icons.file_download, color: Colors.green),
            //   title: const Text('データのエクスポート'),
            //   onTap: () {
            //     Navigator.pop(context);
            //   },
            // ),
            // ListTile(
            //   leading: const Icon(Icons.file_upload, color: Colors.blueAccent),
            //   title: const Text('データのインポート'),
            //   onTap: () {
            //     Navigator.pop(context);
            //   },
            // ),
          ],
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16.0,
          mainAxisSpacing: 16.0,
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 4.0,
            child: InkWell(
              onTap: () {
                if (menuItems[index]['page'] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => menuItems[index]['page']),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${menuItems[index]['title']} を読み込み中...'),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      menuItems[index]['icon'],
                      size: 48.0,
                      color: menuItems[index]['color'], // 色を設定
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      menuItems[index]['title'],
                      style: const TextStyle(fontSize: 16.0),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}