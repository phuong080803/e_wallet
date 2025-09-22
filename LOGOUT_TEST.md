# Test Logout Functionality

## Cách test chức năng đăng xuất:

### 1. **Test User Logout**
1. Đăng nhập với tài khoản user bình thường
2. Vào **Settings** (từ profile)
3. Nhấn **Logout**
4. **Kết quả mong đợi:**
   - Hiển thị "Đã đăng xuất thành công"
   - Chuyển về màn hình đăng nhập
   - Console log: "🚪 User logging out..." và "✅ User logout successful"

### 2. **Test Admin Logout**
1. Đăng nhập với admin (admin / Admin123)
2. Vào **Admin Dashboard**
3. Nhấn nút **Logout** (icon logout ở góc phải)
4. **Kết quả mong đợi:**
   - Hiển thị "Đã đăng xuất khỏi admin"
   - Chuyển về màn hình đăng nhập
   - Console log: "🚪 Admin logging out..." và "✅ Admin logout successful"

### 3. **Debug Logs**
Kiểm tra console logs:
- `🚪 User logging out...` - Bắt đầu đăng xuất user
- `🚪 Admin logging out...` - Bắt đầu đăng xuất admin
- `✅ User logout successful` - Đăng xuất user thành công
- `✅ Admin logout successful` - Đăng xuất admin thành công
- `❌ User logout error: ...` - Lỗi đăng xuất user
- `❌ Admin logout error: ...` - Lỗi đăng xuất admin

### 4. **Các trường hợp test:**

#### ✅ **Test Case 1: User Logout từ Settings**
- Input: Nhấn Logout trong Settings
- Expected: Chuyển về LoginScreen

#### ✅ **Test Case 2: Admin Logout từ Dashboard**
- Input: Nhấn Logout trong Admin Dashboard
- Expected: Chuyển về LoginScreen

#### ✅ **Test Case 3: Error Handling**
- Input: Lỗi network hoặc Supabase
- Expected: Vẫn chuyển về LoginScreen với thông báo lỗi

### 5. **Nếu vẫn không hoạt động:**
1. Kiểm tra console logs
2. Kiểm tra import statements
3. Kiểm tra GetX routing
4. Restart app và test lại
