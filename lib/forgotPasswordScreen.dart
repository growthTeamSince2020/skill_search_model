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

  // パスワード再設定メール送信ロジック (仕様維持)
  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      await UIUtils.showResultDialog(
          context,
          title: '入力エラー',
          message: 'メールアドレスを入力してください',
          isError: true
      );
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
        message: 'パスワード再設定用のメールを送信しました。\nメール内のリンクから新しいパスワードを設定してください。',
        isError: false,
      );
      if (mounted) Navigator.pop(context); // ログイン画面に戻る
    } catch (e) {
      if (!mounted) return;
      await UIUtils.showResultDialog(
          context,
          title: 'エラー',
          message: '送信に失敗しました。メールアドレスが正しく登録されているか確認してください。',
          isError: true
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Row(
          children: [
            const Icon(Icons.lock_open_rounded, color: constData.themeGreen, size: 24),
            const SizedBox(width: 12),
            Text(
              'パスワード再設定',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.withOpacity(0.15), height: 1.0),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(constData.cardPadding),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // アイコンエリア
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: constData.themeGreen.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_reset_rounded, size: 64, color: constData.themeGreen),
                ),
                const SizedBox(height: 24),

                Text(
                  'パスワードをお忘れですか？',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  '登録したメールアドレスを入力してください。\nパスワード再設定用のリンクをお送りします。',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54, height: 1.5),
                ),
                const SizedBox(height: 32),

                // 入力カードエリア
                UIUtils.buildFormSection(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'メールアドレス',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'example@skirun.jp',
                          prefixIcon: Icon(Icons.email_outlined, size: 20),
                        ),
                      ),
                      const SizedBox(height: 32),

                      _isLoading
                          ? const Center(child: CircularProgressIndicator(color: constData.themeGreen))
                          : UIUtils.buildPrimaryButton(
                        label: '再設定メールを送信',
                        onPressed: _sendResetEmail,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: Colors.black54),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_back, size: 16),
                      SizedBox(width: 8),
                      Text('ログイン画面に戻る', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
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