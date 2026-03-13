import 'package:powersync/powersync.dart';

const schema = Schema([
  // ─── Content tables ───────────────────────────────────────────────────────
  // All follow the same base structure: slug, title_pt/es, body_pt/es,
  // is_premium, status, updated_at — mirroring pocus_items.

  Table('diseases', [
    Column.text('slug'),
    Column.text('title_pt'),
    Column.text('title_es'),
    Column.text('body_pt'),
    Column.text('body_es'),
    Column.integer('is_premium'),
    Column.text('status'),
    Column.text('updated_at'),
  ]),
  Table('drugs', [
    Column.text('slug'),
    Column.text('title_pt'),
    Column.text('title_es'),
    Column.text('body_pt'),
    Column.text('body_es'),
    Column.integer('is_premium'),
    Column.text('status'),
    Column.text('updated_at'),
  ]),
  Table('protocols', [
    Column.text('slug'),
    Column.text('title_pt'),
    Column.text('title_es'),
    Column.text('body_pt'),
    Column.text('body_es'),
    Column.integer('is_premium'),
    Column.text('status'),
    Column.text('updated_at'),
  ]),
  Table('pocus_items', [
    Column.text('category'),
    Column.text('title_pt'),
    Column.text('title_es'),
    Column.text('body_pt'),
    Column.text('body_es'),
    Column.integer('is_premium'),
    Column.text('status'),
    Column.text('updated_at'),
  ]),

  // ─── Clinical guides (structured JSON content) ────────────────────────────

  Table('clinical_guides', [
    Column.text('slug'),
    Column.text('title'),
    Column.text('scenario'),     // 'emergencia' | 'enfermaria' | 'ubs' | 'geral'
    Column.text('specialty'),
    Column.text('summary'),
    Column.text('content_json'), // JSON string — parsed in ClinicalGuide model
    Column.text('tags'),         // JSON array string
    Column.text('source'),
    Column.text('version'),
    Column.text('status'),
    Column.text('updated_at'),
  ]),

  // ─── Media assets ─────────────────────────────────────────────────────────
  // Replicated: asset metadata syncs offline; binary files are downloaded
  // on demand by MediaCacheManager and stored in the app cache directory.

  Table('media_assets', [
    Column.text('owner_type'),
    Column.text('owner_id'),
    Column.text('kind'),       // 'image' | 'video'
    Column.text('path'),       // Supabase Storage path
    Column.text('thumb_path'),
    Column.text('updated_at'),
  ]),

  // ─── User profile ─────────────────────────────────────────────────────────

  Table('profiles', [
    Column.text('full_name'),
    Column.text('locale'),
    Column.text('created_at'),
  ]),

  // ─── Plans & subscriptions ────────────────────────────────────────────────

  Table('plans', [
    Column.text('code'),     // 'free' | 'premium'
    Column.text('name_pt'),
    Column.text('name_es'),
    Column.integer('active'),
  ]),

  Table('subscriptions', [
    Column.text('user_id'),
    Column.text('provider'),          // 'mercadopago'
    Column.text('provider_ref'),
    Column.text('status'),            // 'active' | 'pending' | 'cancelled'
    Column.text('current_period_end'),
    Column.text('created_at'),
  ]),

  Table('entitlements', [
    Column.text('user_id'),
    Column.text('plan_code'),
    Column.integer('active'),
    Column.text('starts_at'),
    Column.text('ends_at'),
    Column.text('updated_at'),
  ]),

  // ─── User activity ────────────────────────────────────────────────────────

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
    Column.text('last_opened_at'),
  ]),

  // ─── Local-only ───────────────────────────────────────────────────────────
  // Tracks which media files are cached on disk.
  // Never synced to Supabase. Managed entirely by MediaCacheManager.

  Table('media_cache_entries', [
    Column.text('asset_id'),
    Column.text('local_path'),
    Column.integer('file_size_bytes'),
    Column.text('downloaded_at'),
    Column.text('last_accessed_at'),
  ], localOnly: true),
]);
