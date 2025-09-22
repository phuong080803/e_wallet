# Cập nhật Database Schema - E-Wallet

## Thay đổi chính

### 1. **Cấu trúc Database mới (Tiếng Việt)**
- Tất cả tên cột đã được chuyển sang tiếng Việt
- Loại bỏ hoàn toàn bảng `admin_users`
- Loại bỏ tất cả policies và triggers
- Sử dụng cấu trúc đơn giản hơn

### 2. **Bảng Profiles**
```sql
CREATE TABLE profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    ho_ten VARCHAR(255),
    email VARCHAR(255) NOT NULL,
    hinh_anh VARCHAR(500),
    ngay_tao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ngay_cap_nhat TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 3. **Bảng Wallets**
```sql
CREATE TABLE wallets (
    id VARCHAR(10) PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    so_du DECIMAL(15,2) DEFAULT 0.00,
    loai_tien_te VARCHAR(10) DEFAULT 'VND',
    ngay_tao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ngay_cap_nhat TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);
```

### 4. **Bảng Transactions**
```sql
CREATE TABLE transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    nguoi_gui_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    nguoi_nhan_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    so_tien DECIMAL(15,2) NOT NULL,
    loai VARCHAR(20) NOT NULL CHECK (loai IN ('chuyen_khoan', 'yeu_cau', 'thanh_toan')),
    ghi_chu TEXT,
    trang_thai VARCHAR(20) NOT NULL DEFAULT 'dang_cho' CHECK (trang_thai IN ('dang_cho', 'hoan_thanh', 'that_bai', 'huy')),
    ngay_tao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ngay_cap_nhat TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 5. **Bảng Contacts**
```sql
CREATE TABLE contacts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    ho_ten VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    so_dien_thoai VARCHAR(20),
    hinh_anh VARCHAR(500),
    ngay_tao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ngay_cap_nhat TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 6. **Bảng User Verifications**
```sql
CREATE TABLE user_verifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    so_dien_thoai VARCHAR(20),
    so_dien_thoai_da_xac_thuc BOOLEAN DEFAULT FALSE,
    ngay_xac_thuc_so_dien_thoai TIMESTAMP WITH TIME ZONE,
    so_can_cuoc VARCHAR(20),
    so_can_cuoc_da_xac_thuc BOOLEAN DEFAULT FALSE,
    ngay_xac_thuc_so_can_cuoc TIMESTAMP WITH TIME ZONE,
    dia_chi TEXT,
    dia_chi_da_xac_thuc BOOLEAN DEFAULT FALSE,
    ngay_xac_thuc_dia_chi TIMESTAMP WITH TIME ZONE,
    trang_thai_xac_thuc VARCHAR(20) DEFAULT 'dang_cho' CHECK (trang_thai_xac_thuc IN ('dang_cho', 'da_xac_thuc', 'bi_tu_choi')),
    ghi_chu_admin TEXT,
    ngay_tao TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ngay_cap_nhat TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);
```

## Thay đổi trong Code

### 1. **Models được cập nhật**
- Tất cả models đã được cập nhật để sử dụng tên cột tiếng Việt
- Thêm helper getters để backward compatibility
- Loại bỏ class `AdminUser`

### 2. **Auth Controller**
- Thêm logic kiểm tra admin login trực tiếp trong `signIn()`
- Khi nhập `admin`/`Admin123` sẽ chuyển thẳng đến admin dashboard
- Không cần tạo bảng admin riêng

### 3. **Admin Controller**
- Loại bỏ phần quản lý admin user
- Đơn giản hóa logic đăng nhập
- Cập nhật tên cột trong các method

### 4. **Verification Controller**
- Cập nhật tên cột trong database calls
- Sử dụng tên cột tiếng Việt

## Cách sử dụng Admin

### **Đăng nhập Admin:**
1. Vào màn hình đăng nhập bình thường
2. Nhập:
   - **Email:** `admin`
   - **Password:** `Admin123`
3. Sẽ tự động chuyển đến admin dashboard

### **Chức năng Admin:**
- Xem và quản lý yêu cầu xác thực
- Xem danh sách người dùng
- Xem tất cả giao dịch
- Phê duyệt/từ chối xác thực
- Xác thực từng trường riêng lẻ

## Lợi ích của cấu trúc mới

1. **Đơn giản hóa:** Loại bỏ policies và triggers phức tạp
2. **Dễ hiểu:** Tên cột tiếng Việt dễ đọc và bảo trì
3. **Bảo mật đơn giản:** Admin login được xử lý trực tiếp trong code
4. **Tương thích:** Vẫn giữ được backward compatibility
5. **Hiệu suất:** Ít overhead hơn, không cần RLS

## Migration

Để chuyển đổi từ cấu trúc cũ sang mới:

1. Chạy script `database_setup.sql` mới
2. Cập nhật code để sử dụng tên cột mới
3. Test các chức năng admin với thông tin đăng nhập mới
4. Đảm bảo tất cả models hoạt động đúng

## Lưu ý

- Tất cả tên cột đã được chuyển sang tiếng Việt
- Admin login không cần database riêng
- Không có RLS policies, cần xử lý bảo mật ở tầng ứng dụng
- Backward compatibility được duy trì qua helper getters
