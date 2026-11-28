import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/enums.dart';
import '../domain/repositories/challenge_repository.dart';
import '../domain/repositories/meal_repository.dart';
import '../domain/rules/challenge_rules.dart';
import '../domain/rules/vn_calendar.dart';
import '../domain/rules/weekly_stats.dart';
import 'meal_events.dart';
import 'session_service.dart';

/// Tính lại tiến độ thử thách tuần hiện tại TỪ NHẬT KÝ mỗi khi
/// lưu / xóa / khôi phục bữa ăn (không cộng dồn thủ công để tránh lệch).
class UpdateChallengeProgress {
  UpdateChallengeProgress(this._challenges, this._meals, this._session);

  final ChallengeRepository _challenges;
  final MealRepository _meals;
  final SessionService _session;

  /// Lắng nghe "bảng tin" nhật ký của phân hệ Nhật ký.
  StreamSubscription<void> listenTo(MealEvents events) =>
      events.changes.listen((_) => unawaited(call()));

  Future<void> call({DateTime? now}) async {
    if (_session.status != SessionStatus.ready) return;
    try {
      final uid = _session.uid;
      final weekStart = VnCalendar.weekStartOf(now ?? DateTime.now());
      final weekKey = VnCalendar.dateKey(weekStart);
      final all = await _challenges.getChallenges(uid);
      final current = all
          .where((c) => c.weekStart == weekKey && c.status == ChallengeStatus.active)
          .firstOrNull;
      if (current == null) return;

      final range = VnCalendar.weekRangeUtc(weekStart);
      final meals = await _meals.getMealsBetween(uid, range.start, range.end);
      final progress =
          ChallengeRules.progressFor(current.type, WeeklyStats.compute(meals, weekStart));
      if (progress != current.progress) {
        _challenges.saveChallenge(uid, current.copyWith(progress: progress));
      }
    } catch (e) {
      debugPrint('Update challenge progress failed: $e');
    }
  }
}
