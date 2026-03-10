-- =============================================================
-- 0002_storage_bucket.sql
-- Sets up the Supabase Storage bucket for media files and
-- grants appropriate access via RLS policies.
-- =============================================================

-- 1. Create the private bucket (signed URLs required for access)
insert into storage.buckets (id, name, public)
values ('pocus-media', 'pocus-media', false)
on conflict (id) do nothing;

-- 2. Authenticated users can READ objects (enables createSignedUrl)
create policy "authenticated_read_media"
on storage.objects for select
using (
  bucket_id = 'pocus_media'
  and auth.role() = 'authenticated'
);

-- 3. Admins/editors can UPLOAD files
create policy "admin_insert_media_objects"
on storage.objects for insert
with check (
  bucket_id = 'pocus_media'
  and public.is_admin_or_editor()
);

-- 4. Admins/editors can UPDATE file metadata
create policy "admin_update_media_objects"
on storage.objects for update
using (
  bucket_id = 'pocus_media'
  and public.is_admin_or_editor()
);

-- 5. Admins/editors can DELETE files
create policy "admin_delete_media_objects"
on storage.objects for delete
using (
  bucket_id = 'pocus_media'
  and public.is_admin_or_editor()
);
