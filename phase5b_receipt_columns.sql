-- ════════════════════════════════════════════════════════════════
-- Phase 5b — เพิ่ม columns ใบเสร็จรับเงิน (Receipt) + Running number RPC
-- Run this in Supabase SQL Editor (Project: djdzhepbejsghetbsrmw)
-- ════════════════════════════════════════════════════════════════

-- 1) ALTER gyt_billings — เพิ่ม 4 columns สำหรับใบเสร็จรับเงิน
ALTER TABLE public.gyt_billings
  ADD COLUMN IF NOT EXISTS receipt_no         TEXT,           -- RC-69-001
  ADD COLUMN IF NOT EXISTS receipt_date       DATE,           -- วันที่ออกใบเสร็จ
  ADD COLUMN IF NOT EXISTS receipt_printed_by TEXT,           -- ผู้ออกใบเสร็จ
  ADD COLUMN IF NOT EXISTS receipt_printed_at TIMESTAMPTZ;    -- เวลาที่ออก

-- Unique index บน receipt_no (อนุญาตให้ NULL ได้)
CREATE UNIQUE INDEX IF NOT EXISTS idx_billings_receipt_no
  ON public.gyt_billings(receipt_no)
  WHERE receipt_no IS NOT NULL;

-- 2) Counter table สำหรับ running number ของใบเสร็จ (ต่อ ปี)
CREATE TABLE IF NOT EXISTS public.gyt_receipt_counters (
  year         INTEGER PRIMARY KEY,        -- พ.ศ. 2 ตัวท้าย เช่น 69
  last_number  INTEGER NOT NULL DEFAULT 0,
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.gyt_receipt_counters ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS receipt_counters_read  ON public.gyt_receipt_counters;
CREATE POLICY receipt_counters_read  ON public.gyt_receipt_counters FOR SELECT USING (TRUE);
DROP POLICY IF EXISTS receipt_counters_write ON public.gyt_receipt_counters;
CREATE POLICY receipt_counters_write ON public.gyt_receipt_counters FOR ALL USING (TRUE) WITH CHECK (TRUE);

-- 3) RPC: next_receipt_no(year) — atomic gen "RC-69-001"
-- เรียก: SELECT * FROM next_receipt_no(69);
-- คืน:   receipt_no = 'RC-69-001', number = 1
CREATE OR REPLACE FUNCTION public.next_receipt_no(p_year INTEGER)
RETURNS TABLE(receipt_no TEXT, number INTEGER) AS $$
DECLARE
  v_next INTEGER;
BEGIN
  INSERT INTO public.gyt_receipt_counters(year, last_number)
    VALUES (p_year, 1)
    ON CONFLICT (year)
    DO UPDATE SET last_number = gyt_receipt_counters.last_number + 1,
                  updated_at  = NOW()
    RETURNING last_number INTO v_next;
  RETURN QUERY SELECT ('RC-' || p_year || '-' || LPAD(v_next::TEXT, 3, '0')), v_next;
END;
$$ LANGUAGE plpgsql;

NOTIFY pgrst, 'reload schema';

SELECT 'gyt_billings columns added' AS status,
       (SELECT COUNT(*) FROM information_schema.columns WHERE table_name='gyt_billings' AND column_name LIKE 'receipt%') AS receipt_cols,
       (SELECT * FROM next_receipt_no(69)) AS test_no;

-- Cleanup test counter
DELETE FROM public.gyt_receipt_counters WHERE year = 69 AND last_number = 1;
