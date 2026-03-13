-- =============================================================
-- 0007_storage_bucket_pocus_media_fix.sql
-- Reconciles storage.objects policies for the pocus-media bucket.
-- This removes configuration drift from manual dashboard edits.
-- =============================================================

drop policy if exists "authenticated_read_media" on storage.objects;
drop policy if exists "admin_insert_media_objects" on storage.objects;
drop policy if exists "admin_update_media_objects" on storage.objects;
drop policy if exists "admin_delete_media_objects" on storage.objects;

create policy "authenticated_read_media"
on storage.objects for select
using (
  bucket_id = 'pocus-media'
  and auth.role() = 'authenticated'
);

create policy "admin_insert_media_objects"
on storage.objects for insert
with check (
  bucket_id = 'pocus-media'
  and public.is_admin_or_editor()
);

create policy "admin_update_media_objects"
on storage.objects for update
using (
  bucket_id = 'pocus-media'
  and public.is_admin_or_editor()
);

create policy "admin_delete_media_objects"
on storage.objects for delete
using (
  bucket_id = 'pocus-media'
  and public.is_admin_or_editor()
);
