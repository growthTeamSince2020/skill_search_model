import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_search_model/search.dart';
import 'package:skill_search_model/utils/objectsUtils.dart';
import 'package:skill_search_model/utils/uiUtils.dart';

import 'engineerInputForm.dart';
import 'common/firebase_options.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E7D32),
        brightness: Brightness.light,
        fontFamily: 'sans-serif',
      ),
      home: authState.when(
        data: (user) => user != null ? const MainShell() : const LoginScreen(),
        loading: () =>
        const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) =>
            Scaffold(body: Center(child: Text('Error: $err'))),
      ),
    );
  }
}

class AppUser {
  final String uid;
  final String role;
  final Map<String, dynamic> permissions;

  AppUser({required this.uid, required this.role, required this.permissions});

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      uid: data['uid'] ?? '',
      role: data['role'] ?? 'viewer',
      permissions:
      data['permissions'] ?? {'canEdit': false, 'canExport': false},
    );
  }
}

// Firestoreからユーザー情報を取得するProvider
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(authUser.uid)
      .snapshots()
      .map((snap) {
    if (!snap.exists) {
      return null;
    }
    return AppUser.fromMap(snap.data()!);
  });
});

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;
  bool _isSidebarVisible = true;

  final List<Map<String, dynamic>> menuItems = [
    {'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard, 'title': 'ダッシュボード'},
    {'icon': Icons.person_add_alt_1_outlined, 'activeIcon': Icons.person_add_alt_1, 'title': '技術者登録', 'page': EngineerInputForm(), 'roleRequired': 'editor'},
    {'icon': Icons.search_rounded, 'activeIcon': Icons.search_rounded, 'title': 'スキル検索', 'page': const SearchPage()},
    {'icon': Icons.analytics_outlined, 'activeIcon': Icons.analytics, 'title': '統計データ'},
    {'icon': Icons.cloud_download_outlined, 'activeIcon': Icons.cloud_download, 'title': 'インポート', 'roleRequired': 'admin'},
    {'icon': Icons.cloud_upload_outlined, 'activeIcon': Icons.cloud_upload, 'title': 'エクスポート', 'roleRequired': 'admin'},
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final appUserAsync = ref.watch(appUserProvider);

    return appUserAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('エラー: $err'))),
      data: (appUser) {
        // ObjectUtilsを使ってフィルタリング
        final filteredMenu = menuItems.where((item) =>
            ObjectUtils.canAccessMenuItem(appUser, item)
        ).toList();

        final safeIndex = _selectedIndex >= filteredMenu.length ? 0 : _selectedIndex;

        return Scaffold(
          body: Row(
            children: [
              if (_isSidebarVisible)
                SizedBox(
                  width: 250,
                  child: NavigationDrawer(
                    selectedIndex: safeIndex,
                    onDestinationSelected: (index) {
                      setState(() => _selectedIndex = index);
                      if (filteredMenu[index]['page'] != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => filteredMenu[index]['page']));
                      }
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 32, 16, 20),
                        child: Row(
                          children: [
                            const Icon(Icons.hub_rounded, color: Color(0xFF2E7D32), size: 32),
                            const SizedBox(width: 12),
                            Text('Skill Hub', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      ...filteredMenu.map((item) => NavigationDrawerDestination(
                        icon: Icon(item['icon']),
                        selectedIcon: Icon(item['activeIcon']),
                        label: Text(item['title']),
                      )),
                      const Divider(indent: 28, endIndent: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                            child: user?.photoURL == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(user?.displayName ?? 'ユーザー名なし', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            UIUtils.getRoleDisplayName(appUser?.role),
                            style: UIUtils.getRoleTextStyle(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: TextButton.icon(
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          icon: const Icon(Icons.logout, size: 18, color: Colors.red),
                          label: const Text('ログアウト', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Container(
                  color: const Color(0xFFF8FAFB),
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        floating: true,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        surfaceTintColor: Colors.transparent,
                        leading: IconButton(
                          icon: const Icon(Icons.menu_open_rounded),
                          onPressed: () => setState(() => _isSidebarVisible = !_isSidebarVisible),
                        ),
                        title: Text(filteredMenu.isEmpty ? '' : filteredMenu[safeIndex]['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        actions: [
                          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
                          const SizedBox(width: 16),
                        ],
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.all(24),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 300,
                            mainAxisSpacing: 20,
                            crossAxisSpacing: 20,
                            childAspectRatio: 1.5,
                          ),
                          delegate: SliverChildBuilderDelegate(
                                (context, index) => UIUtils.buildCommonCard( // UIUtilsを使用
                              title: filteredMenu[index]['title'],
                              icon: filteredMenu[index]['icon'],
                              onTap: () {
                                if (filteredMenu[index]['page'] != null) {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => filteredMenu[index]['page']));
                                }
                              },
                            ),
                            childCount: filteredMenu.length,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}