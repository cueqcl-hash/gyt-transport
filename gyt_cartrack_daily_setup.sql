-- gyt_cartrack_daily : ข้อมูล Cartrack รายวันต่อคัน (Dashboard Cartrack โหมด "รายวัน")
-- ฝากทีม WebApp รัน 1 ครั้ง (DDL + seed 23 มิ.ย.; รันซ้ำปลอดภัย). Push-Dashboard -Grain daily เติมต่อทุกวัน
create table if not exists gyt_cartrack_daily (
  id bigserial primary key,
  plate text not null,
  day date not null,
  trips int, km numeric, max_speed numeric, spd_evt int, spd_min int, harsh int, spd_per100 numeric,
  eng_hr numeric, idle_hr numeric, idle_pct numeric, no_tag int,
  fills int, liters numeric, amount numeric, kmpl numeric,
  created_at timestamptz default now()
);
alter table gyt_cartrack_daily disable row level security;
create unique index if not exists ux_cartrack_daily on gyt_cartrack_daily(plate, day);

insert into gyt_cartrack_daily (plate,day,trips,km,max_speed,spd_evt,spd_min,harsh,spd_per100,eng_hr,idle_hr,idle_pct,no_tag,fills,liters,amount,kmpl) values('700-4687','2026-06-23',2,146,78,11,4,5,7.5,5.8,1.2,21,0,0,0,0,NULL),
('64-3450','2026-06-23',0,257,82,10,7,3,3.9,15.8,9.6,61,0,0,0,0,NULL),
('60-9399','2026-06-23',4,103,69,3,1,0,2.9,5.9,1.6,27,0,0,0,0,NULL),
('62-6044','2026-06-23',7,108,72,2,0,2,1.9,8.8,4.8,55,0,0,0,0,NULL),
('61-0699','2026-06-23',3,165,68,15,6,1,9.1,15.3,10.3,67,0,0,0,0,NULL),
('76-1930','2026-06-23',5,126,78,11,5,9,8.7,13.4,8.3,62,0,0,0,0,NULL),
('65-4769','2026-06-23',5,94,82,16,4,5,17,6.7,3.1,46,0,0,0,0,NULL),
('62-6046','2026-06-23',3,221,92,17,6,1,7.7,9.7,4.8,49,2,0,0,0,NULL),
('63-3809','2026-06-23',5,456,87,51,22,1,11.2,10.2,1.7,17,2,0,0,0,NULL),
('77-7108','2026-06-23',6,317,90,37,8,11,11.7,13.7,6.8,50,0,0,0,0,NULL),
('75-3731','2026-06-23',6,70,66,3,1,2,4.3,5.1,2.4,47,5,0,0,0,NULL),
('61-2734','2026-06-23',5,91,67,4,3,5,4.4,7.6,4.5,59,0,0,0,0,NULL),
('65-3012','2026-06-23',0,16,50,0,0,0,0,2.7,1.6,59,0,0,0,0,NULL),
('75-3421','2026-06-23',5,206,75,7,5,2,3.4,11.3,4.2,37,5,0,0,0,NULL),
('64-3449','2026-06-23',3,69,65,8,3,1,11.6,6.1,3.1,51,0,0,0,0,NULL),
('69-4325','2026-06-23',4,231,87,15,6,0,6.5,10.1,5.2,51,0,0,0,0,NULL),
('79-3342','2026-06-23',4,76,69,10,4,1,13.2,8.8,5.6,64,1,0,0,0,NULL)
on conflict (plate,day) do nothing;

