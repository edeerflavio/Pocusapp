import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_asset.freezed.dart';

@freezed
class MediaAsset with _$MediaAsset {
  const factory MediaAsset({
    required String id,
    required String ownerType,
    required String ownerId,
    required String kind,      // 'image' | 'video'
    required String path,      // Supabase Storage path
    String? thumbPath,
  }) = _MediaAsset;

  factory MediaAsset.fromRow(Map<String, dynamic> row) => MediaAsset(
        id: row['id'] as String,
        ownerType: row['owner_type'] as String,
        ownerId: row['owner_id'] as String,
        kind: row['kind'] as String,
        path: row['path'] as String,
        thumbPath: row['thumb_path'] as String?,
      );
}
