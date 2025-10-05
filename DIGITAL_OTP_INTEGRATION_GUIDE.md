# Hướng dẫn tích hợp Digital OTP với Profile

## Tổng quan
Người dùng sẽ tạo và quản lý PIN Digital OTP trong phần **Profile** thay vì tạo lúc chuyển tiền.

## Bước 1: Đã hoàn thành ✅
- ✅ Tạo `digital_otp_controller.dart` - Controller quản lý PIN
- ✅ Tạo `digital_otp_pin_screen.dart` - Màn hình quản lý PIN trong Profile
- ✅ Tạo `transfer_money_screen_new.dart` - Màn hình chuyển tiền với Digital OTP

## Bước 2: Cập nhật transfer_money_screen_new.dart

### 2.1. Xóa các biến không cần thiết (dòng ~33)
```dart
// XÓA dòng này:
final _pinConfirmController = TextEditingController();
final RxBool _showSetPinDialog = false.obs;
```

### 2.2. Xóa dispose của _pinConfirmController (dòng ~48)
```dart
// XÓA dòng này trong dispose():
_pinConfirmController.dispose();
```

### 2.3. Thay đổi hàm _sendOtp() (dòng ~112)
```dart
// THAY THẾ toàn bộ hàm _sendOtp() bằng:
Future<void> _sendOtp() async {
  final hasPin = await _digitalOtpController.hasPin();
  if (!hasPin) {
    // Hiển thị thông báo yêu cầu tạo PIN trong Profile
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: k_blue),
            SizedBox(width: 12),
            Text('Chưa có Digital OTP PIN'),
          ],
        ),
        content: Text(
          'Bạn cần tạo mã PIN Digital OTP trong phần Hồ sơ trước khi có thể chuyển tiền.\n\nVui lòng vào Hồ sơ > Digital OTP PIN để thiết lập.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.toNamed('/digital-otp-pin');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: k_blue,
            ),
            child: Text('Đi tới thiết lập'),
          ),
        ],
      ),
    );
    return;
  }
  _showPinDialog.value = true;
}
```

### 2.4. Xóa overlay Set PIN Dialog trong build() (dòng ~407)
```dart
// XÓA toàn bộ phần này:
// Set PIN Dialog (thiết lập PIN lần đầu)
Obx(() => _showSetPinDialog.value
    ? _buildSetPinDialog()
    : SizedBox.shrink()),
```

### 2.5. Cập nhật nút "Đặt lại mã PIN" trong _buildPinDialog() (dòng ~634)
```dart
// THAY THẾ:
TextButton(
  onPressed: () {
    _showPinDialog.value = false;
    _showSetPinDialog.value = true;  // ← XÓA dòng này
    Get.toNamed('/digital-otp-pin');  // ← THÊM dòng này
    _pinController.clear();
  },
  child: Text(
    'Đặt lại mã PIN',
    style: TextStyle(color: Colors.brown[800]),
  ),
),
```

### 2.6. Xóa toàn bộ hàm _buildSetPinDialog() (dòng ~658-744)
```dart
// XÓA toàn bộ hàm _buildSetPinDialog() (khoảng 90 dòng)
```

## Bước 3: Thêm route cho Digital OTP PIN Screen

### 3.1. Tìm file routes (thường là `main.dart` hoặc `routes.dart`)
```dart
// THÊM route mới:
GetPage(
  name: '/digital-otp-pin',
  page: () => DigitalOtpPinScreen(),
),
```

### 3.2. Thêm import
```dart
import 'package:e_wallet/pages/screens/profile/screens/digital_otp_pin_screen.dart';
```

## Bước 4: Thêm menu Digital OTP vào Profile Screen

### 4.1. Tìm Profile Screen (thường là `profile_screen.dart` hoặc `my_account_screen.dart`)

### 4.2. Thêm menu item mới (sau menu "Ví của tôi" hoặc "Bảo mật")
```dart
// THÊM item mới:
_buildProfileItem(
  context: context,
  icon: Icons.security,
  title: 'Digital OTP PIN',
  subtitle: 'Quản lý mã PIN xác thực giao dịch',
  onTap: () => Get.toNamed('/digital-otp-pin'),
),
```

## Bước 5: Khởi tạo DigitalOtpController

### 5.1. Trong main.dart hoặc nơi khởi tạo controllers
```dart
// THÊM vào phần init controllers:
Get.put(DigitalOtpController());
```

