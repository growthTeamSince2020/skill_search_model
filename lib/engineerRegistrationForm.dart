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

  final Map<String, List<bool>> _processChecked = {
    '要件定義': [false, false, false, false],
    '基本設計': [false, false, false, false],
    '詳細設計': [false, false, false, false],
    'コーディング': [false, false, false, false],
    '単体': [false, false, false, false],
    '結合': [false, false, false, false],
    '保守': [false, false, false, false],
  };

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _codeLanguagesController.dispose();
    _nearestStationController.dispose();
    super.dispose();
  }

  Future<void> _registerEngineer() async {
    if (_formKey.currentState!.validate()) {
      try {
        Map<String, List<String>> selectedProcesses = {};
        _processChecked.forEach((process, levels) {
          List<String> selectedLevels = [];
          if (levels[0]) selectedLevels.add('未経験');
          if (levels[1]) selectedLevels.add('経験浅い');
          if (levels[2]) selectedLevels.add('経験豊富');
          if (selectedLevels.isNotEmpty) {
            selectedProcesses[process] = selectedLevels;
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
                validator: (value) => value == null || value.isEmpty ? '名前を入力してください' : null,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: '苗字'),
                validator: (value) => value == null || value.isEmpty ? '苗字を入力してください' : null,
              ),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(labelText: '年齢'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return '年齢を入力してください';
                  return int.tryParse(value) == null ? '有効な年齢を入力してください' : null;
                },
              ),
              TextFormField(
                controller: _codeLanguagesController,
                decoration: InputDecoration(labelText: '経験言語 (カンマ区切り)'),
                validator: (value) => value == null || value.isEmpty ? '経験言語を入力してください' : null,
              ),
              TextFormField(
                controller: _nearestStationController,
                decoration: InputDecoration(labelText: '最寄駅'),
                validator: (value) => value == null || value.isEmpty ? '最寄駅を入力してください' : null,
              ),
              ExpansionTile(
                title: Text('▼工程'),
                children: _processChecked.keys.map((process) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          title: Text(process),
                          value: _processChecked[process]![3],
                          onChanged: (value) {
                            setState(() {
                              _processChecked[process]![3] = value!;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (_processChecked[process]![3])
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Wrap(
                              spacing: 8.0,
                              children: [
                                CheckboxListTile(
                                  title: Text('未経験'),
                                  value: _processChecked[process]![0],
                                  onChanged: (value) {
                                    setState(() {
                                      _processChecked[process]![0] = value!;
                                      if (value) {
                                        _processChecked[process]![1] = false;
                                        _processChecked[process]![2] = false;
                                      }
                                    });
                                  },
                                  controlAffinity: ListTileControlAffinity.trailing,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                CheckboxListTile(
                                  title: Text('経験があるが未熟'),
                                  value: _processChecked[process]![1],
                                  onChanged: (value) {
                                    setState(() {
                                      _processChecked[process]![1] = value!;
                                      if (value) {
                                        _processChecked[process]![0] = false;
                                        _processChecked[process]![2] = false;
                                      }
                                    });
                                  },
                                  controlAffinity: ListTileControlAffinity.trailing,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                CheckboxListTile(
                                  title: Text('経験豊富'),
                                  value: _processChecked[process]![2],
                                  onChanged: (value) {
                                    setState(() {
                                      _processChecked[process]![2] = value!;
                                      if (value) {
                                        _processChecked[process]![0] = false;
                                        _processChecked[process]![1] = false;
                                      }
                                    });
                                  },
                                  controlAffinity: ListTileControlAffinity.trailing,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ],
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