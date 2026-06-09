-- ============================================================
--  Mon coach perte de poids — schéma Supabase
--  À coller dans : Supabase > SQL Editor > New query > Run
-- ============================================================

-- 1) Table des pesées --------------------------------------------------
create table if not exists public.weights (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  date       date not null,
  kg         numeric(5,1) not null,
  created_at timestamptz default now(),
  unique (user_id, date)            -- une seule pesée par jour (upsert)
);

-- 2) Habitudes quotidiennes (cochées) ----------------------------------
create table if not exists public.habits (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  date    date not null,
  data    jsonb not null default '{}'::jsonb,
  primary key (user_id, date)
);

-- 3) Réglages (objectif de poids, poids de départ, objectif séances) ----
create table if not exists public.settings (
  user_id       uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  target_weight numeric(5,1) default 95,
  start_weight  numeric(5,1),
  workout_goal  integer default 3
);
-- au cas où la table settings existait déjà sans la colonne :
alter table public.settings add column if not exists workout_goal integer default 3;

-- 4) Séances de sport (gamification) -----------------------------------
create table if not exists public.workouts (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  date       date not null,
  type       text not null,           -- 'salle' | 'maison' | 'marche'
  morning    boolean default false,
  note       text,                     -- ressenti général optionnel
  exercises  jsonb default '[]'::jsonb, -- détail : [{n, sr, w}]
  created_at timestamptz default now()
);
-- si la table workouts existait déjà sans ces colonnes :
alter table public.workouts add column if not exists note text;
alter table public.workouts add column if not exists exercises jsonb default '[]'::jsonb;

-- 5) Victoires non-balance ---------------------------------------------
create table if not exists public.victories (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  date       date not null,
  text       text not null,
  created_at timestamptz default now()
);

-- ============================================================
--  Sécurité : Row Level Security
--  Chaque utilisateur ne voit/modifie QUE ses propres lignes.
-- ============================================================
alter table public.weights   enable row level security;
alter table public.habits    enable row level security;
alter table public.settings  enable row level security;
alter table public.workouts  enable row level security;
alter table public.victories enable row level security;

drop policy if exists "own_weights"   on public.weights;
drop policy if exists "own_habits"     on public.habits;
drop policy if exists "own_settings"   on public.settings;
drop policy if exists "own_workouts"   on public.workouts;
drop policy if exists "own_victories"  on public.victories;

create policy "own_weights" on public.weights
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own_habits" on public.habits
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own_settings" on public.settings
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own_workouts" on public.workouts
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

create policy "own_victories" on public.victories
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- Fin. Tu peux vérifier dans Table Editor que les 5 tables existent.
