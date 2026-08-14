import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_search_model/common/constData.dart';
import 'package:skill_search_model/utils/uiUtils.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      UIUtils.showResultDialog(context, title: '入力エラー', message: 'メールアドレスを入力してください', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // Firebaseにパスワード再設定メールの送信を依頼
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;
      await UIUtils.showResultDialog(
        context,
        title: '送信完了',
        message: 'パスワード再設定用のメールを送信しました。メール内のリンクから新しいパスワードを設定してください。',
        isError: false,
      );
      Navigator.pop(context); // ログイン画面に戻る
    } catch (e) {
      if (!mounted) return;
      UIUtils.showResultDialog(context, title: 'エラー', message: '送信に失敗しました。アドレスが正しいか確認してください。', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('パスワード再設定')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_reset, size: 64, color: constData.themeGreen),
              const SizedBox(height: 16),
              const Text(
                '登録したメールアドレスを入力してください。\nパスワード再設定用のリンクをお送りします。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'メールアドレス',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                width: double.infinity,
                child: UIUtils.buildPrimaryButton(
                  label: '再設定メールを送信',
                  onPressed: _sendResetEmail,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('戻る'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}