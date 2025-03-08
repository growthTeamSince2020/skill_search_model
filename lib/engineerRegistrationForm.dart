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

  // 工程チェックボックスの状態を管理する変数（2次元配列に変更）
  final List<String> _processes = [
    '要件定義',
    '基本設計',
    '詳細設計',
    'コーディング',
    '単体',
    '結合',
    '保守',
  ];
  final List<List<bool>> _processChecked =
  List.generate(7, (index) => List.generate(4, (index) => false)); // 4つ目の要素は工程自体のチェック状態

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
        // チェックされた工程のリストを作成
        List<String> selectedProcesses = [];
        for (int i = 0; i < _processes.length; i++) {
          for (int j = 0; j < 3; j++) {
            if (_processChecked[i][j]) {
              selectedProcesses.add(_processes[i]);
              break; // 1つの工程で1つでもチェックされていれば追加
            }
          }
        }

        await FirebaseFirestore.instance.collection('engineers').add({
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'age': int.parse(_ageController.text),
          'codeLanguages': _codeLanguagesController.text.split(','),
          'nearestStation': _nearestStationController.text,
          'processes': selectedProcesses, // チェックされた工程のリストを送信
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('技術者登録が完了しました')),
        );
        Navigator.pop(context); // 登録完了後に前の画面に戻る
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '名前を入力してください';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: '苗字'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '苗字を入力してください';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _ageController,
                decoration: InputDecoration(labelText: '年齢'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '年齢を入力してください';
                  }
                  if (int.tryParse(value) == null) {
                    return '有効な年齢を入力してください';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _codeLanguagesController,
                decoration: InputDecoration(labelText: '経験言語 (カンマ区切り)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '経験言語を入力してください';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nearestStationController,
                decoration: InputDecoration(labelText: '最寄駅'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '最寄駅を入力してください';
                  }
                  return null;
                },
              ),
              // 工程チェックボックス（ExpansionTileをネスト）
              ExpansionTile(
                title: Text('▼工程'),
                children: _processes.map((process) {
                  int processIndex = _processes.indexOf(process);
                  return StatefulBuilder( // チェックボックスの状態を管理するためにStatefulBuilderを使用
                    builder: (context, setState) {
                      return ExpansionTile(
                        title: Row(
                          children: [
                            Checkbox(
                              value: _processChecked[processIndex][3], // 工程自体のチェック状態
                              onChanged: (value) {
                                setState(() {
                                  _processChecked[processIndex][3] = value!;
                                });
                              },
                            ),
                            Text(process),
                          ],
                        ),
                        children: _processChecked[processIndex][3] // 工程がチェックされている場合のみ表示
                            ? [
                          Wrap(
                            spacing: 8.0,
                            children: [
                              CheckboxListTile(
                                title: Text('未経験'),
                                value: _processChecked[processIndex][0],
                                onChanged: (value) {
                                  setState(() {
                                    _processChecked[processIndex][0] = value!;
                                  });
                                },
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              ),
                              CheckboxListTile(
                                title: Text('経験があるが未熟'),
                                value: _processChecked[processIndex][1],
                                onChanged: (value) {
                                  setState(() {
                                    _processChecked[processIndex][1] = value!;
                                  });
                                },
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              ),
                              CheckboxListTile(
                                title: Text('経験豊富'),
                                value: _processChecked[processIndex][2],
                                onChanged: (value) {
                                  setState(() {
                                    _processChecked[processIndex][2] = value!;
                                  });
                                },
                                controlAffinity: ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ]
                            : [],
                      );
                    },
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