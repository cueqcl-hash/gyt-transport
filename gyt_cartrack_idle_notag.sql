-- เพิ่มคอลัมน์ idle + no-card-tap ใน gyt_vehicle_safety (Dashboard Cartrack การ์ด 🅿️ + 🪪)
-- ฝากทีม WebApp รัน 1 ครั้ง (ALTER + seed พ.ค.2569; รันซ้ำปลอดภัย)
alter table gyt_vehicle_safety add column if not exists eng_hr numeric;
alter table gyt_vehicle_safety add column if not exists idle_hr numeric;
alter table gyt_vehicle_safety add column if not exists idle_pct numeric;
alter table gyt_vehicle_safety add column if not exists no_tag int;
update gyt_vehicle_safety set eng_hr=210.1,idle_hr=112.6,idle_pct=54,no_tag=72 where plate='76-1929' and period='2026-05';
update gyt_vehicle_safety set eng_hr=309.9,idle_hr=128,idle_pct=41,no_tag=0 where plate='76-1930' and period='2026-05';
update gyt_vehicle_safety set eng_hr=237.6,idle_hr=53.8,idle_pct=23,no_tag=174 where plate='75-3421' and period='2026-05';
update gyt_vehicle_safety set eng_hr=288.1,idle_hr=151,idle_pct=52,no_tag=0 where plate='77-7108' and period='2026-05';
update gyt_vehicle_safety set eng_hr=254.8,idle_hr=106.7,idle_pct=42,no_tag=100 where plate='62-6046' and period='2026-05';
update gyt_vehicle_safety set eng_hr=357.1,idle_hr=184.1,idle_pct=52,no_tag=0 where plate='61-0699' and period='2026-05';
update gyt_vehicle_safety set eng_hr=242,idle_hr=91.2,idle_pct=38,no_tag=0 where plate='62-6044' and period='2026-05';
update gyt_vehicle_safety set eng_hr=241.3,idle_hr=156.3,idle_pct=65,no_tag=0 where plate='64-3450' and period='2026-05';
update gyt_vehicle_safety set eng_hr=282.7,idle_hr=136.9,idle_pct=48,no_tag=86 where plate='75-3731' and period='2026-05';
update gyt_vehicle_safety set eng_hr=292.6,idle_hr=119.1,idle_pct=41,no_tag=47 where plate='64-3449' and period='2026-05';
update gyt_vehicle_safety set eng_hr=261.3,idle_hr=147.4,idle_pct=56,no_tag=0 where plate='60-9399' and period='2026-05';
update gyt_vehicle_safety set eng_hr=158.8,idle_hr=75.8,idle_pct=48,no_tag=0 where plate='65-4769' and period='2026-05';
update gyt_vehicle_safety set eng_hr=235.9,idle_hr=87.6,idle_pct=37,no_tag=160 where plate='79-3342' and period='2026-05';
update gyt_vehicle_safety set eng_hr=273.6,idle_hr=120.3,idle_pct=44,no_tag=0 where plate='61-2734' and period='2026-05';
update gyt_vehicle_safety set eng_hr=197,idle_hr=79.6,idle_pct=40,no_tag=0 where plate='65-3012' and period='2026-05';
update gyt_vehicle_safety set eng_hr=181.4,idle_hr=79,idle_pct=44,no_tag=6 where plate='73-2787' and period='2026-05';
update gyt_vehicle_safety set eng_hr=242.4,idle_hr=105.9,idle_pct=44,no_tag=0 where plate='69-4325' and period='2026-05';
update gyt_vehicle_safety set eng_hr=193,idle_hr=84.5,idle_pct=44,no_tag=98 where plate='63-3809' and period='2026-05';
update gyt_vehicle_safety set eng_hr=235.4,idle_hr=91.7,idle_pct=39,no_tag=0 where plate='700-4687' and period='2026-05';
update gyt_vehicle_safety set eng_hr=37.7,idle_hr=14.3,idle_pct=38,no_tag=13 where plate='74-1300' and period='2026-05';

