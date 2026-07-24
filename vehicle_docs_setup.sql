-- =====================================================================
-- GYT — ทะเบียนเอกสารรถบริษัท (พ.ร.บ. / ภาษี / ประกันภัย / ตรวจสภาพ / ประกันสินค้า)
-- วิธีใช้: เปิด Supabase Studio → SQL Editor → วางทั้งไฟล์นี้ → Run  (รันครั้งเดียวพอ)
-- ปลอดภัยถ้าเผลอรันซ้ำ: create if not exists + insert แบบเช็คซ้ำ (idempotent)
-- สร้าง 2026-07-24
--
-- ทำไมต้องมีตารางนี้:
--   เดิมวันหมดอายุเก็บเป็น "ช่องข้อความช่องเดียว" ในตารางรถ (date_tax/date_ins/...)
--   → เก็บได้แค่ครั้งล่าสุด ไม่มีประวัติ ไม่รู้ค่าใช้จ่าย และไม่มีช่อง พ.ร.บ. เลย
--   ตารางนี้ = 1 แถวต่อการต่อ 1 ครั้ง (เหมือน gyt_personal_vehicle_docs ของรถส่วนตัว)
-- =====================================================================

-- 1) ตารางเอกสาร ------------------------------------------------------
create table if not exists gyt_vehicle_docs (
  id           bigserial primary key,
  vehicle_id   bigint not null,
  vehicle_type text   not null,             -- 'tractor' (หัวลาก/สิบล้อ) | 'trailer' (หาง)
  doc_type     text   not null,             -- 'พ.ร.บ.' | 'ภาษี' | 'ประกันภัย' | 'ตรวจสภาพ' | 'ประกันสินค้า'
  start_date   date,
  expiry_date  date   not null,
  amount       numeric,                     -- ค่าใช้จ่ายครั้งนั้น (บาท)
  provider     text,                        -- บริษัทประกัน / ตรอ. / สนง.ขนส่ง
  policy_no    text,                        -- เลขกรมธรรม์ / เลขที่ใบเสร็จ
  insurance_class text,                     -- ชั้น 1/2/3 (เฉพาะประกันภัย)
  file_ref     text,                        -- ชื่อไฟล์เอกสารอ้างอิง
  note         text,
  created_at   timestamptz default now(),
  created_by   text
);
alter table gyt_vehicle_docs disable row level security;

-- ดึง "ใบล่าสุดของรถคันนี้ + เอกสารชนิดนี้" ให้เร็ว (query หลักของหน้าแจ้งเตือน)
create index if not exists idx_gyt_vehicle_docs_lookup
  on gyt_vehicle_docs(vehicle_id, vehicle_type, doc_type, expiry_date desc);

-- 2) ตัวช่วยแปลงวันที่ไทย "30/09/2569" → date -------------------------
--    ข้อมูลเดิมในตารางรถเป็น text พ.ศ. รูปแบบ DD/MM/YYYY (บางแถวว่าง/พิมพ์ผิด)
--    ถ้าแปลงไม่ได้ให้คืน null แทนที่จะ error ทั้ง statement
create or replace function _gyt_thai_date(s text) returns date as $$
declare p text[]; y int;
begin
  if s is null or btrim(s) = '' then return null; end if;
  p := string_to_array(btrim(s), '/');
  if coalesce(array_length(p, 1), 0) <> 3 then return null; end if;
  y := p[3]::int;
  if y > 2400 then y := y - 543; end if;          -- พ.ศ. → ค.ศ.
  return make_date(y, p[2]::int, p[1]::int);
exception when others then
  return null;                                     -- วันที่เพี้ยน เช่น 31/02 → ข้ามไป
end $$ language plpgsql immutable;

-- 3) ย้ายข้อมูลเดิมจากตารางรถเข้ามาเป็น "ใบล่าสุด" ---------------------
--    ไม่ลบของเดิม — ตารางรถยังใช้ได้ตามปกติ แอปจะเขียนกลับให้ตรงกันตอนกดต่ออายุ
insert into gyt_vehicle_docs (vehicle_id, vehicle_type, doc_type, expiry_date, note, created_by)
select v.id, 'tractor', d.doc_type, _gyt_thai_date(d.val),
       'ย้ายมาจากช่องวันที่เดิมในตารางรถ', 'migration'
from gyt_tractors v
cross join lateral (values
  ('ภาษี',         v.date_tax),
  ('ประกันภัย',    v.date_ins),
  ('ตรวจสภาพ',     v.date_inspect),
  ('ประกันสินค้า', v.date_cargo_ins)
) as d(doc_type, val)
where _gyt_thai_date(d.val) is not null
  and not exists (
    select 1 from gyt_vehicle_docs x
    where x.vehicle_id = v.id and x.vehicle_type = 'tractor' and x.doc_type = d.doc_type
  );

insert into gyt_vehicle_docs (vehicle_id, vehicle_type, doc_type, expiry_date, note, created_by)
select v.id, 'trailer', d.doc_type, _gyt_thai_date(d.val),
       'ย้ายมาจากช่องวันที่เดิมในตารางรถ', 'migration'
from gyt_trailers v
cross join lateral (values
  ('ภาษี',         v.date_tax),
  ('ประกันภัย',    v.date_ins),
  ('ตรวจสภาพ',     v.date_inspect),
  ('ประกันสินค้า', v.date_cargo_ins)
) as d(doc_type, val)
where _gyt_thai_date(d.val) is not null
  and not exists (
    select 1 from gyt_vehicle_docs x
    where x.vehicle_id = v.id and x.vehicle_type = 'trailer' and x.doc_type = d.doc_type
  );

-- 4) ตรวจผล ------------------------------------------------------------
-- หมายเหตุ: พ.ร.บ. จะยังว่างอยู่ เพราะตารางรถเดิมไม่เคยมีช่องนี้
--           ต้องกรอกเข้ามาทีหลัง (ในแอป: หน้าซ่อมบำรุง → แท็บ 📄 เอกสารรถ → "ต่ออายุแล้ว")
select vehicle_type, doc_type, count(*) as rows, min(expiry_date) as earliest, max(expiry_date) as latest
from gyt_vehicle_docs
group by vehicle_type, doc_type
order by vehicle_type, doc_type;
