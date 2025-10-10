-- RLS policies (mẫu) cho các bảng trọng yếu
-- Lưu ý: chỉnh tên schema/bảng/cột theo DB thực tế trước khi áp dụng.

-- Enable RLS
alter table wallets enable row level security;
alter table transactions enable row level security;
alter table user_verifications enable row level security;

-- WALLET POLICIES
-- Chỉ cho phép user xem ví của chính mình
create policy wallets_select_self on wallets for select
  using (user_id = auth.uid());

-- Chặn update trực tiếp từ client (chỉ cho phép qua RPC)
revoke update on wallets from authenticated;
revoke insert on wallets from authenticated; -- tuỳ chọn

-- TRANSACTION POLICIES
-- Chỉ cho phép user xem giao dịch của chính mình
create policy transactions_select_self on transactions for select
  using (user_id = auth.uid());

-- Chặn insert trực tiếp (chỉ cho phép qua RPC)
revoke insert on transactions from authenticated;
revoke update on transactions from authenticated; -- tuỳ chọn

-- USER_VERIFICATIONS POLICIES
-- User chỉ được xem bản ghi của mình
create policy verif_select_self on user_verifications for select
  using (user_id = auth.uid());

-- User chỉ được insert/upsert bản ghi của chính mình
create policy verif_insert_self on user_verifications for insert
  with check (user_id = auth.uid());

-- User chỉ được update bản ghi của mình (giới hạn cột nếu cần bằng DB trigger/Edge Function)
create policy verif_update_self on user_verifications for update
  using (user_id = auth.uid());

-- Admin thao tác qua Edge Functions dùng Service Role nên không cần policy đặc biệt ở đây.
