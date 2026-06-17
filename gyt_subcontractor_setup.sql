-- ════════════════════════════════════════════════════════════════════════
-- 🆕 v181 — รถร่วม (Subcontractor) สำหรับน้าปุ้ม
-- ════════════════════════════════════════════════════════════════════════
-- รันใน Supabase Studio > SQL Editor (ครั้งเดียว ก่อนใช้ฟีเจอร์)
-- หลังรันเสร็จ: เปิดแอป → เมนู "🚚 รถร่วม" → กด Refresh
-- (ตามด้วยให้ Code import ข้อมูล 10 เจ้า / 746,860 บาท เข้าให้)
-- ════════════════════════════════════════════════════════════════════════

-- 1) รายชื่อเจ้ารถร่วม (master) — ใช้ทำ dropdown
create table if not exists gyt_subcontractors (
  id          bigint generated always as identity primary key,
  name        text not null,            -- ชื่อเจ้ารถร่วม เช่น "พี่โย่ง"
  contact     text,                     -- ผู้ติดต่อ
  tax_id      text,                     -- เลขผู้เสียภาษี
  active      boolean default true,     -- ยังใช้งานอยู่ไหม
  note        text,
  created_at  timestamptz default now()
);

-- 2) งานที่จ้างรถร่วมวิ่ง (แต่ละงาน = ต้นทุน 1 รายการ)
create table if not exists gyt_subcontractor_jobs (
  id                 bigint generated always as identity primary key,
  subcontractor_id   bigint references gyt_subcontractors(id) on delete set null,
  subcontractor_name text,              -- ชื่อเจ้า (เก็บซ้ำไว้ให้แสดงง่าย)
  job_date           date,             -- ว ด ป (วันที่วิ่งงาน) เก็บแบบ พ.ศ. ตามต้นทาง
  voucher_no         text,             -- เลขที่ใบสำคัญจ่าย/ใบวางบิล เช่น "68/001"
  customer           text,             -- ลูกค้าของงานนั้น
  destination        text,             -- ปลายทาง/สถานที่ส่ง
  container_size     text,             -- ขนาดตู้ เช่น "40*1"
  container_no       text,             -- เบอร์ตู้
  hire_amount        numeric default 0, -- ค่าขนส่ง (ค่าจ้างรถร่วม) = ต้นทุน
  container_return   numeric default 0, -- ค่าคืนตู้ (pass-through)
  status             text default 'unpaid',  -- 'unpaid' | 'paid'
  paid_date          date,
  paid_amount        numeric,
  source             text,             -- 'bill' (จากใบวางบิล=ยังไม่จ่าย) | 'pay' (จากใบสำคัญจ่าย=จ่ายแล้ว) | 'manual'
  note               text,
  created_at         timestamptz default now(),
  created_by         text default 'claude-import-rr'
);

create index if not exists idx_rr_jobs_sub    on gyt_subcontractor_jobs(subcontractor_id);
create index if not exists idx_rr_jobs_date   on gyt_subcontractor_jobs(job_date);
create index if not exists idx_rr_jobs_status on gyt_subcontractor_jobs(status);

-- RLS off — แอปใช้ anon key ทำ CRUD เหมือนตารางอื่น (gyt_driver_payouts, gyt_personal_tolls)
alter table gyt_subcontractors     disable row level security;
alter table gyt_subcontractor_jobs disable row level security;


-- ════════════ DATA: 10 เจ้า / 108 งาน / 746,860 บาท (ต.ค.2568→ปัจจุบัน) ════════════
-- ✅ กันซ้ำ: เคลียร์ก่อนใส่ → รันไฟล์นี้ซ้ำกี่รอบก็ได้ ข้อมูลคงที่ 108 รายการ
-- ⚠️ (อย่ารันซ้ำ "หลัง" เริ่มกรอกข้อมูลรถร่วมเองในแอป — เพราะจะล้างของที่กรอกเอง)
truncate table gyt_subcontractor_jobs, gyt_subcontractors restart identity;

