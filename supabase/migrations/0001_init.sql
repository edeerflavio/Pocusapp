-- =============================================================
-- Pocusapp – Supabase initial migration
-- Generated: 2026-03-05
-- =============================================================

-- ─────────────────────────────────────────────────────────────
-- 0. Extensions
-- ─────────────────────────────────────────────────────────────
create extension if not exists "pgcrypto";

-- ─────────────────────────────────────────────────────────────
-- 1. Helper: app_roles (simplest admin approach)
-- ─────────────────────────────────────────────────────────────
create table public.app_roles (
  user_id uuid references auth.users(id) on delete cascade,
  role    text not null check (role in ('admin', 'editor')),
  primary key (user_id, role)
);

alter table public.app_roles enable row level security;

-- Only admins can read/manage roles
create policy "admins_manage_roles" on public.app_roles
  for all using (
    exists (
      select 1 from public.app_roles ar
      where ar.user_id = auth.uid() and ar.role = 'admin'
    )
  );

-- Helper function used in policies
create or replace function public.has_role(required_role text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.app_roles
    where user_id = auth.uid() and role = required_role
  );
$$;

-- Convenience: is admin or editor
create or replace function public.is_admin_or_editor()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.app_roles
    where user_id = auth.uid() and role in ('admin', 'editor')
  );
$$;

-- ─────────────────────────────────────────────────────────────
-- 2. profiles
-- ─────────────────────────────────────────────────────────────
create table public.profiles (
  id         uuid primary key references auth.users(id) on delete cascade,
  full_name  text,
  locale     text not null default 'pt-BR',
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "users_read_own_profile" on public.profiles
  for select using (auth.uid() = id);

create policy "users_update_own_profile" on public.profiles
  for update using (auth.uid() = id);

create policy "admins_manage_profiles" on public.profiles
  for all using (public.is_admin_or_editor());

-- Auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'full_name', ''));
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ─────────────────────────────────────────────────────────────
-- 3. plans
-- ─────────────────────────────────────────────────────────────
create table public.plans (
  id      uuid primary key default gen_random_uuid(),
  code    text unique not null check (code in ('free', 'premium')),
  name_pt text not null,
  name_es text not null,
  active  boolean not null default true
);

alter table public.plans enable row level security;

create policy "anyone_reads_active_plans" on public.plans
  for select using (active = true);

create policy "admins_manage_plans" on public.plans
  for all using (public.has_role('admin'));

-- Seed plans
insert into public.plans (code, name_pt, name_es) values
  ('free',    'Gratuito', 'Gratuito'),
  ('premium', 'Premium',  'Premium');

-- ─────────────────────────────────────────────────────────────
-- 4. subscriptions
-- ─────────────────────────────────────────────────────────────
create table public.subscriptions (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references auth.users(id) on delete cascade,
  provider           text not null default 'mercadopago',
  provider_ref       text,
  status             text not null default 'active',
  current_period_end timestamptz,
  created_at         timestamptz not null default now()
);

alter table public.subscriptions enable row level security;

create policy "users_read_own_sub" on public.subscriptions
  for select using (auth.uid() = user_id);

create policy "admins_manage_subs" on public.subscriptions
  for all using (public.is_admin_or_editor());

create index idx_subscriptions_user_id on public.subscriptions(user_id);

-- ─────────────────────────────────────────────────────────────
-- 5. entitlements
-- ─────────────────────────────────────────────────────────────
create table public.entitlements (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  plan_code  text not null,
  active     boolean not null default true,
  starts_at  timestamptz not null default now(),
  ends_at    timestamptz,
  updated_at timestamptz not null default now()
);

alter table public.entitlements enable row level security;

create policy "users_read_own_entitlement" on public.entitlements
  for select using (auth.uid() = user_id);

create policy "admins_manage_entitlements" on public.entitlements
  for all using (public.is_admin_or_editor());

create index idx_entitlements_user_id on public.entitlements(user_id);
create index idx_entitlements_active  on public.entitlements(user_id, active) where active = true;

-- Helper: does current user have active premium?
create or replace function public.has_premium()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.entitlements
    where user_id = auth.uid()
      and plan_code = 'premium'
      and active = true
      and (ends_at is null or ends_at > now())
  );
$$;

