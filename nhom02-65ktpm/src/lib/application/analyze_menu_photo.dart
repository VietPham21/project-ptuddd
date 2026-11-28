import 'package:flutter/foundation.dart';

import '../core/result.dart';
import '../core/strings/menu_strings.dart';
import '../data/ai/menu_analysis_service.dart';
import '../domain/entities/tip.dart';
import 'ai_allowed_tips.dart';
import 'session_service.dart';
import 'tips_cache.dart';

/// Một đề xuất gọi món đã ghép với nội dung gợi ý trong thư viện.
class MenuSuggestion {
  const MenuSuggestion({
    required this.menuItemName,
    required this.howToOrder,
    required this.reasons,
  });

  final String menuItemName;
  final String howToOrder;

  /// Lý do (bản sao gợi ý từ thư viện, không phải chữ AI tự viết).
  final List<TipSnapshot> reasons;
}

/// Use case: Gọi món thông minh — gợi ý TRƯỚC khi ăn theo mục tiêu.
class AnalyzeMenuPhoto {
  AnalyzeMenuPhoto(this._ai, this._tipsCache, this._session);

  final MenuAnalysisService _ai;
  final TipsCache _tipsCache;
  final SessionService _session;

  Future<Result<List<MenuSuggestion>>> call(Uint8List jpeg) async {
    await _tipsCache.ensureLoaded();
    final result = await _ai.analyzeMenuPhoto(
      jpeg,
      goal: _session.goal,
      allowedTips: allowedTipsForAi(_tipsCache, _session.goal),
    );
    switch (result) {
      case Err(:final failure):
        return Err(failure);
      case Ok(:final value):
        if (!value.isMenu) {
          return const Err(AppFailure(FailureType.notRecognized, MenuStrings.notMenu));
        }
        if (value.recommendations.isEmpty) {
          return const Err(AppFailure(FailureType.notRecognized, MenuStrings.noSuggestion));
        }
        final library = _tipsCache.byCode;
        return Ok([
          for (final r in value.recommendations)
            MenuSuggestion(
              menuItemName: r.menuItemName,
              howToOrder: r.howToOrder,
              // Bỏ mã lạ / đã tắt (phòng hờ).
              reasons: r.tipCodes
                  .map((c) => library[c])
                  .whereType<Tip>()
                  .where((t) => t.active)
                  .map((t) => t.toSnapshot())
                  .toList(),
            ),
        ]);
    }
  }
}
