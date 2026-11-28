# Báo cáo kiểm thử – NutriTrack AI

## 1. Kiểm thử tự động

Chạy trong thư mục `nhom02-65ktpm/src`:

```bash
flutter analyze
flutter test
```

| Nhóm test | File | Nội dung chính | Kết quả |
| --- | --- | --- | --- |
| Lịch tuần VN | `test/domain/vn_calendar_test.dart` | 00:30 thứ Hai giờ VN thuộc tuần mới | |
| Thống kê tuần | `test/domain/weekly_stats_test.dart` | Định nghĩa đếm 7.1, bỏ meal xóa mềm, ranh giới tuần | |
| Đủ dữ liệu | `test/domain/data_sufficiency_test.dart` | 3 ngày → chưa đủ, 4 ngày → đủ | |
| Phản hồi tuần | `test/domain/feedback_rules_test.dart` | Tăng / giảm / không đủ dữ liệu / tối đa 3 câu | |
| Thử thách | `test/domain/challenge_rules_test.dart` | Đề xuất target, completed/failed (max & min), streak | |
| Chọn gợi ý | `test/domain/tip_selector_test.dart` | Lọc theo mục tiêu + applies_to, tối đa 3, bỏ mã lạ | |
| Bữa mặc định | `test/domain/meal_type_rules_test.dart` | Khung giờ sáng/trưa/tối/phụ | |
| Parser AI | `test/data/meal_response_parser_test.dart` | JSON hợp lệ, thiếu trường, mã lạ, recognized=false, không phải JSON | |
| Parser thực đơn | `test/data/menu_response_parser_test.dart` | Cắt how_to_order > 80 ký tự | |
| Chặn lỗi AI | `test/data/ai_guards_test.dart` | Giới hạn 6 lần/phút, phân loại lỗi 403/429/mạng | |

## 2. Kiểm thử thủ công nhận diện ảnh

Bộ ảnh: ~20 ảnh món ăn/đồ uống thật + 3 ảnh thực đơn. Ghi kết quả vào bảng.

- **Hợp lý**: tên món đúng/gần đúng và các mức độ không cần sửa quá 1 trường.
- **Phải sửa**: người dùng phải sửa tên hoặc ≥ 2 mức độ.

| # | Ảnh (mô tả) | Món AI nhận ra | Mức độ hợp lý? | Gợi ý phù hợp? | Số trường phải sửa | Ghi chú |
| - | --- | --- | --- | --- | --- | --- |
| 1 | Trà sữa trân châu | | | | | |
| 2 | Cơm tấm sườn | | | | | |
| 3 | Phở bò | | | | | |
| 4 | Bún chả | | | | | |
| 5 | Bánh mì thịt | | | | | |
| 6 | Gà rán + khoai chiên | | | | | |
| 7 | Salad rau | | | | | |
| 8 | Cà phê sữa đá | | | | | |
| 9 | Nước ngọt có ga | | | | | |
| 10 | Chè thập cẩm | | | | | |
| 11 | Cơm văn phòng nhiều món | | | | | |
| 12 | Bún bò Huế | | | | | |
| 13 | Trái cây | | | | | |
| 14 | Bánh tráng trộn | | | | | |
| 15 | Mì xào | | | | | |
| 16 | Sinh tố bơ | | | | | |
| 17 | Lẩu | | | | | |
| 18 | Bánh ngọt | | | | | |
| 19 | Ảnh không phải đồ ăn (bàn phím) | | | | | Kỳ vọng: không nhận ra → nhập thủ công |
| 20 | Ảnh mờ | | | | | Kỳ vọng: confidence thấp → viền vàng |
| M1 | Thực đơn quán trà sữa | | | | | |
| M2 | Thực đơn quán cơm | | | | | |
| M3 | Thực đơn quán cà phê | | | | | |

**Tổng kết:** tỷ lệ kết quả hợp lý = …/20; tỷ lệ phải sửa = …/20; số lần JSON sai schema = … (kỳ vọng 0).

## 3. Kiểm thử luồng lỗi

| Tình huống | Cách tạo | Kỳ vọng | Kết quả |
| --- | --- | --- | --- |
| Mất mạng khi quét | Bật chế độ máy bay | Thông báo thân thiện + nút "Nhập thủ công", không crash | |
| Quét quá nhanh | Quét 7 lần trong 1 phút | "Bạn quét hơi nhanh, đợi một chút nhé" | |
| App Check sai | Xóa debug token trong Console | Thông báo xác thực + gợi ý kiểm tra (bản debug) | |
| Truy cập chéo | Rules Playground với uid khác | Bị từ chối | |
| Offline thêm món | Máy bay → thêm thủ công → bật mạng | Đồng bộ lên máy thứ 2 | |
