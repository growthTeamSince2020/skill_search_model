import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'common/constData.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // メールアドレスでログイン
  Future<void> _loginWithEmail() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } catch (e) {
      _showSnackBar('ログイン失敗: メールアドレスまたはパスワードが違います');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Googleログイン (既存)
  Future<void> _loginWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final provider = GoogleAuthProvider();
      provider.setCustomParameters({'prompt': 'select_account'});
      await FirebaseAuth.instance.signInWithPopup(provider);
    } on FirebaseAuthException catch (e) {
      // e.toString() だけだと原因特定できないため、code/messageを明示的に出す。
      // よくある原因:
      //  - unauthorized-domain: Firebase Console > Authentication > Settings >
      //    承認済みドメイン に現在アクセス中のドメインが登録されていない
      //  - operation-not-allowed: Sign-in method で Google プロバイダが無効
      //  - popup-blocked / popup-closed-by-user: ブラウザのポップアップブロック
      if (mounted) {
        _showSnackBar('Googleログイン失敗 [${e.code}]: ${e.message}');
      }
      // ポップアップがブロックされた場合はリダイレクト方式にフォールバック
      if (e.code == 'popup-blocked' || e.code == 'popup-closed-by-user') {
        try {
          final provider = GoogleAuthProvider();
          provider.setCustomParameters({'prompt': 'select_account'});
          await FirebaseAuth.instance.signInWithRedirect(provider);
        } catch (_) {
          // リダイレクトも失敗した場合は元のエラーメッセージのみ表示済みなので何もしない
        }
      }
    } catch (e) {
      if (mounted) _showSnackBar('Googleログイン失敗: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
              children: [
                const Icon(Icons.search_rounded, size: 80, color: Colors.green),
                const Text('Skill Search System', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 40),

                // メールアドレス入力欄
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'メールアドレス', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'パスワード', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),

                // ★ 追加：パスワード再設定リンク
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
                    child: const Text('パスワードを忘れた方はこちら', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ),
                ),

                const SizedBox(height: 16), // 間隔を調整

                if (_isLoading)
                  const CircularProgressIndicator()
                else ...[
                  ElevatedButton(
                    onPressed: _loginWithEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: const Text('ログイン'),
                  ),
                  const SizedBox(height: 24),
                  const Text('または'),
                  const SizedBox(height: 24),

                  // Googleログインボタン
                  OutlinedButton.icon(
                    onPressed: _loginWithGoogle,
                    icon: SizedBox(
                      width: 20,
                      height: 20,
                      child: Image.network(
                        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                        width: 20,
                        height: 20,
                        // 読み込み中は同じサイズのプレースホルダーを表示し、
                        // Rowの幅が確定するまでレイアウトが揺れないようにする
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return const SizedBox(width: 20, height: 20);
                        },
                        // 読み込み失敗時もサイズを確保したままアイコンを省略
                        errorBuilder: (context, error, stackTrace) =>
                        const SizedBox(width: 20, height: 20),
                      ),
                    ),
                    label: const Text(
                      'Googleでサインイン',
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  ),
                ],
                const SizedBox(height: 40),
                Text('Version ${constData.systemVersion}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}