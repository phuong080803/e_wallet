# Báo cáo đánh giá bảo mật ứng dụng e-wallet

Tài liệu này tổng hợp hiện trạng bảo mật trong mã nguồn, các rủi ro, và hướng dẫn triển khai biện pháp khắc phục theo mức độ ưu tiên. Tất cả trích dẫn đều tham chiếu tới file/hàm thực tế trong repo để bạn dễ tra cứu.

## 1) Tổng quan các cơ chế bảo mật hiện có
- **[Khởi tạo Supabase]**: `lib/main.dart` khởi tạo bằng `Supabase.initialize()` với `url` và `anonKey` từ `lib/config/supabase_config.dart`.
- **[Quản lý phiên + token]**:
  - `lib/services/token_service.dart`: lưu access/refresh token, expiresAt vào `SharedPreferences`; có logic refresh/recover session.
  - `lib/services/supabase_service.dart`: wrapper đảm bảo session hợp lệ trước khi gọi DB (select/insert/update/delete/rpc/storage/realtime).
- **[Tự động đăng xuất khi không tương tác]**:
  - `lib/services/inactivity_service.dart` + tích hợp ở `lib/main.dart`: timeout 5 phút, gọi `AuthController.signOut()`.
- **[Xác thực/Phân quyền phía client]**:
  - `lib/controllers/auth_controller.dart`: đọc `user.userMetadata['role']` để điều hướng admin/user.
  - `lib/controllers/transaction_controller.dart`: kiểm tra admin qua bảng `admin_users` (client-side truy vấn).
- **[Chuyển tiền]**:
  - `lib/controllers/wallet_controller.dart` `transferMoney()`: cập nhật số dư 2 ví và ghi 2 bản ghi `transactions` bằng nhiều lệnh riêng lẻ (không có giao dịch DB/transaction server-side).
  - `lib/pages/screens/wallet/transfer_money_screen.dart`: UI OTP nội bộ (“Digital OTP”) không ràng buộc server.
- **[OTP]**:
  - `lib/controllers/otp_controller.dart`: dùng Supabase `auth.signInWithOtp()`/`verifyOTP()` (đúng cho xác thực danh tính), nhưng chưa ràng buộc với việc thực thi chuyển tiền ở server.
  - `lib/controllers/digital_otp_controller.dart`: lưu SHA-256 PIN trong `user_metadata` và verify ở client (không có salt, không hạn chế thử sai).
- **[KYC/Verification]**:
  - `lib/controllers/verification_controller.dart`: upload ảnh CMND/CCCD lên bucket `verification_images` và lấy `getPublicUrl()` (bucket công khai).

## 2) Phát hiện rủi ro nghiêm trọng
- **[Rò rỉ Service Role Key trên client]**
  - File: `lib/config/admin_config.dart` đang chứa `service_role_key` và tạo `SupabaseClient` admin để gọi `auth.admin.*` từ client trong `lib/controllers/admin_controller.dart`.
  - Rủi ro: Service Role có toàn quyền DB (bỏ qua RLS). Bất kỳ ai trích xuất APK/IPA đều lấy được key.

- **[Tokens lưu ở SharedPreferences]**
  - File: `lib/services/token_service.dart`.
  - Rủi ro: `SharedPreferences` không phải vùng nhớ an toàn cho token nhạy cảm.

- **[Chuyển tiền không nguyên tử và không được kiểm soát server]**
  - File: `lib/controllers/wallet_controller.dart` `transferMoney()`.
  - Rủi ro: Race condition, cập nhật chồng chéo, thao túng từ client, không có khóa hàng (`FOR UPDATE`) và không có xác thực nghiệp vụ tại DB.

- **[OTP/PIN không ràng buộc server]**
  - File: `lib/pages/screens/wallet/transfer_money_screen.dart`, `lib/controllers/otp_controller.dart`, `lib/controllers/digital_otp_controller.dart`.
  - Rủi ro: Người dùng (hoặc attacker) có thể bỏ qua bước OTP client và tự gọi API cập nhật số dư nếu RLS chưa chặt.

- **[KYC ảnh công khai]**
  - File: `lib/controllers/verification_controller.dart` sử dụng `getPublicUrl()`.
  - Rủi ro: Lộ dữ liệu nhạy cảm (ảnh giấy tờ).

