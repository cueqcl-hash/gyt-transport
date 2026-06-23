-- gyt_sensor_alerts : สถานะเฝ้าระวังน้ำมันหาย/เซ็นเซอร์ (Cartrack) — Dashboard Cartrack การ์ด ⚠️
-- ฝากทีม WebApp รัน 1 ครั้ง (DDL + seed; รันซ้ำปลอดภัย). sensor analysis อนาคต upsert ต่อได้
-- วิธีขโมย #1 = ถอดเซ็นเซอร์ให้สัญญาณหาย → ต่อสายน้ำมันไหลกลับลงถังนอก (parked-drop ตรวจไม่เจอ)
-- สัญญาณจับได้จริง = sensor-dark % ระหว่างวิ่ง (ยิ่งสูงยิ่งเสี่ยง)
create table if not exists gyt_sensor_alerts (
  id bigserial primary key,
  plate text not null,
  period text not null,
  sensor_dark_pct numeric,        -- % เวลาเซ็นเซอร์ดับระหว่างวิ่ง
  status text not null,           -- 'confirmed' | 'watch' | 'normal'
  note text,
  created_at timestamptz default now()
);
alter table gyt_sensor_alerts disable row level security;
create unique index if not exists ux_sensor_alerts on gyt_sensor_alerts(plate, period);

insert into gyt_sensor_alerts (plate,period,sensor_dark_pct,status,note) values
('76-1930','2026-05',32,'confirmed','ยืนยันขโมย — คนขับถอดเซ็นเซอร์ให้สัญญาณหาย แล้วต่อสายน้ำมันไหลกลับลงถังนอก (คนขับรับสารภาพ) · km/L ต่ำสุด 1.81 · เซ็นเซอร์ดับ 32% ตอนวิ่ง'),
('76-1929','2026-05',4,'normal','เคยสงสัย แต่เซ็นเซอร์ปกติ (ดับ 4%) = พฤติกรรมขับ (ซิ่งเกิน90 เยอะสุด เร็วสุด 110) ไม่ใช่ขโมย')
on conflict (plate,period) do nothing;