-- ─────────────────────────────────────────────────────────────
-- 6. drugs
-- ─────────────────────────────────────────────────────────────
create table public.drugs (
  id         uuid primary key default gen_random_uuid(),
  slug       text unique not null,
  title_pt   text not null,
  title_es   text not null,
  body_pt    text not null default '',
  body_es    text not null default '',
  is_premium boolean not null default false,
  status     text not null default 'draft' check (status in ('draft', 'review', 'published')),
  updated_at timestamptz not null default now()
);

alter table public.drugs enable row level security;

create index idx_drugs_slug       on public.drugs(slug);
create index idx_drugs_status     on public.drugs(status);
create index idx_drugs_updated_at on public.drugs(updated_at);

-- ─────────────────────────────────────────────────────────────
-- 7. diseases
-- ─────────────────────────────────────────────────────────────
create table public.diseases (
  id         uuid primary key default gen_random_uuid(),
  slug       text unique not null,
  title_pt   text not null,
  title_es   text not null,
  body_pt    text not null default '',
  body_es    text not null default '',
  is_premium boolean not null default false,
  status     text not null default 'draft' check (status in ('draft', 'review', 'published')),
  updated_at timestamptz not null default now()
);

alter table public.diseases enable row level security;

create index idx_diseases_slug       on public.diseases(slug);
create index idx_diseases_status     on public.diseases(status);
create index idx_diseases_updated_at on public.diseases(updated_at);

-- ─────────────────────────────────────────────────────────────
-- 8. protocols
-- ─────────────────────────────────────────────────────────────
create table public.protocols (
  id         uuid primary key default gen_random_uuid(),
  slug       text unique not null,
  title_pt   text not null,
  title_es   text not null,
  body_pt    text not null default '',
  body_es    text not null default '',
  is_premium boolean not null default false,
  status     text not null default 'draft' check (status in ('draft', 'review', 'published')),
  updated_at timestamptz not null default now()
);

alter table public.protocols enable row level security;

create index idx_protocols_slug       on public.protocols(slug);
create index idx_protocols_status     on public.protocols(status);
create index idx_protocols_updated_at on public.protocols(updated_at);

-- ─────────────────────────────────────────────────────────────
-- 9. pocus_items
-- ─────────────────────────────────────────────────────────────
create table public.pocus_items (
  id         uuid primary key default gen_random_uuid(),
  category   text not null,
  title_pt   text not null,
  title_es   text not null,
  body_pt    text not null default '',
  body_es    text not null default '',
  is_premium boolean not null default false,
  status     text not null default 'draft' check (status in ('draft', 'review', 'published')),
  updated_at timestamptz not null default now()
);

alter table public.pocus_items enable row level security;

create index idx_pocus_items_category   on public.pocus_items(category);
create index idx_pocus_items_status     on public.pocus_items(status);
create index idx_pocus_items_updated_at on public.pocus_items(updated_at);

-- ─────────────────────────────────────────────────────────────
-- 10. RLS policies for content tables (drugs, diseases, protocols, pocus_items)
-- ─────────────────────────────────────────────────────────────
-- We create identical policies for each content table via a DO block.

do $$
declare
  tbl text;
begin
  foreach tbl in array array['drugs', 'diseases', 'protocols', 'pocus_items']
  loop
    -- SELECT: published + free → anyone (including anon)
    execute format(
      'create policy "select_published_free_%1$s" on public.%1$s
         for select using (
           status = ''published'' and is_premium = false
         )',
      tbl
    );

    -- SELECT: published + premium → logged-in user with active entitlement
    execute format(
      'create policy "select_published_premium_%1$s" on public.%1$s
         for select using (
           status = ''published''
           and is_premium = true
           and public.has_premium()
         )',
      tbl
    );

    -- SELECT: draft/review → admin/editor only
    execute format(
      'create policy "select_draft_review_%1$s" on public.%1$s
         for select using (
           status in (''draft'', ''review'')
           and public.is_admin_or_editor()
         )',
      tbl
    );

    -- INSERT/UPDATE/DELETE → admin/editor only
    execute format(
      'create policy "admin_insert_%1$s" on public.%1$s
         for insert with check (public.is_admin_or_editor())',
      tbl
    );
    execute format(
      'create policy "admin_update_%1$s" on public.%1$s
         for update using (public.is_admin_or_editor())',
      tbl
    );
    execute format(
      'create policy "admin_delete_%1$s" on public.%1$s
         for delete using (public.is_admin_or_editor())',
      tbl
    );
  end loop;
