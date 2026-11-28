import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'core/di/injection_container.dart' as di;
import 'core/firebase/firebase_bootstrap.dart';
import 'data/notifications/notification_service.dart';
import 'presentation/screens/splash/startup_error_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Định dạng ngày giờ tiếng Việt (thứ, tháng...) cho package intl.
  await initializeDateFormatting('vi_VN');
  Intl.defaultLocale = 'vi_VN';

  try {
    // 1. Firebase + App Check + Firestore offline
    await FirebaseBootstrap.initialize();
  } catch (e) {
    debugPrint('Firebase init failed: $e');
    runApp(StartupErrorApp(error: e));
    return;
  }

  // 2. Dependency Injection (GetIt)
  await di.initDependencies();

  // 3. Thông báo cục bộ (nhắc ghi bữa). Lỗi ở đây không được làm crash app.
  try {
    await di.sl<NotificationService>().init();
  } catch (e) {
    debugPrint('Notification init failed: $e');
  }

  runApp(const NutriTrackApp());
}
