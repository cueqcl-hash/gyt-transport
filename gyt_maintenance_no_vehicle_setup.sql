-- ════════════════════════════════════════════════════════════════════════
-- 🆕 v154 — รองรับ "ไม่ระบุคัน" ในบันทึกซ่อม
-- ════════════════════════════════════════════════════════════════════════
-- รันใน Supabase Studio > SQL Editor (ครั้งเดียว ก่อน deploy v154)
-- ════════════════════════════════════════════════════════════════════════

alter table gyt_maintenance alter column vehicle_id drop not null;
alter table gyt_maintenance alter column vehicle_type drop not null;

-- รีเฟรช schema cache ของ PostgREST (สำคัญ!)
notify pgrst, 'reload schema';

-- ทดสอบ:
-- select column_name, is_nullable from information_schema.columns
--  where table_name = 'gyt_maintenance' and column_name in ('vehicle_id','vehicle_type');
-- → ต้องเห็น is_nullable = YES ทั้งคู่
