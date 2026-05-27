-- ════════════════════════════════════════════════════════════════
-- Phase 5 — Billing System (ใบวางบิลของน้าปุ้ม)
-- Run this in Supabase SQL Editor (Project: djdzhepbejsghetbsrmw)
-- ════════════════════════════════════════════════════════════════
--
-- 4 tables:
--   1) gyt_billing_master    — ลูกค้าวางบิล master (47 ราย จะ import เข้าทีหลัง)
--   2) gyt_billings          — ใบวางบิลที่ออกแล้ว (TOKO-69/001, ...)
--   3) gyt_billing_counters  — running number ต่อ customer × year
--   4) gyt_billing_audit     — audit log การแก้ไข
--
-- Pattern เดียวกับ gyt_rate_card, gyt_lowbed_rates, gyt_quotes
-- (RLS เปิดอ่าน/เขียนทุกคน — permission check ที่ JS layer)


-- ════════════════════════════════════════════════════════════════
-- 1) gyt_billing_master — ข้อมูลลูกค้าสำหรับออกใบวางบิล
-- ════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.gyt_billing_master (
  id                  BIGSERIAL PRIMARY KEY,
  customer_code       TEXT NOT NULL,                  -- TOKO, UNI, APT, ... (สั้น 3-6 ตัวอักษร ใช้ใน bill_no)
  customer_name       TEXT NOT NULL,                  -- ชื่อเต็มบริษัท
  address             TEXT,                           -- ที่อยู่
  tax_id              TEXT,                           -- เลขประจำตัวผู้เสียภาษี
  branch              TEXT,                           -- สาขา (00000=สำนักงานใหญ่)
  -- เงื่อนไขภาษี/การจ่าย
  wht_pct             NUMERIC(4,2) DEFAULT 1.00,      -- หัก ณ ที่จ่าย % (0/1/3/5)
  vat_pct             NUMERIC(4,2) DEFAULT 0.00,      -- VAT % (0 หรือ 7)
  payment_terms_days  INTEGER DEFAULT 30,             -- เครดิต กี่วัน (0 = เงินสด)
  billing_format      TEXT DEFAULT 'detail',          -- 'summary' = 1 job/1 row | 'detail' = แตกค่า
  -- สถานะ
  is_active           BOOLEAN DEFAULT TRUE,
  notes               TEXT,                           -- หมายเหตุ เช่น "ลูกค้าเงินสด" / "ออกบิลเดือนสุดท้ายเท่านั้น"
  -- meta
  source_file         TEXT,                           -- ไฟล์ Excel ต้นทาง (reference)
  source_sheet        TEXT,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  created_by          TEXT,
  updated_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_by          TEXT
);

-- Unique customer_code (case-insensitive on active rows)
CREATE UNIQUE INDEX IF NOT EXISTS idx_billing_master_code
  ON public.gyt_billing_master(UPPER(customer_code))
  WHERE is_active = TRUE;

CREATE INDEX IF NOT EXISTS idx_billing_master_name   ON public.gyt_billing_master(customer_name);
CREATE INDEX IF NOT EXISTS idx_billing_master_taxid  ON public.gyt_billing_master(tax_id);
CREATE INDEX IF NOT EXISTS idx_billing_master_active ON public.gyt_billing_master(is_active);

ALTER TABLE public.gyt_billing_master ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS billing_master_read  ON public.gyt_billing_master;
CREATE POLICY billing_master_read  ON public.gyt_billing_master FOR SELECT USING (TRUE);
DROP POLICY IF EXISTS billing_master_write ON public.gyt_billing_master;
CREATE POLICY billing_master_write ON public.gyt_billing_master FOR ALL USING (TRUE) WITH CHECK (TRUE);

CREATE OR REPLACE FUNCTION public._gyt_billing_master_touch() RETURNS TRIGGER AS $$
BEGIN NEW.updated_at := NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS trg_billing_master_touch ON public.gyt_billing_master;
CREATE TRIGGER trg_billing_master_touch BEFORE UPDATE ON public.gyt_billing_master
  FOR EACH ROW EXECUTE FUNCTION public._gyt_billing_master_touch();