- **[Phân quyền dựa vào metadata client]**
  - File: `lib/controllers/auth_controller.dart` (đọc `userMetadata['role']`).
  - Rủi ro: `user_metadata` có thể bị sửa bởi chính người dùng (tùy cấu hình), không nên tin cậy trên client.

## 3) Biện pháp khắc phục (ưu tiên triển khai)

### Ưu tiên 1: Xóa Service Role khỏi client và chuyển admin sang server/Edge Functions
- Xóa toàn bộ `service_role_key` khỏi `lib/config/admin_config.dart` và ngừng dùng `AdminConfig.adminClient` ở `lib/controllers/admin_controller.dart`.
- Tạo Edge Functions (hoặc backend riêng) cho tác vụ admin:
  - `GET /admin/users` (trả về danh sách rút gọn)
  - `POST /admin/verification/{id}/approve`
  - `POST /admin/verification/{id}/reject`
- Trong function: xác thực JWT (`auth.uid()`), kiểm tra user có trong bảng `admin_users`. Chỉ khi hợp lệ mới thực thi logic bằng Service Role (nằm server-side).
- Ngay lập tức ROTATE Service Role Key trên Supabase Dashboard.

### Ưu tiên 2: Bảo vệ token bằng Secure Storage
- Dùng `flutter_secure_storage` thay cho `SharedPreferences` trong `lib/services/token_service.dart`.
- Thêm logic migrate: nếu thấy token cũ trong `SharedPreferences` lần đầu chạy, copy sang secure storage rồi xóa bản cũ.

### Ưu tiên 3: Làm nguyên tử quy trình chuyển tiền (server-side transaction)
- Viết Postgres RPC (SQL function) hoặc Edge Function `perform_transfer`:
  - Input: `sender_wallet_id`, `recipient_wallet_id`, `amount`, `notes`.
  - Kiểm tra: `auth.uid()` sở hữu `sender_wallet_id`, số dư đủ, không tự chuyển cho mình, giới hạn số tiền/lần, rate limit…
  - `SELECT ... FOR UPDATE` khóa 2 ví theo thứ tự cố định để tránh deadlock.
  - Cập nhật số dư 2 ví và chèn 2 bản ghi giao dịch trong 1 transaction.
  - Return số dư mới + mã tham chiếu.
- RLS:
  - Cấm UPDATE trực tiếp bảng `wallets` và INSERT trực tiếp `transactions` từ anon/auth role; chỉ cho phép qua RPC/function.
- Client (`WalletController.transferMoney()`): thay chuỗi `.update()`/`.insert()` bằng `.rpc('perform_transfer', params: {...})`.

### Ưu tiên 4: Ràng buộc OTP với chuyển tiền trên server
- Thiết kế 2 bước thông qua Edge Functions:
  - `POST /transfer/challenge`: server lưu challenge gắn với (user, recipient, amount, notes, TTL 5 phút) và gửi OTP email (có thể dùng Supabase OTP hoặc tự gửi). Trả về `challenge_id`.
  - `POST /transfer/confirm`: client gửi `challenge_id` + `otp`. Server verify OTP và nếu hợp lệ thì gọi `perform_transfer` trong cùng request.
- UI: bỏ `generate OTP` ở client (`_generateAndShowOtp`) và thay bằng flow gọi 2 endpoints trên. Nếu muốn giữ UX nhập PIN, dùng biometrics/PIN thiết bị để nâng trải nghiệm nhưng quyết định cuối vẫn do server OTP.

### Ưu tiên 5: Siết RLS cho các bảng trọng yếu
- `wallets`:
  - `select`: chỉ hàng có `user_id = auth.uid()`.
  - `update`: từ chối trực tiếp; chỉ cho phép qua RPC.
- `transactions`:
  - `select`: chỉ hàng có `user_id = auth.uid()`.
  - `insert`: từ chối trực tiếp; chỉ cho phép qua RPC.
- `user_verifications`:
  - Người dùng chỉ được `select/upsert` bản ghi của chính mình và chỉ 1 số cột.
  - Admin cập nhật qua Edge Function (Service Role) – không client trực tiếp.

