import 'package:flutter/foundation.dart';

import '../core/strings/challenge_strings.dart';
import '../data/notifications/notification_service.dart';
import '../domain/entities/user_profile.dart';
import '../domain/rules/meal_type_rules.dart';
import '../domain/rules/vn_calendar.dart';
import 'reminder_scheduler.dart';

/// Lập lại TOÀN BỘ lịch nhắc ghi bữa theo cài đặt hồ sơ.
///
/// Được [SessionService] gọi khi: mở app, đăng nhập, đổi cài đặt nhắc.
/// Đăng xuất -> [cancelAll].
class RescheduleReminders implements ReminderScheduler {
  RescheduleReminders(this._notifications);

  final NotificationService _notifications;

  static const int _baseId = 100;

  @override
  Future<bool> requestPermission() async {
    await _notifications.init();
    return _notifications.requestPermission();
  }

  @override
  Future<void> reschedule(ReminderSettings settings) async {
    try {
      await _notifications.init(); // đảm bảo đã khởi tạo trước khi lập lịch
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('Reschedule reminders failed: $e');
      return;
    }
    if (!settings.enabled) return;
    final today = VnCalendar.vnDateOf(DateTime.now());
    for (var i = 0; i < settings.times.length; i++) {
      final parsed = parseTime(settings.times[i]);
      if (parsed == null) continue;
      // Chọn câu nhắc theo bữa tương ứng với giờ nhắc.
      final mealType =
          MealTypeRules.defaultFor(VnCalendar.combineVn(today, parsed.hour, parsed.minute));
      await _notifications.scheduleDaily(
        id: _baseId + i,
        hour: parsed.hour,
        minute: parsed.minute,
        title: ChallengeStrings.reminderTitle(mealType),
        body: ChallengeStrings.reminderBody,
      );
    }
  }

  @override
  Future<void> cancelAll() async {
    try {
      await _notifications.init();
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('Cancel reminders failed: $e');
    }
  }

  /// "07:30" -> (7, 30); chuỗi sai định dạng -> null.
  static ({int hour, int minute})? parseTime(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return (hour: hour, minute: minute);
  }
}
