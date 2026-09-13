import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // クリップボード用
import 'package:firebase_auth/firebase_auth.dart';
import 'package:skill_search_model/utils/uiUtils.dart'; // ★ 追加
import '../common/constData.dart';
import '../utils/objectsUtils.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _affiliationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _affiliationController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _affiliationController.dispose();
    super.dispose();
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
            const Icon(Icons.settings_suggest_rounded, color: constData.themeGreen, size: 24),
            const SizedBox(width: 12),
            Text(
              'アカウント設定',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.withOpacity(0.15), height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(constData.cardPadding),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. プロフィール画像 ---
                  Center(child: _buildAvatarSection()),
                  const SizedBox(height: 32),

                  // --- 2. UIDエリア ---
                  _buildReadOnlyField(
                    label: 'ユーザーID (UID)',
                    value: user?.uid ?? '不明',
                    icon: Icons.vpn_key_outlined,
                  ),
                  const SizedBox(height: 24),

                  // --- 3. プロフィール編集エリア ---
                  UIUtils.buildFormSection(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('プロフィール情報',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const Divider(height: 32),

                        _buildManagedTextField(
                          label: '氏名 / 表示名',
                          controller: _nameController,
                          icon: Icons.badge_outlined,
                          hint: '検索結果に表示される名前',
                        ),
                        const SizedBox(height: 20),

                        _buildManagedTextField(
                          label: '所属 / 役職',
                          controller: _affiliationController,
                          icon: Icons.corporate_fare_outlined,
                          hint: '例：開発部 第1チーム',
                        ),
                        const SizedBox(height: 20),

                        _buildManagedTextField(
                          label: '連絡用メールアドレス',
                          controller: _emailController,
                          icon: Icons.email_outlined,
                          hint: 'example@mail.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // --- 保存ボタン ---
                  UIUtils.buildPrimaryButton(
                    label: '設定を保存する',
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('設定を保存しました')),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 40),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          'Skirun System Management',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version ${constData.systemVersion}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// UIDなどの「表示専用」フィールド（コピー機能付き）
  Widget _buildReadOnlyField({required String label, required String value, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(constData.borderRadius),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.black38, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.black54, fontSize: 13, fontFamily: 'monospace'),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 20, color: constData.themeGreen),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UIDをコピーしました')));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 入力フィールド
  Widget _buildManagedTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: (value) => ObjectUtils.validateField(value ?? '', label),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20),
            hintText: hint,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarSection() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey[200],
            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
            child: user?.photoURL == null ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: constData.themeGreen,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ),
        ),
      ],
    );
  }
}