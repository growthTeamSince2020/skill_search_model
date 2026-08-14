import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // クリップボード用
import 'package:skill_search_model/utils/uiUtils.dart';
import 'dart:math';

import 'package:url_launcher/url_launcher.dart';

import 'common/constData.dart';

class AdminInvitationScreen extends StatefulWidget {
  const AdminInvitationScreen({super.key});

  @override
  State<AdminInvitationScreen> createState() => _AdminInvitationScreenState();
}

class _AdminInvitationScreenState extends State<AdminInvitationScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _managerNameController = TextEditingController();

  bool _isSending = false;
  String? _generatedUrl;
  String? _generatedSubject; // 生成された件名
  String? _generatedBody;    // 生成された本文
  String? _lastCompanyCode;  // 企業コード保持用

  static const themeGreen = Color(0xFF2E7D32);

  // 企業コード生成 (CP + YYMM + 3桁連番)
  Future<String> _generateCompanyCode() async {
    final now = DateTime.now();
    final year = now.year.toString().substring(2);
    final month = now.month.toString().padLeft(2, '0');
    final datePrefix = 'CP$year$month';

    try {
      final snapshot = await _db
          .collection('companies')
          .where('companyCode', isGreaterThanOrEqualTo: datePrefix)
          .where('companyCode', isLessThan: '${datePrefix}z')
          .get();

      final nextNumber = snapshot.docs.length + 1;
      final sequence = nextNumber.toString().padLeft(3, '0');

      return '$datePrefix$sequence';
    } catch (e) {
      return '$datePrefix${now.millisecond}';
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
      final companyCode = await _generateCompanyCode();
      final expiryDate = DateTime.now().add(const Duration(hours: 24));
      final setupUrl = constData.getInvitationUrl(companyCode);

      // 1. Firestoreに保存
      await _db.collection('companies').doc(companyCode).set({
        'companyCode': companyCode,
        'companyName': _companyNameController.text,
        'tempManagerEmail': _emailController.text.toLowerCase(),
        'tempManagerName': _managerNameController.text,
        'status': '案内中',
        'expiryDate': Timestamp.fromDate(expiryDate),
        'invitationUrl': setupUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. 定型文の作成
      final subject = '【重要】スキル検索システム 初回登録のご案内';
      final body = '${_managerNameController.text} 様\n\n'
          'お世話になっております。システム管理者です。\n'
          '${_companyNameController.text} 様のシステム利用開始に伴い、初回登録URLを発行いたしました。\n\n'
          '以下のURLより、24時間以内に企業情報の登録および管理者パスワードの設定を完了させてください。\n\n'
          '■初回登録URL\n'
          '$setupUrl\n\n'
          '■企業コード\n'
          '$companyCode\n\n'
          '※本URLはセキュリティ保護のため発行から24時間のみ有効です。\n'
          '期限が切れた場合は、お手数ですが再度管理者までご連絡ください。\n'
          '--------------------------------------------\n'
          '※本メールに心当たりがない場合は、破棄していただきますようお願いいたします。';

      setState(() {
        _isSending = false;
        _generatedUrl = setupUrl;
        _generatedSubject = subject;
        _generatedBody = body;
        _lastCompanyCode = companyCode;
      });

      // 3. Gmailをブラウザで自動起動 (Chrome対応)
      final String toEmail = _emailController.text;
      final String encodedSubject = Uri.encodeComponent(subject);
      final String encodedBody = Uri.encodeComponent(body);

      // Gmail新規作成URL
      final String gmailUrl = 'https://mail.google.com/mail/?view=cm&fs=1&to=$toEmail&su=$encodedSubject&body=$encodedBody';
      final Uri gmailUri = Uri.parse(gmailUrl);

      if (await canLaunchUrl(gmailUri)) {
        await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
      } else {
        // フォールバック
        final Uri mailtoUri = Uri.parse('mailto:$toEmail?subject=$encodedSubject&body=$encodedBody');
        if (await canLaunchUrl(mailtoUri)) {
          await launchUrl(mailtoUri);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('案内情報を登録しました。')),
      );
    } catch (e) {
      setState(() => _isSending = false);
      await UIUtils.showResultDialog(
        context,
        title: 'エラー',
        message: '登録に失敗しました: $e',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        title: const Text('企業初回登録案内・管理', style: TextStyle(fontWeight: FontWeight.bold)),
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
                const Text('新規企業招待の発行', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildInputForm(),
                // URL発行後のみ表示されるエリア
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
              label: '企業名（仮）',
              controller: _companyNameController,
              hint: '株式会社サンプル',
              icon: Icons.business,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: '宛先名（担当者）',
              controller: _managerNameController,
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
            const SizedBox(height: 24),
            _isSending
                ? const CircularProgressIndicator(color: themeGreen)
                : UIUtils.buildPrimaryButton(
              label: '案内情報を登録・URL発行',
              onPressed: _sendInvitation,
            ),
          ],
        ),
      ),
    );
  }

  // メール件名と本文をコピーするためのカード
  Widget _buildMailTemplateCard() {
    // build時にnullチェックを行うことでTypeErrorを回避
    if (_generatedSubject == null || _generatedBody == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildCopyableField(
          label: 'メール件名',
          content: _generatedSubject!,
          icon: Icons.title,
        ),
        const SizedBox(height: 16),
        _buildCopyableField(
          label: 'メール本文',
          content: _generatedBody!,
          icon: Icons.subject,
          isLongText: true,
        ),
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