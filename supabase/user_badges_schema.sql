-- user_badges table to persist badge unlocks
-- Run in Supabase SQL Editor.

create table if not exists public.user_badges (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  badge_id text not null,
  earned_at timestamptz not null default now(),
  unique (user_id, badge_id)
);

create index if not exists idx_user_badges_user_id on public.user_badges (user_id);

alter table public.user_badges enable row level security;

drop policy if exists "user_badges_select_own" on public.user_badges;
create policy "user_badges_select_own"
on public.user_badges
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "user_badges_insert_own" on public.user_badges;
create policy "user_badges_insert_own"
on public.user_badges
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "user_badges_update_own" on public.user_badges;
create policy "user_badges_update_own"
on public.user_badges
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
