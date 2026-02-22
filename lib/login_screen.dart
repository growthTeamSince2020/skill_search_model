import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  /// Googleアカウントでログイン (Web対応のポップアップ方式)
  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // Firebase AuthのGoogleプロバイダーを作成
      final provider = GoogleAuthProvider();

      // カスタムパラメータ（必要に応じて、毎回アカウント選択を強制させる設定など）
      provider.setCustomParameters({
        'prompt': 'select_account'
      });

      // Web用のポップアップ認証を実行
      await FirebaseAuth.instance.signInWithPopup(provider);

      // 成功後の画面切り替えは main.dart の authStateProvider が自動で行います
    } catch (e) {
      _showSnackBar('Googleログイン失敗: $e');
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // アプリロゴ（検索アイコン）
                const Icon(Icons.search_rounded, size: 100, color: Colors.green),
                const SizedBox(height: 16),

                // アプリ名
                const Text(
                  'Skill Search System',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'スキル検索モデル',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 60),

                // ログインボタン領域
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.green)
                else
                  Column(
                    children: [
                      const Text(
                        'Googleアカウントでログインしてください',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),

                      // Googleログインボタン
                      OutlinedButton.icon(
                        onPressed: _loginWithGoogle,
                        icon: Image.network(
                          'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                          height: 24,
                          width: 24,
                          errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.account_circle, color: Colors.grey),
                        ),
                        label: const Text(
                          'Googleでサインイン',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 54),
                          side: const BorderSide(color: Colors.black12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // 丸みのあるデザイン
                          ),
                          backgroundColor: Colors.white,
                          elevation: 2, // 軽く影をつけてボタンらしく
                          shadowColor: Colors.black26,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 100), // 下部の余白
              ],
            ),
          ),
        ),
      ),
    );
  }
}