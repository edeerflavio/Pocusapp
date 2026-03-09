import 'package:powersync/powersync.dart';

const schema = Schema([
  Table('diseases', [
    Column.text('slug'),
    Column.text('title_pt'),
    Column.text('title_es'),
    Column.text('body_pt'),
    Column.text('body_es'),
    Column.integer('is_premium'),
    Column.text('status'),
  ]),
  Table('drugs', [
    Column.text('slug'),
    Column.text('title_pt'),
    Column.text('title_es'),
    Column.text('body_pt'),
    Column.text('body_es'),
    Column.integer('is_premium'),
    Column.text('status'),
  ]),
  Table('protocols', [
    Column.text('slug'),
    Column.text('title_pt'),
    Column.text('title_es'),
    Column.text('body_pt'),
    Column.text('body_es'),
    Column.integer('is_premium'),
    Column.text('status'),
  ]),
  Table('pocus_items', [
    Column.text('category'),
    Column.text('title_pt'),
    Column.text('title_es'),
    Column.text('body_pt'),
    Column.text('body_es'),
    Column.integer('is_premium'),
    Column.text('status'),
  ]),
  // Replicated: asset metadata syncs offline; binary files are downloaded
  // on demand by MediaCacheManager and stored in the app cache directory.
  Table('media_assets', [
    Column.text('owner_type'),
    Column.text('owner_id'),
    Column.text('kind'),   // 'image' | 'video'
    Column.text('path'),   // Supabase Storage path
    Column.text('thumb_path'),
    Column.text('updated_at'),
  ]),
  Table('favorites', [
    Column.text('user_id'),
    Column.text('item_type'),
    Column.text('item_id'),
    Column.text('created_at'),
  ]),
  Table('recent_items', [
    Column.text('user_id'),
    Column.text('item_type'),
    Column.text('item_id'),
    Column.text('accessed_at'),
  ]),
  // Local-only: tracks which media files are cached on disk.
  // Never synced to Supabase. Managed entirely by MediaCacheManager.
  Table('media_cache_entries', [
    Column.text('asset_id'),        // FK → media_assets.id
    Column.text('local_path'),      // absolute path on device
    Column.integer('file_size_bytes'),
    Column.text('downloaded_at'),   // ISO-8601
    Column.text('last_accessed_at'), // ISO-8601 — drives LRU eviction
  ], localOnly: true),
]);
