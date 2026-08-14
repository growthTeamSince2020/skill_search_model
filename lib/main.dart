import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

// 各画面のインポート
import 'accountManagementScreen.dart';
import 'permissionSettingsScreen.dart';
import 'common/firebaseOptions.dart';
import 'common/constData.dart';
import 'loginScreen.dart';
import 'menuScreen.dart';
import 'companySetupScreen.dart';
import 'staffSetupScreen.dart';
import 'forgotPasswordScreen.dart'; // ★ 追加

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const ProviderScope(child: MyApp()));
}

// 認証状態の監視
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// アプリ内ユーザー情報の定義
class AppUser {
  final String uid;
  final String role;
  final Map<String, dynamic> permissions;
  final String displayName;
  final String email;
  final String photoURL;
  final String companyCode;

  AppUser({
    required this.uid,
    required this.role,
    required this.permissions,
    this.displayName = '',
    this.email = '',
    this.photoURL = '',
    this.companyCode = '',
  });

  factory AppUser.fromMap(Map<String, dynamic> data) {
    final Map<String, dynamic> rawPermissions = data['permissions'] is Map
        ? Map<String, dynamic>.from(data['permissions'])
        : {'canEdit': false, 'canExport': false};

    // ★ ロールが未設定（null/空）の場合は 'member' (一般ユーザー) をデフォルトにする
    String role = data['role'] ?? constData.roleMember;
    if (role.isEmpty) role = constData.roleMember;

    return AppUser(
      uid: data['uid'] ?? '',
      role: role,
      permissions: rawPermissions,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      photoURL: data['photoURL'] ?? '',
      companyCode: data['companyCode'] ?? '',
    );
  }
}

// Firestoreのユーザー情報を監視するProvider
final appUserProvider = StreamProvider<AppUser?>((ref) {
  final authUser = ref.watch(authStateProvider).value;
  if (authUser == null) return Stream.value(null);

  return FirebaseFirestore.instance
      .collection('users')
      .doc(authUser.uid)
      .snapshots()
      .map((snap) {
    if (!snap.exists) return null;
    return AppUser.fromMap(snap.data()!);
  });
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
        colorSchemeSeed: constData.themeGreen, // テーマカラーを統一
        brightness: Brightness.light,
        fontFamily: 'sans-serif',
      ),

      // 動的ルーティングの設定
      onGenerateRoute: (settings) {
        if (settings.name == null) return null;
        final uri = Uri.parse(settings.name!);
        final path = uri.path.startsWith('/') ? uri.path : '/${uri.path}';

        // 1. アカウント一覧
        if (path == '/accounts') {
          return MaterialPageRoute(builder: (context) => const AccountManagementScreen());
        }

        // 2. 権限設定
        if (path == '/permissions') {
          return MaterialPageRoute(builder: (context) => const PermissionSettingsScreen());
        }

        // 3. パスワード再設定画面 ★ 追加
        if (path == '/forgot_password') {
          return MaterialPageRoute(builder: (context) => const ForgotPasswordScreen());
        }

        // 4. 自社スタッフ招待の受諾
        if (path.contains('staffSetup')) {
          final String? invitationId = uri.queryParameters['id'];
          if (invitationId != null) {
            return MaterialPageRoute(
              builder: (context) => StaffSetupScreen(invitationId: invitationId),
            );
          }
        }

        // 5. 新規企業オンボーディング（管理者招待用）
        if (path.contains('setup')) {
          String? code = uri.queryParameters['code'];
          if (code == null && uri.pathSegments.isNotEmpty) {
            code = uri.pathSegments.last;
          }
          if (code != null) {
            return MaterialPageRoute(
              builder: (context) => CompanySetupScreen(companyCode: code!),
            );
          }
        }
        return null;
      },

      home: authState.when(
        data: (user) => user != null ? const MenuScreen() : const LoginScreen(),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      ),
    );
  }
}