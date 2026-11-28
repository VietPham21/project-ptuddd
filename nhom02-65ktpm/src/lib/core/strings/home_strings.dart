/// Chuỗi của Trang chủ.
class HomeStrings {
  HomeStrings._();

  static String greeting(String name) => name.isEmpty ? 'Xin chào!' : 'Chào $name!';
  static String goalLine(String goal) => 'Mục tiêu: $goal';
  static const today = 'Hôm nay';
  static const mealsToday = 'Bữa đã ghi';
  static const sugaryDrinksToday = 'Đồ uống nhiều đường';
  static const vegMealsToday = 'Bữa có rau';
  static const recentMeals = 'Bữa gần đây';
  static const seeDiary = 'Xem nhật ký';
  static const noMealsYet = 'Chưa có bữa nào';
  static const noMealsHint = 'Nhấn nút Quét ở giữa để ghi bữa đầu tiên nhé.';
  static const scanFirst = 'Ghi bữa đầu tiên';
  static const relogShortcut = 'Ăn lại';
  static const seeAll = 'Xem tất cả';
}
