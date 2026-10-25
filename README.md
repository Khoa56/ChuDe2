# Đồng hồ đếm ngược — Future & Stream

Demo đơn giản bằng Dart/Flutter về lập trình bất đồng bộ. Ứng dụng mở thẳng
màn hình đồng hồ, cho chọn thời lượng, bắt đầu, tạm dừng, tiếp tục và đặt lại.

## Tính năng

- Chọn 15 giây, 30 giây, 1 phút, 2 phút hoặc 5 phút.
- Đếm ngược và cập nhật giao diện khi thời gian thay đổi.
- Tự dừng ở 0 và thông báo hết giờ.
- Nút **Thoát màn hình** đóng phiên; **Mở lại demo** tạo một phiên mới.
- Tự tạm dừng khi chuyển ứng dụng hoặc ẩn trang.

## Nội dung được minh họa

| Nội dung | Mã nguồn |
|---|---|
| Future, async/await: đọc các mốc thời gian từ JSON | `lib/countdown/preset_loader.dart` |
| FutureBuilder: trạng thái chờ, lỗi và thử lại | `lib/ui/session_page.dart` |
| StreamController: phát trạng thái đồng hồ liên tục | `lib/countdown/countdown_controller.dart` |
| StreamBuilder: cập nhật số giây và trạng thái | `lib/ui/session_page.dart` |
| Bắt đầu / Tạm dừng / Đặt lại | `lib/ui/session_page.dart` |
| Hủy listener, hủy Timer, đóng Stream khi thoát | `dispose()` của màn hình và controller |

Tác vụ đọc tài nguyên có độ trễ mô phỏng 700 ms để dễ quan sát việc chờ Future.
Ứng dụng đọc tệp cục bộ, không cần máy chủ API. Future được tạo một lần khi mở
màn hình. Sau `await` có kiểm tra `mounted` để tránh tạo bộ đếm sau khi đã thoát.

Timer kiểm tra thời gian định kỳ; thời gian còn lại được tính theo Stopwatch.
Tạm dừng hủy Timer nhưng giữ Stream. Thoát màn hình hủy listener và Timer,
dừng Stopwatch rồi đóng StreamController. StreamBuilder tự hủy đăng ký của nó.

## Chạy demo

Cần Flutter với Dart >= 3.13.5, Git và Chrome. Đã dùng Flutter 3.47.7 / Dart 3.13.5.

```sh
flutter pub get
flutter run -d chrome
```

Trên Windows, có thể nhấp đúp **`CHAY_DEMO.exe`** nằm cạnh `pubspec.yaml`.
File này chỉ tự chạy Flutter và mở Chrome, máy vẫn cần cài Flutter/Git/Chrome.
Nếu chưa tìm được SDK, chọn thư mục Flutter có `bin/flutter.bat` một lần.
Trình mở sẽ nhớ vị trí trên máy đó và không thay đổi PATH của Windows.
Giữ cửa sổ lệnh mở khi demo, nhấn **q** để dừng.

## Build ứng dụng

```sh
flutter analyze
flutter build web --release --no-web-resources-cdn
flutter build apk --release
```

APK nằm tại `build/app/outputs/flutter-apk/app-release.apk`.
Cần Android SDK/JDK để build hoặc chạy trên thiết bị Android.
APK demo dùng khóa debug; bản Android cần được kiểm tra thêm trên thiết bị thực tế.

## Cấu trúc

```text
lib/main.dart                 Khởi động ứng dụng
lib/countdown/                Dữ liệu, Future và bộ đếm dùng Stream
lib/ui/                       Màn hình và các thành phần giao diện đơn giản
assets/presets.json           Các thời lượng
tool/quick_launcher/          Mã Dart của EXE mở nhanh
android/, web/                Cấu hình nền tảng
```

Mã nguồn trình mở nhanh được cung cấp để có thể tạo lại EXE trên Windows:

```sh
dart compile exe tool/quick_launcher/launcher.dart -o CHAY_DEMO.exe
```

## Tham khảo

- [Dart async/await](https://dart.dev/libraries/async/async-await)
- [StreamController](https://api.dart.dev/dart-async/StreamController-class.html)
- [StreamBuilder](https://api.flutter.dev/flutter/widgets/StreamBuilder-class.html)
