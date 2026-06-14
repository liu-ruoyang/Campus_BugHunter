-- Run this once in the Supabase SQL Editor.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'bounty-images',
  'bounty-images',
  true,
  5242880,
  array['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'image/bmp']
)
on conflict (id) do update set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Users upload their own bounty images" on storage.objects;
create policy "Users upload their own bounty images"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'bounty-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users delete their own bounty images" on storage.objects;
create policy "Users delete their own bounty images"
on storage.objects for delete to authenticated
using (
  bucket_id = 'bounty-images'
  and (storage.foldername(name))[1] = auth.uid()::text
);
