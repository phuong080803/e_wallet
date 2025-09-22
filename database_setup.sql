-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.admin_users (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  username character varying NOT NULL UNIQUE,
  password character varying NOT NULL,
  email character varying,
  full_name character varying,
  is_active boolean DEFAULT true,
  last_login timestamp with time zone,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT admin_users_pkey PRIMARY KEY (id)
);

CREATE TABLE public.contacts (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  ho_ten character varying NOT NULL,
  email character varying NOT NULL,
  so_dien_thoai character varying,
  hinh_anh character varying,
  ngay_tao timestamp with time zone DEFAULT now(),
  ngay_cap_nhat timestamp with time zone DEFAULT now(),
  CONSTRAINT contacts_pkey PRIMARY KEY (id),
  CONSTRAINT contacts_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

CREATE TABLE public.transactions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  wallet_id character varying NOT NULL,
  transaction_group_id uuid NOT NULL,
  transaction_type character varying NOT NULL CHECK (transaction_type::text = ANY (ARRAY['transfer_in'::character varying, 'transfer_out'::character varying, 'deposit'::character varying, 'withdraw'::character varying, 'payment_in'::character varying, 'payment_out'::character varying]::text[])),
  amount numeric NOT NULL,
  balance_before numeric NOT NULL,
  balance_after numeric NOT NULL,
  counterpart_user_id uuid,
  counterpart_wallet_id character varying,
  counterpart_name character varying,
  description text NOT NULL,
  notes text,
  status character varying NOT NULL DEFAULT 'completed'::character varying CHECK (status::text = ANY (ARRAY['pending'::character varying, 'completed'::character varying, 'failed'::character varying, 'cancelled'::character varying]::text[])),
  reference_number character varying,
  fee_amount numeric DEFAULT 0,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  completed_at timestamp with time zone,
  CONSTRAINT transactions_pkey PRIMARY KEY (id),
  CONSTRAINT transactions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT transactions_counterpart_user_id_fkey FOREIGN KEY (counterpart_user_id) REFERENCES auth.users(id)
);

CREATE TABLE public.user_verifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid UNIQUE,
  phone_number character varying,
  phone_verified boolean DEFAULT false,
  phone_verification_date timestamp with time zone,
  id_card_number character varying,
  id_card_verified boolean DEFAULT false,
  id_card_verification_date timestamp with time zone,
  address text,
  address_verified boolean DEFAULT false,
  address_verification_date timestamp with time zone,
  verification_status character varying DEFAULT 'pending'::character varying CHECK (verification_status::text = ANY (ARRAY['pending'::character varying, 'verified'::character varying, 'rejected'::character varying]::text[])),
  admin_notes text,
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  front_id_image_url text,
  back_id_image_url text,
  CONSTRAINT user_verifications_pkey PRIMARY KEY (id),
  CONSTRAINT user_verifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

CREATE TABLE public.wallets (
  id character varying NOT NULL,
  user_id uuid UNIQUE,
  so_du numeric DEFAULT 0.00,
  loai_tien_te character varying DEFAULT 'VND'::character varying,
  ngay_tao timestamp with time zone DEFAULT now(),
  ngay_cap_nhat timestamp with time zone DEFAULT now(),
  CONSTRAINT wallets_pkey PRIMARY KEY (id),
  CONSTRAINT wallets_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- Indexes để tối ưu hiệu suất
CREATE INDEX idx_wallets_user_id ON public.wallets(user_id);
CREATE INDEX idx_transactions_user_id ON public.transactions(user_id);
CREATE INDEX idx_transactions_wallet_id ON public.transactions(wallet_id);
CREATE INDEX idx_transactions_group_id ON public.transactions(transaction_group_id);
CREATE INDEX idx_transactions_type ON public.transactions(transaction_type);
CREATE INDEX idx_transactions_status ON public.transactions(status);
CREATE INDEX idx_transactions_created_at ON public.transactions(created_at DESC);
CREATE INDEX idx_transactions_user_created ON public.transactions(user_id, created_at DESC);
CREATE INDEX idx_contacts_user_id ON public.contacts(user_id);
CREATE INDEX idx_contacts_email ON public.contacts(email);
CREATE INDEX idx_transactions_user_history ON public.transactions(user_id, status, created_at DESC);
CREATE INDEX idx_user_verifications_user_id ON public.user_verifications(user_id);
CREATE INDEX idx_user_verifications_status ON public.user_verifications(verification_status);
CREATE INDEX idx_admin_users_username ON public.admin_users(username);

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
    BEFORE UPDATE ON public.transactions
    FOR EACH ROW
    EXECUTE FUNCTION update_transactions_updated_at();

-- View cho người dùng - Ẩn thông tin người gửi/nhận
CREATE OR REPLACE VIEW user_transaction_history AS
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
    -- Chỉ hiển thị tên đối tác, không hiển thị ID
    t.counterpart_name,
    t.description,
    t.notes,
    t.status,
    t.reference_number,
    t.fee_amount,
    t.created_at,
    t.updated_at,
    t.completed_at
FROM public.transactions t
WHERE t.status = 'completed'
ORDER BY t.created_at DESC;

-- View cho admin - Hiển thị đầy đủ thông tin (sử dụng raw_user_meta_data)
CREATE OR REPLACE VIEW admin_transaction_history AS
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
    -- Thông tin đầy đủ về đối tác cho admin
    t.counterpart_user_id,
    t.counterpart_wallet_id,
    t.counterpart_name,
    -- Thông tin user hiện tại từ auth.users
    u.email as user_email,
    u.raw_user_meta_data->>'ho_ten' as user_name,
    -- Thông tin đối tác từ auth.users
    cp.email as counterpart_email,
    cp.raw_user_meta_data->>'ho_ten' as counterpart_full_name,
    t.description,
    t.notes,
    t.status,
    t.reference_number,
    t.fee_amount,
    t.created_at,
    t.updated_at,
    t.completed_at
FROM public.transactions t
LEFT JOIN auth.users u ON t.user_id = u.id
LEFT JOIN auth.users cp ON t.counterpart_user_id = cp.id
ORDER BY t.created_at DESC;