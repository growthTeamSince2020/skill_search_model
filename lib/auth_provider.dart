/**
 * 認証状態の管理(ログイン状態をアプリ全体で監視できるようにする)
 */
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Firebase Authのインスタンスを提供するProvider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// ログイン状態（Userオブジェクト）を監視するStreamProvider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});