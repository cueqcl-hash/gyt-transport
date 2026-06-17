-- ใบปิดรอบค่าใช้จ่าย (คนโอน) — รัน 1 ครั้งใน Supabase SQL Editor
create table if not exists gyt_expense_closings (
  id bigserial primary key,
  doc_no text,                              -- เลขที่เอกสาร CLS-69-NNN
  payer text not null,                      -- ชื่อผู้โอน (จากบัญชีที่ล็อกอิน)
  payer_username text,                       -- username ผู้โอน
  items jsonb not null default '[]'::jsonb,  -- [{date, desc, amount}]
  item_count integer not null default 0,
  total numeric(14,2) not null default 0,
  note text,
  status text not null default 'closed',     -- closed = ปิดรอบ/ล็อกแล้ว
  created_by text,
  created_at timestamptz not null default now()
);
alter table gyt_expense_closings disable row level security;
create index if not exists idx_ec_payer on gyt_expense_closings (payer_username, created_at desc);
create index if not exists idx_ec_created on gyt_expense_closings (created_at desc);
notify pgrst, 'reload schema';
