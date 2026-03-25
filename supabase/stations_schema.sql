-- stations cache table for public station metadata
-- Run in Supabase SQL Editor.

create table if not exists public.stations (
  id bigint primary key,
  name text not null,
  en text not null default '',
  line text not null,
  icon text not null default '🚉',
  region text not null default '',
  lat double precision not null,
  lng double precision not null,
  updated_at timestamptz not null default now()
);

create index if not exists idx_stations_line on public.stations (line);
create index if not exists idx_stations_region on public.stations (region);
create index if not exists idx_stations_name on public.stations (name);

alter table public.stations enable row level security;

-- Anyone (anon + authenticated) can read stations.
drop policy if exists "stations_select_all" on public.stations;
create policy "stations_select_all"
on public.stations
for select
to anon, authenticated
using (true);

-- Only authenticated users can upsert/update station cache rows.
drop policy if exists "stations_insert_auth" on public.stations;
create policy "stations_insert_auth"
on public.stations
for insert
to authenticated
with check (true);

drop policy if exists "stations_update_auth" on public.stations;
create policy "stations_update_auth"
on public.stations
for update
to authenticated
using (true)
with check (true);
