import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // クリップボード用
import 'package:firebase_auth/firebase_auth.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('アカウント設定', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. プロフィール画像 ---
              Center(child: _buildAvatarSection()),
              const SizedBox(height: 32),

              // --- 2. UID (表示のみ・コピー可能) ---
              _buildReadOnlyField(
                label: 'ユーザーID (UID)',
                value: user?.uid ?? '不明',
                icon: Icons.vpn_key_outlined,
              ),
              const SizedBox(height: 20),

              // --- 3. 氏名 / 表示名 ---
              _buildManagedTextField(
                label: '氏名 / 表示名',
                controller: _nameController,
                icon: Icons.badge_outlined,
                hint: '検索結果に表示される名前',
              ),
              const SizedBox(height: 20),

              // --- 4. 所属 / 役職 ---
              _buildManagedTextField(
                label: '所属 / 役職',
                controller: _affiliationController,
                icon: Icons.corporate_fare_outlined,
                hint: '例：開発部 第1チーム',
              ),
              const SizedBox(height: 20),

              // --- 5. 連絡用メールアドレス ---
              _buildManagedTextField(
                label: '連絡用メールアドレス',
                controller: _emailController,
                icon: Icons.email_outlined,
                hint: 'example@mail.com',
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 40),

              // --- 保存ボタン ---
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('設定を保存しました')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('設定を保存する', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),

              const SizedBox(height: 60),
              Center(
                child: Text('Version ${constData.systemVersion}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ),
            ],
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(icon, color: Colors.grey[600]),
            title: Text(value, style: TextStyle(color: Colors.grey[700], fontSize: 13, fontFamily: 'monospace')),
            trailing: IconButton(
              icon: const Icon(Icons.copy, size: 20),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UIDをコピーしました')));
              },
            ),
          ),
        ),
      ],
    );
  }

  /// ObjectUtils.validateField を活用した共通入力フィールド
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
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black54)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: (value) => ObjectUtils.validateField(value ?? '', label),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.green[700]),
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarSection() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: Colors.grey[200],
          backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
          child: user?.photoURL == null ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: CircleAvatar(
            backgroundColor: const Color(0xFF2E7D32),
            radius: 20,
            child: IconButton(
              icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
              onPressed: () {},
            ),
          ),
        ),
      ],
    );
  }
}