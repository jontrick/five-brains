-- ════════════════════════════════════════════════════════════════════════════
-- 5 BRAINS — tables in the Phoenix Supabase project (mxtowhccuqarszcwpbkq)
-- Run this whole file once in Supabase → SQL Editor. Safe to re-run.
--
--   brains_day    one row per local (Brisbane) day: check-ins, scales, ticks
--   brains_entry  voice/written journal entries + AI reflection  (PRIVATE)
--   daily_water   shared water total — both Phoenix and 5 Brains read/write
--   brains_wellbeing_day   view Phoenix reads: scores only, no journal text
--
-- Every table: RLS on, owner-only policies. Journal text never leaves
-- brains_entry, and the view Phoenix reads physically cannot reach it.
-- ════════════════════════════════════════════════════════════════════════════

create table if not exists public.brains_day (
  user_id     uuid not null references auth.users(id) on delete cascade,
  date        date not null,                 -- Australia/Brisbane local day
  sleep_hours numeric,                       -- e.g. 7.5
  sleep_quality smallint check (sleep_quality between 1 and 10),
  energy_am   smallint check (energy_am between 1 and 10),
  energy_pm   smallint check (energy_pm between 1 and 10),
  mood        smallint check (mood between 1 and 10),
  stress      smallint check (stress between 1 and 10),
  focus       smallint check (focus between 1 and 10),
  intention   text,
  win         text,
  gratitude   text,
  brains      jsonb not null default '{}'::jsonb,  -- 5Brains scores {red,orange,yellow,blue,pink: 1-10}
  checks      jsonb not null default '{}'::jsonb,  -- {habit_id: true/false}
  log         jsonb not null default '{}'::jsonb,  -- recovery timestamps {walk:[],snack:[],breath:[],times:{}}
  goal_moved  boolean,                       -- did the day's target reset upward?
  hit_target  boolean,                       -- hit the ORIGINAL morning target?
  perfect_day boolean,                       -- every required tick done
  updated_at  timestamptz not null default now(),
  primary key (user_id, date)
);

alter table public.brains_day add column if not exists brains jsonb not null default '{}'::jsonb;
alter table public.brains_day add column if not exists log jsonb not null default '{}'::jsonb;
alter table public.brains_day add column if not exists goal_moved boolean;
alter table public.brains_day add column if not exists hit_target boolean;

create table if not exists public.brains_entry (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  date        date not null,
  kind        text not null check (kind in ('feelings','ideas','weekly','pulse')),  -- pulse = timestamped energy log
  transcript  text not null,
  analysis    jsonb,                          -- structured AI reflection
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
alter table public.brains_entry drop constraint if exists brains_entry_kind_check;
alter table public.brains_entry add constraint brains_entry_kind_check check (kind in ('feelings','ideas','weekly','pulse'));
create index if not exists brains_entry_user_date on public.brains_entry (user_id, date desc);

create table if not exists public.daily_water (
  user_id    uuid not null references auth.users(id) on delete cascade,
  date       date not null,
  water_ml   numeric not null default 0 check (water_ml >= 0),
  target_ml  numeric,
  source     text,                            -- 'phoenix' | 'five-brains'
  updated_at timestamptz not null default now(),
  primary key (user_id, date)
);

alter table public.brains_day   enable row level security;
alter table public.brains_entry enable row level security;
alter table public.daily_water  enable row level security;

drop policy if exists "own brains_day"   on public.brains_day;
drop policy if exists "own brains_entry" on public.brains_entry;
drop policy if exists "own daily_water"  on public.daily_water;
create policy "own brains_day"   on public.brains_day   for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own brains_entry" on public.brains_entry for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own daily_water"  on public.daily_water  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

grant select, insert, update, delete on public.brains_day, public.brains_entry, public.daily_water to authenticated;

-- What Phoenix reads. Scores + ticks + water. No intention/win/gratitude text,
-- no journal. security_invoker so RLS on the base tables applies to the caller.
create or replace view public.brains_wellbeing_day with (security_invoker = true) as
select d.user_id, d.date,
       d.sleep_hours, d.sleep_quality, d.energy_am, d.energy_pm,
       d.mood, d.stress, d.focus, d.perfect_day,
       d.brains as five_brains,
       w.water_ml, w.target_ml as water_target_ml
from public.brains_day d
left join public.daily_water w on w.user_id = d.user_id and w.date = d.date
where auth.uid() is null or d.user_id = auth.uid();

grant select on public.brains_wellbeing_day to authenticated;

-- Revoke the Phoenix read side at any time:  drop view brains_wellbeing_day;
