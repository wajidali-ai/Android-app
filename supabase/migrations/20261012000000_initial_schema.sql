-- ==============================================================================
-- Mashallah Crockery Billing System — Supabase PostgreSQL Schema
-- ==============================================================================
-- Description: Multi-shopkeeper, offline-first billing & sales record database.
-- NOTE: This database does NOT track inventory, stock quantities, or stock-in/out.
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. ENUMS
CREATE TYPE payment_status_type AS ENUM ('paid', 'partial', 'unpaid');
CREATE TYPE payment_method_type AS ENUM ('cash', 'online', 'credit');
CREATE TYPE bill_status_type AS ENUM ('active', 'cancelled');
CREATE TYPE sync_status_type AS ENUM ('pending', 'synced', 'failed');
CREATE TYPE print_status_type AS ENUM ('pending', 'success', 'failed');
CREATE TYPE member_role_type AS ENUM ('owner', 'manager', 'shopkeeper');

-- 3. SHOPS TABLE
CREATE TABLE IF NOT EXISTS shops (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL DEFAULT 'Mashallah Crockery',
    tagline VARCHAR(255) DEFAULT 'Quality Crockery & Kitchenware',
    address TEXT,
    phone VARCHAR(50),
    receipt_header TEXT DEFAULT '*** MASHALLAH CROCKERY ***\nMain Bazaar, Shop #12\nPhone: 0300-1234567',
    receipt_footer TEXT DEFAULT 'Thank you for your visit!\nExchange within 3 days with bill.',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 4. SHOP MEMBERS (Shopkeepers and Owners)
CREATE TABLE IF NOT EXISTS shop_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    auth_user_id UUID, -- Links to supabase auth.users if cloud login used
    name VARCHAR(150) NOT NULL,
    phone VARCHAR(50),
    role member_role_type NOT NULL DEFAULT 'shopkeeper',
    pin_code VARCHAR(10), -- Optional local PIN for quick phone sign-in
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 5. REGISTERED DEVICES (Multi-phone tracking)
CREATE TABLE IF NOT EXISTS devices (
    id VARCHAR(100) PRIMARY KEY, -- Android Device ID / Secure ID
    shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    assigned_member_id UUID REFERENCES shop_members(id) ON DELETE SET NULL,
    device_name VARCHAR(100) NOT NULL,
    app_version VARCHAR(20),
    last_sync_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 6. CUSTOMERS TABLE
CREATE TABLE IF NOT EXISTS customers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    name VARCHAR(200) NOT NULL,
    phone VARCHAR(50),
    total_balance NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_shop_customer_phone UNIQUE (shop_id, phone)
);

-- 7. BILLS TABLE (Primary sales transactions)
CREATE TABLE IF NOT EXISTS bills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    bill_number VARCHAR(100) NOT NULL, -- Human-readable identifier e.g. MC-D1-20261012-001
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    customer_name VARCHAR(200) NOT NULL,
    customer_phone VARCHAR(50),
    created_by_member_id UUID REFERENCES shop_members(id) ON DELETE SET NULL,
    created_by_name VARCHAR(150) NOT NULL,
    device_id VARCHAR(100),
    bill_date TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    subtotal NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    discount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    grand_total NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    paid_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    balance_amount NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    payment_status payment_status_type NOT NULL DEFAULT 'paid',
    payment_method payment_method_type NOT NULL DEFAULT 'cash',
    status bill_status_type NOT NULL DEFAULT 'active',
    cancellation_reason TEXT,
    cancelled_at TIMESTAMPTZ,
    cancelled_by_member_id UUID REFERENCES shop_members(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_shop_bill_number UNIQUE (shop_id, bill_number)
);

-- 8. BILL ITEMS TABLE (Line items on bill - strictly NO inventory links)
CREATE TABLE IF NOT EXISTS bill_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_id UUID NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
    item_name VARCHAR(255) NOT NULL,
    quantity NUMERIC(10, 2) NOT NULL DEFAULT 1.00,
    unit_price NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    line_total NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 9. PAYMENTS TABLE (Audit trail of bill payments & subsequent balance clearances)
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    bill_id UUID REFERENCES bills(id) ON DELETE SET NULL,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    amount NUMERIC(12, 2) NOT NULL,
    payment_method payment_method_type NOT NULL DEFAULT 'cash',
    payment_date TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    notes TEXT,
    received_by_member_id UUID REFERENCES shop_members(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- 10. PRINT JOBS TABLE (Audit Bluetooth printer attempts)
CREATE TABLE IF NOT EXISTS print_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bill_id UUID NOT NULL REFERENCES bills(id) ON DELETE CASCADE,
    printer_name VARCHAR(150),
    printer_mac VARCHAR(50),
    status print_status_type NOT NULL DEFAULT 'pending',
    error_message TEXT,
    attempted_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    device_id VARCHAR(100)
);

-- 11. FREQUENT ITEMS TABLE (Optional autocomplete list - NO stock tracking)
CREATE TABLE IF NOT EXISTS frequent_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    shop_id UUID NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
    item_name VARCHAR(255) NOT NULL,
    default_unit_price NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    usage_count INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    CONSTRAINT uq_shop_frequent_item UNIQUE (shop_id, item_name)
);