### Ưu tiên 6: Bảo mật KYC Storage
- Chuyển bucket `verification_images` sang PRIVATE.
- Lưu trong DB chỉ `path` đối tượng. Khi admin xem, server tạo `signed URL` ngắn hạn.
- (Tùy chọn) Dùng Edge Function proxy upload: kiểm tra content-type, kích thước, và log hoạt động.

### Ưu tiên 7: Chuẩn hóa App Lock/Biometrics
- Thêm `local_auth` và yêu cầu xác thực sinh trắc học khi app quay lại foreground hoặc sau `InactivityService` timeout.
- `main.dart`: lắng nghe `AppLifecycleState` và trigger khóa/bắt xác thực.

### Ưu tiên 8: Xử lý Digital OTP PIN
- Không lưu PIN trong `user_metadata`. Nếu vẫn cần PIN:
  - Lưu hash PBKDF2 + salt trong bảng riêng được bảo vệ bởi RLS.
  - Thêm hạn chế số lần sai và backoff server-side.
- Khuyến nghị: chuyển hẳn sang biometrics + OTP server ở mục 4.

### Ưu tiên 9: Quản lý cấu hình/secrets
- Không commit keys vào repo. Dùng build-time define (`--dart-define`) hoặc `.env` (không commit).
- Xoá/rotate toàn bộ khóa đã lộ (đặc biệt Service Role) và kiểm tra lịch sử commit.

## 4) Hướng dẫn triển khai chi tiết (từng hạng mục)

### 4.1 Xóa Service Role khỏi client và chuyển admin sang Edge Functions
- Sửa/xóa:
  - `lib/config/admin_config.dart`: loại bỏ `service_role_key` và `adminClient`.
  - `lib/controllers/admin_controller.dart`: thay các chỗ gọi `AdminConfig.adminClient.auth.admin.*` bằng `http` tới Edge Functions.
- Server (Edge Function mẫu – pseudo):
```ts
// /functions/admin-users/index.ts
import { createClient } from '@supabase/supabase-js'
export default async (req) => {
  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY)
  const jwt = req.headers.get('Authorization') // Bearer <token>
  const user = await validateJwtAndGetUser(jwt)
  const isAdmin = await supabase.from('admin_users').select('id').eq('id', user.id).maybeSingle()
  if (!isAdmin) return new Response('Forbidden', { status: 403 })
  const users = await supabase.auth.admin.listUsers()
  return Response.json(sanitize(users))
}
```
- Nhớ: Key Service Role chỉ dùng trong function (server), không bao giờ trong app.

### 4.2 Migrate token sang `flutter_secure_storage`
- `pubspec.yaml` đã có `flutter_secure_storage`.
- Thay toàn bộ thao tác get/set token trong `lib/services/token_service.dart` bằng API của `FlutterSecureStorage` (kèm migration từ `SharedPreferences`).

### 4.3 RPC `perform_transfer` (SQL phác thảo)
```sql
create or replace function perform_transfer(
  p_sender_wallet_id text,
  p_recipient_wallet_id text,
  p_amount numeric,
  p_notes text
) returns json as $$
declare
  v_sender record;
  v_recipient record;
  v_tx_group uuid := gen_random_uuid();
  v_ref text := 'TXN' || extract(epoch from now())::bigint;
begin
  if p_amount <= 0 then
    raise exception 'invalid_amount';
  end if;

  -- Lấy ví theo thứ tự để tránh deadlock
  select * into v_sender from wallets where id = p_sender_wallet_id for update;
  select * into v_recipient from wallets where id = p_recipient_wallet_id for update;

  if v_sender.user_id <> auth.uid() then
    raise exception 'forbidden';
  end if;
  if v_sender.user_id = v_recipient.user_id then
    raise exception 'self_transfer';
  end if;
  if v_sender.so_du < p_amount then
    raise exception 'insufficient_balance';
  end if;

  update wallets set so_du = so_du - p_amount, ngay_cap_nhat = now() where id = v_sender.id;
  update wallets set so_du = so_du + p_amount, ngay_cap_nhat = now() where id = v_recipient.id;

  insert into transactions(
    user_id, wallet_id, transaction_group_id, transaction_type, amount,
    balance_before, balance_after, counterpart_user_id, counterpart_wallet_id,
    description, notes, status, reference_number, fee_amount, created_at, updated_at, completed_at
  ) values (
    v_sender.user_id, v_sender.id, v_tx_group, 'transfer_out', p_amount,
    v_sender.so_du, v_sender.so_du - p_amount, v_recipient.user_id, v_recipient.id,
    'Chuyển tiền', p_notes, 'completed', v_ref, 0, now(), now(), now()
  ), (
    v_recipient.user_id, v_recipient.id, v_tx_group, 'transfer_in', p_amount,
    v_recipient.so_du, v_recipient.so_du + p_amount, v_sender.user_id, v_sender.id,
    'Nhận tiền', p_notes, 'completed', v_ref, 0, now(), now(), now()
  );

  return json_build_object('reference', v_ref);
end;
$$ language plpgsql security definer;
```
- Chính sách RLS: chặn UPDATE/INSERT trực tiếp, chỉ cho RPC.
- Client: `Supabase.instance.client.rpc('perform_transfer', params: {...})`.

