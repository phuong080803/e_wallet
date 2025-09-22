# Hệ thống Xác thực và Admin Panel - E-Wallet

## Tổng quan
Hệ thống xác thực thông tin cá nhân và admin panel đã được tích hợp vào ứng dụng E-Wallet, cho phép người dùng xác thực thông tin cá nhân và admin quản lý hệ thống.

## Tính năng mới

### 1. Xác thực thông tin cá nhân
- **Vị trí**: Settings > Xác thực thông tin
- **Chức năng**: Người dùng có thể xác thực:
  - Số điện thoại (10-11 chữ số)
  - Số căn cước công dân (9-12 chữ số)
  - Địa chỉ thường trú (tối thiểu 10 ký tự)
- **Trạng thái**: Pending → Verified/Rejected

### 2. Admin Panel
- **Truy cập**: Settings > Admin Panel
- **Thông tin đăng nhập**:
  - Username: `admin`
  - Password: `admin123`

### 3. Chức năng Admin
- **Quản lý xác thực**: Xem, phê duyệt, từ chối yêu cầu xác thực
- **Quản lý người dùng**: Xem danh sách tất cả người dùng
- **Quản lý giao dịch**: Xem tất cả giao dịch trong hệ thống
- **Xác thực từng trường**: Có thể xác thực riêng lẻ từng trường thông tin

## Cấu trúc Database

### Bảng mới được thêm:

#### 1. `user_verifications`
```sql
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key to auth.users)
- phone_number: VARCHAR(20)
- phone_verified: BOOLEAN
- phone_verification_date: TIMESTAMP
- id_card_number: VARCHAR(20)
- id_card_verified: BOOLEAN
- id_card_verification_date: TIMESTAMP
- address: TEXT
- address_verified: BOOLEAN
- address_verification_date: TIMESTAMP
- verification_status: VARCHAR(20) ('pending', 'verified', 'rejected')
- admin_notes: TEXT
- created_at: TIMESTAMP
- updated_at: TIMESTAMP
```

#### 2. `admin_users`
```sql
- id: UUID (Primary Key)
- username: VARCHAR(50) UNIQUE
- password_hash: VARCHAR(255)
- email: VARCHAR(255)
- full_name: VARCHAR(255)
- is_active: BOOLEAN
- last_login: TIMESTAMP
- created_at: TIMESTAMP
- updated_at: TIMESTAMP
```

## Cách sử dụng

### Cho người dùng:
1. Vào **Settings** > **Xác thực thông tin**
2. Điền đầy đủ thông tin:
   - Số điện thoại
   - Số căn cước công dân
   - Địa chỉ thường trú
3. Nhấn **"Gửi yêu cầu xác thực"**
4. Chờ admin xem xét và phê duyệt

### Cho Admin:
1. Vào **Settings** > **Admin Panel**
2. Đăng nhập với:
   - Username: `admin`
   - Password: `admin123`
3. Sử dụng các tab để:
   - **Xác thực**: Quản lý yêu cầu xác thực
   - **Người dùng**: Xem danh sách người dùng
   - **Giao dịch**: Xem tất cả giao dịch

## Các file đã được tạo/cập nhật

### Models:
- `lib/models/database_models.dart` - Thêm `UserVerification` và `AdminUser`

### Controllers:
- `lib/controllers/verification_controller.dart` - Quản lý xác thực
- `lib/controllers/admin_controller.dart` - Quản lý admin

### Screens:
- `lib/pages/screens/profile/screens/verification_screen.dart` - Màn hình xác thực
- `lib/pages/screens/admin/screens/admin_login_screen.dart` - Đăng nhập admin
- `lib/pages/screens/admin/screens/admin_dashboard_screen.dart` - Dashboard admin

### Widgets:
- `lib/pages/screens/admin/widgets/admin_verification_item.dart` - Item xác thực
- `lib/pages/screens/admin/widgets/admin_user_item.dart` - Item người dùng
- `lib/pages/screens/admin/widgets/admin_transaction_item.dart` - Item giao dịch

### Database:
- `database_setup.sql` - Cập nhật schema với bảng mới

### Routes:
- `lib/main.dart` - Thêm routes cho admin

## Lưu ý quan trọng

1. **Bảo mật**: Mật khẩu admin được hash trong database
2. **Validation**: Tất cả thông tin đều được validate trước khi gửi
3. **UI/UX**: Giao diện thân thiện với người dùng
4. **Responsive**: Hỗ trợ đầy đủ các kích thước màn hình
5. **Error Handling**: Xử lý lỗi đầy đủ và thông báo rõ ràng

## Tương lai

- Tích hợp Supabase thực tế
- Thêm email verification
- Thêm push notifications cho admin
- Thêm báo cáo và thống kê
- Thêm phân quyền admin chi tiết hơn