-- ==============================================================================
-- INDEXES FOR FAST SEARCH, FILTERING & REPORTING
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_bills_shop_date ON bills(shop_id, bill_date DESC);
CREATE INDEX IF NOT EXISTS idx_bills_customer ON bills(customer_id);
CREATE INDEX IF NOT EXISTS idx_bills_payment_status ON bills(shop_id, payment_status);
CREATE INDEX IF NOT EXISTS idx_bills_bill_number ON bills(bill_number);
CREATE INDEX IF NOT EXISTS idx_bill_items_bill_id ON bill_items(bill_id);
CREATE INDEX IF NOT EXISTS idx_customers_shop_name ON customers(shop_id, name);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);
CREATE INDEX IF NOT EXISTS idx_payments_bill_id ON payments(bill_id);
CREATE INDEX IF NOT EXISTS idx_payments_customer_id ON payments(customer_id);

-- ==============================================================================
-- TRIGGER FUNCTIONS
-- ==============================================================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION set_updated_at_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_shops_updated_at BEFORE UPDATE ON shops
    FOR EACH ROW EXECUTE FUNCTION set_updated_at_timestamp();

CREATE TRIGGER trg_shop_members_updated_at BEFORE UPDATE ON shop_members
    FOR EACH ROW EXECUTE FUNCTION set_updated_at_timestamp();

CREATE TRIGGER trg_customers_updated_at BEFORE UPDATE ON customers
    FOR EACH ROW EXECUTE FUNCTION set_updated_at_timestamp();

CREATE TRIGGER trg_bills_updated_at BEFORE UPDATE ON bills
    FOR EACH ROW EXECUTE FUNCTION set_updated_at_timestamp();

-- Trigger to recalculate customer balance when bills are inserted/updated
CREATE OR REPLACE FUNCTION recalculate_customer_balance()
RETURNS TRIGGER AS $$
DECLARE
    target_customer_id UUID;
BEGIN
    target_customer_id := COALESCE(NEW.customer_id, OLD.customer_id);
    IF target_customer_id IS NOT NULL THEN
        UPDATE customers
        SET total_balance = COALESCE((
            SELECT SUM(balance_amount)
            FROM bills
            WHERE customer_id = target_customer_id
              AND status = 'active'
        ), 0.00),
        updated_at = timezone('utc'::text, now())
        WHERE id = target_customer_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_bills_customer_balance AFTER INSERT OR UPDATE OF balance_amount, status, customer_id ON bills
    FOR EACH ROW EXECUTE FUNCTION recalculate_customer_balance();

-- ==============================================================================
-- ATOMIC BILL SYNC RPC FUNCTION
-- Enables phone clients to sync a bill and its items atomically in one transaction
-- ==============================================================================
CREATE OR REPLACE FUNCTION sync_bill_with_items(
    p_bill JSONB,
    p_items JSONB
)
RETURNS JSONB AS $$
DECLARE
    v_bill_id UUID;
    v_item JSONB;
