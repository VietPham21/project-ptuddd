import 'package:flutter/material.dart';

import '../../../application/session_service.dart';
import '../../../application/tips_cache.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/strings/menu_strings.dart';
import '../../../domain/entities/tip.dart';
import '../../../domain/enums.dart';
import '../../../domain/rules/tip_selector.dart';
import '../../widgets/disclaimer_note.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/tip_card.dart';

/// Thư viện gợi ý phù hợp mục tiêu hiện tại, nhóm theo loại món.
class GoalTipsScreen extends StatefulWidget {
  const GoalTipsScreen({super.key});

  @override
  State<GoalTipsScreen> createState() => _GoalTipsScreenState();
}

class _GoalTipsScreenState extends State<GoalTipsScreen> {
  final _cache = sl<TipsCache>();
  final _session = sl<SessionService>();

  @override
  void initState() {
    super.initState();
    _cache.ensureLoaded();
  }

  /// Nhóm theo loại món đầu tiên trong `applies_to.category` (không có -> "Chung").
  Map<String, List<Tip>> _group(List<Tip> tips) {
    final groups = <String, List<Tip>>{};
    for (final tip in tips) {
      final categories = tip.appliesTo['category'] ?? const [];
      final category =
          categories.isEmpty ? null : tryParseWire(FoodCategory.values, categories.first);
      final key = category == null ? MenuStrings.generalGroup : AppStrings.category(category);
      groups.putIfAbsent(key, () => []).add(tip);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final goal = _session.goal;
    return Scaffold(
      appBar: AppBar(title: Text(MenuStrings.goalTipsTitle(AppStrings.goal(goal)))),
      body: ListenableBuilder(
        listenable: _cache,
        builder: (context, _) {
          final tips = TipSelector.forGoal(_cache.tips, goal);
          if (tips.isEmpty) {
            return const EmptyState(
              icon: Icons.lightbulb_outline,
              title: MenuStrings.tipsEmpty,
            );
          }
          final groups = _group(tips);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const DisclaimerNote(full: true),
              for (final entry in groups.entries) ...[
                const SizedBox(height: 16),
                Text(
                  entry.key,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                for (final tip in entry.value) TipCard(tip: tip.toSnapshot()),
              ],
            ],
          );
        },
      ),
    );
  }
}
