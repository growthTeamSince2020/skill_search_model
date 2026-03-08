import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'common/firebaseOptions.dart';
import 'loginScreen.dart';
import 'menuScreen.dart';

// アプリの起動時に最初に実行されるメイン関数
void main() async {
  // Flutterのウィジェットの初期化を確実に行う
  WidgetsFlutterBinding.ensureInitialized();

  // Firebaseの初期化（プラットフォームごとの設定を読み込む）
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // RiverpodのProviderScopeでアプリを包み、状態管理を有効にして起動
  runApp(const ProviderScope(child: MyApp()));
}

// --- Providers & Models (状態管理とデータモデル) ---

// Firebase Authのログイン状態（ログイン中か未ログインか）を監視するプロバイダー
final authStateProvider = StreamProvider<User?>((ref) {
  // ユーザーの認証状態が変化するたびに最新情報を流す
  return FirebaseAuth.instance.authStateChanges();
});

// アプリ内で利用するユーザー情報のデータモデル
class AppUser {
  final String uid;         // ユーザー固有ID
  final String role;        // 権限ロール（admin, editor, viewerなど）
  final Map<String, dynamic> permissions; // 詳細な操作権限

  AppUser({required this.uid, required this.role, required this.permissions});

  // Firestoreのデータ（Map形式）からAppUserクラスのインスタンスを作成するファクトリメソッド
  factory AppUser.fromMap(Map<String, dynamic> data) {
    // 権限データがMap形式かチェックし、不正ならデフォルト値を設定
    final Map<String, dynamic> rawPermissions = data['permissions'] is Map
        ? Map<String, dynamic>.from(data['permissions'])
        : {'canEdit': false, 'canExport': false};

    return AppUser(
      uid: data['uid'] ?? '',
      role: data['role'] ?? 'viewer',
      permissions: rawPermissions,
    );
  }
}

// Firestoreにあるユーザー詳細ドキュメントをリアルタイムで取得するプロバイダー
final appUserProvider = StreamProvider<AppUser?>((ref) {
  // まずログイン状態（authStateProvider）を監視
  final authUser = ref.watch(authStateProvider).value;

  // 未ログインならnullを流すストリームを返す
  if (authUser == null) return Stream.value(null);

  // ログイン中なら、Firestoreの 'users' コレクションから該当UIDのドキュメントを購読
  return FirebaseFirestore.instance
      .collection('users')
      .doc(authUser.uid)
      .snapshots()
      .map((snap) {
    // ドキュメントが存在しない場合はnullを返す
    if (!snap.exists) return null;
    // データをAppUserモデルに変換して返す
    return AppUser.fromMap(snap.data()!);
  });
});

// --- Main App Widget (アプリ全体の構造) ---

// Riverpodの機能を使うため ConsumerWidget を継承
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ログイン状態を監視（変化があれば自動で再描画される）
    final authState = ref.watch(authStateProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false, // デバッグラベルを非表示
      theme: ThemeData(
        useMaterial3: true,              // Material 3 デザインを有効化
        colorSchemeSeed: const Color(0xFF2E7D32), // 緑色をベースカラーに設定
        brightness: Brightness.light,    // ライトモード
        fontFamily: 'sans-serif',        // フォントをサンセリフ体に設定
      ),
      // ログイン状態に応じて表示する画面を分岐
      home: authState.when(
        // データが取得できた場合
        data: (user) => user != null ? const MenuScreen() : const LoginScreen(),
        // 読み込み中の表示
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        // エラー発生時の表示
        error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      ),
    );
  }
}