import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// プロジェクト内の他画面・ユーティリティのインポート
import 'package:skill_search_model/permissionSettingsScreen.dart';
import 'package:skill_search_model/accountManagementScreen.dart';
import 'package:skill_search_model/search.dart';
import 'package:skill_search_model/settings_screen.dart';
import 'package:skill_search_model/utils/objectsUtils.dart';
import 'package:skill_search_model/utils/uiUtils.dart';
import 'package:skill_search_model/common/constData.dart';

import 'adminInvitationScreen.dart';
import 'staffInvitationScreen.dart';
import 'fileImportExportScreen.dart';
import 'engineerInputForm.dart';
import 'main.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});
  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  int _selectedIndex = 0;
  bool _isSidebarVisible = true;

  // メメニューアイテムの定義
  final List<Map<String, dynamic>> menuItems = [
    {'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard, 'title': 'ダッシュボード'},
    {'icon': Icons.person_add_alt_1_outlined, 'activeIcon': Icons.person_add_alt_1, 'title': '技術者登録', 'page': const EngineerInputForm(), 'roleRequired': 'editor'},
    {'icon': Icons.search_rounded, 'activeIcon': Icons.search_rounded, 'title': '技術者検索一覧', 'page': const SearchPage()},
    {'icon': Icons.cloud_download_outlined, 'activeIcon': Icons.cloud_download, 'title': 'インポート', 'roleRequired': constData.roleAdmin},
    {'icon': Icons.cloud_upload_outlined, 'activeIcon': Icons.cloud_upload, 'title': 'エクスポート', 'roleRequired': constData.roleAdmin},
    {'icon': Icons.person_add_rounded, 'activeIcon': Icons.person_add_rounded, 'title': '自社スタッフ招待', 'roleRequired': constData.roleAdmin},
    {'icon': Icons.manage_accounts_outlined, 'activeIcon': Icons.manage_accounts, 'title': 'アカウント一覧', 'roleRequired': constData.roleAdmin},
    {'icon': Icons.admin_panel_settings_outlined, 'activeIcon': Icons.admin_panel_settings, 'title': '権限設定', 'roleRequired': constData.roleAdmin},
    {'icon': Icons.business_rounded, 'activeIcon': Icons.business_rounded, 'title': '企業初回登録案内', 'roleRequired': constData.roleOwner},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final appUserAsync = ref.watch(appUserProvider);

    return appUserAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator(color: constData.themeGreen))),
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
                  width: 260,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.1))),
                    ),
                    child: NavigationDrawer(
                      backgroundColor: Colors.white,
                      indicatorColor: constData.themeGreen.withOpacity(0.1),
                      selectedIndex: safeIndex,
                      onDestinationSelected: (index) {
                        setState(() => _selectedIndex = index);
                        final selectedItem = filteredMenu[index];
                        _handleNavigation(selectedItem);
                      },
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(28, 32, 16, 24),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.directions_run_rounded,
                                color: constData.themeGreen,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                constData.systemName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),

                        ...filteredMenu.map((item) => NavigationDrawerDestination(
                          icon: Icon(item['icon'], color: Colors.black54),
                          selectedIcon: Icon(item['activeIcon'], color: constData.themeGreen),
                          label: Text(item['title'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        )),

                        const Divider(indent: 24, endIndent: 24, height: 40),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: ListTile(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(constData.borderRadius)),
                            leading: CircleAvatar(
                              backgroundColor: constData.themeGreen.withOpacity(0.1),
                              backgroundImage: (user?.photoURL != null && user!.photoURL!.isNotEmpty)
                                  ? NetworkImage(user.photoURL!) : null,
                              child: (user?.photoURL == null || user!.photoURL!.isEmpty)
                                  ? const Icon(Icons.person, color: constData.themeGreen) : null,
                            ),
                            title: Text(appUser?.displayName ?? user?.displayName ?? 'ユーザー',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text(UIUtils.getRoleDisplayName(appUser?.role),
                                style: const TextStyle(fontSize: 11, color: Colors.black45)),
                            trailing: const Icon(Icons.settings_outlined, size: 18, color: Colors.black26),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: TextButton.icon(
                            onPressed: () => FirebaseAuth.instance.signOut(),
                            icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.redAccent),
                            label: const Text('ログアウト', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                            style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // --- メインコンテンツ ---
              Expanded(
                child: Container(
                  color: const Color(0xFFF8FAFB),
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        floating: true,
                        backgroundColor: Colors.white,
                        elevation: 0,
                        scrolledUnderElevation: 0,
                        leading: IconButton(
                          icon: Icon(_isSidebarVisible ? Icons.menu_open_rounded : Icons.menu_rounded, color: Colors.black87),
                          onPressed: () => setState(() => _isSidebarVisible = !_isSidebarVisible),
                        ),
                        title: Text(
                          filteredMenu.isEmpty ? '' : filteredMenu[safeIndex]['title'],
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        bottom: PreferredSize(
                          preferredSize: const Size.fromHeight(1.0),
                          child: Container(color: Colors.grey.withOpacity(0.1), height: 1.0),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(constData.cardPadding),
                          child: _buildDashboardContent(theme, appUser), // ★ 修正：appUser を渡す
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

  void _handleNavigation(Map<String, dynamic> selectedItem) {
    switch (selectedItem['title']) {
      case 'アカウント一覧':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountManagementScreen()));
        break;
      case '権限設定':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const PermissionSettingsScreen()));
        break;
      case '自社スタッフ招待':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const StaffInvitationScreen()));
        break;
      case 'インポート':
      case 'エクスポート':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const CsvImportExportScreen()));
        break;
      case '企業初回登録案内':
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminInvitationScreen()));
        break;
      default:
        if (selectedItem['page'] != null) {
          Navigator.push(context, MaterialPageRoute(builder: (context) => selectedItem['page']));
        }
    }
  }

  // ★ 修正：引数に appUser を追加
  Widget _buildDashboardContent(ThemeData theme, dynamic appUser) {
    // ログインユーザーの法人コードを取得（String型に安全に変換）
    final myCompanyCode = appUser?.companyCode?.toString() ?? '';

    return StreamBuilder<QuerySnapshot>(
      // ★ 修正：法人コードが一致する技術者のみをリタイム監視するクエリに変更
      stream: FirebaseFirestore.instance
          .collection('engineer')
          .where('companyCode', isEqualTo: myCompanyCode)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: LinearProgressIndicator(color: constData.themeGreen));
        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = snapshot.data?.docs.where((doc) => doc.id != 'sequenceNo').toList() ?? [];
        final now = DateTime.now();

        int totalCount = docs.length;
        int thisMonthNewCount = 0;

        List<DateTime> lastSixMonthsDates = [];
        List<int> lastSixMonths = [];
        for (int i = 5; i >= 0; i--) {
          final date = DateTime(now.year, now.month - i, 1);
          lastSixMonthsDates.add(date);
          lastSixMonths.add(date.month);
        }

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final regDate = data['registration_date'] as Timestamp?;
          if (regDate != null) {
            final date = regDate.toDate();
            if (date.year == now.year && date.month == now.month) {
              thisMonthNewCount++;
            }
          }
        }

        final List<FlSpot> lineDataReg = List.generate(lastSixMonthsDates.length, (i) {
          final targetMonth = lastSixMonthsDates[i];
          int monthlyNewCount = 0;
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final regDate = data['registration_date'] as Timestamp?;
            if (regDate != null) {
              final date = regDate.toDate();
              if (date.year == targetMonth.year && date.month == targetMonth.month) {
                monthlyNewCount++;
              }
            }
          }
          return FlSpot(i.toDouble(), monthlyNewCount.toDouble());
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UIUtils.buildStatCard(
                    label: '登録技術者数',
                    value: totalCount.toString(),
                    unit: '名',
                    icon: Icons.people_alt_rounded,
                    color: constData.themeGreen
                ),
                const SizedBox(width: 16),
                UIUtils.buildStatCard(
                    label: '今月の新規登録',
                    value: thisMonthNewCount.toString(),
                    unit: '名',
                    icon: Icons.person_add_rounded,
                    color: Colors.blueAccent
                ),
              ],
            ),
            const SizedBox(height: 24),
            UIUtils.buildFormSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '登録者数の推移 (直近6ヶ月)',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 40),
                  _buildRegistrationChart(lastSixMonths, lineDataReg, totalCount),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRegistrationChart(List<int> lastSixMonths, List<FlSpot> lineDataReg, int totalCount) {
    double maxYValue = totalCount.toDouble();
    double chartMaxY = ((maxYValue / 10).ceil() * 10).toDouble();
    if (chartMaxY < 10) chartMaxY = 10;
    double sideInterval = chartMaxY / 5;

    return Container(
      height: 240,
      padding: const EdgeInsets.only(right: 20, left: 0, top: 10),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: 5,
          minY: 0,
          maxY: chartMaxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => constData.themeGreen.withOpacity(0.9),
              getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                '${s.y.toInt()}名',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              )).toList(),
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 35,
                interval: sideInterval,
                getTitlesWidget: (v, meta) => SideTitleWidget(
                  meta: meta,
                  child: Text(
                    '${v.toInt()}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (v, meta) {
                  int idx = v.toInt();
                  if (idx >= 0 && idx < lastSixMonths.length) {
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        '${lastSixMonths[idx]}月',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: sideInterval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.withOpacity(0.05),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: lineDataReg,
              isCurved: true,
              preventCurveOverShooting: true,
              color: constData.themeGreen,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: constData.themeGreen,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    constData.themeGreen.withOpacity(0.2),
                    constData.themeGreen.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}