### 4.4 OTP ràng buộc chuyển tiền (Edge Functions)
- `POST /transfer/challenge`:
  - Lưu `challenge_id`, `user_id`, `payload` (sender, recipient, amount, notes), `expires_at` (+5')
  - Gửi OTP tới email user (dùng Supabase OTP hoặc thư viện mail).
- `POST /transfer/confirm`:
  - Xác thực OTP hợp lệ + còn hạn, payload khớp.
  - Gọi `perform_transfer` và trả về kết quả.
- UI: cập nhật `transfer_money_screen.dart` để gọi 2 endpoint trên; bỏ `_generateAndShowOtp()`.

### 4.5 RLS khuyến nghị (phác thảo)
- `wallets`:
```sql
create policy wallets_select on wallets for select using (user_id = auth.uid());
revoke update on wallets from authenticated; -- cấm update trực tiếp
```
- `transactions`:
```sql
create policy transactions_select on transactions for select using (user_id = auth.uid());
revoke insert on transactions from authenticated; -- cấm insert trực tiếp
```
- `user_verifications`:
```sql
create policy verif_select on user_verifications for select using (user_id = auth.uid());
create policy verif_upsert on user_verifications for insert with check (user_id = auth.uid());
create policy verif_update on user_verifications for update using (user_id = auth.uid());
```
(Admin cập nhật qua Edge Function dùng Service Role.)

### 4.6 KYC Storage
- Chuyển bucket `verification_images` sang PRIVATE.
- Lưu DB: `front_id_image_path`, `back_id_image_path` thay vì URL.
- Admin xem ảnh: server tạo `signedUrl` tạm thời.

### 4.7 App Lock/Biometrics
- Thêm `local_auth` và khi `AppLifecycleState.resumed` hoặc khi `InactivityService` timeout, yêu cầu xác thực sinh trắc học.

### 4.8 Digital OTP PIN
- Xóa lưu PIN khỏi `user_metadata` (`digital_otp_controller.dart`).
- Nếu vẫn cần PIN server-side: dùng PBKDF2 + salt, lưu bảng riêng, hạn chế thử sai.
- Khuyến nghị chuyển sang biometrics + OTP server.

### 4.9 Quản lý secrets/config
- Di chuyển `SupabaseConfig.url` và `anonKey` sang `--dart-define`.
- Xoá khóa lộ khỏi repo và rotate trên Supabase.

## 5) Liên quan tới các thay đổi trước đây (Memories)
- Bạn đã chuẩn hóa name trong `user_metadata['name']` (tham chiếu `AuthController._loadProfile()`), điều này đúng và nên giữ.
- Flow chuyển tiền/OTP trước đây đã thay đổi nhiều lần. Tài liệu này đề xuất chuẩn hoá: mọi ủy quyền giao dịch phải kiểm tra ở server (OTP/biometrics chỉ là thêm lớp bảo vệ UI/UX), và cập nhật số dư phải nguyên tử qua RPC.

---

Nếu bạn muốn, tôi có thể bắt đầu thực hiện theo đúng thứ tự ưu tiên (xóa Service Role khỏi client và thêm Edge Functions cho admin), sau đó triển khai RPC chuyển tiền và cập nhật RLS. Hãy cho tôi biết hạng mục bạn muốn làm trước.
