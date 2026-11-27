import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../../data/firestore/firestore_paths.dart';

final sl = GetIt.instance; // sl = Service Locator

/// Hàm khởi tạo Dependency Injection cho toàn ứng dụng
Future<void> initDependencies() async {
  // -------------------------------------------------------------
  // 1. External & Backend (Firebase, App Check, Local Storage)
  // Phụ trách: Phạm Văn Việt (Issue #3)
  // -------------------------------------------------------------
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirestorePaths>(() => FirestorePaths(sl()));

  // -------------------------------------------------------------
  // 2. Data Sources & Repositories
  // Phụ trách: Phùng Thành An (Issue #5), Nguyễn Hoàng Anh (Issue #4)
  // -------------------------------------------------------------

  // -------------------------------------------------------------
  // 3. Application Use Cases
  // Phụ trách: Phùng Thành An (Issue #5, #7), Nguyễn Hoàng Anh (Issue #8)
  // -------------------------------------------------------------

  // -------------------------------------------------------------
  // 4. State / Services dùng chung (ChangeNotifier)
  // -------------------------------------------------------------
}
