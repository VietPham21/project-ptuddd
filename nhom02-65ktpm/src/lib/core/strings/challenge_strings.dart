import '../../domain/enums.dart';

/// Chuỗi của phân hệ Thử thách tuần, Streak & Nhắc nhở.
class ChallengeStrings {
  ChallengeStrings._();

  static const weeklyChallenge = 'Thử thách tuần';
  static const newChallenge = 'Thử thách tuần mới';
  static const newChallengeHint = 'Chọn một mục tiêu nhỏ cho tuần này nhé. Bạn chỉnh được con số.';
  static const accept = 'Nhận thử thách';
  static const skip = 'Bỏ qua';
  static const editTarget = 'Sửa mục tiêu';
  static const skippedThisWeek = 'Bạn đã bỏ qua thử thách tuần này.';
  static const takeAgain = 'Nhận lại';
  static const history = 'Lịch sử thử thách';
  static const noHistory = 'Chưa có thử thách nào đã kết thúc.';
  static String streak(int weeks) => 'Chuỗi $weeks tuần';
  static String streakHeadline(int weeks) =>
      weeks == 0 ? 'Hoàn thành thử thách để bắt đầu chuỗi nhé!' : 'Chuỗi hiện tại: $weeks tuần liên tiếp';
  static const onTrackMax = 'Đang trong giới hạn, giữ vững nhé!';
  static const overMax = 'Đã vượt mục tiêu một chút – tuần sau mình thử lại nhé.';
  static const reachedMin = 'Đã đạt mục tiêu, tuyệt vời!';
  static const keepGoingMin = 'Cố lên, bạn đang tiến gần mục tiêu!';
  static const targetLabel = 'Mục tiêu';

  static String title(ChallengeType type, int target) => switch (type) {
        ChallengeType.maxSugaryDrinks => 'Tối đa $target ly đồ uống nhiều đường',
        ChallengeType.lessSugarOrders => 'Gọi đồ uống ít đường ít nhất $target lần',
        ChallengeType.vegMeals => 'Ít nhất $target bữa có rau',
        ChallengeType.maxFriedMeals => 'Tối đa $target bữa nhiều dầu mỡ',
      };

  static String progress(ChallengeType type, int progress, int target) => switch (type) {
        ChallengeType.maxSugaryDrinks => 'Đã có $progress/$target ly',
        ChallengeType.lessSugarOrders => 'Đã gọi ít đường $progress/$target lần',
        ChallengeType.vegMeals => 'Đã có $progress/$target bữa có rau',
        ChallengeType.maxFriedMeals => 'Đã có $progress/$target bữa nhiều dầu mỡ',
      };

  static String status(ChallengeStatus status) => switch (status) {
        ChallengeStatus.active => 'Đang diễn ra',
        ChallengeStatus.completed => 'Hoàn thành',
        ChallengeStatus.failed => 'Chưa đạt',
        ChallengeStatus.cancelled => 'Đã bỏ qua',
      };

  // Thông báo nhắc ghi bữa (giọng nhẹ nhàng)
  static String reminderTitle(MealType type) => switch (type) {
        MealType.breakfast => 'Bữa sáng hôm nay thế nào?',
        MealType.lunch => 'Đến giờ ghi bữa trưa rồi',
        MealType.dinner => 'Ghi lại bữa tối nhé',
        MealType.snack => 'Bạn vừa ăn gì không?',
      };
  static const reminderBody = 'Chụp nhanh món bạn ăn để NutriTrack AI gợi ý cho bạn nhé.';
}
