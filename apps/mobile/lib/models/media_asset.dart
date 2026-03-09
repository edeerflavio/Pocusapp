/// Represents a media asset (image or video) linked to a content item.
class MediaAsset {
  final String id;
  final String ownerType;
  final String ownerId;
  final String kind; // 'image' | 'video'
  final String path;
  final String? thumbPath;
  final DateTime createdAt;

  const MediaAsset({
    required this.id,
    required this.ownerType,
    required this.ownerId,
    required this.kind,
    required this.path,
    this.thumbPath,
    required this.createdAt,
  });

  factory MediaAsset.fromRow(Map<String, dynamic> row) {
    return MediaAsset(
      id: row['id'] as String,
      ownerType: row['owner_type'] as String,
      ownerId: row['owner_id'] as String,
      kind: row['kind'] as String,
      path: row['path'] as String,
      thumbPath: row['thumb_path'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
