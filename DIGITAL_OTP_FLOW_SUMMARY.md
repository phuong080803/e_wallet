# 📋 DIGITAL OTP FLOW - TÓM TẮT HOÀN CHỈNH

## 🎯 Flow đúng như bạn yêu cầu

### 1️⃣ **TẠO PIN** (Trong Profile)
```
Profile → Digital OTP PIN → Nhập PIN 6 số → Xác nhận → ✅ Lưu vào Supabase
```

### 2️⃣ **CHUYỂN TIỀN** (Chỉ nhập PIN)
```
1. Nhập thông tin chuyển tiền
2. Bấm "Xác nhận chuyển tiền"
3. Kiểm tra có PIN chưa?
   ├─ ❌ Chưa có → Dialog yêu cầu tạo PIN trong Profile
   └─ ✅ Đã có → Hiển thị dialog nhập PIN (6 ô tròn)
4. Nhập PIN 6 số
5. Tự động verify khi nhập đủ 6 số
6. ✅ PIN đúng → Hiển thị OTP với countdown 120s
7. Bấm "Xác thực" → Chuyển tiền thành công
```

---

## ✅ ĐÃ XÓA (Không còn trong transfer screen)

- ❌ Dialog "Thiết lập PIN" trong màn chuyển tiền
- ❌ `_showSetPinDialog` variable
- ❌ `_pinConfirmController` 
- ❌ `_buildSetPinDialog()` function

---

## ✅ CÒN LẠI (Trong transfer screen)

### Variables:
```dart
final _pinController = TextEditingController();  // ✅ Chỉ để nhập PIN
final RxBool _showPinDialog = false.obs;        // ✅ Dialog nhập PIN
final RxBool _showOtpDialog = false.obs;        // ✅ Dialog hiển thị OTP
final RxString _generatedOtp = ''.obs;          // ✅ Mã OTP
final RxInt _otpSecondsLeft = 0.obs;            // ✅ Countdown
Timer? _otpTimer;                                // ✅ Timer
```

### Functions:
```dart
_sendOtp()              // ✅ Kiểm tra PIN → Hiển thị dialog nhập PIN
_generateAndShowOtp()   // ✅ Sinh OTP → Hiển thị với countdown
_verifyOtpAndTransfer() // ✅ Xác thực → Chuyển tiền
_verifyPinAndShowOtp()  // ✅ Verify PIN → Hiển thị OTP
```

### Dialogs:
```dart
_buildPinDialog()        // ✅ Dialog nhập PIN (6 ô tròn)
_buildDigitalOtpDialog() // ✅ Dialog hiển thị OTP + countdown
```

---

## 🔄 FLOW CHI TIẾT

### Khi bấm "Xác nhận chuyển tiền":

```dart
_sendOtp() {
  hasPin = await _digitalOtpController.hasPin();
  
  if (!hasPin) {
    // Hiển thị dialog: "Chưa có Digital OTP PIN"
    // Nút "Đi tới thiết lập" → Navigate to /digital-otp-pin
    return;
  }
  
  // Hiển thị dialog nhập PIN
  _showPinDialog.value = true;
}
```

### Khi nhập đủ 6 số PIN:

```dart
_verifyPinAndShowOtp() {
  ok = await _digitalOtpController.verifyPin(pin);
  
  if (!ok) {
    Get.snackbar('Lỗi', 'PIN không đúng');
    return;
  }
  
  // Đóng dialog PIN
  _showPinDialog.value = false;
  
  // Sinh và hiển thị OTP
  _generateAndShowOtp();
}
```

### Hiển thị OTP:

```dart
_generateAndShowOtp() {
  // Sinh mã OTP 6 số
  code = random 6 digits;
  _generatedOtp.value = code;
  
  // Set countdown 120 giây
  _otpSecondsLeft.value = 120;
  
  // Hiển thị dialog OTP
  _showOtpDialog.value = true;
  
  // Start countdown timer
  Timer.periodic(1 second) {
    _otpSecondsLeft.value--;
    if (_otpSecondsLeft <= 0) {
      // Hết hạn → Đóng dialog
      _showOtpDialog.value = false;
    }
  }
}
```

