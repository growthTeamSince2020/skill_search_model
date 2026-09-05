import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skill_search_model/seachDetail.dart';
import 'package:skill_search_model/utils/uiUtils.dart';
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
  static const themeColor = Color(0xFF2E7D32);
  //static const themeColor = Color(0xFFFFFFFF);

  // =========================================================
  // ★ 選択モード関連の状態
  // =========================================================
  /// チェックボックスの表示/非表示を切り替えるフラグ
  bool _selectionModeEnabled = false;

  // 一覧削除機能フラグ　チェックボックス選択・一括削除機能　TRUE：可能、FALSE：不能
  static const bool _canDeleteEngineer = true;

  /// 選択中のドキュメントIDの集合
  final Set<String> _selectedIds = {};

  /// 直近にロードされた一覧（「全選択」機能で使用）
  List<DocumentSnapshot> _lastLoadedDocs = [];

  /// 選択モードのON/OFF切り替え
  void _toggleSelectionMode() {
    if (!_canDeleteEngineer) return;
    setState(() {
      _selectionModeEnabled = !_selectionModeEnabled;
      // OFFにする時は選択状態をクリア
      if (!_selectionModeEnabled) {
        _selectedIds.clear();
      }
    });
  }

  /// 個別チェックボックスのON/OFF切り替え
  void _toggleSelected(String docId) {
    setState(() {
      if (_selectedIds.contains(docId)) {
        _selectedIds.remove(docId);
      } else {
        _selectedIds.add(docId);
      }
    });
  }

  /// 表示中の全件を選択 / 全解除
  void _toggleSelectAll() {
    setState(() {
      final allIds = _lastLoadedDocs.map((d) => d.id).toSet();
      final bool isAllSelected =
          allIds.isNotEmpty && _selectedIds.containsAll(allIds);
      if (isAllSelected) {
        _selectedIds.removeAll(allIds);
      } else {
        _selectedIds.addAll(allIds);
      }
    });
  }

  /// 一括削除実行
  Future<void> _bulkDelete() async {
    if (!_canDeleteEngineer || _selectedIds.isEmpty) return;
    final idList = _selectedIds.toList();

    final bool deleted = await UIUtils.deleteListData_confirmDialog(
      context,
      title: '一括削除の確認',
      content: '選択した ${idList.length} 件の技術者情報を完全に削除しますか？\nこの操作は取り消せません。',
      collectionPath: 'engineer',
      documentIdList: idList,
    );

    if (deleted && mounted) {
      setState(() {
        _selectedIds.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${idList.length}件の技術者情報を削除しました')),
      );
    }
  }

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
      backgroundColor: Colors.grey[100],//カードの間の色
      appBar: AppBar(
        title: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 12.0),
              child: Icon(Icons.screen_search_desktop_outlined, color: themeColor, size: 24.0),
            ),
            Text(
              'エンジニア検索 ',
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const Spacer(),
            Text('表示件数 $totalCount 件',style: const TextStyle(fontSize: 14, color: Colors.blueGrey),),
          ],
        ),
        shape: const Border(
          bottom: BorderSide(
            color: themeColor,//画面タイトルの下の線の色
            width: 1.0,
          ),
        ),
        backgroundColor: Colors.white,//画面タイトルの色
        foregroundColor: themeColor,//戻るボタンの矢印の色
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,color: Colors.black,),
          onPressed: () {
            // 全ての画面履歴を消して最初の画面に戻る場合、または特定のトップ画面に戻る場合
            // もし '/top' という名前でトップ画面を登録しているなら pushNamedAndRemoveUntil
            // 単に最初の画面まで戻るなら popUntil を使います。
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
        // ★追加②: 選択モード切替ボタン と 一括削除ボタン
        actions: [
          if (_canDeleteEngineer && _selectionModeEnabled)
            IconButton(
              // ★追加⑤: 全選択/全解除ボタン
              icon: Icon(
                _lastLoadedDocs.isNotEmpty &&
                    _selectedIds.containsAll(
                        _lastLoadedDocs.map((d) => d.id).toSet())
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
              ),
              tooltip: '全選択/全解除',
              onPressed: _lastLoadedDocs.isEmpty ? null : _toggleSelectAll,
            ),
          if (_canDeleteEngineer)
          IconButton(
            icon: Icon(_selectionModeEnabled ? Icons.close : Icons.checklist),
            tooltip: _selectionModeEnabled ? '選択モードを終了' : '選択モード',
            onPressed: _toggleSelectionMode,
          ),
          if(_canDeleteEngineer && _selectionModeEnabled)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: '選択した項目を一括削除',
              color: _selectedIds.isEmpty ? Colors.grey : Colors.red,
              onPressed: _selectedIds.isEmpty ? null : _bulkDelete,
            ),
        ],
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
            _lastLoadedDocs = docs ?? []; // ★追加①: 全選択機能用にキャッシュ

            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && totalCount != (docs?.length ?? 0)) {
                setState(() => totalCount = docs?.length ?? 0);
              }
            });

            if (docs == null || docs.isEmpty) {
              return const Center(child: Text("該当するエンジニアが見つかりませんでした。"));
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,//左寄せ
              children: [
                _buildLegend(),//凡例
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final docId = docs[index].id; // ★追加③: チェックボックス用にID取得
                      final bool isSelected = _selectedIds.contains(docId); // ★追加③

                      return Card(
                        color: Color(0xFFFFFFFF),//カードの色
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            // ★追加④: 選択モード時はチェック切替、通常時は詳細画面へ
                            if (_selectionModeEnabled) {
                              _toggleSelected(docId);
                            } else {
                              _engineerDetailScreen(docId);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // ★追加③: 選択モード時のみチェックボックスを表示
                                    if (_selectionModeEnabled)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 4),
                                        child: Checkbox(
                                          value: isSelected,
                                          activeColor: themeColor,
                                          onChanged: (_) => _toggleSelected(docId),
                                        ),
                                      ),
                                    const CircleAvatar(
                                      backgroundColor: themeColor,//写真アイコンの色
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
                                                color: Colors.black,//年齢と駅の色
                                                fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right,
                                        color: Colors.grey),
                                  ],
                                ),
                                Divider(height: 24, thickness: 0.5, color: Colors.black87),
                                _buildSkillRow(Icons.account_tree, "工程",
                                    data['process'], processItem, data['process_experience'], true),
                                _buildSkillRow(Icons.group, "役割",
                                    data['team_role'], teamRoleItem, data['team_role_years'], false),
                                _buildSkillRow(Icons.code, "言語",
                                    data['code_languages'], codeLanguagesItem, data['code_languages_years'], false),
                      Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.black12),
                      child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,

                      title: const Text('その他のスキル情報',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black)),
                      childrenPadding: EdgeInsets.zero,
                      children: [
                                _buildSkillRow(Icons.storage, "DB",
                                    data['db_experience'], dbExperienceItem, data['db_experience_years'], false),
                                _buildSkillRow(Icons.memory_rounded, "OS",
                                    data['os_experience'], osExperienceItem, data['os_experience_years'], false),
                                _buildSkillRow(Icons.cloud_queue_rounded, "CLOUD",
                                    data['cloud_technology'], cloudTechnologyItem, data['cloud_technology_years'], false),
                                _buildSkillRow(Icons.build_circle_outlined, "TOOL",
                                    data['tool'], toolItem, data['tool_years'], true),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _detailSearchScreen,
        label:
            const Text('検索条件変更', style: TextStyle(fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.tune),
        backgroundColor: Colors.lightGreen.shade100,
      ),
    );
  }

