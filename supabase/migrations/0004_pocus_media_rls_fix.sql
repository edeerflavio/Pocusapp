-- Migration: 0004_pocus_media_rls_fix.sql
-- Purpose : Fix security gap in media_assets RLS (premium check was missing),
--           add updated_at for PowerSync incremental sync, and publish
--           media_assets via the PowerSync logical replication publication.
--
-- SECURITY GAP (found in 0001_init.sql):
--   The original "select_media_via_parent" policy only verified that the
--   parent row was "published", but did NOT verify the caller's premium
--   entitlement. A free user could therefore read video/image assets that
--   belong to premium pocus_items.  This migration closes that gap.

-- ──────────────────────────────────────────────────────────────────────────
-- 1. Helper: checks both published status AND premium entitlement for a
--    given (owner_type, owner_id) pair.
--    SECURITY DEFINER so it can query all tables without RLS interference.
-- ──────────────────────────────────────────────────────────────────────────
create or replace function public.can_read_content(
  p_owner_type text,
  p_owner_id   uuid
)
returns boolean
language sql
stable
security definer
set search_path = 'public', 'auth'
as $$
  select case p_owner_type
    when 'drugs' then (
      select d.status = 'published'
             and (not d.is_premium or public.has_premium())
      from public.drugs d where d.id = p_owner_id
    )
    when 'diseases' then (
      select d.status = 'published'
             and (not d.is_premium or public.has_premium())
      from public.diseases d where d.id = p_owner_id
    )
    when 'protocols' then (
      select p.status = 'published'
             and (not p.is_premium or public.has_premium())
      from public.protocols p where p.id = p_owner_id
    )
    when 'pocus_items' then (
      select i.status = 'published'
             and (not i.is_premium or public.has_premium())
      from public.pocus_items i where i.id = p_owner_id
    )
    else false
  end;
$$;

-- ──────────────────────────────────────────────────────────────────────────
-- 2. Replace the deficient SELECT policy on media_assets.
--    The new policy delegates the full access check (published + premium)
--    to can_read_content(), which is tested and reusable.
-- ──────────────────────────────────────────────────────────────────────────
drop policy if exists "select_media_via_parent" on public.media_assets;

create policy "select_media_via_parent" on public.media_assets
  for select using (
    public.is_admin_or_editor()
    or public.can_read_content(owner_type, owner_id)
  );

-- ──────────────────────────────────────────────────────────────────────────
-- 3. Add updated_at to media_assets so PowerSync can do incremental sync.
--    Without this column the replication stream cannot compute row deltas.
-- ──────────────────────────────────────────────────────────────────────────
alter table public.media_assets
  add column if not exists updated_at timestamptz not null default now();

create index if not exists idx_media_assets_updated_at
  on public.media_assets(updated_at);

-- Reuse the existing set_updated_at() trigger function
drop trigger if exists set_media_assets_updated_at on public.media_assets;
create trigger set_media_assets_updated_at
  before update on public.media_assets
  for each row execute function public.set_updated_at();

-- ──────────────────────────────────────────────────────────────────────────
-- 4. Extend the PowerSync publication to include media_assets.
--    The mobile app now receives asset metadata (path, thumb_path, kind)
--    offline and can decide which files to pre-download.
--    Actual binary files are fetched on demand via short-lived signed URLs.
-- ──────────────────────────────────────────────────────────────────────────
drop publication if exists powersync;

create publication powersync for table
  diseases,
  drugs,
  protocols,
  pocus_items,
  favorites,
  recent_items,
  media_assets;
