-- Cải thiện bảng transactions để tối ưu lịch sử giao dịch
-- Mỗi giao dịch sẽ tạo 2 bản ghi: 1 cho người gửi, 1 cho người nhận

DROP TABLE IF EXISTS transactions;

CREATE TABLE transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Thông tin người dùng (mỗi bản ghi thuộc về 1 user cụ thể)
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    wallet_id VARCHAR(10) NOT NULL, -- ID ví của user này
    
    -- Thông tin giao dịch
    transaction_group_id UUID NOT NULL, -- Nhóm giao dịch (cùng 1 lần chuyển tiền)
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN (
        'transfer_in',    -- Nhận tiền
        'transfer_out',   -- Chuyển tiền
        'deposit',        -- Nạp tiền
        'withdraw',       -- Rút tiền
        'payment_in',     -- Thanh toán nhận
        'payment_out'     -- Thanh toán gửi
    )),
    
    -- Số tiền và số dư
    amount DECIMAL(15,2) NOT NULL, -- Số tiền giao dịch (luôn dương)
    balance_before DECIMAL(15,2) NOT NULL, -- Số dư trước giao dịch
    balance_after DECIMAL(15,2) NOT NULL, -- Số dư sau giao dịch
    
    -- Thông tin đối tác giao dịch
    counterpart_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    counterpart_wallet_id VARCHAR(10),
    counterpart_name VARCHAR(255), -- Tên người gửi/nhận
    
    -- Mô tả và ghi chú
    description TEXT NOT NULL, -- Mô tả giao dịch
    notes TEXT, -- Ghi chú từ người dùng
    
    -- Trạng thái và thời gian
    status VARCHAR(20) NOT NULL DEFAULT 'completed' CHECK (status IN (
        'pending',    -- Đang chờ
        'completed',  -- Hoàn thành
        'failed',     -- Thất bại
        'cancelled'   -- Đã hủy
    )),
    
    -- Metadata bổ sung
    reference_number VARCHAR(50), -- Mã tham chiếu giao dịch
    fee_amount DECIMAL(15,2) DEFAULT 0, -- Phí giao dịch
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Indexes để tối ưu truy vấn
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_wallet_id ON transactions(wallet_id);
CREATE INDEX idx_transactions_group_id ON transactions(transaction_group_id);
CREATE INDEX idx_transactions_type ON transactions(transaction_type);
CREATE INDEX idx_transactions_status ON transactions(status);
CREATE INDEX idx_transactions_created_at ON transactions(created_at DESC);
CREATE INDEX idx_transactions_user_created ON transactions(user_id, created_at DESC);

-- Composite index cho truy vấn lịch sử theo user
CREATE INDEX idx_transactions_user_history ON transactions(user_id, status, created_at DESC);

-- Function để tự động cập nhật updated_at
CREATE OR REPLACE FUNCTION update_transactions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger để tự động cập nhật updated_at
CREATE TRIGGER trigger_transactions_updated_at
    BEFORE UPDATE ON transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_transactions_updated_at();

-- View để dễ dàng truy vấn lịch sử giao dịch
CREATE OR REPLACE VIEW transaction_history AS
SELECT 
    t.id,
    t.user_id,
    t.wallet_id,
    t.transaction_group_id,
    t.transaction_type,
    t.amount,
    t.balance_before,
    t.balance_after,
    -- Tính toán số tiền thay đổi (+ hoặc -)
    CASE 
        WHEN t.transaction_type IN ('transfer_in', 'deposit', 'payment_in') 
        THEN t.amount
        ELSE -t.amount
    END as balance_change,
    -- Xác định loại giao dịch dễ hiểu
    CASE 
        WHEN t.transaction_type = 'transfer_in' THEN 'Nhận tiền'
        WHEN t.transaction_type = 'transfer_out' THEN 'Chuyển tiền'
        WHEN t.transaction_type = 'deposit' THEN 'Nạp tiền'
        WHEN t.transaction_type = 'withdraw' THEN 'Rút tiền'
        WHEN t.transaction_type = 'payment_in' THEN 'Thanh toán nhận'
        WHEN t.transaction_type = 'payment_out' THEN 'Thanh toán gửi'
    END as transaction_label,
    t.counterpart_user_id,
    t.counterpart_wallet_id,
    t.counterpart_name,
    t.description,
    t.notes,
    t.status,
    t.reference_number,
    t.fee_amount,
    t.created_at,
    t.updated_at,
    t.completed_at
FROM transactions t
WHERE t.status = 'completed'
ORDER BY t.created_at DESC;