-- ════════════════════════════════════════════════════════════════
-- 2) gyt_billings — ใบวางบิลที่ออกแล้ว
-- ════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.gyt_billings (
  id                  BIGSERIAL PRIMARY KEY,
  bill_no             TEXT UNIQUE NOT NULL,            -- TOKO-69/001
  bill_date           DATE NOT NULL,                   -- วันที่ออกใบ
  -- ลูกค้า (snapshot + ref)
  customer_code       TEXT NOT NULL,                   -- ref gyt_billing_master.customer_code
  customer_snapshot   JSONB NOT NULL,                  -- {name, address, tax_id, wht_pct, vat_pct, payment_terms_days}
                                                       -- snapshot ตอนออก เผื่อ master เปลี่ยนทีหลัง
  -- รายการ
  job_ids             TEXT[] DEFAULT '{}',             -- ['JOB-2412','JOB-2413', ...] ที่รวมในใบนี้
  line_items          JSONB NOT NULL DEFAULT '[]',     -- [{date, desc, container_size, amt_freight, amt_other, amt_total, job_id?, note?}, ...]
  -- ยอด
  subtotal            NUMERIC(12,2) DEFAULT 0,         -- ผลรวม line_items.amt_total
  wht_pct_snapshot    NUMERIC(4,2) DEFAULT 0,
  wht_amt             NUMERIC(12,2) DEFAULT 0,
  vat_pct_snapshot    NUMERIC(4,2) DEFAULT 0,
  vat_amt             NUMERIC(12,2) DEFAULT 0,
  net_amt             NUMERIC(12,2) DEFAULT 0,         -- ยอดสุทธิ = subtotal - wht_amt + vat_amt
  -- สถานะ
  status              TEXT NOT NULL DEFAULT 'draft',   -- draft / issued / paid
  status_changed_at   TIMESTAMPTZ,
  status_changed_by   TEXT,
  -- การจ่าย (กรอกตอน mark 'paid')
  paid_date           DATE,
  paid_amount         NUMERIC(12,2),
  paid_note           TEXT,                            -- "เช็ค ธ.กรุงเทพ 2180238665" / "เงินสด"
  -- misc
  notes               TEXT,
  created_at          TIMESTAMPTZ DEFAULT NOW(),
  created_by          TEXT,
  updated_at          TIMESTAMPTZ DEFAULT NOW(),
  updated_by          TEXT
);

CREATE INDEX IF NOT EXISTS idx_billings_customer  ON public.gyt_billings(customer_code);
CREATE INDEX IF NOT EXISTS idx_billings_status    ON public.gyt_billings(status);
CREATE INDEX IF NOT EXISTS idx_billings_date      ON public.gyt_billings(bill_date DESC);
CREATE INDEX IF NOT EXISTS idx_billings_no        ON public.gyt_billings(bill_no);
CREATE INDEX IF NOT EXISTS idx_billings_created   ON public.gyt_billings(created_at DESC);
-- GIN index for job_ids array search (เช็คว่า JOB-XXX อยู่ในใบไหนแล้ว)
CREATE INDEX IF NOT EXISTS idx_billings_job_ids   ON public.gyt_billings USING GIN(job_ids);

ALTER TABLE public.gyt_billings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS billings_read  ON public.gyt_billings;
CREATE POLICY billings_read  ON public.gyt_billings FOR SELECT USING (TRUE);
DROP POLICY IF EXISTS billings_write ON public.gyt_billings;
CREATE POLICY billings_write ON public.gyt_billings FOR ALL USING (TRUE) WITH CHECK (TRUE);

CREATE OR REPLACE FUNCTION public._gyt_billings_touch() RETURNS TRIGGER AS $$
BEGIN NEW.updated_at := NOW(); RETURN NEW; END;
$$ LANGUAGE plpgsql;
DROP TRIGGER IF EXISTS trg_billings_touch ON public.gyt_billings;
CREATE TRIGGER trg_billings_touch BEFORE UPDATE ON public.gyt_billings
  FOR EACH ROW EXECUTE FUNCTION public._gyt_billings_touch();


-- ════════════════════════════════════════════════════════════════
-- 3) gyt_billing_counters — running number ต่อ customer × year
-- ════════════════════════════════════════════════════════════════
-- ใช้ตอนสร้างใบใหม่: SELECT + UPDATE atomic เพื่อกัน race condition
-- ตัวอย่าง: TOKO-69/001 → upsert (customer_code='TOKO', year=69) → last_number+1
CREATE TABLE IF NOT EXISTS public.gyt_billing_counters (
  customer_code   TEXT NOT NULL,
  year            INTEGER NOT NULL,                    -- พ.ศ. 2 ตัวท้าย เช่น 69
  last_number     INTEGER NOT NULL DEFAULT 0,
  updated_at      TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (customer_code, year)
);

