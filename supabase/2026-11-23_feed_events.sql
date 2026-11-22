-- ════════════════════════════════════════════════════════════════════════════
-- FEED EVENTS — one row per Phoenix feed (meal/snack) per day, shared table.
-- Phoenix writes the tick (eaten, eaten_at, macros). 5 Brains writes ONLY
-- location + note. Neither app overwrites the other's columns.
-- Run once in Supabase → SQL Editor. Safe to re-run.
-- ════════════════════════════════════════════════════════════════════════════

create table if not exists public.feed_events (
  user_id      uuid not null references auth.users(id) on delete cascade,
  date         date not null,                 -- Australia/Brisbane local day
  feed_id      text not null,                 -- Phoenix feed id (e.g. 'F2') or v1 slot name
  name         text,                          -- 'Breakfast', 'Feed 3', 'Snack' …
  planned_time text,                          -- Phoenix plan time 'HH:MM'
  eaten        boolean not null default false,
  eaten_at     timestamptz,                   -- set by Phoenix at the moment of the tick
  kcal         numeric,
  protein_g    numeric,
  location     text,                          -- set by 5 Brains
  note         text,                          -- set by 5 Brains
  source       text,
  updated_at   timestamptz not null default now(),
  primary key (user_id, date, feed_id)
);
create index if not exists feed_events_user_date on public.feed_events (user_id, date desc);

alter table public.feed_events enable row level security;
drop policy if exists "own feed_events" on public.feed_events;
create policy "own feed_events" on public.feed_events for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
grant select, insert, update, delete on public.feed_events to authenticated;
