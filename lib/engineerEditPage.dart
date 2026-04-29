import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'common/constData.dart';

class EngineerEditPage extends StatefulWidget {
  final String engineerId;
  final Map<String, dynamic> currentData;

  const EngineerEditPage({super.key, required this.engineerId, required this.currentData});

  @override
  State<EngineerEditPage> createState() => _EngineerEditPageState();
}

class _EngineerEditPageState extends State<EngineerEditPage> {

  // 基本情報用コントローラ
  late TextEditingController _lastNameController;
  late TextEditingController _firstNameController;
  late TextEditingController _ageController;
  late TextEditingController _lineController;
  late TextEditingController _stationController;
  late TextEditingController _idController;

  // 開閉状態の管理
  bool _isBasicInfoExpanded = true;
  bool _isRoleExpanded = true;
  bool _isSkillExpanded = true;
  bool _isToolExpanded = true;

  // 選択データ管理
  late Map<String, List<int>> _selectedIndices;
  late Map<String, List<int>> _selectedYears;

  // masters を constData から一括取得するように変更
  final Map<String, List<String>> masters = constData.engineerMasters;

  @override
  void initState() {
    super.initState();
    final d = widget.currentData;

    _lastNameController = TextEditingController(text: d['last_name']?.toString() ?? '');
    _firstNameController = TextEditingController(text: d['first_name']?.toString() ?? '');
    _ageController = TextEditingController(text: d['age']?.toString() ?? '');
    _lineController = TextEditingController(text: d['nearest_station_line_name']?.toString() ?? '');
    _stationController = TextEditingController(text: d['nearest_station_name']?.toString() ?? '');
    _idController = TextEditingController(text: d['id']?.toString() ?? '');

    _selectedIndices = {};
    _selectedYears = {};

    _initCategory('team_role', 'team_role_years');
    _initCategory('process', 'process_experience');
    _initCategory('code_languages', 'code_languages_years');
    _initCategory('db_experience', 'db_experience_years');
    _initCategory('os_experience', 'os_experience_years');
    _initCategory('cloud_technology', 'cloud_technology_years');
    _initCategory('tool', 'tool_years');
  }

  void _initCategory(String mainKey, String yearKey) {
    final mainData = widget.currentData[mainKey];
    final yearData = widget.currentData[yearKey];
    _selectedIndices[mainKey] = mainData is List ? List<int>.from(mainData.map((e) => (e as num).toInt())) : [];
    _selectedYears[mainKey] = yearData is List ? List<int>.from(yearData.map((e) => (e as num).toInt())) : [];
  }

