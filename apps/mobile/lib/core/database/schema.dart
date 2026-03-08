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
]);
