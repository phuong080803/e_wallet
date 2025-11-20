-- E-Wallet Database Schema Migration Script
-- This script deploys all necessary database objects for the transfer functionality
-- Copy and paste the contents of perform_transfer.sql and rls_policies.sql below

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- PASTE CONTENTS OF perform_transfer.sql HERE:
-- ============================================================================
-- SQL: RPC perform_transfer - thực thi chuyển tiền nguyên tử
-- Lưu ý: Cần bật extension pgcrypto hoặc uuid-ossp để tạo uuid nếu dùng gen_random_uuid()

create or replace function perform_transfer(
  p_sender_wallet_id text,
  p_recipient_wallet_id text,
  p_amount numeric,
  p_notes text
) returns json as $$
declare
  v_sender wallets%rowtype;
  v_recipient wallets%rowtype;
  v_tx_group uuid := gen_random_uuid();
  v_ref text := 'TXN' || extract(epoch from now())::bigint;
begin
  if p_amount is null or p_amount <= 0 then
    raise exception 'invalid_amount';
  end if;

  if p_sender_wallet_id = p_recipient_wallet_id then
    raise exception 'self_transfer_same_wallet';
  end if;

  -- Lock rows to avoid race
  select * into v_sender from wallets where id = p_sender_wallet_id for update;
  if not found then
    raise exception 'sender_wallet_not_found';
  end if;

  select * into v_recipient from wallets where id = p_recipient_wallet_id for update;
  if not found then
    raise exception 'recipient_wallet_not_found';
  end if;

  -- Owner check
  if v_sender.user_id <> auth.uid() then
    raise exception 'forbidden';
  end if;

  if v_sender.user_id = v_recipient.user_id then
    raise exception 'self_transfer_same_user';
  end if;

  if v_sender.so_du < p_amount then
    raise exception 'insufficient_balance';
  end if;

  -- Update balances
  update wallets set so_du = so_du - p_amount, ngay_cap_nhat = now() where id = v_sender.id;
  update wallets set so_du = so_du + p_amount, ngay_cap_nhat = now() where id = v_recipient.id;

  -- Insert transactions
  insert into transactions (
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

  return json_build_object(
    'reference', v_ref,
    'transaction_group_id', v_tx_group
  );
end;
$$ language plpgsql security definer;

-- ============================================================================
-- PASTE CONTENTS OF rls_policies.sql HERE:
-- ============================================================================
-- RLS policies (mẫu) cho các bảng trọng yếu
-- Lưu ý: chỉnh tên schema/bảng/cột theo DB thực tế trước khi áp dụng.

-- Drop existing policies if they exist (to avoid "already exists" errors)
DROP POLICY IF EXISTS wallets_select_self ON wallets;
DROP POLICY IF EXISTS transactions_select_self ON transactions;
DROP POLICY IF EXISTS verif_select_self ON user_verifications;
DROP POLICY IF EXISTS verif_insert_self ON user_verifications;
DROP POLICY IF EXISTS verif_update_self ON user_verifications;

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

-- ============================================================================
-- VERIFICATION AND TESTING
-- ============================================================================

-- Verify deployment
DO $$
BEGIN
    RAISE NOTICE '✅ Database schema deployment completed successfully';
    RAISE NOTICE '📋 Verification queries you can run manually:';
    RAISE NOTICE '   SELECT routine_name FROM information_schema.routines WHERE routine_name = ''perform_transfer'';';
    RAISE NOTICE '   SELECT schemaname, tablename, rowsecurity FROM pg_tables WHERE tablename IN (''wallets'', ''transactions'');';
END $$;

-- Final instructions:
-- 1. Verify the deployment by running the verification queries above.
-- 2. Test the RPC function by uncommenting the test block below.
-- 3. Make sure to update the wallet IDs and amount in the test block to valid values.

-- Test RPC function (will fail if not deployed correctly)
-- Uncomment the following block to test the RPC function:
/*
DO $$
DECLARE
    test_result JSON;
BEGIN
    -- This should fail with 'sender_wallet_not_found' since we're using fake wallet IDs
    BEGIN
        test_result := perform_transfer('1234567890', '0987654321', 1000.0, 'Test transfer');
        RAISE NOTICE '⚠️  RPC test succeeded unexpectedly: %', test_result;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLERRM LIKE '%sender_wallet_not_found%' THEN
                RAISE NOTICE '✅ RPC function is deployed and working correctly (expected error for fake wallet)';
            ELSE
                RAISE EXCEPTION '❌ RPC function error: %', SQLERRM;
            END IF;
    END;
END $$;
*/
