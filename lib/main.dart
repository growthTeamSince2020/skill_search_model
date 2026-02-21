import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_search_model/search.dart';

import 'engineerInputForm.dart';
import 'common/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        // 全体の背景を真っ白に設定して濁りを解消
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const MyWidget(),
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
    {'icon': Icons.person_add, 'title': '技術者登録', 'page': EngineerInputForm(), 'color': Colors.red},
    {'icon': Icons.person_remove, 'title': '技術者削除', 'color': Colors.green},
    {'icon': Icons.search, 'title': '検索一覧', 'page': const SearchPage(), 'color': Colors.blue},
    {'icon': Icons.dashboard, 'title': 'パネル', 'color': Colors.orange},
    {'icon': Icons.hail_outlined, 'title': '予備1', 'color': Colors.purple},
    {'icon': Icons.ac_unit, 'title': '予備2', 'color': Colors.teal},
    {'icon': Icons.access_alarm, 'title': '予備3', 'color': Colors.brown},
    {'icon': Icons.drive_folder_upload_rounded, 'title': 'インポート', 'color': Colors.cyan},
    {'icon': Icons.folder_shared_rounded, 'title': 'エクスポート', 'color': Colors.amber},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        toolbarHeight: 70, // 85からさらに縮小（これ以下だと24pxの文字が窮屈になります）
        leading: IconButton(
          icon: const Icon(Icons.menu_open_rounded, color: Colors.white, size: 26),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // サブタイトルを極小にして高さを稼ぐ
            Text(
              'SKILL SEARCH',
              style: TextStyle(
                fontSize: 8,
                letterSpacing: 4,
                color: Colors.white.withOpacity(0.7),
                fontWeight: FontWeight.w300,
              ),
            ),
            // 余白を最小化
            const SizedBox(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2), // パディングもスリムに
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
              ),
              child: const Text(
                'スキル検索モデル',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF2E7D32),
                Color(0xFFD4FF00),
              ],
              stops: [0.2, 1.0],
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Text('メニュー', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('設定'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(

              title: const Text('ヘルプ'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 5.0, // 左右の隙間をわずかに開ける
          mainAxisSpacing: 5.0,  // 上下の隙間をわずかに開ける
          childAspectRatio: 1.25,
        ),
        itemCount: menuItems.length,
        itemBuilder: (context, index) => AnimatedMenuTile(item: menuItems[index]),
      ),
    );
  }
}

class AnimatedMenuTile extends StatefulWidget {
  final Map<String, dynamic> item;
  const AnimatedMenuTile({super.key, required this.item});
  @override
  State<AnimatedMenuTile> createState() => _AnimatedMenuTileState();
}

class _AnimatedMenuTileState extends State<AnimatedMenuTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.item['color'] as Color;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        if (widget.item['page'] != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => widget.item['page']));
        }
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Center(
          // FittedBoxを入れることで、グリッドが狭くなっても
          // 円形ボタンがはみ出さずに枠いっぱいに広がります
          child: FittedBox(
            fit: BoxFit.contain,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(_isPressed ? 0.3 : 0.15),
                    blurRadius: _isPressed ? 8 : 15,
                    offset: Offset(0, _isPressed ? 3 : 6),
                  ),
                ],
                border: Border.all(color: color.withOpacity(0.1), width: 1),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.item['icon'],
                    size: 42.0, // アイコンを少し強調
                    color: color,
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      widget.item['title'],
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontSize: 17.0, // 少し大きく
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                        letterSpacing: -1.0, // 文字間隔を詰めて円の中に収める
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}