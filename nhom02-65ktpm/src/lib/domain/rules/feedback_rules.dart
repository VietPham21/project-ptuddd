import 'weekly_stats.dart';

/// Mã câu phản hồi tuần. Tầng giao diện đổi mã thành câu tiếng Việt
/// (ReportStrings.feedback), nhờ vậy quy tắc ở đây test được bằng Dart thuần.
enum FeedbackCode {
  sugaryDrinksDown,
  sugaryDrinksUp,
  noSugaryDrinks,
  lowVeg,
  goodVeg,
  manyFried,
  keepGoing,
}

class WeeklyFeedback {
  const WeeklyFeedback(this.code, {this.current, this.previous});

  final FeedbackCode code;
  final int? current;
  final int? previous;

  @override
  String toString() => 'WeeklyFeedback($code, $current, $previous)';
}

/// Sinh tối đa 3 câu phản hồi tuần dựa trên quy tắc, giọng tích cực (mục 7.3).
class FeedbackRules {
  FeedbackRules._();

  static const int maxMessages = 3;
  static const double lowVegRatio = 0.5;
  static const double goodVegRatio = 0.7;
  static const int manyFriedThreshold = 5;

  static List<WeeklyFeedback> build({
    required WeeklyStats current,
    required bool currentSufficient,
    WeeklyStats? previous,
    bool previousSufficient = false,
  }) {
    // Tuần này chưa đủ dữ liệu -> không nhận xét.
    if (!currentSufficient) return const [];

    final result = <WeeklyFeedback>[];

    // 1. So sánh đồ uống nhiều đường với tuần trước (chỉ khi tuần trước đủ dữ liệu).
    var compared = false;
    if (previous != null && previousSufficient) {
      if (current.sugaryDrinks < previous.sugaryDrinks) {
        result.add(WeeklyFeedback(FeedbackCode.sugaryDrinksDown,
            current: current.sugaryDrinks, previous: previous.sugaryDrinks));
        compared = true;
      } else if (current.sugaryDrinks > previous.sugaryDrinks) {
        result.add(WeeklyFeedback(FeedbackCode.sugaryDrinksUp,
            current: current.sugaryDrinks, previous: previous.sugaryDrinks));
        compared = true;
      }
    }
    if (!compared && current.sugaryDrinks == 0) {
      result.add(const WeeklyFeedback(FeedbackCode.noSugaryDrinks));
    }

    // 2. Rau: dưới 50% số bữa -> gợi ý nhẹ; từ 70% -> khen.
    if (current.totalMeals > 0) {
      if (current.vegRatio < lowVegRatio) {
        result.add(WeeklyFeedback(FeedbackCode.lowVeg,
            current: current.mealsWithVeg, previous: current.totalMeals));
      } else if (current.vegRatio >= goodVegRatio) {
        result.add(WeeklyFeedback(FeedbackCode.goodVeg,
            current: current.mealsWithVeg, previous: current.totalMeals));
      }
    }

    // 3. Món nhiều dầu mỡ >= 5 -> gợi ý đổi sang luộc/hấp vài bữa.
    if (current.highFatItems >= manyFriedThreshold) {
      result.add(WeeklyFeedback(FeedbackCode.manyFried, current: current.highFatItems));
    }

    if (result.isEmpty) result.add(const WeeklyFeedback(FeedbackCode.keepGoing));
    return result.take(maxMessages).toList();
  }
}
