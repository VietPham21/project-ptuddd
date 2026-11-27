# Kịch bản demo cuối kỳ – NutriTrack AI

Thời lượng gợi ý: 7–8 phút. Chuẩn bị: 2 điện thoại Android cùng đăng nhập tài khoản demo
(đã có dữ liệu 2 tuần, tuần trước đủ dữ liệu – xem `src/tools/demo_data/README.md`),
1 ly trà sữa thật hoặc ảnh in, 1 thực đơn quán trà sữa.

| # | Thao tác | Điểm cần nhấn mạnh |
| - | --- | --- |
| 1 | Mở app trên máy 1 (đã đăng nhập tài khoản demo). Trang chủ: lời chào, tóm tắt hôm nay, thẻ thử thách tuần | App giúp đạt mục tiêu, không chỉ cung cấp thông tin |
| 2 | Nhấn **Quét** → *Quét món ăn* → chụp ly trà sữa | Ảnh nén trong máy, không lưu lên Cloud |
| 3 | Màn hình xác nhận: chip "Độ ngọt: cao" (màu cam), gợi ý "Gọi ít đường", "Bỏ bớt topping", dòng "Gợi ý mang tính tham khảo". Đổi bữa → **Lưu** | AI chỉ chọn mã gợi ý trong thư viện; người dùng sửa được mọi trường |
| 4 | Nhấn **Quét** → *Gọi món thông minh* → chụp thực đơn | Gợi ý **trước khi** ăn: 2–3 món + cách gọi (size M, 30% đường...) |
| 5 | Nhấn *Tôi đã gọi món này* → xác nhận → Lưu | Luồng gọi món nối vào nhật ký |
| 6 | Cầm máy 2: bữa vừa lưu hiện ngay ở Trang chủ/Nhật ký | Đồng bộ realtime Firestore |
| 7 | Mở tab **Báo cáo**: biểu đồ so sánh tuần trước, nhận xét tích cực, thẻ thử thách "Tối đa 3 ly đồ uống nhiều đường" với tiến độ vừa tăng | Quy tắc thống kê theo tuần giờ Việt Nam, ngưỡng đủ dữ liệu 4 ngày |
| 8 | Bật chế độ máy bay trên máy 1 → mở Nhật ký vẫn xem được → *Nhập thủ công* một món → Lưu. Tắt chế độ máy bay → máy 2 nhận được món | Offline persistence |
| 9 | Vuốt xóa một bữa → nhấn *Hoàn tác* → xóa lại → mở **Thùng rác** → Khôi phục | Xóa mềm (tombstone) |
| 10 | Hồ sơ: đổi giao diện Tối, xem giờ nhắc, dòng miễn trừ trách nhiệm | Material 3 Dark/Light, an toàn người dùng |

Phương án dự phòng: nếu mạng hội trường yếu hoặc AI hết lượt → dùng *Nhập tên món* /
*Nhập thủ công* (không cần AI) và giải thích luồng xử lý lỗi.
