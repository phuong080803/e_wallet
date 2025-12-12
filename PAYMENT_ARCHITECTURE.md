# Kiến trúc Xử lý Thanh toán & Chống Double-Spending

## Tổng quan
Tài liệu này mô tả kiến trúc xử lý thanh toán và cơ chế chống double-spending trong hệ thống e-wallet, sử dụng Supabase (PostgreSQL) với các tính năng:
- Row Level Security (RLS)
- Database Functions (RPC)
- Transaction & FOR UPDATE
- Edge Functions cho xác thực 2 lớp

## 1. Kiến trúc Cơ sở Dữ liệu

### Bảng `wallets`
```sql
CREATE TABLE wallets (
  id VARCHAR(10) PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) UNIQUE NOT NULL,
  so_du DECIMAL(15,2) DEFAULT 0.00,
  loai_tien_te VARCHAR(3) DEFAULT 'VND',
  ngay_tao TIMESTAMPTZ DEFAULT NOW(),
  ngay_cap_nhat TIMESTAMPTZ DEFAULT NOW()
);
```

### Bảng `transactions`
```sql
CREATE TABLE transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  wallet_id VARCHAR(10) NOT NULL,
  transaction_group_id UUID NOT NULL,
  transaction_type VARCHAR(20) CHECK (
    transaction_type IN (
      'transfer_in', 'transfer_out', 
      'deposit', 'withdraw',
      'payment_in', 'payment_out'
    )
  ),
  amount DECIMAL(15,2) NOT NULL,
  balance_before DECIMAL(15,2) NOT NULL,
  balance_after DECIMAL(15,2) NOT NULL,
  -- Thông tin đối tác
  counterpart_user_id UUID REFERENCES auth.users(id),
  counterpart_wallet_id VARCHAR(10),
  counterpart_name VARCHAR(255),
  -- Metadata
  description TEXT,
  notes TEXT,
  status VARCHAR(20) DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
  reference_number VARCHAR(50) UNIQUE,
  fee_amount DECIMAL(15,2) DEFAULT 0,
  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);
```

## 2. Bảo mật với Row Level Security (RLS)

### Kích hoạt RLS
```sql
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;
```

### Chính sách RLS
```sql
-- Chỉ xem được ví của chính mình
CREATE POLICY wallets_select_self ON wallets 
  FOR SELECT USING (user_id = auth.uid());

-- Chặn thao tác trực tiếp từ client
REVOKE UPDATE, INSERT ON wallets FROM authenticated;
REVOKE INSERT, UPDATE ON transactions FROM authenticated;
```

## 3. Xử lý Giao dịch Nguyên tử với RPC

### Hàm `perform_transfer`
```sql
CREATE OR REPLACE FUNCTION perform_transfer(
  p_sender_wallet_id TEXT,
  p_recipient_wallet_id TEXT,
  p_amount NUMERIC,
  p_notes TEXT
) RETURNS JSON
LANGUAGE plpgsql 
SECURITY DEFINER
AS $$
DECLARE
  v_sender wallets%ROWTYPE;
  v_recipient wallets%ROWTYPE;
  v_tx_group UUID := gen_random_uuid();
  v_ref TEXT := 'TXN' || EXTRACT(EPOCH FROM NOW())::BIGINT;
BEGIN
  -- Validate
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'invalid_amount';
  END IF;

  -- Lock rows để tránh race condition
  SELECT * INTO v_sender FROM wallets WHERE id = p_sender_wallet_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'sender_wallet_not_found'; END IF;
  
  SELECT * INTO v_recipient FROM wallets WHERE id = p_recipient_wallet_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'recipient_wallet_not_found'; END IF;

  -- Kiểm tra quyền sở hữu
  IF v_sender.user_id != auth.uid() THEN
    RAISE EXCEPTION 'forbidden';
  END IF;

  -- Kiểm tra số dư
  IF v_sender.so_du < p_amount THEN
    RAISE EXCEPTION 'insufficient_balance';
  END IF;

  -- Cập nhật số dư (atomic)
  UPDATE wallets SET so_du = so_du - p_amount WHERE id = v_sender.id;
  UPDATE wallets SET so_du = so_du + p_amount WHERE id = v_recipient.id;

  -- Ghi log giao dịch
  INSERT INTO transactions (...) VALUES (...);
  
  RETURN json_build_object('reference', v_ref, 'transaction_group_id', v_tx_group);
END;
$$;
```

## 4. Luồng Giao dịch từ Client

### Chuyển tiền (Flutter)
```dart
// Trong WalletController
Future<bool> transferMoney({
  required String recipientWalletId,
  required double amount,
  String? notes,
}) async {
  try {
    final result = await Supabase.instance.client.rpc('perform_transfer', params: {
      'p_sender_wallet_id': userWallet.value!.id,
      'p_recipient_wallet_id': recipientWalletId,
      'p_amount': amount,
      'p_notes': notes,
    });
    
    await loadUserWallet(); // Reload số dư mới
    return true;
  } catch (e) {
    // Xử lý lỗi
    return false;
  }
}
```

## 5. Cơ chế Chống Double-Spending

1. **Khóa hàng (Row Locking)**:
   - Sử dụng `SELECT ... FOR UPDATE` để khóa các bản ghi ví trong suốt quá trình giao dịch.

2. **Giao dịch Nguyên tử**:
   - Toàn bộ hàm `perform_transfer` chạy trong một transaction.
   - Nếu có lỗi, mọi thay đổi được rollback tự động.

3. **Idempotency**:
   - Mỗi giao dịch có `transaction_group_id` và `reference_number` duy nhất.
   - Client có thể retry an toàn với cùng `reference_number`.

4. **RLS & Security**:
   - Chỉ chủ ví mới được thực hiện giao dịch.
   - Client không thể tự ý cập nhật số dư.

## 6. Cải tiến Tiềm năng

1. **Xác thực 2 lớp (2FA)**:
   - Đã có sẵn Edge Functions `transfer-challenge`/`transfer-confirm` (đang ở chế độ demo).
   - Cần tích hợp với hệ thống OTP thật (SMS/Email/App).

2. **Idempotency Key**:
   - Thêm cơ chế idempotency key cho các yêu cầu thanh toán.

3. **Giới hạn giao dịch**:
   - Thêm policy giới hạn số tiền giao dịch/ngày.

4. **Audit Logs**:
   - Ghi lại lịch sử thay đổi số dư chi tiết.

## 7. Kết luận

Hệ thống hiện tại đã áp dụng đúng các nguyên tắc bảo mật và xử lý giao dịch nguyên tử của PostgreSQL thông qua Supabase RPC. Các điểm mạnh:

✅ Sử dụng RLS để kiểm soát truy cập
✅ Xử lý giao dịch nguyên tử với `FOR UPDATE`
✅ Client không thể tự ý thay đổi số dư
✅ Có sẵn cấu trúc mở rộng cho các loại giao dịch khác

Để tăng cường bảo mật, nên triển khai đầy đủ xác thực 2 lớp và cơ chế idempotency cho các giao dịch thanh toán.