end;
$$;

-- ─────────────────────────────────────────────────────────────
-- 11. media_assets
-- ─────────────────────────────────────────────────────────────
create table public.media_assets (
  id         uuid primary key default gen_random_uuid(),
  owner_type text not null,
  owner_id   uuid not null,
  kind       text not null check (kind in ('image', 'video')),
  path       text not null,
  thumb_path text,
  created_at timestamptz not null default now()
);

alter table public.media_assets enable row level security;

create index idx_media_assets_owner on public.media_assets(owner_type, owner_id);

-- Anyone can see media for published content (resolved at app layer);
-- admin/editor can manage all.
create policy "select_media_published" on public.media_assets
  for select using (true);  -- media visibility controlled by parent content RLS

create policy "admin_insert_media" on public.media_assets
  for insert with check (public.is_admin_or_editor());

create policy "admin_update_media" on public.media_assets
  for update using (public.is_admin_or_editor());

create policy "admin_delete_media" on public.media_assets
  for delete using (public.is_admin_or_editor());

-- ─────────────────────────────────────────────────────────────
-- 12. favorites
-- ─────────────────────────────────────────────────────────────
create table public.favorites (
  user_id    uuid not null references auth.users(id) on delete cascade,
  item_type  text not null,
  item_id    uuid not null,
  created_at timestamptz not null default now(),
  unique (user_id, item_type, item_id)
);

alter table public.favorites enable row level security;

create policy "own_favorites" on public.favorites
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index idx_favorites_user_id on public.favorites(user_id);

-- ─────────────────────────────────────────────────────────────
-- 13. recent_items
-- ─────────────────────────────────────────────────────────────
create table public.recent_items (
  user_id        uuid not null references auth.users(id) on delete cascade,
  item_type      text not null,
  item_id        uuid not null,
  last_opened_at timestamptz not null default now(),
  unique (user_id, item_type, item_id)
);

alter table public.recent_items enable row level security;

create policy "own_recent_items" on public.recent_items
  for all using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create index idx_recent_items_user_id on public.recent_items(user_id);

-- ─────────────────────────────────────────────────────────────
-- 14. content_versions
-- ─────────────────────────────────────────────────────────────
create table public.content_versions (
  id           uuid primary key default gen_random_uuid(),
  version      integer not null,
  published_at timestamptz not null default now(),
  notes        text
);

alter table public.content_versions enable row level security;

create policy "anyone_reads_versions" on public.content_versions
  for select using (true);

create policy "admin_manage_versions" on public.content_versions
  for all using (public.is_admin_or_editor())
  with check (public.is_admin_or_editor());

-- ─────────────────────────────────────────────────────────────
-- 15. audit_log
-- ─────────────────────────────────────────────────────────────
create table public.audit_log (
  id            uuid primary key default gen_random_uuid(),
  actor_user_id uuid references auth.users(id) on delete set null,
  action        text not null,
  table_name    text not null,
  row_id        uuid,
  meta          jsonb default '{}',
  created_at    timestamptz not null default now()
);

alter table public.audit_log enable row level security;

-- Only admins can read audit logs
create policy "admins_read_audit" on public.audit_log
  for select using (public.has_role('admin'));

-- Insert via security-definer function (not direct)
create policy "system_insert_audit" on public.audit_log
  for insert with check (public.is_admin_or_editor());

create index idx_audit_log_actor      on public.audit_log(actor_user_id);
create index idx_audit_log_table_row  on public.audit_log(table_name, row_id);
create index idx_audit_log_created_at on public.audit_log(created_at);

-- ─────────────────────────────────────────────────────────────
-- 16. Helper: updated_at trigger
-- ─────────────────────────────────────────────────────────────
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Apply to all content tables
create trigger set_drugs_updated_at
  before update on public.drugs
  for each row execute function public.set_updated_at();

create trigger set_diseases_updated_at
  before update on public.diseases
  for each row execute function public.set_updated_at();

create trigger set_protocols_updated_at
  before update on public.protocols
  for each row execute function public.set_updated_at();

create trigger set_pocus_items_updated_at
  before update on public.pocus_items
  for each row execute function public.set_updated_at();

create trigger set_entitlements_updated_at
  before update on public.entitlements
  for each row execute function public.set_updated_at();
