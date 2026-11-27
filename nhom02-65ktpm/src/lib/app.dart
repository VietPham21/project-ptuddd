import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'application/session_service.dart';
import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'domain/enums.dart';

class NutriTrackApp extends StatelessWidget {
  const NutriTrackApp({super.key});

  static ThemeMode _toThemeMode(AppThemeMode? mode) => switch (mode) {
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  @override
  Widget build(BuildContext context) {
    final session = sl<SessionService>();
    // Đổi giao diện Sáng/Tối/Theo hệ thống trong Hồ sơ -> áp dụng ngay.
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _toThemeMode(session.profile?.themeMode),
        // Tiếng Việt cho DatePicker, TimePicker và các widget hệ thống.
        locale: const Locale('vi', 'VN'),
        supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
