# SECURITY IMPLEMENTATION GUIDE

Tài liệu này mô tả chi tiết các hạng mục bảo mật được áp dụng và khuyến nghị triển khai cho ứng dụng e-wallet (Flutter + Supabase).

Ngày cập nhật: 2025-10-08

---

## 1) Các thay đổi đã áp dụng ngay trong codebase

- **[Chống chụp màn hình]**: Kích hoạt cờ hệ thống `FLAG_SECURE` trên màn hình chuyển tiền để chặn chụp màn hình và quay màn hình.
  - File: `lib/pages/screens/wallet/transfer_money_screen.dart`
  - Imports: `package:flutter_windowmanager/flutter_windowmanager.dart`
  - Logic:
    - Bật flag trong `initState()`:
      ```dart
      FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
      ```
    - Gỡ flag trong `dispose()`:
      ```dart
      FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      ```
  - Dependency: thêm `flutter_windowmanager: ^0.2.0` trong `pubspec.yaml`.

- Lưu ý sử dụng: Nên áp dụng cơ chế này cho tất cả màn hình nhạy cảm khác như OTP, hiển thị PIN, chi tiết giao dịch chứa PII.

---

## 2) Bảo mật cơ sở dữ liệu Supabase (bắt buộc)

- **Bật Row Level Security (RLS)** cho mọi bảng: `wallets`, `transactions`, `otp_verifications`, `user_verifications`, ...
- **Policies mẫu (tham khảo)**:
  - Bảng `wallets` (chỉ chủ ví truy cập):
    ```sql
    -- Enable RLS
    alter table public.wallets enable row level security;

    -- Chỉ owner có thể select
    create policy wallets_owner_select
    on public.wallets for select
    using (auth.uid() = user_id);

    -- Cập nhật bởi owner (nếu cần)
    create policy wallets_owner_update
    on public.wallets for update
    using (auth.uid() = user_id);
    ```
  - Bảng `transactions` (chỉ xem giao dịch của mình):
    ```sql
    alter table public.transactions enable row level security;

    create policy transactions_self_select
    on public.transactions for select
    using (auth.uid() = user_id);

    -- Chèn giao dịch: khuyến nghị chỉ từ RPC (Postgres function) hoặc role server, không cho client insert trực tiếp
    revoke insert on public.transactions from anon, authenticated;
    ```
  - Bảng `otp_verifications` (nếu dùng DB-based OTP):
    ```sql
    alter table public.otp_verifications enable row level security;

    create policy otp_owner_select
    on public.otp_verifications for select
    using (auth.uid() = user_id);

    create policy otp_owner_insert
    on public.otp_verifications for insert
    with check (auth.uid() = user_id);

    -- Cấm liệt kê toàn bộ OTP từ người khác
    ```

- **Khuyến nghị**:
  - Dùng `views` (vd: `transaction_history`) để giới hạn cột trả về.
  - Lưu snapshot số dư và `transaction_group_id` để audit (đã áp dụng trong dự án theo các bản cập nhật trước).
  - Thao tác nhạy cảm (chuyển tiền, nạp/rút) nên thông qua **RPC** (Postgres function) để đảm bảo tính nguyên tử và logic server-side.

---

## 3) RPC chuyển tiền an toàn (gợi ý kiến trúc)

- Tạo hàm Postgres `transfer_funds(sender_wallet_id, recipient_wallet_id, amount, notes, idempotency_key)`:
  - Kiểm tra: số dư đủ, không chuyển tự thân, ví hoạt động.
  - Giao dịch SQL (BEGIN/COMMIT) cập nhật 2 ví và tạo 2 bản ghi giao dịch với snapshot.
  - Ghi `idempotency_key` để chống double-spend khi client retry.
  - Trả về kết quả duy nhất.
- Từ Flutter: gọi hàm qua `supabase.rpc('transfer_funds', params: {...})`.
- Ưu điểm: Chặn bypass logic client, đảm bảo đồng nhất dữ liệu.

---

## 4) OTP/MFA cho giao dịch

- Trạng thái hiện tại (theo dự án):
  - Đã có luồng OTP giao dịch/digital OTP trên app (PIN trước khi sinh OTP, countdown OTP, xác thực rồi mới chuyển tiền).
  - Nếu dùng Supabase OTP Email: dùng `auth.signInWithOtp()` và `verifyOTP()` (theo tài liệu nội bộ đã từng áp dụng).
  - Nếu dùng DB-based OTP: lưu trong bảng `otp_verifications` với `expires_at`, `is_used` và dọn rác định kỳ.

- Khuyến nghị nâng cao:
  - Thêm **rate limit** và **tạm khóa** sau N lần OTP sai.
  - Hỗ trợ **TOTP** (Google Authenticator) hoặc **biometric** cho giao dịch > ngưỡng.
  - Xóa/cleanup state OTP ngay khi dùng xong.

---

## 5) Quản lý phiên và token

