import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../../core/constants/app_config.dart';

/// Thông báo cục bộ (không cần FCM/server) để nhắc ghi bữa hằng ngày.
///
/// Lập lịch kiểu INEXACT (`inexactAllowWhileIdle`): không cần quyền exact alarm,
/// thông báo có thể lệch vài phút – chấp nhận được với nhắc ghi bữa.
/// Lịch được khôi phục sau khi khởi động lại máy nhờ ScheduledNotificationBootReceiver
/// (khai báo trong AndroidManifest.xml).
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  late final tz.Location _location;
  Future<void>? _initFuture;
  bool _ready = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'meal_reminders',
      'Nhắc ghi bữa',
      channelDescription: 'Nhắc bạn ghi lại bữa ăn theo giờ đã chọn',
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Gọi nhiều lần cũng chỉ khởi tạo một lần.
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    tzdata.initializeTimeZones();
    _location = tz.getLocation(AppConfig.timezone);
    tz.setLocalLocation(_location);
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        // Không tự xin quyền lúc khởi động; xin ở bước Onboarding kèm giải thích.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// Android 13+: xin quyền POST_NOTIFICATIONS. iOS: xin quyền alert/sound.
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) return await android.requestNotificationsPermission() ?? false;
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, sound: true, badge: true) ?? false;
    }
    return true;
  }

  /// Lặp lại mỗi ngày vào [hour]:[minute] (giờ Việt Nam).
  Future<void> scheduleDaily({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    if (!_ready) return;
    final now = tz.TZDateTime.now(_location);
    var next = tz.TZDateTime(_location, now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    try {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: next,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        matchDateTimeComponents: DateTimeComponents.time, // lặp hằng ngày
      );
    } catch (e) {
      debugPrint('Schedule reminder failed: $e');
    }
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }
}
