# Test Admin Login

## Cách test admin login:

### 1. **Chạy ứng dụng**
```bash
flutter run
```

### 2. **Đăng nhập admin**
- Vào màn hình đăng nhập
- Nhập:
  - **Email:** `admin`
  - **Password:** `Admin123`
- Nhấn **Login**

### 3. **Kết quả mong đợi**
- Hiển thị thông báo: "Đăng nhập admin thành công"
- Tự động chuyển đến Admin Dashboard
- Admin Dashboard có 3 tab: Xác thực, Người dùng, Giao dịch

### 4. **Nếu không hoạt động**
Kiểm tra:
1. Route `/admin-dashboard` có được định nghĩa trong `main.dart`
2. `AdminDashboardScreen` có được import đúng
3. Không có lỗi console

### 5. **Debug**
Thêm log để debug:
```dart
print('Admin login detected: $email, $password');
print('Navigating to admin dashboard...');
```

## Các trường hợp test:

### ✅ **Test Case 1: Admin Login**
- Input: admin / Admin123
- Expected: Chuyển đến admin dashboard

### ✅ **Test Case 2: User Login**
- Input: user@example.com / password123
- Expected: Chuyển đến main app

### ✅ **Test Case 3: Wrong Admin Password**
- Input: admin / wrongpassword
- Expected: Hiển thị "Login failed"

### ✅ **Test Case 4: Empty Fields**
- Input: "" / ""
- Expected: Hiển thị "Please enter email and password"