// =============================================
// ③ _buildSkillRow を完全置き換え
// =============================================

  Widget _buildSkillRow(IconData icon, String label, dynamic numList,
      List<String> masterArray, dynamic valueList, bool isProcessOrTool) {

    // チップリストを生成
    final chips = <Widget>[];
    if (numList is List && masterArray.isNotEmpty && valueList is List) {
      for (int i = 0; i < numList.length; i++) {
        final itemIdx = numList[i] as int;
        if (itemIdx >= masterArray.length) continue;
        final valIdx = i < valueList.length ? (valueList[i] as int) : 0;
        chips.add(
          isProcessOrTool
              ? _buildProcessChip(masterArray[itemIdx], valIdx)
              : _buildYearChip(masterArray[itemIdx], valIdx),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ラベル行
          Row(
            children: [
              Icon(icon, size: 15, color: Colors.black),//工程、役割、言語、DB、OS、CLOUD、TOOLのアイコンの色
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black)),//工程、役割、言語、DB、OS、CLOUD、TOOLのアイコンの色
            ],
          ),
          const SizedBox(height: 8),
          // チップ行
          chips.isEmpty
              ? Text('登録情報がありません。',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600))
              : Wrap(spacing: 0, runSpacing: 6, children: chips),
        ],
      ),
    );
  }

