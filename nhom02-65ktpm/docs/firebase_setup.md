# Hướng dẫn cấu hình Firebase cho NutriTrack AI

Các bước dưới đây chỉ làm **một lần** (trưởng nhóm làm, rồi chia sẻ quyền cho cả nhóm).
Toàn bộ dự án phải chạy được trên **gói Spark (miễn phí)** – **không** liên kết thẻ thanh toán.

## 1. Tạo dự án Firebase (gói Spark)

1. Vào <https://console.firebase.google.com> → *Add project* → đặt tên, ví dụ `nutritrack-ai-nhom02`.
2. Có thể tắt Google Analytics. Giữ gói **Spark**.
3. *Project settings → Users and permissions*: thêm email các thành viên (quyền Editor).

## 2. Kết nối ứng dụng Flutter (FlutterFire CLI)

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
firebase login
cd nhom02-65ktpm/src
flutterfire configure --project=<project-id> --platforms=android,ios
```

Lệnh trên **ghi đè** `lib/firebase_options.dart` và tạo `android/app/google-services.json`.
Package Android của app: `com.nhom02.nutritrack.nutritrack_ai`.

## 3. Authentication

1. *Build → Authentication → Get started*.
2. *Sign-in method*: bật **Email/Password** và **Google** (chọn email hỗ trợ).
3. Lấy SHA-1/SHA-256 của keystore debug:

   ```bash
   cd nhom02-65ktpm/src/android
   ./gradlew signingReport
   ```

   (Windows: `gradlew.bat signingReport`). Copy dòng `SHA1` và `SHA-256` của biến thể `debug`.
4. *Project settings → Your apps → Android app → Add fingerprint*: dán SHA-1 và SHA-256.
   Mỗi thành viên dùng máy riêng thì **mỗi máy có keystore debug khác nhau** → thêm SHA của từng máy.
5. Tải lại `google-services.json` (hoặc chạy lại `flutterfire configure`).
6. Khi build bản release, thêm SHA của keystore release.

## 4. Cloud Firestore + Security Rules + Index

1. *Build → Firestore Database → Create database* → chọn vùng `asia-southeast1` → *Production mode*.
2. Deploy rules và index từ repo:

   ```bash
   cd nhom02-65ktpm/src
   firebase use <project-id>
   firebase deploy --only firestore:rules,firestore:indexes
   ```

3. Kiểm thử Rules: đăng nhập tài khoản A thêm bữa ăn; dùng *Rules Playground* trong Console
   giả lập tài khoản B đọc `users/<uidA>/meals/...` → phải bị **từ chối**.

## 5. Firebase AI Logic (Gemini Developer API) + App Check

1. *Build → AI Logic → Get started* → chọn **Gemini Developer API** (không chọn Vertex AI – cần gói Blaze).
2. *Build → App Check → Apps* → chọn app Android → đăng ký **Play Integrity** (dùng cho bản release).
3. **Debug token cho bản debug** (mỗi máy/emulator một token):
   - Chạy `flutter run` (bản debug) trên máy thật.
   - Mở logcat, tìm dòng có chữ `DebugAppCheckProvider`, ví dụ:
     `Enter this debug secret into the allow list in the Firebase Console for your project: 1234abcd-...`

     ```bash
     adb logcat | findstr DebugAppCheckProvider
     ```

   - *App Check → Apps → (app Android) → ⋮ → Manage debug tokens → Add debug token* → dán token.
4. Sau khi đã thử AI chạy được, bật **Enforce** cho Firebase AI Logic trong App Check.
5. Tên model nằm ở `lib/core/constants/app_config.dart` (`AppConfig.geminiModel`).
   Nếu model bị ngừng, đổi sang model Flash khác có trong
   <https://firebase.google.com/docs/ai-logic/models> (cột "billing not required").

## 6. Nạp thư viện gợi ý (tips)

1. Cả nhóm **duyệt nội dung** `src/tools/seed_tips/tips.json`.
2. *Project settings → Service accounts → Generate new private key* → lưu file **ngoài repo**.
3. Làm theo `src/tools/seed_tips/README.md` (`npm install`, `npm run check`, `npm run seed`).

## 7. Chạy thử trên máy thật

- Kiểm tra: đăng nhập, onboarding, quét món, gọi món, thông báo nhắc (đặt giờ nhắc sau 2–3 phút
  để thử), tắt mạng vẫn thêm được món, bật mạng tự đồng bộ, 2 thiết bị cùng tài khoản thấy
  dữ liệu cập nhật realtime.
