import 'package:get_it/get_it.dart';

final sl = GetIt.instance; // sl = Service Locator

/// Hàm khởi tạo Dependency Injection cho toàn ứng dụng
Future<void> initDependencies() async {
  // -------------------------------------------------------------
  // 1. External & Backend (Firebase, App Check, Local Storage)
  // Phụ trách: Phạm Văn Việt (Issue #3)
  // -------------------------------------------------------------

  // -------------------------------------------------------------
  // 2. Data Sources & Repositories
  // Phụ trách: Phùng Thành An (Issue #5), Nguyễn Hoàng Anh (Issue #4)
  // -------------------------------------------------------------

  // -------------------------------------------------------------
  // 3. Domain Use Cases
  // Phụ trách: Phùng Thành An (Issue #5, #7), Nguyễn Hoàng Anh (Issue #8)
  // -------------------------------------------------------------

  // -------------------------------------------------------------
  // 4. Application / State Management (Bloc / Notifier / ViewModels)
  // -------------------------------------------------------------
}
