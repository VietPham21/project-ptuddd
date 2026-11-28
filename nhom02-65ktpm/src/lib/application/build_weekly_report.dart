import '../domain/entities/meal.dart';
import '../domain/repositories/meal_repository.dart';
import '../domain/rules/data_sufficiency.dart';
import '../domain/rules/feedback_rules.dart';
import '../domain/rules/vn_calendar.dart';
import '../domain/rules/weekly_stats.dart';
import 'session_service.dart';

/// Báo cáo tuần: tuần này + tuần trước, đủ dữ liệu hay chưa, câu phản hồi.
class WeeklyReport {
  const WeeklyReport({
    required this.current,
    required this.previous,
    required this.currentSufficient,
    required this.previousSufficient,
    required this.feedback,
  });

  final WeeklyStats current;
  final WeeklyStats previous;
  final bool currentSufficient;
  final bool previousSufficient;
  final List<WeeklyFeedback> feedback;
}

class BuildWeeklyReport {
  BuildWeeklyReport(this._meals, this._session);

  final MealRepository _meals;
  final SessionService _session;

  /// Khoảng thời gian UTC bao trùm tuần trước + tuần này.
  static ({DateTime start, DateTime end, DateTime currentWeekStart}) _range(DateTime now) {
    final currentWeekStart = VnCalendar.weekStartOf(now);
    final previousWeekStart = currentWeekStart.subtract(const Duration(days: 7));
    return (
      start: VnCalendar.weekRangeUtc(previousWeekStart).start,
      end: VnCalendar.weekRangeUtc(currentWeekStart).end,
      currentWeekStart: currentWeekStart,
    );
  }

  /// Báo cáo cập nhật realtime khi nhật ký thay đổi (kể cả từ thiết bị khác).
  Stream<WeeklyReport> watch({DateTime? now}) {
    final r = _range(now ?? DateTime.now());
    return _meals
        .watchMealsBetween(_session.uid, r.start, r.end)
        .map((meals) => build(meals, r.currentWeekStart));
  }

  Future<WeeklyReport> load({DateTime? now}) async {
    final r = _range(now ?? DateTime.now());
    final meals = await _meals.getMealsBetween(_session.uid, r.start, r.end);
    return build(meals, r.currentWeekStart);
  }

  /// Tính báo cáo từ danh sách bữa ăn (hàm thuần, dễ test).
  static WeeklyReport build(List<Meal> meals, DateTime currentWeekStart) {
    final previousWeekStart = currentWeekStart.subtract(const Duration(days: 7));
    final current = WeeklyStats.compute(meals, currentWeekStart);
    final previous = WeeklyStats.compute(meals, previousWeekStart);
    final currentSufficient = DataSufficiency.isSufficient(current);
    final previousSufficient = DataSufficiency.isSufficient(previous);
    return WeeklyReport(
      current: current,
      previous: previous,
      currentSufficient: currentSufficient,
      previousSufficient: previousSufficient,
      feedback: FeedbackRules.build(
        current: current,
        currentSufficient: currentSufficient,
        previous: previous,
        previousSufficient: previousSufficient,
      ),
    );
  }
}