  Future<void> _update() async {
    final Map<String, dynamic> updateData = {
      'last_name': _lastNameController.text,
      'first_name': _firstNameController.text,
      'age': int.tryParse(_ageController.text) ?? 0,
      'nearest_station_line_name': _lineController.text,
      'nearest_station_name': _stationController.text,
      'id': _idController.text,
    };

    _selectedIndices.forEach((key, value) {
      updateData[key] = value;
      String yearKey = key == 'process' ? 'process_experience' : '${key}_years';
      updateData[yearKey] = _selectedYears[key];
    });

    await FirebaseFirestore.instance.collection('engineer').doc(widget.engineerId).update(updateData);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: false,
        title: Row(
          children: [
            const Icon(
              Icons.assignment_ind,
              color: constData.themeGreen,
              size: 24,
            ),
            const SizedBox(width: 10),
            const Text(
              constData.engineerDetailEdit,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _update,
            child: const Text(
                '保存',
                style: TextStyle(
                    color: constData.themeGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 16
                )
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            _buildEditCard(
              Icons.person_outline,
              '基本情報',
              [
                _buildTextField('管理No (ID)', _idController, isReadOnly: true),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildTextField('姓', _lastNameController)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField('名', _firstNameController)),
                  ],
                ),
                Row(
                  children: [
                    Expanded(flex: 1, child: _buildTextField('年齢', _ageController, isNumber: true)),
                    const SizedBox(width: 12),
                    const Spacer(flex: 1),
                  ],
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    Expanded(child: _buildTextField('最寄沿線', _lineController)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField('最寄駅', _stationController)),
                  ],
                ),
              ],
              isExpanded: _isBasicInfoExpanded,
              onToggle: () => setState(() => _isBasicInfoExpanded = !_isBasicInfoExpanded),
            ),
            _buildEditCard(
              Icons.assignment_outlined,
              '役割・担当工程',
              [
                _buildMultiSelectCategory('担当役割', 'team_role', 'team_role_years'),
                const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Divider()),
                _buildMultiSelectCategory('経験工程', 'process', 'process_experience'),
              ],
              isExpanded: _isRoleExpanded,
              onToggle: () => setState(() => _isRoleExpanded = !_isRoleExpanded),
            ),
            _buildEditCard(
              Icons.code_outlined,
              '開発スキル詳細',
              [
                _buildMultiSelectCategory('プログラミング言語', 'code_languages', 'code_languages_years'),
                const Divider(height: 32),
                _buildMultiSelectCategory('データベース', 'db_experience', 'db_experience_years'),
                const Divider(height: 32),
                _buildMultiSelectCategory('クラウド技術', 'cloud_technology', 'cloud_technology_years'),
                const Divider(height: 32),
                _buildMultiSelectCategory('OS', 'os_experience', 'os_experience_years'),
              ],
              isExpanded: _isSkillExpanded,
              onToggle: () => setState(() => _isSkillExpanded = !_isSkillExpanded),
            ),
            _buildEditCard(
              Icons.build_outlined,
              '使用ツール',
              [
                _buildMultiSelectCategory('ツール', 'tool', 'tool_years'),
              ],
              isExpanded: _isToolExpanded,
              onToggle: () => setState(() => _isToolExpanded = !_isToolExpanded),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildEditCard(IconData icon, String title, List<Widget> children, {required bool isExpanded, required VoidCallback onToggle}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(icon, color: constData.themeGreen, size: 22),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const Spacer(),
                  AnimatedRotation(turns: isExpanded ? 0 : 0.5, duration: const Duration(milliseconds: 200), child: const Icon(Icons.expand_more, color: Colors.grey)),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Divider(thickness: 0.5),
                const SizedBox(height: 12),
                ...children,
              ]),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false, bool isReadOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: isReadOnly ? Colors.grey : constData.themeGreen.withOpacity(0.7)),
          filled: true,
          fillColor: isReadOnly ? Colors.grey.shade100 : const Color(0xFFF8FAFB),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          prefixIcon: isReadOnly ? const Icon(Icons.lock_outline, size: 18, color: Colors.grey) : null,
        ),
      ),
    );
  }

  Widget _buildMultiSelectCategory(String label, String mainKey, String yearKey) {
    final options = masters[mainKey]!;
    final yearOptions = masters[yearKey]!;
    final selectedIdxs = _selectedIndices[mainKey]!;
    final selectedYrs = _selectedYears[mainKey]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(options.length, (index) {
            final bool isSelected = selectedIdxs.contains(index);
            final int listPos = selectedIdxs.indexOf(index);

            return FilterChip(
              label: Text(
                isSelected ? "${options[index]} (${yearOptions[selectedYrs[listPos]]})" : options[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isSelected,
              onSelected: (bool value) async {
                if (isSelected) {
                  int? yearIdx = await _showYearPicker(options[index], yearOptions, isUpdate: true);
                  if (yearIdx == -1) {
                    setState(() {
                      int removeIdx = selectedIdxs.indexOf(index);
                      selectedIdxs.removeAt(removeIdx);
                      selectedYrs.removeAt(removeIdx);
                    });
                  } else if (yearIdx != null) {
                    setState(() {
                      selectedYrs[listPos] = yearIdx;
                    });
                  }
                } else {
                  int? yearIdx = await _showYearPicker(options[index], yearOptions, isUpdate: false);
                  if (yearIdx != null && yearIdx != -1) {
                    setState(() {
                      selectedIdxs.add(index);
                      selectedYrs.add(yearIdx);
                    });
                  }
                }
              },
              selectedColor: constData.themeGreen,
              checkmarkColor: Colors.white,
              backgroundColor: const Color(0xFFF1F1F1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            );
          }),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<int?> _showYearPicker(String title, List<String> yearOptions, {bool isUpdate = false}) async {
    return await showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 550),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: constData.themeGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.history_toggle_off, color: constData.themeGreen, size: 24)
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(isUpdate ? '経験年数を変更' : '経験年数を選択', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87))
                            ]
                        )
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        ...List.generate(yearOptions.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: InkWell(
                              onTap: () => Navigator.pop(context, index),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(12)),
                                child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(yearOptions[index], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                                      const Icon(Icons.chevron_right, color: Colors.grey, size: 20)
                                    ]
                                ),
                              ),
                            ),
                          );
                        }),
                        if (isUpdate) ...[
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: () => Navigator.pop(context, -1),
                            child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                                child: Center(child: Text('選択を解除する', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)))
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                    width: double.infinity,
                    child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('キャンセル', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
                    )
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}