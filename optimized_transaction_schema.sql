-- Optimized Transaction Schema Migration Script
-- This script updates the existing transactions table to support balance tracking and user-centric records

-- Step 1: Backup existing transactions (optional but recommended)
CREATE TABLE transactions_backup AS SELECT * FROM transactions;

-- Step 2: Drop existing transactions table and recreate with optimized schema
DROP TABLE IF EXISTS transactions CASCADE;

-- Step 3: Create optimized transactions table
CREATE TABLE transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    transaction_group_id UUID NOT NULL, -- Links related transactions (sender/recipient pair)
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('transfer_in', 'transfer_out', 'deposit', 'withdraw', 'payment_in', 'payment_out')),
    amount DECIMAL(15,2) NOT NULL,
    fee_amount DECIMAL(15,2) DEFAULT 0.00,
    balance_before DECIMAL(15,2) NOT NULL,
    balance_after DECIMAL(15,2) NOT NULL,
    counterpart_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    counterpart_wallet_id VARCHAR(10),
    counterpart_name VARCHAR(255),
    description TEXT,
    notes TEXT,
    reference_number VARCHAR(50) UNIQUE,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 4: Create indexes for performance
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_group_id ON transactions(transaction_group_id);
CREATE INDEX idx_transactions_type ON transactions(transaction_type);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_created_at ON transactions(created_at);
CREATE INDEX idx_transactions_counterpart_user ON transactions(counterpart_user_id);
CREATE INDEX idx_transactions_reference ON transactions(reference_number);

-- Step 5: Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_transactions_updated_at 
    BEFORE UPDATE ON transactions 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Step 6: Create view for easy transaction history querying
CREATE OR REPLACE VIEW transaction_history AS
SELECT 
    t.id,
    t.user_id,
    t.transaction_group_id,
    t.transaction_type,
    t.amount,
    t.fee_amount,
    t.balance_before,
    t.balance_after,
    (t.balance_after - t.balance_before) as balance_change,
    t.counterpart_user_id,
    t.counterpart_wallet_id,
    t.counterpart_name,
    t.description,
    t.notes,
    t.reference_number,
    t.status,
    t.created_at,
    t.updated_at,
    CASE 
        WHEN t.transaction_type IN ('transfer_in', 'deposit', 'payment_in') THEN 'credit'
        WHEN t.transaction_type IN ('transfer_out', 'withdraw', 'payment_out') THEN 'debit'
        ELSE 'unknown'
    END as transaction_direction,
    CASE 
        WHEN t.transaction_type = 'transfer_in' THEN 'Nhận tiền'
        WHEN t.transaction_type = 'transfer_out' THEN 'Chuyển tiền'
        WHEN t.transaction_type = 'deposit' THEN 'Nạp tiền'
        WHEN t.transaction_type = 'withdraw' THEN 'Rút tiền'
        WHEN t.transaction_type = 'payment_in' THEN 'Thanh toán nhận'
        WHEN t.transaction_type = 'payment_out' THEN 'Thanh toán'
        ELSE 'Khác'
    END as transaction_label
FROM transactions t
WHERE t.status = 'completed'
ORDER BY t.created_at DESC;

-- Step 7: Grant necessary permissions (adjust as needed for your setup)
-- GRANT SELECT, INSERT, UPDATE ON transactions TO authenticated;
-- GRANT SELECT ON transaction_history TO authenticated;

-- Step 8: Migration script for existing data (if needed)
-- Note: This assumes you want to migrate data from transactions_backup
-- Uncomment and modify as needed based on your existing data structure

/*
INSERT INTO transactions (
    user_id,
    transaction_group_id,
    transaction_type,
    amount,
    balance_before,
    balance_after,
    counterpart_user_id,
    description,
    notes,
    reference_number,
    status,
    created_at,
    updated_at
)
SELECT 
    nguoi_gui_id as user_id,
    gen_random_uuid() as transaction_group_id,
    CASE 
        WHEN so_tien > 0 THEN 'transfer_in'
        ELSE 'transfer_out'
    END as transaction_type,
    ABS(so_tien) as amount,
    0 as balance_before, -- You'll need to calculate this based on your business logic
    0 as balance_after,  -- You'll need to calculate this based on your business logic
    CASE 
        WHEN so_tien > 0 THEN nguoi_gui_id
        ELSE nguoi_nhan_id
    END as counterpart_user_id,
    CASE 
        WHEN loai = 'chuyen_khoan' THEN 'Chuyển khoản'
        WHEN loai = 'yeu_cau' THEN 'Yêu cầu thanh toán'
        WHEN loai = 'thanh_toan' THEN 'Thanh toán'
        ELSE 'Giao dịch'
    END as description,
    ghi_chu as notes,
    CONCAT('TXN', EXTRACT(EPOCH FROM ngay_tao)::bigint) as reference_number,
    CASE 
        WHEN trang_thai = 'hoan_thanh' THEN 'completed'
        WHEN trang_thai = 'that_bai' THEN 'failed'
        WHEN trang_thai = 'huy' THEN 'cancelled'
        ELSE 'pending'
    END as status,
    ngay_tao as created_at,
    ngay_cap_nhat as updated_at
FROM transactions_backup;
*/

-- Verification queries to check the new schema
-- SELECT COUNT(*) FROM transactions;
-- SELECT * FROM transaction_history LIMIT 10;
-- SELECT transaction_type, COUNT(*) FROM transactions GROUP BY transaction_type;
