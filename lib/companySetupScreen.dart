import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_search_model/utils/uiUtils.dart';
import 'package:skill_search_model/common/constData.dart'; // ★ 追加

class CompanySetupScreen extends StatefulWidget {
  final String companyCode;

  const CompanySetupScreen({super.key, required this.companyCode});

  @override
  State<CompanySetupScreen> createState() => _CompanySetupScreenState();
}

class _CompanySetupScreenState extends State<CompanySetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _managerNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _verifyInvitation();
  }

  // 招待コードの有効性チェック (ロジック維持)
  Future<void> _verifyInvitation() async {
    try {
      final doc = await _db.collection('companies').doc(widget.companyCode).get();
      if (!doc.exists) {
        setState(() { _errorMessage = "無効な招待URLです。"; _isLoading = false; });
        return;
      }
      final data = doc.data() as Map<String, dynamic>;

      final expiryDate = (data['expiryDate'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiryDate)) {
        setState(() { _errorMessage = "招待URLの有効期限が切れています。"; _isLoading = false; });
        return;
      }

      if (data['status'] == '登録完了') {
        setState(() { _errorMessage = "この企業は既に本登録が完了しています。"; _isLoading = false; });
        return;
      }

      setState(() {
        _companyNameController.text = data['companyName'] ?? "";
        _managerNameController.text = data['tempManagerName'] ?? "";
        _emailController.text = data['tempManagerEmail'] ?? "";
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _errorMessage = "データ取得エラー: $e"; _isLoading = false; });
    }
  }

  // 本登録実行
  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;

      // 1. Authユーザー作成
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user!.uid;

      try {
        // 2. usersドキュメント作成 (権限判定の起点となるため最優先)
        await _db.collection('users').doc(uid).set({
          'uid': uid,
          'email': email,
          'displayName': _managerNameController.text,
          'photoURL': "",
          'role': 'admin',
          'permissions': {'canEdit': true, 'canExport': true},
          'registrationDate': FieldValue.serverTimestamp(),
          'updateDate': FieldValue.serverTimestamp(),
          'companyCode': widget.companyCode,
        });

        // 3. companies更新
        await _db.collection('companies').doc(widget.companyCode).update({
          'companyName': _companyNameController.text,
          'tempManagerName': _managerNameController.text,
          'tempManagerEmail': email,
          'status': '登録完了',
          'registeredAt': FieldValue.serverTimestamp(),
        });

        // 4. userMappings作成
        await _db.collection('userMappings').doc(email).set({
          'email': email,
          'companyCode': widget.companyCode,
          'uid': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Firestore失敗時のロールバック
        await userCredential.user!.delete();
        rethrow;
      }

      if (!mounted) return;

      // ★ 登録完了ダイアログをしっかり表示
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('本登録が完了しました'),
          content: Text('ログインID: $email\nとして登録されました。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              child: const Text('はじめる'),
            ),
          ],
        ),
      );

    } on FirebaseAuthException catch (e) {
      String msg = '認証エラー (${e.code}): ${e.message}';
      await UIUtils.showResultDialog(context, title: '認証エラー', message: msg, isError: true); // ★await追加
    } catch (e) {
      await UIUtils.showResultDialog(context, title: 'エラー', message: e.toString(), isError: true); // ★await追加
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            const Icon(Icons.business_rounded, color: constData.themeGreen, size: 24),
            const SizedBox(width: 12),
            Text('企業初回登録', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(constData.cardPadding),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: _errorMessage != null ? _buildErrorView(theme) : _buildSetupForm(theme),
          ),
        ),
      ),
    );
  }

  // エラー表示 (招待無効時など)
  Widget _buildErrorView(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 60),
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 80),
        const SizedBox(height: 24),
        Text(_errorMessage!, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
        const SizedBox(height: 32),
        UIUtils.buildPrimaryButton(
          label: 'ログイン画面へ戻る',
          onPressed: () => Navigator.pushReplacementNamed(context, '/'),
          color: Colors.grey[700] ?? Colors.grey,
        ),
      ],
    );
  }

  // 入力フォーム本体
  Widget _buildSetupForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('管理者アカウントの設定', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('招待コード: ${widget.companyCode}', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        UIUtils.buildFormSection(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField('正式企業名', _companyNameController, Icons.business, '例：株式会社サンプル'),
                const SizedBox(height: 16),
                _buildField('担当責任者氏名', _managerNameController, Icons.person, '例：山田 太郎'),
                const SizedBox(height: 16),
                _buildField('管理者メールアドレス', _emailController, Icons.email, 'example@mail.com'),
                const SizedBox(height: 16),
                _buildPasswordField('ログインパスワード', _passwordController, '8文字以上'),
                const SizedBox(height: 16),
                _buildPasswordField('パスワード再入力', _confirmPasswordController, '確認のためもう一度'),
                const SizedBox(height: 32),
                _isSubmitting
                    ? const Center(child: CircularProgressIndicator())
                    : UIUtils.buildPrimaryButton(
                  label: '本登録を確定する',
                  onPressed: _completeSetup,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            hintText: hint,
          ),
          validator: (v) => (v == null || v.isEmpty) ? '入力してください' : null,
        ),
      ],
    );
  }

  Widget _buildPasswordField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          obscureText: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            hintText: hint,
          ),
          validator: (v) {
            if (v == null || v.length < 8) return '8文字以上必要です';
            if (ctrl == _confirmPasswordController && v != _passwordController.text) return 'パスワードが一致しません';
            return null;
          },
        ),
      ],
    );
  }
}