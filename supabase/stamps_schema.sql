-- stamps table for station stamp history
-- Run in Supabase SQL Editor.

create table if not exists public.stamps (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  station_id bigint not null,
  station_name text not null,
  station_line text not null,
  stamped_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (user_id, station_id)
);

create index if not exists idx_stamps_user_id on public.stamps (user_id);
create index if not exists idx_stamps_user_stamped_at on public.stamps (user_id, stamped_at desc);

alter table public.stamps enable row level security;

-- Users can read only their own stamps.
drop policy if exists "stamps_select_own" on public.stamps;
create policy "stamps_select_own"
on public.stamps
for select
to authenticated
using (auth.uid() = user_id);

-- Users can insert only their own stamps.
drop policy if exists "stamps_insert_own" on public.stamps;
create policy "stamps_insert_own"
on public.stamps
for insert
to authenticated
with check (auth.uid() = user_id);

-- Users can update only their own stamps (optional, future-proof).
drop policy if exists "stamps_update_own" on public.stamps;
create policy "stamps_update_own"
on public.stamps
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

-- Users can delete only their own stamps (optional, future-proof).
drop policy if exists "stamps_delete_own" on public.stamps;
create policy "stamps_delete_own"
on public.stamps
for delete
to authenticated
using (auth.uid() = user_id);
