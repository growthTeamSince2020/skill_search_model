import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_search_model/common/constData.dart';
import 'package:skill_search_model/utils/uiUtils.dart';

/// 自社スタッフ招待の受諾画面
class StaffSetupScreen extends StatefulWidget {
  final String invitationId;

  const StaffSetupScreen({super.key, required this.invitationId});

  @override
  State<StaffSetupScreen> createState() => _StaffSetupScreenState();
}

class _StaffSetupScreenState extends State<StaffSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  String _companyCode = '';
  String _companyName = '';
  String _role = constData.roleMember;

  @override
  void initState() {
    super.initState();
    _verifyInvitation();
  }

  // 招待URLの有効性チェック (仕様維持)
  Future<void> _verifyInvitation() async {
    try {
      final doc = await _db.collection('staffInvitations').doc(widget.invitationId).get();
      if (!doc.exists) {
        setState(() { _errorMessage = "無効な招待URLです。"; _isLoading = false; });
        return;
      }
      final data = doc.data() as Map<String, dynamic>;

      if (data['expiryDate'] != null) {
        final expiryDate = (data['expiryDate'] as Timestamp).toDate();
        if (DateTime.now().isAfter(expiryDate)) {
          setState(() { _errorMessage = "招待URLの有効期限が切れています。"; _isLoading = false; });
          return;
        }
      }

      if (data['status'] == '登録完了') {
        setState(() { _errorMessage = "このアカウントは既に登録が完了しています。"; _isLoading = false; });
        return;
      }

      setState(() {
        _companyCode = data['companyCode'] ?? '';
        _companyName = data['companyName'] ?? '';
        _role = data['role'] ?? constData.roleMember;
        _nameController.text = data['tempName'] ?? "";
        _emailController.text = data['tempEmail'] ?? "";
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _errorMessage = "データ取得エラー: $e"; _isLoading = false; });
    }
  }

  Map<String, dynamic> _defaultPermissionsForRole(String role) {
    if (role == constData.roleAdmin || role == constData.roleOwner) {
      return {'canEdit': true, 'canExport': true};
    }
    return {'canEdit': false, 'canExport': false};
  }

  // 本登録実行
  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user!.uid;

      try {
        // 1. users ドキュメント作成
        await _db.collection('users').doc(uid).set({
          'uid': uid,
          'email': email,
          'displayName': _nameController.text,
          'photoURL': "",
          'role': _role,
          'permissions': _defaultPermissionsForRole(_role),
          'registrationDate': FieldValue.serverTimestamp(),
          'updateDate': FieldValue.serverTimestamp(),
          'companyCode': _companyCode,
        });

        // 2. 招待ドキュメント更新
        await _db.collection('staffInvitations').doc(widget.invitationId).update({
          'status': '登録完了',
          'registeredUid': uid,
          'registeredAt': FieldValue.serverTimestamp(),
        });

        // 3. userMappings 作成
        await _db.collection('userMappings').doc(email).set({
          'email': email,
          'companyCode': _companyCode,
          'uid': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        try {
          await userCredential.user!.delete();
        } catch (_) {}
        rethrow;
      }

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(constData.borderRadius)),
          title: const Text('登録が完了しました'),
          content: Text('ログインID: $email\nとして登録されました。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              child: const Text('はじめる', style: TextStyle(fontWeight: FontWeight.bold, color: constData.themeGreen)),
            ),
          ],
        ),
      );
    } on FirebaseAuthException catch (e) {
      String msg = '認証エラー (${e.code}): ${e.message}';
      await UIUtils.showResultDialog(context, title: '認証エラー', message: msg, isError: true);
    } catch (e) {
      await UIUtils.showResultDialog(context, title: 'エラー', message: e.toString(), isError: true);
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
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_add_rounded, color: constData.themeGreen, size: 24),
            const SizedBox(width: 12),
            Text('スタッフアカウント登録', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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

  Widget _buildSetupForm(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('プロフィールとパスワードの設定', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('所属企業: $_companyName', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        UIUtils.buildFormSection(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField('氏名', _nameController, Icons.person_outline, '例：山田 太郎'),
                const SizedBox(height: 16),
                _buildField('メールアドレス', _emailController, Icons.email_outlined, 'example@skirun.jp'),
                const SizedBox(height: 16),
                _buildPasswordField('ログインパスワード', _passwordController, '8文字以上'),
                const SizedBox(height: 16),
                _buildPasswordField('パスワード再入力', _confirmPasswordController, '確認のためもう一度'),
                const SizedBox(height: 32),
                _isSubmitting
                    ? const Center(child: CircularProgressIndicator(color: constData.themeGreen))
                    : UIUtils.buildPrimaryButton(
                    label: '登録を確定する',
                    onPressed: _completeSetup
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