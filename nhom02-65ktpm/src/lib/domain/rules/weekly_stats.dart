import '../entities/meal.dart';
import '../enums.dart';
import 'vn_calendar.dart';

/// Thống kê thói quen của MỘT tuần (thứ Hai 00:00 – Chủ nhật 23:59, giờ VN).
///
/// Định nghĩa đếm (mục 7.1 của đặc tả):
/// - Đồ uống nhiều đường: item có category == drink và sugar == high.
/// - Món nhiều dầu mỡ: item có fat == high.
/// - Bữa có rau: meal có ít nhất 1 item veg ∈ {medium, high}.
/// - Bữa nhiều tinh bột: meal có ít nhất 1 item carb == high.
/// - Số ngày có ghi nhận: số ngày (giờ VN) khác nhau có ít nhất 1 meal.
/// Chỉ tính meal chưa xóa mềm và có eaten_at nằm trong tuần.
class WeeklyStats {
  const WeeklyStats({
    required this.weekStart,
    this.totalMeals = 0,
    this.sugaryDrinks = 0,
    this.lessSugarDrinks = 0,
    this.highFatItems = 0,
    this.friedMeals = 0,
    this.mealsWithVeg = 0,
    this.highCarbMeals = 0,
    this.loggedDays = 0,
    this.mealsPerDay = const [0, 0, 0, 0, 0, 0, 0],
  });

  /// Ngày thứ Hai đầu tuần (VN date).
  final DateTime weekStart;
  final int totalMeals;

  /// Đồ uống nhiều đường (drink + sugar high).
  final int sugaryDrinks;

  /// Đồ uống ít/vừa đường (drink + sugar low/medium) – dùng cho thử thách.
  final int lessSugarDrinks;

  /// Số MÓN nhiều dầu mỡ (fat high).
  final int highFatItems;

  /// Số BỮA có ít nhất 1 món nhiều dầu mỡ – dùng cho thử thách.
  final int friedMeals;
  final int mealsWithVeg;
  final int highCarbMeals;
  final int loggedDays;

  /// Số bữa mỗi ngày, thứ Hai -> Chủ nhật.
  final List<int> mealsPerDay;

  /// Tỷ lệ bữa có rau (0..1).
  double get vegRatio => totalMeals == 0 ? 0 : mealsWithVeg / totalMeals;

  static WeeklyStats compute(List<Meal> meals, DateTime weekStart) {
    final range = VnCalendar.weekRangeUtc(weekStart);
    final inWeek = meals.where((m) =>
        !m.isDeleted &&
        !m.eatenAt.isBefore(range.start) &&
        m.eatenAt.isBefore(range.end));

    var total = 0, sugary = 0, lessSugar = 0, highFat = 0;
    var friedMeals = 0, veg = 0, highCarb = 0;
    final days = <DateTime>{};
    final perDay = List<int>.filled(7, 0);

    for (final meal in inWeek) {
      total++;
      final day = VnCalendar.vnDateOf(meal.eatenAt);
      days.add(day);
      perDay[day.difference(weekStart).inDays.clamp(0, 6)]++;

      var mealHasFat = false, mealHasVeg = false, mealHasCarb = false;
      for (final item in meal.items) {
        final levels = item.levels;
        if (item.category == FoodCategory.drink) {
          if (levels.sugar == Level.high) {
            sugary++;
          } else {
            lessSugar++;
          }
        }
        if (levels.fat == Level.high) {
          highFat++;
          mealHasFat = true;
        }
        if (levels.veg != Level.low) mealHasVeg = true;
        if (levels.carb == Level.high) mealHasCarb = true;
      }
      if (mealHasFat) friedMeals++;
      if (mealHasVeg) veg++;
      if (mealHasCarb) highCarb++;
    }

    return WeeklyStats(
      weekStart: weekStart,
      totalMeals: total,
      sugaryDrinks: sugary,
      lessSugarDrinks: lessSugar,
      highFatItems: highFat,
      friedMeals: friedMeals,
      mealsWithVeg: veg,
      highCarbMeals: highCarb,
      loggedDays: days.length,
      mealsPerDay: perDay,
    );
  }
}
