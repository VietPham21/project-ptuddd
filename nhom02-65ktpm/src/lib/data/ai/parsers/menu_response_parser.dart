import 'dart:convert';

import '../../../core/constants/app_config.dart';
import 'meal_response_parser.dart';

/// Một đề xuất gọi món AI trả về.
class ParsedMenuRecommendation {
  const ParsedMenuRecommendation({
    required this.menuItemName,
    required this.howToOrder,
    required this.tipCodes,
  });

  final String menuItemName;
  final String howToOrder;
  final List<String> tipCodes;
}

class ParsedMenuResponse {
  const ParsedMenuResponse({required this.isMenu, required this.recommendations});

  final bool isMenu;
  final List<ParsedMenuRecommendation> recommendations;
}

/// Đọc + kiểm tra JSON của Gemini cho Gọi món thông minh (Dart thuần).
///
/// - Không phải JSON object -> [FormatException].
/// - `how_to_order` là chuỗi tự do nên app tự cắt nếu dài quá 80 ký tự.
/// - Tối đa 3 đề xuất, tối đa 2 mã lý do mỗi đề xuất.
class MenuResponseParser {
  MenuResponseParser._();

  static const int maxRecommendations = 3;
  static const int maxReasons = 2;

  static ParsedMenuResponse parse(String raw) {
    final decoded = jsonDecode(MealResponseParser.stripCodeFence(raw));
    if (decoded is! Map) {
      throw const FormatException('AI response is not a JSON object');
    }
    final isMenu = decoded['is_menu'] == true;
    final rawList =
        decoded['recommendations'] is List ? decoded['recommendations'] as List : const [];
    final recommendations = isMenu
        ? rawList
            .whereType<Map>()
            .map(_parse)
            .whereType<ParsedMenuRecommendation>()
            .take(maxRecommendations)
            .toList()
        : <ParsedMenuRecommendation>[];
    return ParsedMenuResponse(isMenu: isMenu, recommendations: recommendations);
  }

  static ParsedMenuRecommendation? _parse(Map m) {
    final name = m['menu_item_name'] is String ? (m['menu_item_name'] as String).trim() : '';
    if (name.isEmpty) return null;
    final how = m['how_to_order'] is String ? (m['how_to_order'] as String).trim() : '';
    final codes = (m['reason_tip_codes'] is List ? m['reason_tip_codes'] as List : const [])
        .whereType<String>()
        .toSet()
        .take(maxReasons)
        .toList();
    return ParsedMenuRecommendation(
      menuItemName: name,
      howToOrder: truncate(how, AppConfig.howToOrderMaxLength),
      tipCodes: codes,
    );
  }

  /// Cắt chuỗi về tối đa [max] ký tự, thêm "…" nếu bị cắt.
  static String truncate(String text, int max) {
    if (text.length <= max) return text;
    return '${text.substring(0, max - 1).trimRight()}…';
  }
}
