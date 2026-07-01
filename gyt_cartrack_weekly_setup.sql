-- gyt_cartrack_weekly : ข้อมูล Cartrack รายสัปดาห์ต่อคัน (Dashboard Cartrack โหมด "รายสัปดาห์")
-- ฝากทีม WebApp รัน 1 ครั้ง (DDL + seed สัปดาห์ 17-23 มิ.ย.; รันซ้ำปลอดภัย). Push-Dashboard -Grain weekly เติมต่อทุกสัปดาห์
-- week = วันเริ่มสัปดาห์ (YYYY-MM-DD)
create table if not exists gyt_cartrack_weekly (
  id bigserial primary key,
  plate text not null,
  week date not null,
  trips int, km numeric, max_speed numeric, spd_evt int, spd_min int, harsh int, brake int, accel int, corner int, spd_per100 numeric,
  eng_hr numeric, idle_hr numeric, idle_pct numeric, no_tag int,
  fills int, liters numeric, amount numeric, kmpl numeric,
  created_at timestamptz default now()
);
alter table gyt_cartrack_weekly disable row level security;
create unique index if not exists ux_cartrack_weekly on gyt_cartrack_weekly(plate, week);

insert into gyt_cartrack_weekly (plate,week,trips,km,max_speed,spd_evt,spd_min,harsh,spd_per100,eng_hr,idle_hr,idle_pct,no_tag,fills,liters,amount,kmpl) values('700-4687','2026-06-17',22,1444,86,115,41,39,8,45.7,9.3,20,0,0,0,0,NULL),
('64-3450','2026-06-17',5,1332,86,91,35,17,6.8,50.9,49.9,98,0,0,0,0,NULL),
('60-9399','2026-06-17',34,785,80,23,11,2,2.9,58.7,28.3,48,0,0,0,0,NULL),
('62-6044','2026-06-17',48,967,87,39,17,11,4,38.7,14,36,0,0,0,0,NULL),
('61-0699','2026-06-17',29,1010,88,90,26,7,8.9,78.4,45.4,58,0,0,0,0,NULL),
('76-1930','2026-06-17',6,126,78,11,5,9,8.7,13.6,8.4,62,0,0,0,0,NULL),
('65-4769','2026-06-17',27,1419,87,149,45,34,10.5,61.2,26.3,43,0,0,0,0,NULL),
('62-6046','2026-06-17',23,1174,100,129,28,18,11,57.5,25.2,44,18,0,0,0,NULL),
('63-3809','2026-06-17',25,963,87,130,46,15,13.5,46.6,21.6,46,14,0,0,0,NULL),
('77-7108','2026-06-17',25,1550,95,150,53,49,9.7,77,40.6,53,0,0,0,0,NULL),
('75-3731','2026-06-17',36,1239,76,45,17,23,3.6,72.3,30.9,43,22,0,0,0,NULL),
('61-2734','2026-06-17',23,914,77,36,17,9,3.9,55.8,27.9,50,0,0,0,0,NULL),
('65-3012','2026-06-17',24,788,90,104,30,14,13.2,37.2,15.5,42,0,0,0,0,NULL),
('75-3421','2026-06-17',36,1378,92,114,42,17,8.3,61.5,12.8,21,36,0,0,0,NULL),
('64-3449','2026-06-17',20,1176,91,113,31,18,9.6,50.8,22.2,44,4,0,0,0,NULL),
('69-4325','2026-06-17',20,912,89,89,28,8,9.8,52.9,26.7,50,0,0,0,0,NULL),
('79-3342','2026-06-17',36,1087,92,90,45,5,8.3,61.7,28.9,47,23,0,0,0,NULL)
on conflict (plate,week) do nothing;

