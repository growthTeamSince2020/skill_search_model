import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// プロジェクト内の他画面・ユーティリティのインポート
import 'package:skill_search_model/permissionSettingsScreen.dart';
import 'package:skill_search_model/search.dart';
import 'package:skill_search_model/settings_screen.dart';
import 'package:skill_search_model/utils/objectsUtils.dart';
import 'package:skill_search_model/utils/uiUtils.dart';

import 'fileImportExportScreen.dart';
import 'engineerInputForm.dart';
import 'main.dart'; // appUserProviderなどを参照するために必要

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});
  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  int _selectedIndex = 0;
  bool _isSidebarVisible = true;

  final List<Map<String, dynamic>> menuItems = [
    {'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard, 'title': 'ダッシュボード'},
    {'icon': Icons.person_add_alt_1_outlined, 'activeIcon': Icons.person_add_alt_1, 'title': '技術者登録', 'page': EngineerInputForm(), 'roleRequired': 'editor'},
    {'icon': Icons.search_rounded, 'activeIcon': Icons.search_rounded, 'title': 'エンジニア検索一覧', 'page': const SearchPage()},
    {'icon': Icons.cloud_download_outlined, 'activeIcon': Icons.cloud_download, 'title': 'インポート', 'roleRequired': 'admin'},
    {'icon': Icons.cloud_upload_outlined, 'activeIcon': Icons.cloud_upload, 'title': 'エクスポート', 'roleRequired': 'admin'},
    {'icon': Icons.admin_panel_settings_outlined, 'activeIcon': Icons.admin_panel_settings, 'title': '権限設定', 'roleRequired': 'admin'},
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final appUserAsync = ref.watch(appUserProvider);

    return appUserAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('エラー: $err'))),
      data: (appUser) {
        final filteredMenu = menuItems.where((item) =>
            ObjectUtils.canAccessMenuItem(appUser, item)
        ).toList();

        final safeIndex = _selectedIndex >= filteredMenu.length ? 0 : _selectedIndex;

        return Scaffold(
          body: Row(
            children: [
              if (_isSidebarVisible)
                SizedBox(
                  width: 250,
                  child: NavigationDrawer(
                    selectedIndex: safeIndex,
                    onDestinationSelected: (index) {
                      setState(() => _selectedIndex = index);
                      final selectedItem = filteredMenu[index];

                      if (selectedItem['title'] == 'インポート' || selectedItem['title'] == 'エクスポート') {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const CsvImportExportScreen()));
                        return;
                      }
                      if (selectedItem['title'] == '権限設定') {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const PermissionSettingsScreen()));
                        return;
                      }
                      if (selectedItem['page'] != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => selectedItem['page']));
                      }
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(28, 32, 16, 20),
                        child: Row(
                          children: [
                            const Icon(Icons.hub_rounded, color: Color(0xFF2E7D32), size: 32),
                            const SizedBox(width: 12),
                            Text('Skill Hub', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      ...filteredMenu.map((item) => NavigationDrawerDestination(
                        icon: Icon(item['icon']),
                        selectedIcon: Icon(item['activeIcon']),
                        label: Text(item['title']),
                      )),
                      const Divider(indent: 28, endIndent: 28),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                          },
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          leading: CircleAvatar(
                            backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                            child: user?.photoURL == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text(user?.displayName ?? 'ユーザー名なし', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          subtitle: Text(UIUtils.getRoleDisplayName(appUser?.role), style: UIUtils.getRoleTextStyle()),
                          trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: TextButton.icon(
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          icon: const Icon(Icons.logout, size: 18, color: Colors.red),
                          label: const Text('ログアウト', style: TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Container(
                  color: const Color(0xFFF8FAFB),
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        floating: true,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        surfaceTintColor: Colors.transparent,
                        leading: IconButton(
                          icon: const Icon(Icons.menu_open_rounded),
                          onPressed: () => setState(() => _isSidebarVisible = !_isSidebarVisible),
                        ),
                        title: Text(filteredMenu.isEmpty ? '' : filteredMenu[safeIndex]['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        actions: [
                          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
                          const SizedBox(width: 16),
                        ],
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('engineer').snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: LinearProgressIndicator());
                              }
                              if (!snapshot.hasData) return const SizedBox.shrink();

                              final docs = snapshot.data?.docs.where((doc) => doc.id != 'sequenceNo').toList() ?? [];
                              final now = DateTime.now();

                              int totalCount = docs.length;
                              int thisMonthNewCount = 0;
                              Map<int, int> monthlyCounts = {};
                              List<int> lastSixMonths = [];

                              for (int i = 5; i >= 0; i--) {
                                final date = DateTime(now.year, now.month - i, 1);
                                monthlyCounts[date.month] = 0;
                                lastSixMonths.add(date.month);
                              }

                              for (var doc in docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                final regDate = data['registration_date'] as Timestamp?;
                                if (regDate != null) {
                                  final date = regDate.toDate();
                                  if (date.year == now.year && date.month == now.month) thisMonthNewCount++;
                                  if (monthlyCounts.containsKey(date.month)) monthlyCounts[date.month] = monthlyCounts[date.month]! + 1;
                                }
                              }

                              final List<FlSpot> lineDataReg = List.generate(lastSixMonths.length, (i) {
                                return FlSpot(i.toDouble(), monthlyCounts[lastSixMonths[i]]!.toDouble());
                              });

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      UIUtils.buildStatCard(label: '技術者数', value: totalCount.toString(), unit: '名', icon: Icons.people_outline, color: const Color(0xFF2E7D32)),
                                      const SizedBox(width: 16),
                                      UIUtils.buildStatCard(label: '今月の新規', value: thisMonthNewCount.toString(), unit: '名', icon: Icons.person_add_outlined, color: Colors.blue),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // --- グラフセクション ---
                                  UIUtils.buildFormSection(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('登録者数の推移 (直近6ヶ月)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 32),
                                        // 長いグラフ描画処理をメソッド化して呼び出し
                                        _buildRegistrationChart(lastSixMonths, lineDataReg),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- グラフ描画専用のメソッド (buildメソッドをスッキリさせるため) ---
  Widget _buildRegistrationChart(List<int> lastSixMonths, List<FlSpot> lineDataReg) {
    return Container(
      height: 200,
      padding: const EdgeInsets.only(right: 28, left: 12),
      child: LineChart(LineChartData(
        minX: 0, maxX: 5, minY: 0,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => Colors.blueAccent,
            getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
              '${s.y.toInt()}名',
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            )).toList(),
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: (v, meta) => SideTitleWidget(
                meta: meta,
                child: Text('${v.toInt()}', style: const TextStyle(fontSize: 10))
            ),
          )),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (v, meta) {
              if (v % 1 != 0) return const SizedBox();
              int idx = v.toInt();
              if (idx >= 0 && idx < lastSixMonths.length) {
                return SideTitleWidget(
                    meta: meta,
                    child: Text('${lastSixMonths[idx]}月', style: const TextStyle(fontSize: 10))
                );
              }
              return const SizedBox();
            },
          )),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: lineDataReg,
            isCurved: true,
            preventCurveOverShooting: true,
            color: Colors.blueAccent,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
                show: true,
                color: Colors.blueAccent.withOpacity(0.1)
            ),
          ),
        ],
      )),
    );
  }
}