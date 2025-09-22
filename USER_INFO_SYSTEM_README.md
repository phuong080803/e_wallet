# Hệ thống Quản lý Thông tin Người dùng - E-Wallet

## Tổng quan

Hệ thống đã được cập nhật để phân biệt rõ ràng giữa **thông tin cá nhân** và **thông tin cần xác thực**, giúp người dùng có thể cập nhật thông tin cá nhân ngay lập tức mà không cần chờ admin xác thực.

## Cấu trúc Database

### Bảng `profiles` (Thông tin cá nhân - Không cần xác thực)
```sql
CREATE TABLE profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    ho_ten VARCHAR(255),           -- Họ và tên
    email VARCHAR(255) NOT NULL,   -- Email
    tuoi INTEGER CHECK (tuoi >= 16 AND tuoi <= 120), -- Tuổi
    dia_chi TEXT,                  -- Địa chỉ
    hinh_anh VARCHAR(500),         -- Ảnh đại diện (URL)
    ngay_tao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ngay_cap_nhat TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Bảng `user_verifications` (Thông tin cần xác thực)
```sql
CREATE TABLE user_verifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    so_dien_thoai VARCHAR(20),                    -- Số điện thoại
    so_dien_thoai_da_xac_thuc BOOLEAN DEFAULT FALSE,
    ngay_xac_thuc_so_dien_thoai TIMESTAMP WITH TIME ZONE,
    so_can_cuoc VARCHAR(20),                      -- Số căn cước công dân
    so_can_cuoc_da_xac_thuc BOOLEAN DEFAULT FALSE,
    ngay_xac_thuc_so_can_cuoc TIMESTAMP WITH TIME ZONE,
    trang_thai_xac_thuc VARCHAR(20) DEFAULT 'dang_cho',
    ghi_chu_admin TEXT,
    ngay_tao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ngay_cap_nhat TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);
```

## Các Controller

### 1. ProfileController
- **Mục đích**: Quản lý thông tin cá nhân không cần xác thực
- **Chức năng**:
  - `loadUserProfile()`: Tải thông tin profile
  - `updateProfile()`: Cập nhật thông tin cá nhân
  - Validation cho tên, tuổi, địa chỉ, URL ảnh

### 2. VerificationController (Đã cập nhật)
- **Mục đích**: Quản lý thông tin cần xác thực
- **Chức năng**:
  - `submitVerification()`: Gửi yêu cầu xác thực
  - `updateVerification()`: Cập nhật thông tin xác thực
  - Validation cho số điện thoại và số căn cước
  - **Loại bỏ**: Xử lý địa chỉ (đã chuyển sang ProfileController)

## Các Màn hình

### 1. EditProfileScreen
- **Mục đích**: Chỉnh sửa thông tin cá nhân
- **Thông tin**: Họ tên, tuổi, địa chỉ, ảnh đại diện
- **Đặc điểm**: Cập nhật ngay lập tức, không cần chờ admin

### 2. VerificationScreen (Đã cập nhật)
- **Mục đích**: Xác thực thông tin quan trọng
- **Thông tin**: Số điện thoại, số căn cước công dân
- **Đặc điểm**: Cần admin xác thực

### 3. MyAccountScreen (Đã cập nhật)
- **Mục đích**: Hiển thị tổng quan thông tin người dùng
- **Phân chia**:
  - **Thông tin cá nhân**: Hiển thị trong container màu xanh lá
  - **Thông tin cần xác thực**: Hiển thị trong container màu cam
  - **Nút chỉnh sửa**: Dẫn đến EditProfileScreen
  - **Nút xác thực**: Dẫn đến VerificationScreen

## Quy trình Hoạt động

### 1. Thông tin Cá nhân (Không cần xác thực)
```
Người dùng → EditProfileScreen → ProfileController → Database (profiles)
```
- Cập nhật ngay lập tức
- Validation cơ bản
- Không cần admin phê duyệt

### 2. Thông tin Cần Xác thực
```
Người dùng → VerificationScreen → VerificationController → Database (user_verifications) → Admin xác thực
```
- Cần admin phê duyệt
- Validation nghiêm ngặt
- Trạng thái: `dang_cho`, `da_xac_thuc`, `bi_tu_choi`

## Lợi ích

1. **Trải nghiệm người dùng tốt hơn**: Có thể cập nhật thông tin cá nhân ngay lập tức
2. **Bảo mật cao**: Thông tin quan trọng vẫn cần xác thực
3. **Phân chia rõ ràng**: Dễ quản lý và bảo trì
4. **Hiệu quả**: Giảm tải cho admin, chỉ cần xác thực thông tin quan trọng

## Cách sử dụng

1. **Cập nhật thông tin cá nhân**:
   - Vào MyAccountScreen
   - Nhấn "Chỉnh sửa" trong phần "Thông tin cá nhân"
   - Chỉnh sửa và lưu

2. **Xác thực thông tin quan trọng**:
   - Vào MyAccountScreen
   - Nhấn "Xác thực thông tin"
   - Điền số điện thoại và số căn cước
   - Chờ admin xác thực

## Migration Database

Nếu bạn đang có database cũ, cần chạy các lệnh SQL sau:

```sql
-- Thêm cột tuoi và dia_chi vào bảng profiles
ALTER TABLE profiles ADD COLUMN tuoi INTEGER CHECK (tuoi >= 16 AND tuoi <= 120);
ALTER TABLE profiles ADD COLUMN dia_chi TEXT;

-- Xóa các cột địa chỉ khỏi bảng user_verifications
ALTER TABLE user_verifications DROP COLUMN IF EXISTS dia_chi;
ALTER TABLE user_verifications DROP COLUMN IF EXISTS dia_chi_da_xac_thuc;
ALTER TABLE user_verifications DROP COLUMN IF EXISTS ngay_xac_thuc_dia_chi;
```




