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

  // Googleログイン
  Future<void> _loginWithGoogle() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final provider = GoogleAuthProvider();
      provider.setCustomParameters({'prompt': 'select_account'});
      await FirebaseAuth.instance.signInWithPopup(provider);
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        _showSnackBar('Googleログイン失敗 [${e.code}]: ${e.message}');
      }
      if (e.code == 'popup-blocked' || e.code == 'popup-closed-by-user') {
        try {
          final provider = GoogleAuthProvider();
          provider.setCustomParameters({'prompt': 'select_account'});
          await FirebaseAuth.instance.signInWithRedirect(provider);
        } catch (_) {}
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(constData.cardPadding),
            child: Column(
              children: [
                // アイコンサイズを少し調整（タイトルの大きさに合わせる）
                Icon(Icons.directions_run_rounded, size: 90, color: theme.primaryColor),

                // ★ headlineLarge を適用してタイトルを大きく表示
                Text(
                  constData.systemName,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: theme.primaryColor,
                    letterSpacing: 1.2, // ロゴらしく少し文字間を広げる
                  ),
                ),
                const SizedBox(height: 40),

                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'メールアドレス'),
                ),
                const SizedBox(height: constData.elementSpacing),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'パスワード'),
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/forgot_password'),
                    child: Text(
                      'パスワードを忘れた方はこちら',
                      style: TextStyle(
                          fontSize: constData.fontSizeSmall,
                          color: Colors.grey[600]
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                if (_isLoading)
                  const CircularProgressIndicator()
                else ...[
                  ElevatedButton(
                    onPressed: _loginWithEmail,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54), // 高さを少し出し押しやすく
                    ),
                    child: const Text('ログイン'),
                  ),
                  const SizedBox(height: 24),
                  Text('または', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 24),

                  OutlinedButton.icon(
                    onPressed: _loginWithGoogle,
                    icon: SizedBox(
                      width: 20,
                      height: 20,
                      child: Image.network(
                        'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                        loadingBuilder: (context, child, progress) => progress == null ? child : const SizedBox(),
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),
                    label: const Text('Googleでサインイン'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(constData.borderRadius)
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 60),
                Text(
                  'Version ${constData.systemVersion}',
                  style: TextStyle(
                      color: Colors.grey,
                      fontSize: constData.fontSizeSmall
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}