insert into gyt_subcontractors (name) values
  ('TNK (ตี๋ l หนุ่ม)'),
  ('โซนุ'),
  ('คุณอ้อย (ชั้นล่าง)'),
  ('ธัช โลจิสติกส์'),
  ('บ.ฟาอีฟ'),
  ('พี่โย่ง'),
  ('รินทร ทรานสปอร์ต'),
  ('หจก.ซุ่งเฮงขนส่ง ( K. เพ้ง )'),
  ('อ้อม B.A.I'),
  ('อัจจิมา');

insert into gyt_subcontractor_jobs
  (subcontractor_id, subcontractor_name, job_date, voucher_no, customer, destination, container_size, container_no, hire_amount, container_return, status, paid_date, paid_amount, source, created_by) values
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2568-10-08', '68/010', 'ON-GREEN PRODUCES', 'PAT - มหาชัย (ส่ง 2 ที่)', '40*1 RF', 'OTPU1004871', 8000, 2140, 'paid', '2568-10-08', 8000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2568-10-09', '68/010', 'SEABRA TRANS / GUARDIAN', 'PAT - สระบุรี', '40*2 RF', '-', 18000, 2246, 'paid', '2568-10-09', 18000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2568-10-15', '68/010', 'BESTDEAL ONLINE CO.,LTD.', 'PAT - เทียนทะเล', '20*1 RF', 'SZLU2073117', 6500, 897, 'paid', '2568-10-15', 6500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2568-10-15', '68/010', 'SEABRA TRANS / GUARDIAN', 'PAT - สระบุรี', '40*1 RF', 'FBIU5116162', 9000, 1123, 'paid', '2568-10-15', 9000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2568-10-29', '68/010', 'SEABRA TRANS / GUARDIAN', 'PAT - สระบุรี', '40*1 RF', 'OTPU6225849', 9000, 1123, 'paid', '2568-10-29', 9000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2568-11-05', '68/011', 'PSN INTERFOOD CO.,LTD.', 'PAT - บางนา ก.ม.21', '20*1 RF', 'OERU2003311', 6500, 910, 'paid', '2568-11-05', 6500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2568-11-08', '68/011', 'SEABRA TRANS / GUARDIAN', 'PAT - สระบุรี', '40*1 RF', 'SZLU9920050', 9000, 1534, 'paid', '2568-11-08', 9000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2568-11-14', '68/011', 'ON-GREEN PRODUCES  (@ 8,000 * 2 )', 'PAT - มหาชัย (ส่ง 2 ที่)', '40*2 RF', 'OTPU6634873', 16000, 2140, 'paid', '2568-11-14', 16000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2568-11-14', '68/011', 'ON-GREEN PRODUCES  (@ 1,000 * 2 )', 'ค่าต่อระยะส่งของ 2 ที่', '40*2 RF', 'SEKU9102250', 2000, 1872.5, 'paid', '2568-11-14', 2000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2568-11-22', '68/011', 'BESTDEAL ONLINE CO.,LTD.', 'SSW - เทียนทะเล', '20*1 RF', 'SEGU9303310', 6500, 891.99, 'paid', '2568-11-22', 6500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2568-11-29', '68/011', 'BESTDEAL ONLINE CO.,LTD.', 'SSW - เทียนทะเล', '20*1 RF', 'SZLU2016668', 6500, 891.99, 'paid', '2568-11-29', 6500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2568-12-03', '68/012', 'AMERICAN TAIWAN BIOPHARM', 'PAT - บางพลี', '40*1 RF', 'SEKU9312282', 6000, 1539, 'paid', '2568-12-03', 6000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2568-12-13', '68/012', 'BESTDEAL ONLINE CO.,LTD.', 'SSW - เทียนทะเล', '20*1 RF', 'SEGU9873632', 6500, 891.99, 'paid', '2568-12-13', 6500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2568-12-15', '68/012', 'GREAT EASTERN', 'PAT - บางนา ก.ม.23', '40*1 RF', 'FBIU5833775', 6000, 1539, 'paid', '2568-12-15', 6000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2568-12-17', '68/012', 'GREAT EASTERN', 'PAT - บางนา ก.ม.23', '40*1 RF', 'FBIU5832721', 6000, 1539, 'paid', '2568-12-17', 6000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2568-12-23', '68/012', 'BESTDEAL ONLINE CO.,LTD.', 'SSW - เทียนทะเล', '20*1 RF', 'SEGU9302783', 6500, 842, 'paid', '2568-12-23', 6500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2569-01-06', '69/001', 'PSN INTERFOOD CO.,LTD.', 'PAT - บางนา ก.ม.21', '20*1 RF', 'OERU2008714', 6500, 910, 'paid', '2569-01-06', 6500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2569-01-08', '69/001', 'SEABRA TRANS / GUARDIAN', 'PAT - สระบุรี', '40*1 RF', 'SEGU9755917', 9000, 1551, 'paid', '2569-01-08', 9000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2569-01-15', '69/001', 'BESTDEAL ONLINE CO.,LTD.', 'SSW - ศรีนครินทร์', '20*1 RF', 'TRIU6719057', 6500, 897, 'paid', '2569-01-15', 6500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2569-01-27', '69/001', 'SEABRA TRANS / GUARDIAN', 'PAT - สระบุรี', '40*1 RF', 'WHLU7732621', 9000, 1551, 'paid', '2569-01-27', 9000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2569-02-20', '69/002', 'I-FRESH DRINKING WATER CO.,LTD.', 'PAT - โคราช', '40 * 1', 'TCNU3069069', 12300, 1748, 'paid', '2569-02-20', 12300, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2568-10-18', '68/004', 'WINTEK LUGGAGE (THAILAND) CO.,LTD.', 'PAT - สามพราน', '40*1', 'FFAU6965317', 5300, 1539, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2568-11-07', '68/004', 'WINTEK LUGGAGE (THAILAND) CO.,LTD.', 'PAT - สามพราน', '40*1', 'WHSU6544538', 5300, 1753, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2568-12-17', '68/005', 'GETEC INTERTRADE CO.,LTD.', 'PAT - ปทุมธานี', '40*1 OT', 'CAIU5620109', 5500, 1504, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2569-01-29', '69/001', 'TRANSFERTECH CO.,LTD.', 'ท่าเรือ PAT - สมุทรสาคร', '40*1 F/L', 'SEGU7675556', 17000, 1605, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2569-03-12', '69/002', 'SIAM FIBRE CEMENT GROUP CO.,LTD..', 'LKB#1 - หนองแค', '40 * 1', 'SUDU8754768', 7000, 599.4, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='TNK (ตี๋ l หนุ่ม)' limit 1), 'TNK (ตี๋ l หนุ่ม)', '2569-04-23', '69/003', 'KASKAL CO.,LTD.', 'ท่าเรือ PAT - บางพลี ตำหรุ', '40 OT * 1', 'FBLU4211431', 9460, 1607.5, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='โซนุ' limit 1), 'โซนุ', '2568-10-31', '68/001', 'AJINOMOTO FROZEN', 'ท่าเรือ PAT - สาย 5', '40*1 RF', 'FBIU5596499', 6500, 1714, 'paid', '2568-10-31', 6500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='โซนุ' limit 1), 'โซนุ', '2569-04-04', '68/002', 'DOMINO ASIA PACIFIC', 'ท่าเรือ PAT - วังน้อย', '20 * 1', 'CSNU1717146', 8500, 909.5, 'paid', '2569-04-04', 8500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='โซนุ' limit 1), 'โซนุ', '2569-06-05', '69/001', 'MENGHUA', 'ท่าเรือ PAT - มหาชัย', '40 * 1', 'TGHU5207282', 6000, 1369.1, 'paid', '2569-06-05', 6000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='โซนุ' limit 1), 'โซนุ', '2569-06-06', '69/001', 'LIFT YIFAN', 'ตู้บรรจุโรจนะ - คืนตู้ปู่เจ้า', '40 * 1', 'BMOU9828913', 7500, 3050.6, 'paid', '2569-06-06', 7500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='โซนุ' limit 1), 'โซนุ', '2569-06-08', '69/001', 'WAH TECH', 'ท่าเรือ PAT - เทพารักษ์', '20 * 1', 'WHSU0145931', 4800, 1019, 'paid', '2569-06-08', 4800, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='โซนุ' limit 1), 'โซนุ', '2568-10-01', '68/001', 'SVIZZ-ONE CO.,LTD.', 'PAT - บางเลน', '40 * 1', 'EGSU9173410', 5400, 1450.01, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='โซนุ' limit 1), 'โซนุ', '2568-10-08', '68/002', 'SINO MEDICAL CO.,LTD.', 'PAT - อ้อมใหญ่', '40 * 1', 'TXGU8939755', 5000, 1230.5, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='โซนุ' limit 1), 'โซนุ', '2569-02-21', '69/001', 'A B P STAINLESS FASTENER', 'ท่าเรือ PAT - โรจนะ', '20 * 1 ตู้หนัก', 'SEGU2478868', 5500, 949, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='คุณอ้อย (ชั้นล่าง)' limit 1), 'คุณอ้อย (ชั้นล่าง)', '2569-02-13', '69/001', 'AG-GRO (THAILAND) CO.,LTD.', 'PAT - บางปู', '40*1', 'RFCU4031350', 5000, 1534, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='ธัช โลจิสติกส์' limit 1), 'ธัช โลจิสติกส์', '2568-10-22', '68/004', 'TAKO FOODS INDUSTRY CO.,LTD.', 'ตู้บรรจุบ้านแพ้ว-คืนตู้ท่าสหไทย', '20*2', NULL, 10000, 3336.6, 'paid', '2568-10-22', 10000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='ธัช โลจิสติกส์' limit 1), 'ธัช โลจิสติกส์', '2568-10-22', '68/004', 'PICO TECHNOLOGY CO.,LTD.', 'ตู้บรรจุวัดเทียนดัด - คืนตู้ PAT', '20*1', 'SEGU2506743', 4500, 1293, 'paid', '2568-10-22', 4500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='ธัช โลจิสติกส์' limit 1), 'ธัช โลจิสติกส์', '2568-10-22', '68/004', 'WATSADUNIYOM CO.,LTD.', 'ท่าเรือ PAT - อ่อนนุช 70', '20*1', 'TWCU2151991', 4500, 842, 'paid', '2568-10-22', 4500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='ธัช โลจิสติกส์' limit 1), 'ธัช โลจิสติกส์', '2568-10-27', '68/004', 'U.LEK 2560 CO.,LTD.', 'ท่าเรือ PAT - พุทธบูชา', '40*1', 'SEGU6420416', 4800, 1550, 'paid', '2568-10-27', 4800, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='ธัช โลจิสติกส์' limit 1), 'ธัช โลจิสติกส์', '2568-10-29', '68/004', 'U.LEK 2560 CO.,LTD.', 'ท่าเรือ PAT - พุทธบูชา', '40*1', 'TCNU1226786', 4800, 1550, 'paid', '2568-10-29', 4800, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='ธัช โลจิสติกส์' limit 1), 'ธัช โลจิสติกส์', '2568-10-31', '68/004', 'JJTAP CO.,LTD.', 'ท่าเรือ PAT - บางนา ก.ม.23', '20*1', 'GAOU2519911', 3700, 892, 'paid', '2568-10-31', 3700, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='ธัช โลจิสติกส์' limit 1), 'ธัช โลจิสติกส์', '2568-11-11', '68/005', 'TAKO FOODS INDUSTRY CO.,LTD.', 'ตู้บรรจุบ้านแพ้ว-คืนตู้ท่า TCT', '20*2', NULL, 10000, 5053.2, 'paid', '2568-11-11', 10000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='ธัช โลจิสติกส์' limit 1), 'ธัช โลจิสติกส์', '2568-11-11', '68/005', 'SIAM OHGITANI CO.,LTD.', 'PAT - โรจนะ', '20*1', 'FYCU7120817', 6000, 1004, 'paid', '2568-11-11', 6000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='ธัช โลจิสติกส์' limit 1), 'ธัช โลจิสติกส์', '2568-11-12', '68/005', 'U.LEK 2560 CO.,LTD.', 'ท่าเรือ PAT - พุทธบูชา', '40*1', 'FFAU4507383', 4800, 1550, 'paid', '2568-11-12', 4800, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='ธัช โลจิสติกส์' limit 1), 'ธัช โลจิสติกส์', '2568-11-13', '68/005', 'ASIAN-PACIFIC CAN CO,.LTD.', 'ตู้บรรจุเอกชัย - คืนตู้ LKB#3', '40*2', NULL, 9600, 4778, 'paid', '2568-11-13', 9600, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='ธัช โลจิสติกส์' limit 1), 'ธัช โลจิสติกส์', '2568-11-13', '68/005', 'U.LEK 2560 CO.,LTD.', 'ท่าเรือ PAT - พุทธบูชา', '40*1', 'TEMU6482163', 4800, 1550, 'paid', '2568-11-13', 4800, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='ธัช โลจิสติกส์' limit 1), 'ธัช โลจิสติกส์', '2568-11-14', '68/005', 'DEFENCE INDUSTRIAL', 'ตู้บรรจุเมืองทอง - คืนตู้ PAT', '40*1', 'SKHU9905400', 5000, 1970.8, 'paid', '2568-11-14', 5000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='ธัช โลจิสติกส์' limit 1), 'ธัช โลจิสติกส์', '2568-11-13', '68/005', 'TAKO FOODS INDUSTRY CO.,LTD.', 'ตู้บรรจุบ้านแพ้ว-คืนตู้ท่าสหไทย', '40*2', NULL, 10000, 5948.7, 'paid', '2568-11-13', 10000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='ธัช โลจิสติกส์' limit 1), 'ธัช โลจิสติกส์', '2568-11-29', '68/005', 'U.LEK 2560 CO.,LTD.', 'ท่าเรือ PAT - พุทธบูชา', '40*1', 'TCKU6604945', 4800, 1539, 'paid', '2568-11-29', 4800, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='ธัช โลจิสติกส์' limit 1), 'ธัช โลจิสติกส์', '2568-12-21', '68/006', 'NIPPON HUME CONCRETE CO.,LTD.', 'PAT - บางปะอิน', '20*2 ตู้ยกลง', NULL, 10600, 0, 'paid', '2568-12-21', 10600, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='ธัช โลจิสติกส์' limit 1), 'ธัช โลจิสติกส์', '2568-12-23', '68/006', 'NEXT CAN INNOVATION CO.,LTD.', 'LKB#4 - หนองแค', '20 * 6', NULL, 37200, 5172, 'paid', '2568-12-23', 37200, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='ธัช โลจิสติกส์' limit 1), 'ธัช โลจิสติกส์', '2568-12-24', '68/006', 'KPPS FORWARDING CO.,LTD.', 'PAT - คลองสามวา', '40*1', 'ONEU1404810', 5300, 1016, 'paid', '2568-12-24', 5300, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='ธัช โลจิสติกส์' limit 1), 'ธัช โลจิสติกส์', '2569-01-20', '69/001', 'U.LEK CO,.LTD.', 'ท่าเรือ PAT - พุทธบูชา', '40 * 1', 'MEDU7867629', 4800, 1504, 'paid', '2569-01-20', 4800, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='ธัช โลจิสติกส์' limit 1), 'ธัช โลจิสติกส์', '2569-01-20', '69/001', 'WATSADUNIYOM CO.,LTD.', 'ท่าเรือ PAT - อ่อนนุช 70', '20*1', 'TWCU2104623', 4500, 842, 'paid', '2569-01-20', 4500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='ธัช โลจิสติกส์' limit 1), 'ธัช โลจิสติกส์', '2568-11-26', '68/003', 'PAT - บางปู (DELTA ELECTRONICS)', NULL, '40*1', 'BSIU8270458', 4500, 1539, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='บ.ฟาอีฟ' limit 1), 'บ.ฟาอีฟ', '2569-01-09', '69/001', 'THAI ESCORP LTD.', 'ท่าเรือ PAT - โรจนะ', '20 * 1', 'CAAU2551779', 5000, 842, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='บ.ฟาอีฟ' limit 1), 'บ.ฟาอีฟ', '2569-05-06', '69/002', 'TODA KOGYO ASIA', 'ท่าเรือ PAT - โรจนะ', '20 * 1', 'TWCU2108552', 7000, 895.5, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='บ.ฟาอีฟ' limit 1), 'บ.ฟาอีฟ', '2569-05-06', '69/002', 'SUNSU SOLUTION CO.,LTD.', 'LKB#3 - ลาดหลุมแก้ว', '40 * 1', 'TCNU2081028', 7200, 866.7, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='บ.ฟาอีฟ' limit 1), 'บ.ฟาอีฟ', '2569-05-21', '69/003', 'SUNSU SOLUTION CO.,LTD.', 'LKB#3 - ลาดหลุมแก้ว', '40 * 1', 'EGSU6022575', 7200, 866.7, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='บ.ฟาอีฟ' limit 1), 'บ.ฟาอีฟ', '2569-05-23', '69/004', 'KUNKA GROUP CO.,LTD.', 'PAT - ปู่เจ้า สมุทรปราการ', '40 * 1', 'GAOU6005187', 5400, 1624, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='บ.ฟาอีฟ' limit 1), 'บ.ฟาอีฟ', '2569-05-23', '69/005', 'FUSIFANG TRADING (2022) CO.,LTD.', 'PAT - ไทรน้อย', '40 * 1', 'NLLU4234883', 6800, 2311.2, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2568-12-04', '68/008', 'SARD SONG SANG CO.,LTD.', 'PAT - ลำลูกกา', '40*1', 'UETU7191298', 6000, 1550, 'paid', '2568-12-04', 6000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2568-12-11', '68/008', 'MODI SOLAR CO.,LTD.', 'PAT - ลาดหลุมแก้ว', '40*1', 'NLLU4198657', 5500, 1604, 'paid', '2568-12-11', 5500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2568-12-23', '68/008', 'บจก. ไดมอนด์ อินเตอร์เคม', 'PAT - คลองสามวา', '20*1(ตู้หนัก)', 'ONEU2468316', 4500, 1113, 'paid', '2568-12-23', 4500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-01-08', '69/001', 'ORIENTAL SPORTS INDUSTRIAL CO.,LTD.', 'ท่าเรือ PAT - แพรกษา', '20 * 1', 'TEMU5152969', 4000, 842, 'paid', '2569-01-08', 4000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-01-09', '69/001', 'WATSADUNIYOM CO.,LTD.', 'ท่าเรือ PAT - อ่อนนุช 70', '20 * 1', 'GAOU2022102', 4500, 936.25, 'paid', '2569-01-09', 4500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-01-10', '69/001', 'P B S PRODUCTS (THAILAND) CO,.LTD.', 'ท่าเรือ PAT - ซ.สามัคคี', '20 * 1', 'LYGU3136837', 4000, 963, 'paid', '2569-01-10', 4000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-01-13', '69/001', 'NIPRO (THAILAND) CO.,LTD.', 'ท่าเรือ PAT - เสนา อยุธยา', '20 * 1', 'SKLU2471188', 5000, 936.25, 'paid', '2569-01-13', 5000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-01-13', '69/001', 'SIAM OHGITANI CO.,LTD.', 'ท่าเรือ PAT - โรจนะ', '40 * 1', 'CAAU9598567', 6000, 1504, 'paid', '2569-01-13', 6000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-02-20', '69/001', 'PACKINGTHAI CO.,LTD.', 'ท่าเรือ - ไมตรีจิต', '20 * 1', 'HPCU2932405', 4300, 862, 'paid', '2569-02-20', 4300, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-02-20', '69/001', 'M PLAST PACK', 'ท่าเรือ PAT - บางน้ำจืด', '20 * 1', 'CKSU2206245', 4300, 936.25, 'paid', '2569-02-20', 4300, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-01-15', '69/001', 'SCAN INTER CO.,LTD.', 'ค่าเสียเวลา ขึ้นตู้ตรวจไม่ผ่าน ยกตู้ลง', '20 * 1', 'FTAU1729682', 1000, 0, 'paid', '2569-01-15', 1000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-03-13', '69/002', 'NIPRO (THAILAND) CO.,LTD.', 'ท่าเรือ PAT - เสนา อยุธยา', '20 * 1', 'SKLU2423153', 5000, 936.25, 'paid', '2569-03-13', 5000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-03-17', '69/002', 'SIAM OHGITANI CO.,LTD.', 'ท่าเรือ PAT - โรจนะ', '40 * 1', 'EGSU1166203', 6000, 1450.01, 'paid', '2569-03-17', 6000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-03-19', '69/002', 'WAH TECH INDUSTRIAL CO.,LTD.', 'ท่าเรือ PAT - หนองจอก', '20 * 1(ตู้หนัก)', 'HMMU2047590', 5000, 1284, 'paid', '2569-03-19', 5000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-03-19', '69/002', 'INFOSAT INTERTRADE CO.,LTD.', 'ท่าเรือ PAT - สระบุรี', '40 * 1', 'CULU6013845', 8000, 1554, 'paid', '2569-03-19', 8000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-03-09', '69/002', 'SVIZZ-ONE CORPORATION LIMITED.', 'ท่าเรือ PAT - ดอนตูม', '20 * 1(ตู้หนัก)', 'HALU2027573', 5800, 936.25, 'paid', '2569-03-09', 5800, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-04-01', '69/002', 'TAKOFOOD INDUSTRY CO,.LTD.', 'ตู้บรรจุบ้านแพ้ว - คืนตู้ท่าเรือ PAT', '20 * 1', 'FTAU1037350', 6500, 1523.49, 'paid', '2569-04-01', 6500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-04-03', '69/002', 'NIPRO (THAILAND) CO.,LTD.', 'ท่าเรือ PAT - เสนา อยุธยา', '20 * 1', 'SKLU2342703', 6500, 982, 'paid', '2569-04-03', 6500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-04-03', '69/002', 'TAKOFOOD INDUSTRY CO,.LTD.', 'ตู้บรรจุบ้านแพ้ว - คืนตู้ท่าเรือ TCT', '20 * 1', 'BEAU2500975', 7000, 1871.7, 'paid', '2569-04-03', 7000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-04-03', '69/002', 'JAM PRINTING CO,.LTD.', 'ตู้บรรจุเทียนทะเล - คืนตู้ PAT', '20 * 1', 'TGBU2388708', 4500, 1433, 'paid', '2569-04-03', 4500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-04-03', '69/002', 'BURAPHA DISPENSARY CO,.LTD.', 'ตู้บรรจุงามวงศ์วาน - คืนตู้ PAT', '20 * 1', 'CAIU6040701', 5000, 1433, 'paid', '2569-04-03', 5000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-04-08', '69/002', 'SIAM OHGITANI CO.,LTD.', 'ท่าเรือ PAT - บิสโก้ บางนา', '20 * 1(ตู้หนัก)', 'UACU3586799', 5500, 965.5, 'paid', '2569-04-08', 5500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-04-10', '69/002', 'DIAMOND INTER CHEM CO.,LTD.', 'ท่าเรือ PAT - คลองสามวา', '20 * 1(ตู้หนัก)', 'TRHU3559413', 6000, 895.5, 'paid', '2569-04-10', 6000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-04-24', '69/002', 'NIHON MAX (THAILAND) CO,.LTD.', 'ท่าเรือ PAT - คลองสามวา', '20 * 1', 'MSKU5675532', 5500, 390.5, 'paid', '2569-04-24', 5500, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-05-08', '69/002', 'NIPRO (THAILAND) CO.,LTD.', 'ท่าเรือ PAT - เสนา อยุธยา', '20 * 1', 'SKLU2423153', 6000, 936.25, 'paid', '2569-05-08', 6000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-01-21', '69/001', 'ท่าเรือ PAT - บางพลี', NULL, '40 * 1', 'HLHU8444667', 4500, 1504, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='พี่โย่ง' limit 1), 'พี่โย่ง', '2569-05-07', '69/002', 'ท่าเรือ PAT - ไทรน้อย', NULL, '40 * 1', 'SITU2763837', 5500, 892, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='รินทร ทรานสปอร์ต' limit 1), 'รินทร ทรานสปอร์ต', '2569-04-08', '69/001', 'SVIZZ ONE CO.,LTD.', 'UNITHAI - ดอนตูม', '40 * 3', NULL, 24000, 2400, 'paid', '2569-04-08', 24000, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='รินทร ทรานสปอร์ต' limit 1), 'รินทร ทรานสปอร์ต', '2569-05-07', '69/002', 'SVIZZ ONE CO.,LTD.', 'PAT - ดอนตูม', '40 * 1', 'EGSU1712156', 6800, 1610.01, 'paid', '2569-05-07', 6800, 'pay', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='หจก.ซุ่งเฮงขนส่ง ( K. เพ้ง )' limit 1), 'หจก.ซุ่งเฮงขนส่ง ( K. เพ้ง )', '2569-02-10', '69/001', 'ท่าเรือ PAT - สาย 4', NULL, '20 * 1', NULL, 4000, 842, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='อ้อม B.A.I' limit 1), 'อ้อม B.A.I', '2568-12-24', '69/001', 'HWA FONG RUBBER', 'PAT - บางปู', '20 * 1', 'HALU2063101', 3500, 0, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='อ้อม B.A.I' limit 1), 'อ้อม B.A.I', '2569-01-10', '69/001', 'THE UNIVERSAL IMPORT', 'PAT - มหาชัย', '40 * 1', 'SEGU6575320', 5000, 0, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='อ้อม B.A.I' limit 1), 'อ้อม B.A.I', '2569-04-11', '69/002', 'B&W STEEL WORK CO.,LTD.', 'PAT - เอกชัย บางบอน', '40 * 1', 'BMOU6723971', 6800, 1765.5, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='อัจจิมา' limit 1), 'อัจจิมา', '2568-10-20', '68/040', 'THAI TECHNO PLATE CO.,LTD.', 'ขนส่ง  L/B', NULL, NULL, 12000, 0, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='อัจจิมา' limit 1), 'อัจจิมา', '2568-11-05', '68/041', 'M.L. POLYMER CO.,LTD.', '20 X 2 (ตู้หนัก)', NULL, NULL, 11000, 0, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='อัจจิมา' limit 1), 'อัจจิมา', '2568-11-14', '68/042', 'SUN EXPO SERVICE CO.,LTD.', 'ขนส่ง  L/B', NULL, NULL, 10000, 0, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='อัจจิมา' limit 1), 'อัจจิมา', '2568-11-20', '68/043', 'QUICK PACK PACIFIC CO.LTD.', '40 X 1', NULL, NULL, 5500, 0, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='อัจจิมา' limit 1), 'อัจจิมา', '2568-12-26', '68/044', NULL, '40 X 1', NULL, NULL, 5500, 0, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='อัจจิมา' limit 1), 'อัจจิมา', '2568-12-26', '68/044', NULL, '40 X 1', NULL, NULL, 5000, 0, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='อัจจิมา' limit 1), 'อัจจิมา', '2568-12-26', '68/044', NULL, '40 X 1', NULL, NULL, 4500, 0, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='อัจจิมา' limit 1), 'อัจจิมา', '2569-01-09', '69/001', NULL, '40 X 1', NULL, NULL, 4500, 0, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='อัจจิมา' limit 1), 'อัจจิมา', '2569-01-09', '69/001', NULL, '20 X 1 (ตู้หนัก)', NULL, NULL, 5000, 0, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='อัจจิมา' limit 1), 'อัจจิมา', '2569-02-06', '69/002', 'TISSUE CONNECT CO.LTD.', '40 X 1', NULL, NULL, 5500, 0, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='อัจจิมา' limit 1), 'อัจจิมา', '2569-02-12', '69/003', 'THAIDA GLOBAL TRADE CO.LTD.', '40 X 1', NULL, NULL, 5500, 0, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='อัจจิมา' limit 1), 'อัจจิมา', '2569-02-18', '69/004', 'STANDARD INTERNATIONAL LOGISTICS CO.LTD.', '40 X 1 FR', NULL, NULL, 8000, 0, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff'),
  ((select id from gyt_subcontractors where name='อัจจิมา' limit 1), 'อัจจิมา', '2569-05-06', '69/009', 'SUN EXPO SERVICES CO.,LTD.', '40 X 1', NULL, NULL, 5500, 0, 'unpaid', NULL, NULL, 'bill', 'webapp-handoff');

-- verify
select count(*) as jobs, sum(hire_amount) as total_hire, sum(case when status='paid' then hire_amount else 0 end) as paid, sum(case when status='unpaid' then hire_amount else 0 end) as unpaid from gyt_subcontractor_jobs;
