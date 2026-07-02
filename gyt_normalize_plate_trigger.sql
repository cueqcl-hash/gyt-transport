-- ============================================================
-- Trigger แปลงทะเบียนอัตโนมัติ: ลง "75-3421 กท." (หรือมีอะไรต่อท้าย/นำหน้า) → เก็บเป็น "75-3421"
-- ครอบคลุม "ทุกทาง" ที่เขียนเข้า gyt_fuel_logs / gyt_toll_logs (ฟอร์มเว็บ / import / sync)
-- แก้ปัญหา: พี่อ้อยบางครั้งพิมพ์ " กท." ทำให้ Dashboard(ตัด กท.) กับหน้าค่าน้ำมัน(หาเป๊ะ)ไม่ตรงกัน
-- ฝากทีม WebApp รัน 1 ครั้ง ใน Supabase SQL Editor (idempotent — รันซ้ำปลอดภัย)
-- ============================================================
create or replace function gyt_normalize_plate() returns trigger as $$
declare m text;
begin
  -- ดึงเฉพาะรูปแบบทะเบียน XX-XXXX / XXX-XXXX ตัวแรก; ถ้าไม่เจอ (เช่นเครื่องปั่นไฟ/ทะเบียนพิเศษ) เก็บค่าเดิม
  m := (regexp_match(coalesce(new.plate,''), '[0-9]{2,3}-[0-9]{4}'))[1];
  if m is not null then
    new.plate := m;
  end if;
  return new;
end;
$$ language plpgsql;

drop trigger if exists trg_norm_plate_fuel on gyt_fuel_logs;
create trigger trg_norm_plate_fuel before insert or update on gyt_fuel_logs
  for each row execute function gyt_normalize_plate();

drop trigger if exists trg_norm_plate_toll on gyt_toll_logs;
create trigger trg_norm_plate_toll before insert or update on gyt_toll_logs
  for each row execute function gyt_normalize_plate();