## Bước 6: Copy file transfer_money_screen_new.dart

### 6.1. Sau khi chỉnh sửa xong transfer_money_screen_new.dart
```bash
# Copy nội dung từ transfer_money_screen_new.dart
# Paste vào transfer_money_screen.dart (ghi đè file cũ)
```

## Bước 7: Test flow hoàn chỉnh

### 7.1. Test tạo PIN
1. Mở app → Vào Profile
2. Chọn "Digital OTP PIN"
3. Nhập PIN 6 số và xác nhận
4. Kiểm tra thông báo "Đã tạo PIN Digital OTP thành công"

### 7.2. Test chuyển tiền với PIN
1. Vào màn hình chuyển tiền
2. Nhập thông tin người nhận và số tiền
3. Bấm "Xác nhận chuyển tiền"
4. Nhập PIN 6 số (6 ô tròn)
5. Xem mã OTP hiển thị với countdown 120 giây
6. Bấm "Xác thực" để hoàn tất

### 7.3. Test chuyển tiền khi chưa có PIN
1. Xóa PIN trong Profile (nếu có)
2. Vào màn hình chuyển tiền
3. Bấm "Xác nhận chuyển tiền"
4. Kiểm tra dialog yêu cầu tạo PIN
5. Bấm "Đi tới thiết lập" → phải chuyển đến Digital OTP PIN Screen

### 7.4. Test thay đổi PIN
1. Vào Profile → Digital OTP PIN
2. Nhập PIN hiện tại
3. Nhập PIN mới và xác nhận
4. Kiểm tra thông báo thành công

### 7.5. Test xóa PIN
1. Vào Profile → Digital OTP PIN
2. Bấm "Xóa PIN"
3. Xác nhận xóa
4. Kiểm tra trạng thái chuyển về "Chưa kích hoạt"

## Tính năng đã hoàn thành ✅

### Digital OTP PIN Screen (Profile)
- ✅ Tạo PIN 6 số lần đầu
- ✅ Thay đổi PIN (yêu cầu PIN hiện tại)
- ✅ Xóa PIN
- ✅ Hiển thị trạng thái kích hoạt
- ✅ Lưu ý bảo mật
- ✅ Toggle hiển thị/ẩn PIN

### Transfer Money Screen
- ✅ Kiểm tra PIN trước khi chuyển tiền
- ✅ Dialog nhập PIN với 6 ô tròn (giống hình 1)
- ✅ Dialog hiển thị OTP với countdown (giống hình 2)
- ✅ Tự động verify khi nhập đủ 6 số PIN
- ✅ Countdown 120 giây cho OTP
- ✅ Nút "Đặt lại mã PIN" dẫn đến Profile
- ✅ Thông báo nếu chưa có PIN

### Security
- ✅ PIN lưu trong flutter_secure_storage
- ✅ Mã hóa an toàn
- ✅ OTP tự động hết hạn
- ✅ Validation đầy đủ

## Lưu ý quan trọng ⚠️

1. **Không xóa file gốc** `transfer_money_screen.dart` cho đến khi test xong
2. **Backup** trước khi thay đổi
3. **Test kỹ** từng bước trước khi deploy
4. **Route name** `/digital-otp-pin` phải khớp trong toàn bộ app
5. **DigitalOtpController** phải được khởi tạo trước khi sử dụng

## Troubleshooting

### Lỗi: "DigitalOtpController not found"
```dart
// Thêm vào main.dart:
Get.put(DigitalOtpController());
```

### Lỗi: Route '/digital-otp-pin' not found
```dart
// Kiểm tra routes trong main.dart hoặc routes.dart
GetPage(name: '/digital-otp-pin', page: () => DigitalOtpPinScreen()),
```

### PIN không lưu được
```dart
// Kiểm tra pubspec.yaml đã có:
flutter_secure_storage: ^9.0.0
```

### Countdown không chạy
```dart
// Kiểm tra đã dispose timer:
_otpTimer?.cancel();
```

## Kết luận

Sau khi hoàn thành các bước trên, người dùng sẽ:
1. Tạo PIN trong Profile một lần
2. Sử dụng PIN đó cho mọi giao dịch chuyển tiền
3. Có thể thay đổi hoặc xóa PIN bất cứ lúc nào trong Profile

Flow hoàn chỉnh: **Profile → Tạo PIN → Chuyển tiền → Nhập PIN → Xem OTP → Xác thực**
