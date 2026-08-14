import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_search_model/utils/uiUtils.dart';

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

  Future<void> _verifyInvitation() async {
    try {
      final doc = await _db.collection('companies').doc(widget.companyCode).get();
      if (!doc.exists) {
        setState(() { _errorMessage = "無効な招待URLです。"; _isLoading = false; });
        return;
      }
      final data = doc.data() as Map<String, dynamic>;

      // 有効期限チェック
      final expiryDate = (data['expiryDate'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiryDate)) {
        setState(() { _errorMessage = "招待URLの有効期限が切れています。"; _isLoading = false; });
        return;
      }

      // ステータスチェック
      if (data['status'] == '登録完了') {
        setState(() { _errorMessage = "この企業は既に本登録が完了しています。"; _isLoading = false; });
        return;
      }

      setState(() {
        // 実データの項目名 (tempManagerName, tempManagerEmail) から読み込み
        _companyNameController.text = data['companyName'] ?? "";
        _managerNameController.text = data['tempManagerName'] ?? "";
        _emailController.text = data['tempManagerEmail'] ?? "";
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _errorMessage = "データ取得エラー: $e"; _isLoading = false; });
    }
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final String email = _emailController.text.trim();
      final String password = _passwordController.text;

      // 1. Firebase Authにユーザーを作成 (ここでパスワードが安全に管理されます)
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user!.uid;

      // ここから先、途中で失敗したらAuthアカウントを削除してロールバックする
      try {
        // 2. users コレクションの作成を「最初に」行う
        // Firestoreのセキュリティルールは通常 users/{uid} の role を見て
        // 他コレクション(companies, userMappings)への書き込み可否を判定するため、
        // このドキュメントが無い状態で先にcompaniesを更新すると
        // permission-denied になる。そのため作成順序をここに変更。
        await _db.collection('users').doc(uid).set({
          'uid': uid,
          'email': email,
          'displayName': _managerNameController.text, // name ではなく displayName
          'photoURL': "",
          'role': 'admin', // 初回登録者は管理者
          'permissions': {
            'canEdit': true,
            'canExport': true,
          },
          'registrationDate': FieldValue.serverTimestamp(), // registrationDateを使用
          'updateDate': FieldValue.serverTimestamp(),       // updateDateを使用
          'companyCode': widget.companyCode,
        });

        // 3. companies コレクションの更新
        // 実データの tempManager... を更新し、ご指摘の registeredAt をセット
        await _db.collection('companies').doc(widget.companyCode).update({
          'companyName': _companyNameController.text,
          'tempManagerName': _managerNameController.text, // 入力された名前に更新
          'tempManagerEmail': email,                      // 入力されたメールに更新
          'status': '登録完了',
          'registeredAt': FieldValue.serverTimestamp(),   // createdAtではなくregisteredAt
        });

        // 4. userMappings コレクションの作成 (紐づけテーブル)
        await _db.collection('userMappings').doc(email).set({
          'email': email,
          'companyCode': widget.companyCode,
          'uid': uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // Firestore書き込みに失敗した場合、作成済みのAuthアカウントを削除して
        // 「アカウントだけ存在して再登録できない」状態を防ぐ
        try {
          await userCredential.user!.delete();
        } catch (_) {
          // 削除に失敗しても元のエラーを優先して投げる
        }
        rethrow;
      }

      if (!mounted) return;

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

      // } on FirebaseAuthException catch (e) {
      //   String msg = '登録に失敗しました';
      //   if (e.code == 'email-already-in-use') msg = 'このメールアドレスは既に登録されています';
      //   UIUtils.showResultDialog(context, title: '認証エラー', message: msg, isError: true);
    } on FirebaseAuthException catch (e) {
      String msg = '認証エラー (${e.code}): ${e.message}';
      UIUtils.showResultDialog(context, title: '認証エラー', message: msg, isError: true); // ★awaitがない
    } catch (e) {
      UIUtils.showResultDialog(context, title: 'エラー', message: e.toString(), isError: true); // ★awaitがない
    } finally {
      if (mounted) setState(() => _isSubmitting = false); // ★ダイアログが出るのと同時に実行される
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(title: const Text('企業初回登録'), elevation: 0),
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
        const Text('企業初回登録', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('企業コード: ${widget.companyCode}', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        UIUtils.buildFormSection(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildField('正式企業名', _companyNameController, Icons.business, '例：株式会社サンプル'),
                const SizedBox(height: 16),
                _buildField('担当責任者氏名', _managerNameController, Icons.person, '例：山田 太郎'),
                const SizedBox(height: 16),
                _buildField('管理者メールアドレス', _emailController, Icons.email, 'example@mail.com'),
                const SizedBox(height: 16),
                _buildPasswordField('ログインパスワード設定', _passwordController, '8文字以上'),
                const SizedBox(height: 16),
                _buildPasswordField('パスワード再入力', _confirmPasswordController, '確認のためもう一度'),
                const SizedBox(height: 32),
                _isSubmitting
                    ? const CircularProgressIndicator()
                    : UIUtils.buildPrimaryButton(label: '本登録を確定する', onPressed: _completeSetup),
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
          decoration: InputDecoration(prefixIcon: Icon(icon), hintText: hint, border: const OutlineInputBorder()),
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
          decoration: InputDecoration(prefixIcon: const Icon(Icons.lock), hintText: hint, border: const OutlineInputBorder()),
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