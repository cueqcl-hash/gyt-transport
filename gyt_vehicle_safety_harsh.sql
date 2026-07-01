-- เพิ่มคอลัมน์เบรกกระทันหันแยก (brake/accel/corner) ใน gyt_vehicle_safety + seed พ.ค.
alter table gyt_vehicle_safety add column if not exists brake int;
alter table gyt_vehicle_safety add column if not exists accel int;
alter table gyt_vehicle_safety add column if not exists corner int;

update gyt_vehicle_safety set brake=3,accel=5,corner=57 where plate='76-1929' and period='2026-05';
update gyt_vehicle_safety set brake=0,accel=2,corner=176 where plate='76-1930' and period='2026-05';
update gyt_vehicle_safety set brake=40,accel=40,corner=60 where plate='75-3421' and period='2026-05';
update gyt_vehicle_safety set brake=18,accel=12,corner=121 where plate='77-7108' and period='2026-05';
update gyt_vehicle_safety set brake=15,accel=17,corner=30 where plate='62-6046' and period='2026-05';
update gyt_vehicle_safety set brake=13,accel=12,corner=26 where plate='61-0699' and period='2026-05';
update gyt_vehicle_safety set brake=19,accel=10,corner=16 where plate='62-6044' and period='2026-05';
update gyt_vehicle_safety set brake=24,accel=19,corner=46 where plate='64-3450' and period='2026-05';
update gyt_vehicle_safety set brake=4,accel=2,corner=130 where plate='75-3731' and period='2026-05';
update gyt_vehicle_safety set brake=29,accel=32,corner=54 where plate='64-3449' and period='2026-05';
update gyt_vehicle_safety set brake=0,accel=2,corner=21 where plate='60-9399' and period='2026-05';
update gyt_vehicle_safety set brake=41,accel=33,corner=11 where plate='65-4769' and period='2026-05';
update gyt_vehicle_safety set brake=1,accel=1,corner=38 where plate='79-3342' and period='2026-05';
update gyt_vehicle_safety set brake=18,accel=17,corner=8 where plate='61-2734' and period='2026-05';
update gyt_vehicle_safety set brake=8,accel=10,corner=20 where plate='65-3012' and period='2026-05';
update gyt_vehicle_safety set brake=9,accel=8,corner=22 where plate='73-2787' and period='2026-05';
update gyt_vehicle_safety set brake=8,accel=9,corner=45 where plate='69-4325' and period='2026-05';
update gyt_vehicle_safety set brake=15,accel=15,corner=51 where plate='63-3809' and period='2026-05';
update gyt_vehicle_safety set brake=0,accel=3,corner=154 where plate='700-4687' and period='2026-05';
update gyt_vehicle_safety set brake=2,accel=3,corner=0 where plate='74-1300' and period='2026-05';

