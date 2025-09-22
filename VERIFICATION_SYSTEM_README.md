# Hệ thống Xác thực Thông tin Cá nhân - E-Wallet

## Tổng quan
Hệ thống xác thực thông tin cá nhân cho phép người dùng gửi yêu cầu xác thực và admin sẽ xem xét, phê duyệt hoặc từ chối các yêu cầu này.

## Quy trình Xác thực

### 1. **Người dùng gửi yêu cầu xác thực**
- Vào **Settings** > **Xác thực thông tin**
- Điền đầy đủ thông tin:
  - Số điện thoại (10-11 chữ số)
  - Số căn cước công dân (9-12 chữ số)
  - Địa chỉ thường trú (tối thiểu 10 ký tự)
- Nhấn **"Gửi yêu cầu xác thực"**
- Trạng thái: `dang_cho` (Chờ xử lý)

### 2. **Admin xem xét và phê duyệt**
- Admin đăng nhập: `admin` / `Admin123`
- Vào **Admin Panel** > **Xác thực**
- Xem danh sách yêu cầu xác thực
- Có thể:
  - **Phê duyệt toàn bộ**: Tất cả thông tin được xác thực
  - **Từ chối**: Yêu cầu bị từ chối với lý do
  - **Xác thực từng trường**: Xác thực riêng lẻ từng thông tin

## Cấu trúc Database

### Bảng `user_verifications`
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

## Các Trạng thái Xác thực

### 1. **dang_cho** (Chờ xử lý)
- Yêu cầu vừa được gửi
- Chờ admin xem xét
- Màu: Cam

### 2. **da_xac_thuc** (Đã xác thực)
- Admin đã phê duyệt
- Tất cả thông tin đã được xác thực
- Màu: Xanh lá

### 3. **bi_tu_choi** (Bị từ chối)
- Admin đã từ chối yêu cầu
- Có ghi chú lý do từ chối
- Màu: Đỏ

## Chức năng Admin

### **Tab Xác thực**
- Xem danh sách yêu cầu xác thực
- Phê duyệt/từ chối toàn bộ
- Xác thực từng trường riêng lẻ:
  - Số điện thoại
  - Số căn cước
  - Địa chỉ
- Thêm ghi chú admin

### **Tab Người dùng**
- Xem danh sách tất cả người dùng
- Thông tin cơ bản của từng user

### **Tab Giao dịch**
- Xem tất cả giao dịch trong hệ thống
- Theo dõi hoạt động tài chính

## Cách sử dụng

### **Cho Người dùng:**
1. Vào **Settings** > **Xác thực thông tin**
2. Điền thông tin chính xác
3. Gửi yêu cầu
4. Chờ admin xem xét (24-48 giờ)

### **Cho Admin:**
1. Đăng nhập với `admin` / `Admin123`
2. Vào **Admin Panel** (từ Settings)
3. Chọn tab **Xác thực**
4. Xem xét và quyết định:
   - **Phê duyệt**: Nhấn "Phê duyệt" + ghi chú
   - **Từ chối**: Nhấn "Từ chối" + lý do
   - **Xác thực từng trường**: Nhấn icon ✓ hoặc ✗ cho từng trường

## Validation Rules

### **Số điện thoại**
- Định dạng: 10-11 chữ số
- Regex: `^[0-9]{10,11}$`

### **Số căn cước**
- Định dạng: 9-12 chữ số
- Regex: `^[0-9]{9,12}$`

### **Địa chỉ**
- Tối thiểu: 10 ký tự
- Phải là địa chỉ thường trú thực tế

## Lợi ích

1. **Bảo mật**: Xác thực thông tin cá nhân trước khi sử dụng dịch vụ
2. **Tuân thủ**: Đáp ứng yêu cầu pháp lý về xác thực danh tính
3. **Kiểm soát**: Admin có thể quản lý và giám sát
4. **Linh hoạt**: Có thể xác thực từng trường riêng lẻ
5. **Minh bạch**: Có ghi chú và lý do rõ ràng

## Lưu ý quan trọng

- Thông tin phải chính xác và trung thực
- Admin cần xem xét kỹ lưỡng trước khi phê duyệt
- Có thể từ chối với lý do cụ thể
- Tất cả hoạt động đều được ghi log
- Người dùng có thể gửi lại yêu cầu nếu bị từ chối
