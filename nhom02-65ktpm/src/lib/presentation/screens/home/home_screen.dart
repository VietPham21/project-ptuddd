import 'package:flutter/material.dart';

import '../../../application/meal_queries.dart';
import '../../../application/meal_trash_actions.dart';
import '../../../application/relog_meal.dart';
import '../../../application/session_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/di/injection_container.dart';
import '../../../core/result.dart';
import '../../../core/strings/app_strings.dart';
import '../../../core/strings/diary_strings.dart';
import '../../../core/strings/home_strings.dart';
import '../../../domain/entities/favorite_food.dart';
import '../../../domain/entities/meal.dart';
import '../../../domain/enums.dart';
import '../../../domain/rules/vn_calendar.dart';
import '../../widgets/disclaimer_note.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/meal_card.dart';
import '../../widgets/shimmer_box.dart';
import '../challenge/challenge_section.dart';
import '../relog/relog_screen.dart';
import '../review/review_meal_screen.dart';
import '../scan/scan_options_sheet.dart';

/// Trang chủ: lời chào, tóm tắt hôm nay, thử thách tuần, 3 bữa gần nhất, "Ăn lại".
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = sl<SessionService>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // Lời chào cập nhật ngay khi đổi tên/mục tiêu trong Hồ sơ.
          ListenableBuilder(
            listenable: session,
            builder: (context, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  HomeStrings.greeting(session.profile?.displayName ?? ''),
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  HomeStrings.goalLine(AppStrings.goal(session.goal)),
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _TodaySummary(),
          const SizedBox(height: 16),
          const ChallengeSection(),
          const SizedBox(height: 16),
          const _RelogShortcut(),
          const SizedBox(height: 8),
          const _RecentMeals(),
          const SizedBox(height: 16),
          const DisclaimerNote(full: true),
        ],
      ),
    );
  }
}

/// Tóm tắt hôm nay: số bữa, đồ uống nhiều đường, bữa có rau (định nghĩa như mục 7.1).
class _TodaySummary extends StatefulWidget {
  const _TodaySummary();

  @override
  State<_TodaySummary> createState() => _TodaySummaryState();
}

class _TodaySummaryState extends State<_TodaySummary> {
  late final Stream<List<Meal>> _stream =
      sl<MealQueries>().watchDay(VnCalendar.vnDateOf(DateTime.now()));

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Meal>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const ShimmerBox(height: 96);
        final meals = snapshot.data!;
        final sugary = meals
            .expand((m) => m.items)
            .where((i) => i.category == FoodCategory.drink && i.levels.sugar == Level.high)
            .length;
        final veg = meals.where((m) => m.items.any((i) => i.levels.veg != Level.low)).length;
        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Row(
              children: [
                _SummaryItem(
                    icon: Icons.restaurant, label: HomeStrings.mealsToday, value: meals.length),
                _SummaryItem(
                    icon: Icons.local_cafe_outlined,
                    label: HomeStrings.sugaryDrinksToday,
                    value: sugary),
                _SummaryItem(icon: Icons.eco_outlined, label: HomeStrings.vegMealsToday, value: veg),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(height: 6),
          Text('$value', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Lối tắt "Ăn lại": các món hay ăn, chạm 1 lần để ghi lại.
class _RelogShortcut extends StatefulWidget {
  const _RelogShortcut();

  @override
  State<_RelogShortcut> createState() => _RelogShortcutState();
}

class _RelogShortcutState extends State<_RelogShortcut> {
  late final Stream<List<FavoriteFood>> _stream = sl<MealQueries>().watchFavorites();

  void _relog(FavoriteFood favorite) {
    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    switch (sl<RelogMeal>()(favorite)) {
      case Ok(:final value):
        messenger.showSnackBar(SnackBar(
          content: Text(RelogStrings.logged(favorite.name)),
          action: SnackBarAction(
            label: AppStrings.undo,
            onPressed: () => sl<MealTrashActions>().deleteForever(value),
          ),
        ));
      case Err(:final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FavoriteFood>>(
      stream: _stream,
      builder: (context, snapshot) {
        final favorites = snapshot.data ?? const <FavoriteFood>[];
        if (favorites.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: HomeStrings.relogShortcut,
              action: HomeStrings.seeAll,
              onAction: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => const RelogScreen())),
            ),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: favorites.length.clamp(0, 8),
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final f = favorites[index];
                  return ActionChip(
                    avatar: Icon(RelogScreen.categoryIcon(f.category), size: 18),
                    label: Text(f.name),
                    onPressed: () => _relog(f),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 3 bữa gần nhất.
class _RecentMeals extends StatefulWidget {
  const _RecentMeals();

  @override
  State<_RecentMeals> createState() => _RecentMealsState();
}

class _RecentMealsState extends State<_RecentMeals> {
  late final Stream<List<Meal>> _stream = sl<MealQueries>().watchRecent(limit: 3);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SectionHeader(title: HomeStrings.recentMeals),
        StreamBuilder<List<Meal>>(
          stream: _stream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Column(children: [ShimmerBox(), ShimmerBox()]);
            }
            final meals = snapshot.data!;
            if (meals.isEmpty) {
              return EmptyState(
                icon: Icons.ramen_dining_outlined,
                title: HomeStrings.noMealsYet,
                message: HomeStrings.noMealsHint,
                actionLabel: HomeStrings.scanFirst,
                onAction: () => ScanOptionsSheet.show(context),
              );
            }
            return Column(
              children: [
                for (final meal in meals)
                  MealCard(
                    meal: meal,
                    showDate: true,
                    onTap: () => ReviewMealScreen.openExisting(context, meal),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
        ],
      ),
    );
  }
}
