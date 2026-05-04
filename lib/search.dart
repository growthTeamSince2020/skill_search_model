import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_search_model/seachDetail.dart';
import 'engineerSeachDetail.dart';
import 'model/searchConditionsDto.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  int totalCount = 0;
  final CollectionReference engineer =
      FirebaseFirestore.instance.collection('engineer');
  late SearchConditionsDto searchConditions;

  // マスターデータ用リスト
  List<String> codeLanguagesItem = [];
  List<String> processItem = [];
  List<String> teamRoleItem = [];
  List<String> dbExperienceItem = [];
  List<String> osExperienceItem = [];
  List<String> cloudTechnologyItem = [];
  List<String> toolItem = [];

  // メインカラーを定義
  static const themeGreen = Color(0xFF2E7D32);

  //詳細検索アイコン押下時
  void _detailSearchScreen() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const SeachDetailPage(),
      ),
    );
  }

  //エンジニア詳細ボタン押下時
  void _engineerDetailScreen(String engineerId) {
    // 引数を追加
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        // const を削除し、engineerId を渡す
        builder: (BuildContext context) =>
            EngineerSeachDetailPage(engineerId: engineerId),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 画面起動時にデータを取得
    _fetchData();
  }

  // Firestoreからマスターデータを取得する処理
  Future<void> _fetchData() async {
    // getStringListFromFirestore は既存の共通関数として定義されている前提
    // 引数の最後を false にすることで純粋なリストを取得
    processItem = await getStringListFromFirestore(
        "utilData", "process_item", "process", false);
    teamRoleItem = await getStringListFromFirestore(
        "utilData", "team_role_item", "team_role", false);
    codeLanguagesItem = await getStringListFromFirestore(
        "utilData", "code_languages_item", "code_languages", false);
    dbExperienceItem = await getStringListFromFirestore(
        "utilData", "db_experience_item", "db_experience", false);
    osExperienceItem = await getStringListFromFirestore(
        "utilData", "os_experience_item", "os_experience", false);
    cloudTechnologyItem = await getStringListFromFirestore(
        "utilData", "cloud_technology_item", "cloud_technology", false);
    toolItem = await getStringListFromFirestore(
        "utilData", "tool_item", "tool", false);

    if (mounted) {
      setState(() {}); // 取得後に再描画
    }
  }

  // モック用の共通関数（プロジェクトに既存のものを利用してください）
  Future<List<String>> getStringListFromFirestore(
      String collection, String doc, String field, bool addDefault) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection(collection)
          .doc(doc)
          .get();
      List<dynamic> list = snapshot.get(field);
      List<String> result = list.map((e) => e.toString()).toList();
      if (addDefault) result.insert(0, "選択してください");
      return result;
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: Icon(Icons.search, color: themeGreen, size: 24.0),
            ),
            Text(
              'エンジニア検索 ($totalCount件)',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: themeGreen,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // 全ての画面履歴を消して最初の画面に戻る場合、または特定のトップ画面に戻る場合
            // もし '/top' という名前でトップ画面を登録しているなら pushNamedAndRemoveUntil
            // 単に最初の画面まで戻るなら popUntil を使います。
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
          future: getStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('エラーが発生しました: ${snapshot.error}'));
            }

            final docs = snapshot.data;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && totalCount != (docs?.length ?? 0)) {
                setState(() => totalCount = docs?.length ?? 0);
              }
            });

            if (docs == null || docs.isEmpty) {
              return const Center(child: Text("該当するエンジニアが見つかりませんでした。"));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _engineerDetailScreen(docs[index].id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: themeGreen,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${data['last_name'] ?? ''}${data['first_name'] ?? ''}',
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${data['age'] ?? '--'}歳 / ${data['nearest_station_name'] ?? '駅未登録'}駅',
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: Colors.grey),
                            ],
                          ),
                          const Divider(height: 24, thickness: 1),
                          _buildSkillRow(
                              Icons.account_tree,
                              "工程",
                              getUtilDateListGetterSimpleEvaluation(
                                          data['process'],
                                          processItem,
                                          data['process_experience'],
                                          true),),
                          _buildSkillRow(
                              Icons.group,
                              "役割",
                              getUtilDateListGetterSimpleEvaluation(
                                          data['team_role'],
                                          teamRoleItem,
                                          data['team_role_years'],
                                          false),),
                          _buildSkillRow(
                              Icons.code,
                              "言語",
                              getUtilDateListGetterSimpleEvaluation(
                                          data['code_languages'],
                                          codeLanguagesItem,
                                          data['code_languages_years'],
                                          false),),
                          _buildSkillRow(
                              Icons.storage,
                              "DB",
                              getUtilDateListGetterSimpleEvaluation(
                                          data['db_experience'],
                                          dbExperienceItem,
                                          data['db_experience_years'],
                                          false),),
                          _buildSkillRow(
                              Icons.memory_rounded,
                              "OS",
                              getUtilDateListGetterSimpleEvaluation(
                                  data['os_experience'],
                                  osExperienceItem,
                                  data['os_experience_years'],
                                  false),),
                          _buildSkillRow(
                              Icons.cloud_queue_rounded,
                              "CLOUD",
                              getUtilDateListGetterSimpleEvaluation(
                                  data['cloud_technology'],
                                  cloudTechnologyItem,
                                  data['cloud_technology_years'],
                                  false),),
                          _buildSkillRow(
                              Icons.build_circle_outlined,
                              "TOOL",
                              getUtilDateListGetterSimpleEvaluation(
                                  data['tool'],
                                  toolItem,
                                  data['tool_years'],
                                  false),),

                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _detailSearchScreen,
        label:
            const Text('検索条件変更', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.tune),
        backgroundColor: Colors.orangeAccent,
      ),
    );
  }

  Widget _buildSkillRow(IconData icon, String label, List<String>? values) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blueGrey),
          const SizedBox(width: 8),
          SizedBox(
            width: 45,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.blueGrey)),
          ),
          Expanded(
            child: Wrap(
              spacing: 6.0, // チップ間の横の間隔
              runSpacing: 4.0, // 改行した時の縦の間隔
              children: values != null && values.isNotEmpty
                  ? values.map((value) => _buildTag(value)).toList()
                  : [
                const Text('未登録',
                    style: TextStyle(fontSize: 13, color: Colors.grey))
              ],
            ),
          ),
        ],
      ),
    );
  }