// =============================================
// ① ランク判定ヘルパー（クラス内に追加）
// =============================================

// yearsList index → ランク色テーマ
// 0=1年未満, 1=1〜2年, 2=2〜3年, 3=3〜5年, 4=5〜10年, 5=10年以上
  _YearTheme _yearTheme(int yearIdx) {
    if (yearIdx >= 4)
      return _YearTheme(
          dot: const Color(0xFFFFAA00),
          border: const Color(0xFFFFAA00),
          // label: yearIdx == 5 ? '10年以上' : '5〜10年'
          label: ''
      );
    if (yearIdx >= 3)
      return _YearTheme(
          dot: const Color(0xFF4CAF50),
          border: const Color(0xFF4CAF50),
          // label: '3〜5年'
          label: ''
      );
    if (yearIdx >= 2)
      return _YearTheme(
          dot: const Color(0xFF4CAF50),
          border: const Color(0xFF4CAF50),
          label: ''
          // label: '2〜3年'
      );
    if (yearIdx >= 1)
      return _YearTheme(
          dot: const Color(0xFF2196F3),
          border: const Color(0xFF2196F3),
          // label: '1〜2年'
          label: ''
      );
    return _YearTheme(
        dot: const Color(0xFF9E9E9E),
        border: const Color(0xFF616161),
        // label: '1年未満'
        label: ''
    );
  }

// processLevelList index → ランク色テーマ
// 0=未経験, 1=経験あり作成サポート必要, 2=サポートなくできる, 3=経験豊富でレビューできる
  _YearTheme _levelTheme(int levelIdx, String name) {
    if (levelIdx >= 3)
      return _YearTheme(
          dot: const Color(0xFFFFAA00),
          border: const Color(0xFFFFAA00),
          label: name,
          isCheck: true);
    if (levelIdx >= 2)
      return _YearTheme(
          dot: const Color(0xFF4CAF50),
          border: const Color(0xFF4CAF50),
          label: name,
          isCheck: true);
    if (levelIdx >= 1)
      return _YearTheme(
          dot: const Color(0xFF9E9E9E),
          border: const Color(0xFF616161),
          label: name,
          isCheck: true);
    return _YearTheme(
        dot: const Color(0xFF555555),
        border: const Color(0xFF444444),
        label: name,
        isDash: true);
  }

// =============================================
// ② チップWidget（_buildTag の置き換え）
// =============================================
  Widget _buildYearChip(String name, int yearIdx) {
    final t = _yearTheme(yearIdx);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: Border.all(color: t.border, width: 3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: t.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(name,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black//Colors.white
              )),
          const SizedBox(width: 6),
          Text(t.label,
              style: TextStyle(fontSize: 11, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildProcessChip(String name, int levelIdx) {
    final t = _levelTheme(levelIdx, name);

    if (t.isDash) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: Border.all(color: t.border, width: 3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            t.isDash ? Icons.camera : Icons.camera,
            // Icons.remove : Icons.check,
            size: 12,
            color: t.dot,
          ),
          const SizedBox(width: 5),
          Text(name,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black)),
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

// 凡例（レジェンド）を表示するウィジェット
  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ランク凡例:",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              children: [
                _legendItem(const Color(0xFFFFAA00), "5年以上/リード可"),
                _legendItem(const Color(0xFF4CAF50), "2〜5年/独力可"),
                _legendItem(const Color(0xFF2196F3), "1〜2年/サポート有"),
                _legendItem(const Color(0xFF9E9E9E), "1年未満"),
              ],
            ),
          ],
        ),
      ),
    );
  }

// 凡例の各項目（丸い点とテキスト）
  Widget _legendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 10, color: Colors.black54)),
      ],
    );
  }
}
// search.dart の末尾（クラス外）に追加
class _YearTheme {
  final Color dot;
  final Color border;
  final String label;
  final bool isCheck;
  final bool isDash;
  const _YearTheme({
    required this.dot,
    required this.border,
    required this.label,
    this.isCheck = false,
    this.isDash = false,
  });
}