BEGIN
    -- Extract bill id
    v_bill_id := (p_bill->>'id')::UUID;

    -- Upsert bill
    INSERT INTO bills (
        id,
        shop_id,
        bill_number,
        customer_id,
        customer_name,
        customer_phone,
        created_by_member_id,
        created_by_name,
        device_id,
        bill_date,
        subtotal,
        discount,
        grand_total,
        paid_amount,
        balance_amount,
        payment_status,
        payment_method,
        status,
        cancellation_reason,
        created_at,
        updated_at
    ) VALUES (
        v_bill_id,
        (p_bill->>'shop_id')::UUID,
        p_bill->>'bill_number',
        NULLIF(p_bill->>'customer_id', '')::UUID,
        p_bill->>'customer_name',
        p_bill->>'customer_phone',
        NULLIF(p_bill->>'created_by_member_id', '')::UUID,
        p_bill->>'created_by_name',
        p_bill->>'device_id',
        (p_bill->>'bill_date')::TIMESTAMPTZ,
        (p_bill->>'subtotal')::NUMERIC,
        (p_bill->>'discount')::NUMERIC,
        (p_bill->>'grand_total')::NUMERIC,
        (p_bill->>'paid_amount')::NUMERIC,
        (p_bill->>'balance_amount')::NUMERIC,
        (p_bill->>'payment_status')::payment_status_type,
        (p_bill->>'payment_method')::payment_method_type,
        COALESCE(p_bill->>'status', 'active')::bill_status_type,
        p_bill->>'cancellation_reason',
        COALESCE((p_bill->>'created_at')::TIMESTAMPTZ, now()),
        COALESCE((p_bill->>'updated_at')::TIMESTAMPTZ, now())
    )
    ON CONFLICT (id) DO UPDATE SET
        customer_name = EXCLUDED.customer_name,
        customer_phone = EXCLUDED.customer_phone,
        paid_amount = EXCLUDED.paid_amount,
        balance_amount = EXCLUDED.balance_amount,
        payment_status = EXCLUDED.payment_status,
        status = EXCLUDED.status,
        cancellation_reason = EXCLUDED.cancellation_reason,
        updated_at = EXCLUDED.updated_at;

    -- Delete existing items to avoid duplicates if re-syncing
    DELETE FROM bill_items WHERE bill_id = v_bill_id;

    -- Insert items
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        INSERT INTO bill_items (
            id,
            bill_id,
            item_name,
            quantity,
            unit_price,
            line_total,
            sort_order,
            created_at
        ) VALUES (
            COALESCE(NULLIF(v_item->>'id', '')::UUID, gen_random_uuid()),
            v_bill_id,
            v_item->>'item_name',
            (v_item->>'quantity')::NUMERIC,
            (v_item->>'unit_price')::NUMERIC,
            (v_item->>'line_total')::NUMERIC,
            COALESCE((v_item->>'sort_order')::INT, 0),
            COALESCE((v_item->>'created_at')::TIMESTAMPTZ, now())
        );
    END LOOP;

    RETURN jsonb_build_object('success', true, 'bill_id', v_bill_id);
END;
$$ LANGUAGE plpgsql;

-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
ALTER TABLE shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE shop_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE bills ENABLE ROW LEVEL SECURITY;
ALTER TABLE bill_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE print_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE frequent_items ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read and insert data for their shop
CREATE POLICY "Allow members access to their shop bills" ON bills
    FOR ALL USING (true); -- Custom auth checks can bind to auth.uid() = auth_user_id

CREATE POLICY "Allow members access to bill items" ON bill_items
    FOR ALL USING (true);

CREATE POLICY "Allow members access to customers" ON customers
    FOR ALL USING (true);

CREATE POLICY "Allow members access to payments" ON payments
    FOR ALL USING (true);

CREATE POLICY "Allow members access to shops" ON shops
    FOR ALL USING (true);

CREATE POLICY "Allow members access to shop members" ON shop_members
    FOR ALL USING (true);

CREATE POLICY "Allow members access to devices" ON devices
    FOR ALL USING (true);

CREATE POLICY "Allow members access to print jobs" ON print_jobs
    FOR ALL USING (true);

CREATE POLICY "Allow members access to frequent items" ON frequent_items
    FOR ALL USING (true);

-- ==============================================================================
-- SEED INITIAL SHOP DATA FOR MASHALLAH CROCKERY
-- ==============================================================================
INSERT INTO shops (
    id,
    name,
    tagline,
    address,
    phone,
    receipt_header,
    receipt_footer
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Mashallah Crockery',
    'Finest Crockery, Dinner Sets & Glassware',
    'Shop #14, Main Market, Crockery Bazaar, Lahore',
    '0300-8451234 / 0321-9876543',
    '*** MASHALLAH CROCKERY ***\nShop #14, Main Crockery Bazaar\nTel: 0300-8451234',
    'Thank you for shopping with us!\nFor inquiries: 0300-8451234\nGoods sold can be exchanged within 3 days.'
) ON CONFLICT (id) DO NOTHING;

-- Seed default shopkeeper
INSERT INTO shop_members (
    id,
    shop_id,
    name,
    phone,
    role,
    pin_code
) VALUES (
    '00000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000001',
    'Main Counter (Shopkeeper)',
    '0300-8451234',
    'owner',
    '1234'
) ON CONFLICT (id) DO NOTHING;