// タグ（縁取り）を作るサブ部品
  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blueGrey.shade200), // 縁取り線
        borderRadius: BorderRadius.circular(20), // カプセル型
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.blueGrey,
        ),
      ),
    );
   }

  Future<List<DocumentSnapshot>> getStream() async {
    searchConditions = ref.watch(searchConditionsControllerProvider);
    Query query =
        engineer.where(FieldPath.documentId, isNotEqualTo: "sequenceNo");

    if (searchConditions.getSearchSettingFlag == true) {
      if (searchConditions.getAgeDropdownSelectedValue! > 0) {
        int searchNum = (searchConditions.getAgeDropdownSelectedValue == 1)
            ? 30
            : (searchConditions.getAgeDropdownSelectedValue == 2)
                ? 40
                : 50;
        query = query.where("age", isLessThanOrEqualTo: searchNum);
      }
    }

    QuerySnapshot allDocs = await query.get();

    return allDocs.docs.where((doc) {
      var data = doc.data() as Map<String, dynamic>;
      if (searchConditions.getSearchSettingFlag != true) return true;

      // 各カテゴリのAND判定（既存ロジック通り）
      bool processMatch = true;
      if (searchConditions.getSearchSettingProcessFlag == true) {
        processMatch = _checkExperience(
            userItems: data["process"] ?? [],
            userYears: data["process_experience"] ?? [],
            searchSettings: searchConditions.getProcessSearchItemChecked!);
      }

      bool teamRoleMatch = true;
      if (searchConditions.getSearchSettingTeamRolesFlag == true) {
        teamRoleMatch = _checkExperience(
            userItems: data["team_role"] ?? [],
            userYears: data["team_role_years"] ?? [],
            searchSettings: searchConditions.getTeamRolesSearchItemChecked!);
      }

      bool codeLanguagesMatch = true;
      if (searchConditions.getSearchSettingCodeLanguagesFlag == true) {
        codeLanguagesMatch = _checkExperience(
            userItems: data["code_languages"] ?? [],
            userYears: data["code_languages_years"] ?? [],
            searchSettings:
                searchConditions.getCodeLanguagesSearchItemChecked!);
      }

      bool dbExperienceMatch = true;
      if (searchConditions.getSearchSettingDbExperienceFlag == true) {
        dbExperienceMatch = _checkExperience(
            userItems: data["db_experience"] ?? [],
            userYears: data["db_experience_years"] ?? [],
            searchSettings: searchConditions.getDbExperienceSearchItemChecked!);
      }

      bool osExperienceMatch = true;
      if (searchConditions.getSearchSettingOsExperienceFlag == true) {
        osExperienceMatch = _checkExperience(
            userItems: data["os_experience"] ?? [],
            userYears: data["os_experience_years"] ?? [],
            searchSettings: searchConditions.getOsExperienceSearchItemChecked!);
      }

      bool cloudTechnologyMatch = true;
      if (searchConditions.getSearchSettingCloudTechnologyFlag == true) {
        cloudTechnologyMatch = _checkExperience(
            userItems: data["cloud_technology"] ?? [],
            userYears: data["cloud_technology_years"] ?? [],
            searchSettings: searchConditions.getCloudTechnologySearchItemChecked!);
      }

      bool toolMatch = true;
      if (searchConditions.getSearchSettingToolFlag == true) {
        toolMatch = _checkExperience(
            userItems: data["tool"] ?? [],
            userYears: data["tool_years"] ?? [],
            searchSettings: searchConditions.getToolSearchItemChecked!);
      }

      return processMatch &&
          teamRoleMatch &&
          codeLanguagesMatch &&
          dbExperienceMatch
          && osExperienceMatch
          && cloudTechnologyMatch
          && toolMatch;
    }).toList();
  }

  bool _checkExperience(
      {required List<dynamic> userItems,
      required List<dynamic> userYears,
      required List<List<bool>> searchSettings}) {
    bool hasAnyCondition = false;
    for (var setting in searchSettings) {
      if (setting.contains(true)) {
        hasAnyCondition = true;
        break;
      }
    }
    if (!hasAnyCondition) return true;

    for (int i = 0; i < searchSettings.length; i++) {
      if (searchSettings[i].contains(true)) {
        int userIdx = userItems.indexOf(i);
        if (userIdx == -1) return false;
        bool yearMatch = false;
        for (int j = 0; j < searchSettings[i].length; j++) {
          if (searchSettings[i][j] == true &&
              userYears[userIdx].toString() == j.toString()) {
            yearMatch = true;
            break;
          }
        }
        if (!yearMatch) return false;
      }
    }
    return true;
  }

  // 表示用ロジック（修正：正しいインデックスで名前を引くように変更）
  List<String>? getUtilDateListGetterSimpleEvaluation(dynamic numList,
      List<String> utilArray, dynamic yearsList, bool category) {
    if (numList == null || utilArray.isEmpty || yearsList == null) return null;
    List<String> result = [];
    for (int i = 0; i < numList.length; i++) {
      int itemIndex = numList[i]; // ユーザーが持っているIDを取得
      if (itemIndex < utilArray.length) {
        String mark = (yearsList[i] < 2)
            ? "△"
            : (yearsList[i] < 4)
                ? "◯"
                : "◎";
        result.add("${utilArray[itemIndex]} $mark");
      }
    }
    return result.isEmpty ? null : result;
  }
}
