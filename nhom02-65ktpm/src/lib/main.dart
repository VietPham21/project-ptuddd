import 'package:flutter/material.dart';
import 'app.dart';
import 'core/di/injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Dependency Injection (GetIt)
  await di.initDependencies();

  runApp(const NutriTrackApp());
}