ALTER TABLE public.gyt_billing_counters ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS billing_counters_read  ON public.gyt_billing_counters;
CREATE POLICY billing_counters_read  ON public.gyt_billing_counters FOR SELECT USING (TRUE);
DROP POLICY IF EXISTS billing_counters_write ON public.gyt_billing_counters;
CREATE POLICY billing_counters_write ON public.gyt_billing_counters FOR ALL USING (TRUE) WITH CHECK (TRUE);

-- RPC: ดึงเลขถัดไป (atomic — ใช้ใน app ตอนกด "ออกใบ")
-- เรียก: SELECT * FROM next_bill_no('TOKO', 69);
-- คืน:   bill_no = 'TOKO-69/001', number = 1
CREATE OR REPLACE FUNCTION public.next_bill_no(p_customer TEXT, p_year INTEGER)
RETURNS TABLE(bill_no TEXT, number INTEGER) AS $$
DECLARE
  v_next INTEGER;
BEGIN
  INSERT INTO public.gyt_billing_counters(customer_code, year, last_number)
    VALUES (p_customer, p_year, 1)
    ON CONFLICT (customer_code, year)
    DO UPDATE SET last_number = gyt_billing_counters.last_number + 1,
                  updated_at  = NOW()
    RETURNING last_number INTO v_next;
  RETURN QUERY SELECT (p_customer || '-' || p_year || '/' || LPAD(v_next::TEXT, 3, '0')), v_next;
END;
$$ LANGUAGE plpgsql;


-- ════════════════════════════════════════════════════════════════
-- 4) gyt_billing_audit — audit log การแก้ไขใบวางบิล
-- ════════════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS public.gyt_billing_audit (
  id            BIGSERIAL PRIMARY KEY,
  billing_id    BIGINT,                                -- ref gyt_billings.id (no FK)
  bill_no       TEXT,                                  -- snapshot
  action        TEXT NOT NULL,                         -- 'create' / 'update' / 'status_change' / 'delete'
  old_data      JSONB,                                 -- snapshot ก่อนแก้
  new_data      JSONB,                                 -- snapshot หลังแก้
  changed_by    TEXT,
  changed_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_billing_audit_billing  ON public.gyt_billing_audit(billing_id);
CREATE INDEX IF NOT EXISTS idx_billing_audit_at       ON public.gyt_billing_audit(changed_at DESC);
CREATE INDEX IF NOT EXISTS idx_billing_audit_by       ON public.gyt_billing_audit(changed_by);

ALTER TABLE public.gyt_billing_audit ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS billing_audit_read  ON public.gyt_billing_audit;
CREATE POLICY billing_audit_read  ON public.gyt_billing_audit FOR SELECT USING (TRUE);
DROP POLICY IF EXISTS billing_audit_write ON public.gyt_billing_audit;
CREATE POLICY billing_audit_write ON public.gyt_billing_audit FOR ALL USING (TRUE) WITH CHECK (TRUE);


-- ════════════════════════════════════════════════════════════════
-- DONE — Reload PostgREST schema cache + verify
-- ════════════════════════════════════════════════════════════════
NOTIFY pgrst, 'reload schema';

SELECT 'gyt_billing_master created'    AS status, (SELECT COUNT(*) FROM public.gyt_billing_master)    AS rows_count
UNION ALL
SELECT 'gyt_billings created',                    (SELECT COUNT(*) FROM public.gyt_billings)
UNION ALL
SELECT 'gyt_billing_counters created',            (SELECT COUNT(*) FROM public.gyt_billing_counters)
UNION ALL
SELECT 'gyt_billing_audit created',               (SELECT COUNT(*) FROM public.gyt_billing_audit);

-- Test the next_bill_no() function (ลองเรียกดูว่า function ทำงานได้)
SELECT * FROM public.next_bill_no('TEST', 69);
-- ลบ test counter ออกหลัง verify
DELETE FROM public.gyt_billing_counters WHERE customer_code = 'TEST';
