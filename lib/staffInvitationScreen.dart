import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // クリップボード用
import 'package:skill_search_model/common/constData.dart'; // ★ 追加
import 'package:skill_search_model/utils/uiUtils.dart';
import 'package:url_launcher/url_launcher.dart';

/// 自社スタッフ招待画面
///
/// adminInvitationScreen.dart（新規企業オンボーディング）とは目的が異なる。
/// こちらは「すでにcompanyCodeを持っている自社」に、管理担当(admin)が
/// 追加のスタッフ（デフォルトはmember）を招待するための画面。
/// - companyCodeは新規発行せず、招待した本人のcompanyCodeを引き継ぐ
/// - ロールはmemberがデフォルト（admin自身も選択可・ownerは選択不可）
class StaffInvitationScreen extends StatefulWidget {
  const StaffInvitationScreen({super.key});

  @override
  State<StaffInvitationScreen> createState() => _StaffInvitationScreenState();
}

class _StaffInvitationScreenState extends State<StaffInvitationScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _selectedRole = constData.roleMember; // ★ engineer -> member (定数化)

  bool _isLoading = true; // 自分のcompanyCode取得中
  bool _isSending = false;
  String? _errorMessage;

  String _myCompanyCode = '';
  String _myCompanyName = '';
  String _myDisplayName = '';

  String? _generatedUrl;
  String? _generatedSubject;
  String? _generatedBody;

  static const themeGreen = Color(0xFF2E7D32);

  // adminはownerを招待できない
  static const Map<String, String> _invitableRoles = {
    constData.roleAdmin: '管理担当(admin)', // ★ 定数化
    constData.roleMember: '一般ユーザー(member)', // ★ engineer -> member (定数化)
  };

  @override
  void initState() {
    super.initState();
    _loadMyCompanyInfo();
  }

  Future<void> _loadMyCompanyInfo() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() { _errorMessage = "ログイン情報が確認できません。"; _isLoading = false; });
        return;
      }
      final userDoc = await _db.collection('users').doc(uid).get();
      final userData = userDoc.data();
      final companyCode = userData?['companyCode'] ?? '';

      if (companyCode.toString().isEmpty) {
        setState(() { _errorMessage = "所属企業（法人コード）が設定されていないため、招待を送信できません。"; _isLoading = false; });
        return;
      }

      String companyName = '';
      final companyDoc = await _db.collection('companies').doc(companyCode).get();
      if (companyDoc.exists) {
        companyName = companyDoc.data()?['companyName'] ?? '';
      }

      setState(() {
        _myCompanyCode = companyCode;
        _myCompanyName = companyName;
        _myDisplayName = userData?['displayName'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _errorMessage = "情報取得エラー: $e"; _isLoading = false; });
    }
  }

  Future<void> _sendInvitation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
      _generatedUrl = null;
      _generatedSubject = null;
      _generatedBody = null;
    });

    try {
      final inviteRef = _db.collection('staffInvitations').doc();
      final expiryDate = DateTime.now().add(const Duration(hours: 24));
      final setupUrl = constData.getStaffInvitationUrl(inviteRef.id);

      // companyCodeは新規発行せず、招待者自身のcompanyCodeをそのまま引き継ぐ
      await inviteRef.set({
        'companyCode': _myCompanyCode,
        'companyName': _myCompanyName,
        'tempName': _nameController.text,
        'tempEmail': _emailController.text.toLowerCase(),
        'role': _selectedRole,
        'status': '案内中',
        'expiryDate': Timestamp.fromDate(expiryDate),
        'invitationUrl': setupUrl,
        'invitedByUid': FirebaseAuth.instance.currentUser?.uid,
        'invitedByName': _myDisplayName,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final roleLabel = UIUtils.getRoleDisplayName(_selectedRole); // ★ 共通部品を使用
      final subject = '【重要】$_myCompanyName スキル検索システム アカウント登録のご案内';
      final body = '${_nameController.text} 様\n\n'
          'お世話になっております。$_myDisplayName です。\n'
          '$_myCompanyName のスキル検索システムアカウントを発行いたしました（権限: $roleLabel）。\n\n'
          '以下のURLより、24時間以内にパスワード設定を完了させてください。\n\n'
          '■登録URL\n'
          '$setupUrl\n\n'
          '※本URLはセキュリティ保護のため発行から24時間のみ有効です。\n'
          '期限が切れた場合は、お手数ですが再度管理担当までご連絡ください。\n'
          '--------------------------------------------\n'
          '※本メールに心当たりがない場合は、破棄していただきますようお願いいたします。';

      setState(() {
        _isSending = false;
        _generatedUrl = setupUrl;
        _generatedSubject = subject;
        _generatedBody = body;
      });

      final String toEmail = _emailController.text;
      final String encodedSubject = Uri.encodeComponent(subject);
      final String encodedBody = Uri.encodeComponent(body);
      final String gmailUrl = 'https://mail.google.com/mail/?view=cm&fs=1&to=$toEmail&su=$encodedSubject&body=$encodedBody';
      final Uri gmailUri = Uri.parse(gmailUrl);

      if (await canLaunchUrl(gmailUri)) {
        await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
      } else {
        final Uri mailtoUri = Uri.parse('mailto:$toEmail?subject=$encodedSubject&body=$encodedBody');
        if (await canLaunchUrl(mailtoUri)) {
          await launchUrl(mailtoUri);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('招待情報を登録しました。')),
      );
    } catch (e) {
      setState(() => _isSending = false);
      UIUtils.showResultDialog(
        context,
        title: 'エラー',
        message: '招待の送信に失敗しました: $e',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('自社スタッフ招待')),
        body: Center(child: Text(_errorMessage!, style: const TextStyle(fontSize: 16))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text('自社スタッフ招待', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$_myCompanyName（$_myCompanyCode）へのスタッフ招待',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildInputForm(),
                if (_generatedUrl != null) ...[
                  const SizedBox(height: 32),
                  const Text('発行済み案内メール定型文', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildMailTemplateCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    return UIUtils.buildFormSection(
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(
              label: '宛先名（担当者）',
              controller: _nameController,
              hint: '担当者名',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: '送付先メールアドレス',
              controller: _emailController,
              hint: 'example@company.com',
              icon: Icons.mail_outline,
              isEmail: true,
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: const Text('付与する権限', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              items: _invitableRoles.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedRole = val!),
            ),
            const SizedBox(height: 24),
            _isSending
                ? const CircularProgressIndicator(color: themeGreen)
                : SizedBox(
              width: double.infinity,
              child: UIUtils.buildPrimaryButton(
                label: '招待情報を登録・URL発行',
                onPressed: _sendInvitation,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMailTemplateCard() {
    if (_generatedSubject == null || _generatedBody == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildCopyableField(label: 'メール件名', content: _generatedSubject!, icon: Icons.title),
        const SizedBox(height: 16),
        _buildCopyableField(label: 'メール本文', content: _generatedBody!, icon: Icons.subject, isLongText: true),
      ],
    );
  }

  Widget _buildCopyableField({
    required String label,
    required String content,
    required IconData icon,
    bool isLongText = false,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: themeGreen),
                    const SizedBox(width: 8),
                    Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: content));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$labelをコピーしました')));
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('コピー'),
                  style: TextButton.styleFrom(foregroundColor: themeGreen),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 4),
            SelectableText(
              content,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blueGrey.shade800,
                height: 1.5,
                fontFamily: isLongText ? 'monospace' : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isEmail = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return '必須入力です';
            if (isEmail && !value.contains('@')) return '有効なメールアドレスを入力してください';
            return null;
          },
        ),
      ],
    );
  }
}