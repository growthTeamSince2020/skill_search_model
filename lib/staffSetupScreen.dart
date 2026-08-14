import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_search_model/common/constData.dart'; // ★ 追加
import 'package:skill_search_model/utils/uiUtils.dart';

/// 自社スタッフ招待の受諾画面
///
/// companySetupScreen.dart（新規企業オンボーディング）とは異なり、
/// - companyCodeは新規発行せず、招待ドキュメント(staffInvitations/{id})に
///   保存されている既存のcompanyCodeをそのまま引き継ぐ
/// - roleも招待ドキュメントに保存された値（デフォルトは member）を使う
///   （'admin'固定ではない）
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
  String _role = constData.roleMember; // ★ engineer -> member (定数化)

  @override
  void initState() {
    super.initState();
    _verifyInvitation();
  }

  Future<void> _verifyInvitation() async {
    try {
      final doc = await _db.collection('staffInvitations').doc(widget.invitationId).get();
      if (!doc.exists) {
        setState(() { _errorMessage = "無効な招待URLです。"; _isLoading = false; });
        return;
      }
      final data = doc.data() as Map<String, dynamic>;

      // 有効期限チェック（招待作成時に設定されている前提）
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
        _role = data['role'] ?? constData.roleMember; // ★ engineer -> member (定数化)
        _nameController.text = data['tempName'] ?? "";
        _emailController.text = data['tempEmail'] ?? "";
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _errorMessage = "データ取得エラー: $e"; _isLoading = false; });
    }
  }

  // roleに応じたデフォルト権限
  // admin相当で招待された場合はcanEdit/canExportをtrueに、それ以外(member)はfalseに。
  Map<String, dynamic> _defaultPermissionsForRole(String role) {
    if (role == constData.roleAdmin || role == constData.roleOwner) {
      return {'canEdit': true, 'canExport': true};
    }
    return {'canEdit': false, 'canExport': false};
  }

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
        // users ドキュメント作成。companyCode/roleは招待ドキュメントから引き継ぐ
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

        // 招待ドキュメントを完了状態に更新
        await _db.collection('staffInvitations').doc(widget.invitationId).update({
          'status': '登録完了',
          'registeredUid': uid,
          'registeredAt': FieldValue.serverTimestamp(),
        });

        // userMappings コレクションの作成
        await _db.collection('userMappings').doc(email).set({
          'email': email,
          'companyCode': _companyCode,
          'uid': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Firestoreへの書き込みに失敗した場合はAuthユーザーも削除してロールバックを試みる
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
          title: const Text('登録が完了しました'),
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
      UIUtils.showResultDialog(context, title: '認証エラー', message: msg, isError: true);
    } catch (e) {
      UIUtils.showResultDialog(context, title: 'エラー', message: e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(title: const Text('アカウント登録'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: _errorMessage != null ? _buildErrorView() : _buildSetupForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Column(
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 60),
        const SizedBox(height: 16),
        Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 24),
        ElevatedButton(onPressed: () => Navigator.pushReplacementNamed(context, '/'), child: const Text('ログイン画面へ')),
      ],
    );
  }

  Widget _buildSetupForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('アカウント登録', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('所属企業: $_companyName', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        UIUtils.buildFormSection(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildField('氏名', _nameController, Icons.person, '例：山田 太郎'),
                const SizedBox(height: 16),
                _buildField('メールアドレス', _emailController, Icons.email, 'example@mail.com'),
                const SizedBox(height: 16),
                _buildPasswordField('ログインパスワード設定', _passwordController, '8文字以上'),
                const SizedBox(height: 16),
                _buildPasswordField('パスワード再入力', _confirmPasswordController, '確認のためもう一度'),
                const SizedBox(height: 32),
                _isSubmitting
                    ? const CircularProgressIndicator()
                    : SizedBox(
                  width: double.infinity,
                  child: UIUtils.buildPrimaryButton(label: '登録を確定する', onPressed: _completeSetup),
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            hintText: hint,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          obscureText: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock),
            hintText: hint,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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