- Bật **refresh token rotation**, revoke refresh token khi logout.
- Thiết lập TTL hợp lý cho access token.
- Ràng buộc session với `device_id` (lưu trong `flutter_secure_storage`) để phát hiện sử dụng token trái phép trên thiết bị khác.

---

## 6) Ứng dụng (Flutter) – Lưu trữ & Hardening

- **Lưu trữ an toàn**:
  - Dùng `flutter_secure_storage` cho token, device_id, metadata nhạy cảm.
  - Tránh lưu OTP/PIN ở `SharedPreferences`.
- **App hardening**:
  - Bật **obfuscation** (Dart/Proguard) trong build production.
  - **Root/Jailbreak detection**: cảnh báo/khóa chức năng nhạy cảm khi thiết bị không an toàn.
  - **Chặn screenshot** ở tất cả màn hình nhạy cảm (đã áp dụng ở chuyển tiền; nên áp dụng thêm ở OTP/PIN/chi tiết giao dịch).
- **Biometric/App PIN**:
  - Yêu cầu xác nhận Biometric/PIN khi mở app hoặc khi giao dịch vượt ngưỡng.

---

## 7) Mạng & API

- **SSL Pinning** trên Flutter networking layer để giảm rủi ro MITM:
  - Pin public key/cert của endpoint Supabase.
  - Cập nhật khi cert rotate.
- **Rate limiting**:
  - Áp dụng ở Edge Functions (nếu dùng) và trong luồng OTP.
- **Idempotency & retry**:
  - Dùng `idempotency_key` khi gọi RPC chuyển tiền để tránh double-spend khi retry mạng.

---

## 8) Fraud/Risk Controls

- **Velocity rules**: giới hạn số lần/giá trị chuyển tiền theo thời gian, thiết bị, IP.
- **Anomaly detection**: cờ cho hành vi bất thường (nhiều OTP sai, đổi thiết bị, giao dịch ngoài khung giờ, nhận lần đầu...)
- **Blacklist**: block thiết bị/tài khoản/IP vi phạm; yêu cầu KYC lại.

---

## 9) Secrets & CI/CD

- Không hardcode keys trong source.
- Phân tách cấu hình `dev/stage/prod` với biến môi trường riêng.
- Bật secret scanning trong CI, pre-commit hooks.

---

## 10) Giám sát & Nhật ký

- Tích hợp Sentry/Crashlytics cho client.
- Bật audit logs Supabase, tạo cảnh báo khi:
  - Tỷ lệ OTP fail tăng cao
  - Nhiều giao dịch bị từ chối
  - Biến động nạp/rút đột biến

---

## 11) Admin & Phân quyền

- RBAC: tách vai trò `viewer`, `operator`, `auditor`, `admin`.
- Ẩn PII không cần thiết khỏi giao diện admin.
- Áp dụng xác nhận 2 người (four-eyes) cho thay đổi quan trọng.

---

## 12) Kiểm thử & Sao lưu

- Kịch bản kiểm thử:
  - Chuyển tiền đồng thời, retry mạng, OTP sai/nhiều lần, khóa tạm thời, idempotency.
- Backup/restore DB định kỳ và diễn tập khôi phục.
- Chính sách retention/xóa dữ liệu theo quy định.

---

## 13) Hướng dẫn triển khai nhanh

1. Chạy `flutter pub get` sau khi thêm dependency `flutter_windowmanager`.
2. Áp dụng chặn screenshot cho các màn hình nhạy cảm khác (OTP, PIN, chi tiết giao dịch): thêm FLAG_SECURE tương tự như `transfer_money_screen.dart`.
3. Rà soát và bật RLS + viết Policies cho các bảng chính.
4. Tạo RPC `transfer_funds` và chuyển luồng chuyển tiền sang RPC thay vì insert/update từ client.
5. Bật refresh token rotation và kiểm soát phiên.
6. Thêm SSL Pinning trong network layer.
7. Thiết lập rate limit OTP và khóa tạm thời sau N lần sai.

---

## 14) Tham chiếu code chính

- `lib/pages/screens/wallet/transfer_money_screen.dart`: luồng chuyển tiền, chặn screenshot, Digital OTP UI.
- `pubspec.yaml`: dependencies bảo mật (`flutter_secure_storage`, `flutter_windowmanager`).

---

## 15) Gợi ý mở rộng tiếp theo

- Áp dụng xác nhận Biometric/PIN cho giao dịch vượt ngưỡng cấu hình.
- Tích hợp Sentry/Crashlytics và cảnh báo Supabase.
- Thêm root/jailbreak detection và cảnh báo thiết bị không an toàn.
- Viết tài liệu vận hành sự cố (incident response) cho giao dịch và OTP.

---

Nếu cần, tôi có thể cung cấp mẫu SQL policies/RPC và mã Flutter cho SSL pinning hoặc biometric để bạn áp dụng ngay.
