-- gyt_personal_tolls : ค่าทางด่วน M-Flow รถส่วนตัวกรรมการ (แยกจากบริษัท ไม่นับต้นทุน)
-- ฝากทีม WebApp รัน 1 ครั้งใน Supabase SQL Editor — โค้ด dashboard (dfin-personal-tolls) อยู่ใน v184 แล้ว รัน SQL นี้แล้วการ์ดจะมีข้อมูล
-- ปลอดภัยถ้ารันซ้ำ (unique index + on conflict do nothing)
create table if not exists gyt_personal_tolls (
  id bigserial primary key,
  plate text not null,
  brand text,
  toll_date date not null,
  toll_time text,
  amount numeric not null,
  source text default 'M-Flow',
  created_at timestamptz default now()
);
alter table gyt_personal_tolls disable row level security;
create unique index if not exists ux_personal_tolls on gyt_personal_tolls(plate,toll_date,toll_time);

insert into gyt_personal_tolls (plate,brand,toll_date,toll_time,amount) values
('2ขท-9888','MERCEDES BENZ','2026-01-11','19:02:16',30),
('2ขท-9888','MERCEDES BENZ','2026-03-18','10:19:27',30),
('2ขท-9888','MERCEDES BENZ','2026-03-18','16:16:36',30),
('3ขฌ-9933','AION','2025-12-15','14:09:30',30),
('3ขฌ-9933','AION','2026-02-08','10:34:36',30),
('3ขฌ-9933','AION','2026-02-08','12:06:35',30),
('3ขฌ-9933','AION','2026-03-25','22:27:34',30),
('3ขฌ-9933','AION','2026-04-04','19:30:16',30),
('3ขฌ-9933','AION','2026-04-04','19:43:49',30),
('3ขฌ-9933','AION','2026-04-05','22:00:42',30),
('8กง-8144','NISSAN','2026-01-26','17:52:01',30),
('8กง-8144','NISSAN','2026-01-26','18:10:07',30),
('8กง-8144','NISSAN','2026-01-29','14:15:23',30),
('8กง-8144','NISSAN','2026-01-29','14:29:55',30),
('8กง-8144','NISSAN','2026-01-29','17:22:39',30),
('8กง-8144','NISSAN','2026-01-29','17:39:23',30)
on conflict (plate,toll_date,toll_time) do nothing;