### Khi bấm "Xác thực":

```dart
_verifyOtpAndTransfer() {
  // Thực hiện chuyển tiền
  success = await _walletController.transferMoney(...);
  
  if (success) {
    // Đóng dialog OTP
    _showOtpDialog.value = false;
    
    // Stop timer
    _otpTimer?.cancel();
    
    // Navigate to success screen
    Get.off(() => TransferSuccessScreen(...));
  }
}
```

---

## 📱 UI/UX

### Dialog 1: Nhập PIN (Hình 1)
```
┌─────────────────────────────┐
│   Xác thực Digital OTP      │
│                             │
│ Vui lòng nhập mã PIN...     │
│                             │
│   ⚫ ⚫ ⚫ ⚫ ⚫ ⚫           │ ← 6 ô tròn
│                             │
│   [Đặt lại mã PIN]          │
└─────────────────────────────┘
```

### Dialog 2: Hiển thị OTP (Hình 2)
```
┌─────────────────────────────┐
│   Xác thực Digital OTP      │
│                             │
│      Mã xác thực            │
│                             │
│   1  2  3  4  5  6          │ ← Mã OTP
│                             │
│ Có hiệu lực trong 120 giây  │
│                             │
│   [    Xác thực    ]        │ ← Nút đỏ
└─────────────────────────────┘
```

---

## 🔐 BẢO MẬT

### PIN:
- ✅ Lưu trong Supabase `user_metadata`
- ✅ Hash bằng SHA-256
- ✅ Không lưu plain text

### OTP:
- ✅ Sinh ngẫu nhiên 6 số
- ✅ Hiệu lực 120 giây
- ✅ Tự động hết hạn
- ✅ Không gửi email (local only)

---

## 📂 FILES

### Đã cập nhật đúng:
- ✅ `lib/pages/screens/wallet/transfer_money_screen_new.dart` - File mới (đúng)
- ✅ `lib/pages/screens/profile/screens/digital_otp_pin_screen.dart` - Tạo PIN
- ✅ `lib/controllers/digital_otp_controller.dart` - Lưu PIN vào Supabase
- ✅ `lib/main.dart` - Route + Controller init

### Cần cập nhật:
- ⚠️ `lib/pages/screens/wallet/transfer_money_screen.dart` - File gốc (cũ)

**Giải pháp:** Copy nội dung từ `transfer_money_screen_new.dart` sang `transfer_money_screen.dart`

---

## ✅ CHECKLIST

- ✅ Tạo PIN trong Profile
- ✅ Lưu PIN vào Supabase metadata (hash SHA-256)
- ✅ Kiểm tra PIN trước khi chuyển tiền
- ✅ Dialog nhập PIN với 6 ô tròn
- ✅ Tự động verify khi nhập đủ 6 số
- ✅ Hiển thị OTP với countdown 120s
- ✅ Nút "Xác thực" để chuyển tiền
- ✅ Nút "Đặt lại mã PIN" → Navigate to Profile
- ✅ Dialog yêu cầu tạo PIN nếu chưa có
- ❌ Không còn dialog "Thiết lập PIN" trong transfer screen

---

## 🎯 KẾT LUẬN

**Flow hiện tại đúng 100% như yêu cầu:**
1. ✅ Tạo PIN trong Profile
2. ✅ Chuyển tiền chỉ nhập PIN
3. ✅ Nhập PIN → Hiển thị OTP → Xác thực

**File `transfer_money_screen_new.dart` đã đúng!**

Bạn chỉ cần:
1. Copy nội dung từ `_new.dart` sang file gốc
2. Hoặc đổi tên `_new.dart` thành file gốc
3. Test flow: Profile → Tạo PIN → Chuyển tiền → Nhập PIN → Xem OTP → Xác thực

**Sẵn sàng test!** 🚀
