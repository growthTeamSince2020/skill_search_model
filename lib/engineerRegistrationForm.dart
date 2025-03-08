import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EngineerRegistrationForm extends StatefulWidget {
  @override
  _EngineerRegistrationFormState createState() =>
      _EngineerRegistrationFormState();
}

class _EngineerRegistrationFormState extends State<EngineerRegistrationForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _codeLanguagesController = TextEditingController();
  final _nearestStationController = TextEditingController();
  List<String> _processes = [];
  List<String> _experienceCategories = [];

  final Map<String, String?> _processChecked = {};

  @override
  void initState() {
    super.initState();
    _fetchUtilData().then((data) {
      setState(() {
        _processes = List<String>.from(data['process'] ?? []);
        _experienceCategories =
        List<String>.from(data['experience_category'] ?? []);
        _processChecked.clear();
      });
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _codeLanguagesController.dispose();
    _nearestStationController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchUtilData() async {
    try {
      final docProcess = await FirebaseFirestore.instance
          .collection('utilData')
          .doc('process_item')
          .get();
      final docExperienceCategory = await FirebaseFirestore.instance
          .collection('utilData')
          .doc('experience_category_item')
          .get();

      if (docProcess.exists && docExperienceCategory.exists) {
        return {
          'process': docProcess.data()!['process'] as List<dynamic>,
          'experience_category':
          docExperienceCategory.data()!['experience_category'] as List<dynamic>,
        };
      } else {
        throw Exception('必要なドキュメントが見つかりませんでした。');
      }
    } catch (e) {
      print('データの取得に失敗しました: $e');
      return {};
    }
  }

  Future<void> _registerEngineer() async {
    if (_formKey.currentState!.validate()) {
      try {
        Map<String, String> selectedProcesses = {};
        _processChecked.forEach((process, level) {
          if (level != null) {
            selectedProcesses[process] = level;
          }
        });

        await FirebaseFirestore.instance.collection('engineers').add({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'age': int.parse(_ageController.text),
          'codeLanguages': _codeLanguagesController.text.split(','),
          'nearestStation': _nearestStationController.text,
          'processes': selectedProcesses,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('技術者登録が完了しました')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登録に失敗しました: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('技術者登録')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(labelText: '名前'),
                validator: (value) =>
                value == null || value.isEmpty
                    ? '名前を入力してください'
                    : null,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: '苗字'),
                validator: (value) =>
                value == null || value.isEmpty
                    ? '苗字を入力してください'
                    : null,
              ),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(labelText: '年齢'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return '年齢を入力してください';
                  return int.tryParse(value) == null
                      ? '有効な年齢を入力してください'
                      : null;
                },
              ),
              TextFormField(
                controller: _codeLanguagesController,
                decoration: InputDecoration(
                    labelText: '経験言語 (カンマ区切り)'),
                validator: (value) =>
                value == null || value.isEmpty
                    ? '経験言語を入力してください'
                    : null,
              ),
              TextFormField(
                controller: _nearestStationController,
                decoration: InputDecoration(labelText: '最寄駅'),
                validator: (value) =>
                value == null || value.isEmpty
                    ? '最寄駅を入力してください'
                    : null,
              ),
              ExpansionTile(
                title: Text('▼工程'),
                children: _processes.map((process) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          title: Text(process),
                          value: _processChecked[process] != null,
                          onChanged: (value) {
                            setState(() {
                              _processChecked[process] = value! ? '選択' : null;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (_processChecked[process] != null)
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Wrap(
                              spacing: 8.0,
                              children: _experienceCategories.map((
                                  experienceCategory) {
                                return RadioListTile<String>(
                                  title: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 16.0 * 4), // ここで左にスペースを追加
                                    child: Text(experienceCategory),
                                  ),
                                  value: experienceCategory,
                                  groupValue: _processChecked[process],
                                  onChanged: (value) {
                                    setState(() {
                                      _processChecked[process] = value;
                                    });
                                  },
                                  contentPadding: EdgeInsets.zero,
                                  controlAffinity: ListTileControlAffinity
                                      .trailing,
                                );
                              }).toList(),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              ElevatedButton(
                onPressed: _registerEngineer,
                child: Text('登録'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}