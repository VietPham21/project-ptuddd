import '../../domain/rules/feedback_rules.dart';

/// Chuỗi của phân hệ Thống kê thói quen & Báo cáo tuần.
class ReportStrings {
  ReportStrings._();

  static const title = 'Báo cáo tuần';
  static String weekRange(String from, String to) => 'Tuần này ($from – $to)';
  static const notEnoughData = 'Chưa đủ dữ liệu để đánh giá';
  static String notEnoughDataHint(int days, int minDays) =>
      'Ghi nhận ít nhất $minDays ngày trong tuần để nhận nhận xét. Hiện có $days ngày.';
  static const previousNotEnough = 'Tuần trước chưa đủ dữ liệu nên chưa so sánh.';
  static const loggedDays = 'Ngày có ghi nhận';
  static const sugaryDrinks = 'Đồ uống nhiều đường';
  static const highFatItems = 'Món nhiều dầu mỡ';
  static const vegMeals = 'Bữa có rau';
  static const highCarbMeals = 'Bữa nhiều tinh bột';
  static const chartTitle = 'So sánh với tuần trước';
  static const lastWeek = 'Tuần trước';
  static const thisWeek = 'Tuần này';
  static const feedbackTitle = 'Nhận xét tuần này';
  static const loadError = 'Không tải được báo cáo, thử lại sau nhé.';

  // Nhãn ngắn cho trục biểu đồ
  static const chartSugary = 'Đồ ngọt';
  static const chartFat = 'Dầu mỡ';
  static const chartVeg = 'Có rau';
  static const chartCarb = 'Tinh bột';

  /// Đổi mã phản hồi thành câu tiếng Việt (giọng tích cực, không chê trách).
  static String feedback(WeeklyFeedback f) => switch (f.code) {
        FeedbackCode.sugaryDrinksDown =>
          'Tuyệt vời! Tuần này bạn có ${f.current} ly đồ ngọt, ít hơn tuần trước '
              '${(f.previous ?? 0) - (f.current ?? 0)} ly.',
        FeedbackCode.sugaryDrinksUp =>
          'Tuần này có ${f.current} ly đồ ngọt, nhiều hơn tuần trước một chút. '
              'Thử gọi ít đường ở vài ly tới nhé.',
        FeedbackCode.noSugaryDrinks => 'Cả tuần không có đồ uống nhiều đường – rất đáng khen!',
        FeedbackCode.lowVeg =>
          'Mới có ${f.current}/${f.previous} bữa có rau. Thử thêm rau vào bữa tối nhé.',
        FeedbackCode.goodVeg =>
          '${f.current}/${f.previous} bữa có rau – bạn đang làm rất tốt!',
        FeedbackCode.manyFried =>
          'Tuần này có ${f.current} món nhiều dầu mỡ, thử đổi vài bữa sang món luộc hoặc hấp nhé.',
        FeedbackCode.keepGoing => 'Bạn đang ghi nhật ký đều đặn, cứ tiếp tục nhé!',
      };
}
