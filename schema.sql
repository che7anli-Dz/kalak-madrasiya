-- ============================================================
-- كَلَك المدرسة — قاعدة البيانات (Supabase)
-- انسخ الكود كامل والصقو في SQL Editor ثم اضغط Run
-- ملاحظة: إذا ظهر خطأ "already exists" تجاهلو، معناها الجدول موجود من قبل
-- ============================================================

-- 1) الغرف
create table if not exists public.kalak_rooms (
  id uuid primary key default gen_random_uuid(),
  code text unique not null,
  host_name text not null,
  level text,          -- prim | moy | sec
  year_id text,
  year_label text,
  trimester int,       -- 1 | 2 | 3
  subject_id text,
  subject_label text,
  status text not null default 'lobby',  -- lobby | answering | voting | reveal | finished
  q jsonb,             -- {"q":"...","a":"..."} السؤال الحالي
  round int not null default 0,
  created_at timestamptz default now()
);

-- 2) اللاعبون
create table if not exists public.kalak_players (
  id uuid primary key default gen_random_uuid(),
  room_id uuid references public.kalak_rooms(id) on delete cascade,
  name text not null,
  score int not null default 0,
  is_host boolean default false,
  joined_at timestamptz default now()
);

-- 3) الإجابات (الحقيقية + المزيفة)
create table if not exists public.kalak_answers (
  id uuid primary key default gen_random_uuid(),
  room_id uuid references public.kalak_rooms(id) on delete cascade,
  round int not null,
  player_id uuid references public.kalak_players(id) on delete cascade,
  text text not null,
  is_true boolean not null default false,
  created_at timestamptz default now()
);

-- 4) الأصوات
create table if not exists public.kalak_votes (
  id uuid primary key default gen_random_uuid(),
  room_id uuid references public.kalak_rooms(id) on delete cascade,
  round int not null,
  voter_id uuid references public.kalak_players(id) on delete cascade,
  answer_id uuid references public.kalak_answers(id) on delete cascade,
  created_at timestamptz default now(),
  unique(room_id, round, voter_id)
);

-- 5) اقتراحات الأسئلة (يكبر بها بنك الأسئلة)
create table if not exists public.kalak_suggestions (
  id uuid primary key default gen_random_uuid(),
  level text,
  year_label text,
  trimester int,
  subject_label text,
  q text not null,
  a text not null,
  by_name text,
  created_at timestamptz default now()
);

-- 6) الصلاحيات (لعبة جماعية بلا تسجيل دخول)
grant all on public.kalak_rooms to anon;
grant all on public.kalak_players to anon;
grant all on public.kalak_answers to anon;
grant all on public.kalak_votes to anon;
grant all on public.kalak_suggestions to anon;

alter table public.kalak_rooms enable row level security;
alter table public.kalak_players enable row level security;
alter table public.kalak_answers enable row level security;
alter table public.kalak_votes enable row level security;
alter table public.kalak_suggestions enable row level security;

drop policy if exists "anon all" on public.kalak_rooms;
drop policy if exists "anon all" on public.kalak_players;
drop policy if exists "anon all" on public.kalak_answers;
drop policy if exists "anon all" on public.kalak_votes;
drop policy if exists "anon all" on public.kalak_suggestions;

create policy "anon all" on public.kalak_rooms for all to anon using (true) with check (true);
create policy "anon all" on public.kalak_players for all to anon using (true) with check (true);
create policy "anon all" on public.kalak_answers for all to anon using (true) with check (true);
create policy "anon all" on public.kalak_votes for all to anon using (true) with check (true);
create policy "anon all" on public.kalak_suggestions for all to anon using (true) with check (true);

-- 7) التحديث اللحظي (Realtime) — ضروري للعب الجماعي
alter publication supabase_realtime add table public.kalak_rooms;
alter publication supabase_realtime add table public.kalak_players;
alter publication supabase_realtime add table public.kalak_answers;
alter publication supabase_realtime add table public.kalak_votes;
