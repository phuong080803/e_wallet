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
