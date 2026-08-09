import 'package:flutter/material.dart';

/// 選択肢と経験レベル（複数選択可・OR条件）をチップでまとめて選べる共通ウィジェット
///
/// - items    : 選択肢のラベル一覧（"Python","JAVA"... など）
/// - levels   : 経験レベルのラベル一覧（"1年未満","1〜2年"... など）
/// - selected : 現在の選択状態 { itemIndex: {levelIndex, levelIndex, ...} }
///              1つのitemに対して複数levelを持てる＝OR条件
/// - onChanged: 選択状態が変わるたびに新しい selected 全体を返す
///
/// 工程・チーム役割・経験言語・DB・OS・クラウド・ツール、
/// すべてこの1つのウィジェットで表示できます（見た目・挙動を一元管理）。
class SkillChipGroup extends StatelessWidget {
  final List<String> items;
  final List<String> levels;
  final Map<int, Set<int>> selected;
  final ValueChanged<Map<int, Set<int>>> onChanged;

  const SkillChipGroup({
    super.key,
    required this.items,
    required this.levels,
    required this.selected,
    required this.onChanged,
  });

  static const _accent = Color(0xFF2E7D32);
  static const _popoverWidth = 220.0;

  void _openPicker(BuildContext chipContext, int itemIndex) {
    final overlayState = Overlay.of(chipContext);
    final RenderBox chipBox = chipContext.findRenderObject() as RenderBox;
    final RenderBox overlayBox =
        overlayState.context.findRenderObject() as RenderBox;

    final Offset chipTopLeft =
        chipBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final Size chipSize = chipBox.size;

    late OverlayEntry entry;
    // ポップアップを開いている間だけ使う作業用コピー。
    // チェックのたびに即座に外側の selected へも反映する。
    final Set<int> working = Set<int>.from(selected[itemIndex] ?? {});

    double left = chipTopLeft.dx;
    final double maxLeft = overlayBox.size.width - _popoverWidth - 12;
    if (left > maxLeft) left = maxLeft.clamp(12, double.infinity);

    entry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            // 背景タップで閉じる透明レイヤー
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => entry.remove(),
              ),
            ),
            Positioned(
              left: left,
              top: chipTopLeft.dy + chipSize.height + 6,
              child: StatefulBuilder(
                builder: (context, setLocalState) {
                  return Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: Container(
                      width: _popoverWidth,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
                            child: Text(
                              '${items[itemIndex]} ・経験レベル（複数選択可）',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...List.generate(levels.length, (li) {
                            final bool on = working.contains(li);
                            return InkWell(
                              onTap: () {
                                setLocalState(() {
                                  on ? working.remove(li) : working.add(li);
                                });
                                final newMap =
                                    Map<int, Set<int>>.from(selected);
                                if (working.isEmpty) {
                                  newMap.remove(itemIndex);
                                } else {
                                  newMap[itemIndex] = Set<int>.from(working);
                                }
                                onChanged(newMap);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                child: Row(
                                  children: [
                                    Icon(
                                      on
                                          ? Icons.check_box
                                          : Icons.check_box_outline_blank,
                                      size: 20,
                                      color: on ? _accent : Colors.grey,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(levels[li],
                                          style:
                                              const TextStyle(fontSize: 13)),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const Divider(height: 12),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(10, 0, 10, 4),
                            child: SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: () => entry.remove(),
                                child: const Text(
                                  '閉じる',
                                  style: TextStyle(
                                      color: _accent,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );

    overlayState.insert(entry);
  }

  String _levelSummary(Set<int> levelSet) {
    final sorted = levelSet.toList()..sort();
    if (sorted.length == 1) return levels[sorted.first];
    return '${levels[sorted.first]} 他${sorted.length - 1}件';
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(items.length, (index) {
        final Set<int> levelSet = selected[index] ?? {};
        final bool isSelected = levelSet.isNotEmpty;
        final String label = isSelected
            ? '${items[index]} ・${_levelSummary(levelSet)}'
            : items[index];

        return Builder(
          builder: (chipContext) => ChoiceChip(
            label: Text(label, style: const TextStyle(fontSize: 13)),
            selected: isSelected,
            selectedColor: _accent,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            backgroundColor: Colors.white,
            side: BorderSide(
                color: isSelected ? _accent : Colors.grey.shade300),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            onSelected: (_) => _openPicker(chipContext, index),
          ),
        );
      }),
    );
  }
}

/// --- 既存の List<bool> / List<List<bool>> 状態との橋渡しヘルパー ---
/// seachDetail.dart の状態管理（Providerの型）は変えずに、
/// SkillChipGroup が使う Map<int, Set<int>> との相互変換だけを行います。

Map<int, Set<int>> checkedListsToMap(
    List<bool> mainChecked, List<List<bool>> itemChecked) {
  final map = <int, Set<int>>{};
  for (int i = 0; i < mainChecked.length; i++) {
    final levels = <int>{};
    for (int j = 0; j < itemChecked[i].length; j++) {
      if (itemChecked[i][j]) levels.add(j);
    }
    if (levels.isNotEmpty) map[i] = levels;
  }
  return map;
}

void applyMapToCheckedLists(
    Map<int, Set<int>> map, List<bool> mainChecked, List<List<bool>> itemChecked) {
  for (int i = 0; i < mainChecked.length; i++) {
    final levels = map[i];
    mainChecked[i] = levels != null && levels.isNotEmpty;
    for (int j = 0; j < itemChecked[i].length; j++) {
      itemChecked[i][j] = levels?.contains(j) ?? false;
    }
  }
}
