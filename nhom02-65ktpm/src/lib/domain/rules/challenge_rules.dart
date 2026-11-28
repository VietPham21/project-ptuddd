import 'dart:math' as math;

import '../entities/challenge.dart';
import '../enums.dart';
import 'vn_calendar.dart';
import 'weekly_stats.dart';

/// Thử thách được đề xuất cho tuần mới.
class ChallengeProposal {
  const ChallengeProposal(this.type, this.target);

  final ChallengeType type;
  final int target;

  @override
  bool operator ==(Object other) =>
      other is ChallengeProposal && other.type == type && other.target == target;

  @override
  int get hashCode => Object.hash(type, target);

  @override
  String toString() => 'ChallengeProposal(${type.value}, $target)';
}

/// Quy tắc thử thách tuần (mục 7.4), Dart thuần, có unit test.
class ChallengeRules {
  ChallengeRules._();

  /// Thử thách mặc định nhẹ nhàng khi tuần trước chưa đủ dữ liệu.
  static const defaultProposal = ChallengeProposal(ChallengeType.vegMeals, 5);

  /// Đề xuất thử thách dựa trên tuần trước (chỉ khi tuần trước ĐỦ dữ liệu).
  ///
  /// Ví dụ: tuần trước 5 đồ uống nhiều đường -> `max_sugary_drinks`,
  /// target = max(0, 5 - 2) = 3.
  static ChallengeProposal propose({
    required WeeklyStats? lastWeek,
    required bool lastWeekSufficient,
    required Goal goal,
  }) {
    if (lastWeek == null || !lastWeekSufficient) return defaultProposal;

    final sugar = lastWeek.sugaryDrinks >= 3
        ? ChallengeProposal(ChallengeType.maxSugaryDrinks, math.max(0, lastWeek.sugaryDrinks - 2))
        : null;
    final fried = lastWeek.friedMeals >= 4
        ? ChallengeProposal(ChallengeType.maxFriedMeals, math.max(0, lastWeek.friedMeals - 2))
        : null;
    final veg = lastWeek.vegRatio < 0.5
        ? ChallengeProposal(ChallengeType.vegMeals, (lastWeek.mealsWithVeg + 2).clamp(3, 14))
        : null;
    final lessSugar = lastWeek.sugaryDrinks > 0
        ? ChallengeProposal(
            ChallengeType.lessSugarOrders, (lastWeek.lessSugarDrinks + 2).clamp(2, 10))
        : null;

    // Thứ tự ưu tiên theo mục tiêu của người dùng.
    final ordered = switch (goal) {
      Goal.lessSugar => [sugar, lessSugar, veg, fried],
      Goal.weightLoss => [sugar, fried, veg],
      Goal.balanced => [veg, fried, sugar],
    };
    for (final proposal in ordered) {
      if (proposal != null) return proposal;
    }
    // Tuần trước đã khá tốt: duy trì thói quen ăn rau.
    return ChallengeProposal(ChallengeType.vegMeals, (lastWeek.mealsWithVeg + 1).clamp(5, 14));
  }

  /// Tiến độ = đếm lại từ thống kê tuần (không cộng dồn thủ công).
  static int progressFor(ChallengeType type, WeeklyStats stats) => switch (type) {
        ChallengeType.maxSugaryDrinks => stats.sugaryDrinks,
        ChallengeType.lessSugarOrders => stats.lessSugarDrinks,
        ChallengeType.vegMeals => stats.mealsWithVeg,
        ChallengeType.maxFriedMeals => stats.friedMeals,
      };

  /// Kết quả khi tuần kết thúc:
  /// - loại "tối đa": progress <= target -> completed, ngược lại failed;
  /// - loại "tối thiểu": progress >= target -> completed, ngược lại failed.
  static ChallengeStatus evaluate(ChallengeType type, int target, int progress) {
    final success = type.isMaxType ? progress <= target : progress >= target;
    return success ? ChallengeStatus.completed : ChallengeStatus.failed;
  }

  /// Giữa tuần: thử thách "tối đa" đã vượt mục tiêu chưa / "tối thiểu" đã đạt chưa.
  static bool isOnTrack(ChallengeType type, int target, int progress) =>
      type.isMaxType ? progress <= target : progress >= target;

  /// Streak: số tuần LIÊN TIẾP gần nhất có thử thách `completed`.
  /// Tuần hiện tại (đang diễn ra) không làm đứt chuỗi.
  static int streak(List<Challenge> challenges, {required String currentWeekStart}) {
    final completedWeeks = {
      for (final c in challenges)
        if (c.status == ChallengeStatus.completed) c.weekStart,
    };
    var count = completedWeeks.contains(currentWeekStart) ? 1 : 0;
    var week = VnCalendar.parseDateKey(currentWeekStart).subtract(const Duration(days: 7));
    while (completedWeeks.contains(VnCalendar.dateKey(week))) {
      count++;
      week = week.subtract(const Duration(days: 7));
    }
    return count;
  }
}
