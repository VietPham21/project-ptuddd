/// Chuỗi của phân hệ Gọi món thông minh & Gợi ý theo mục tiêu.
class MenuStrings {
  MenuStrings._();

  static const sheetTitle = 'Gọi món thông minh';
  static const sheetSub = 'Chụp thực đơn, AI gợi ý món và cách gọi hợp mục tiêu';
  static const title = 'Gọi món thông minh';
  static const analyzing = 'Đang đọc thực đơn...';
  static String resultHeader(String goal) => 'Gợi ý cho mục tiêu "$goal"';
  static const howToOrder = 'Cách gọi';
  static const why = 'Vì sao';
  static const iOrderedThis = 'Tôi đã gọi món này';
  static const preparing = 'Đang chuẩn bị thông tin món...';
  static const notMenu = 'Ảnh này có vẻ không phải thực đơn. Bạn thử chụp lại rõ hơn nhé.';
  static const noSuggestion = 'Chưa tìm được món phù hợp trên thực đơn này.';
  static const scanAnother = 'Chụp thực đơn khác';

  // Thư viện gợi ý theo mục tiêu
  static const goalTipsEntry = 'Gợi ý theo mục tiêu';
  static const goalTipsEntrySub = 'Xem các thói quen nhỏ phù hợp với bạn';
  static String goalTipsTitle(String goal) => 'Gợi ý: $goal';
  static const generalGroup = 'Chung';
  static const tipsEmpty = 'Thư viện gợi ý chưa có dữ liệu. Hãy nạp tips bằng tools/seed_tips.';
}
