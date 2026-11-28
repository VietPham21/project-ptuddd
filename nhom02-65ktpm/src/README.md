# NutriTrack AI

Trợ lý gợi ý và hình thành thói quen ăn uống lành mạnh bằng nhận diện hình ảnh
(Firebase AI Logic – Gemini) và điện toán đám mây (Firebase).
Đồ án cuối kỳ học phần *Phát triển ứng dụng cho thiết bị di động* – Nhóm 02 – 65KTPM.

> Gợi ý mang tính tham khảo, không thay thế tư vấn của chuyên gia dinh dưỡng.
> Ứng dụng dành cho người từ 18 tuổi trở lên.

## 1. Tính năng chính

| Phân hệ | Mô tả |
| --- | --- |
| Đăng nhập & Hồ sơ | Email/Mật khẩu, Google; onboarding xác nhận ≥ 18 tuổi, chọn mục tiêu (Giảm cân / Cân bằng / Giảm đường), thói quen ban đầu, giờ nhắc |
| Quét món ăn | Chụp/chọn ảnh → Gemini đánh giá **mức độ** (thấp/vừa/cao) cho đường, dầu mỡ, tinh bột, rau, đạm, năng lượng và chọn **mã gợi ý** từ thư viện → màn hình xác nhận |
| Nhập tên món | Gõ tên món, AI đánh giá; lỗi AI thì tự chọn mức độ bằng chip |
| Gọi món thông minh | Chụp thực đơn → 2–3 món phù hợp mục tiêu + cách gọi + lý do |
| Nhật ký | Theo ngày, 4 bữa; thêm thủ công; "Ăn lại" 1 chạm; xóa mềm + Hoàn tác + Thùng rác; đồng bộ realtime, dùng được khi offline |
| Báo cáo tuần | Thống kê theo tuần (giờ Việt Nam), biểu đồ so sánh tuần trước (fl_chart), nhận xét tích cực dựa trên quy tắc |
| Thử thách & nhắc nhở | Thử thách tuần đề xuất từ dữ liệu tuần trước, tiến độ tự cập nhật, streak; thông báo nhắc ghi bữa |

**Không làm:** tính calo, cân gram, tư vấn y tế, ăn kiêng cực đoan, lưu ảnh lên Cloud.

## 2. Công nghệ

Flutter (Material 3, Dark/Light) · Firebase Auth · Cloud Firestore (offline persistence) ·
Firebase AI Logic với **Gemini Developer API** (chạy trên gói **Spark miễn phí**) ·
Firebase App Check · get_it · fl_chart · flutter_local_notifications · image_picker ·
flutter_image_compress · intl.

## 3. Kiến trúc

```
Presentation (screens, widgets, ChangeNotifier)
      │
Application (use cases: confirm_and_save_meal, analyze_meal_photo, build_weekly_report, ...)
      │
Domain (Dart thuần: entities, enums, rules, repository interfaces)  ◄──  Data (Firestore, Gemini, notifications)
```

- **Domain** không import Flutter/Firebase → unit test bằng Dart thuần (`test/domain`).
- Quy tắc nghiệp vụ nằm ở `lib/domain/rules/`: `weekly_stats`, `data_sufficiency`,
  `feedback_rules`, `challenge_rules`, `tip_selector`, `meal_type_rules`, `vn_calendar`.
- DI bằng `get_it` (`lib/core/di/injection_container.dart`).

```
lib/
  main.dart, app.dart, firebase_options.dart
  core/        constants (AppConfig), strings (chuỗi tiếng Việt), theme, di, firebase, result.dart
  domain/      entities/, enums.dart, rules/, repositories/
  data/        firestore/, auth/, ai/ (prompt_builder, schemas, gemini_client, parsers/), notifications/
  application/ use case + service (session, tips cache, challenge...)
  presentation/screens/<phân hệ>/, presentation/widgets/
tools/seed_tips/   thư viện gợi ý (tips.json) + script nạp Firestore
firestore.rules, firestore.indexes.json, firebase.json
```

## 4. An toàn & quyền riêng tư

- AI **chỉ trả giá trị trong enum** (JSON schema). Nội dung gợi ý lấy từ thư viện `tips`
  đã kiểm duyệt; AI chỉ chọn mã và viết một câu mô tả ngắn.
- Kết quả AI **luôn qua màn hình xác nhận**, sửa được mọi trường trước khi lưu.
- Ảnh **không bao giờ** lưu lên Cloud: nén trong máy → gửi Gemini → bỏ; file tạm bị xóa.
- Security Rules: mỗi người chỉ đọc/ghi `users/{uid}` của mình; `tips` chỉ đọc.
- App Check chặn lạm dụng quota Gemini; giới hạn client 6 lần gọi AI/phút.

## 5. Cài đặt & chạy

Yêu cầu: Flutter stable (Dart ≥ 3.13), Android Studio/VS Code, máy Android thật
(API 24+), Node.js ≥ 18 (để nạp tips), Firebase CLI + FlutterFire CLI.

1. Cấu hình Firebase theo hướng dẫn chi tiết: [`../docs/firebase_setup.md`](../docs/firebase_setup.md)
   (tạo dự án Spark, `flutterfire configure`, bật Auth + SHA-1, bật Firebase AI Logic,
   App Check, deploy rules/indexes, nạp tips).
2. Chạy ứng dụng:

   ```bash
   cd nhom02-65ktpm/src
   flutter pub get
   flutter run
   ```

3. Kiểm tra mã nguồn:

   ```bash
   flutter analyze
   flutter test
   ```

## 6. Sự cố thường gặp

| Hiện tượng | Cách xử lý |
| --- | --- |
| Màn hình "Không khởi động được Firebase" | Chưa chạy `flutterfire configure` hoặc thiếu `android/app/google-services.json` |
| Quét món báo "Không xác thực được ứng dụng với dịch vụ AI" | Chưa thêm App Check debug token (xem mục 5 trong `firebase_setup.md`) |
| Nhật ký/Thùng rác báo lỗi tải | Chưa deploy index: `firebase deploy --only firestore:indexes` |
| Đăng nhập Google thất bại | Thiếu SHA-1/SHA-256 trong Firebase Console, tải lại `google-services.json` |
| "Dịch vụ AI đang tạm hết lượt miễn phí" | Hết quota ngày của gói miễn phí; dùng nhập thủ công, thử lại hôm sau |
| Không thấy thông báo nhắc | Cấp quyền thông báo cho app; tắt tối ưu pin cho app trên một số máy |

## 7. Tài liệu khác

- Hướng dẫn cấu hình Firebase: [`../docs/firebase_setup.md`](../docs/firebase_setup.md)
- Kịch bản demo: [`../docs/demo_script.md`](../docs/demo_script.md)
- Báo cáo kiểm thử thủ công: [`../docs/test_report.md`](../docs/test_report.md)
- Thư viện gợi ý: [`tools/seed_tips/README.md`](tools/seed_tips/README.md)
