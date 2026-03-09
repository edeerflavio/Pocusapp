import 'package:freezed_annotation/freezed_annotation.dart';

part 'pocus_item.freezed.dart';

@freezed
class PocusItem with _$PocusItem {
  const factory PocusItem({
    required String id,
    required String category,
    required String titlePt,
    required String titleEs,
    required String bodyPt,
    required String bodyEs,
    required bool isPremium,
    required String status,
  }) = _PocusItem;

  factory PocusItem.fromRow(Map<String, dynamic> row) => PocusItem(
        id: row['id'] as String,
        category: row['category'] as String? ?? '',
        titlePt: row['title_pt'] as String? ?? '',
        titleEs: row['title_es'] as String? ?? '',
        bodyPt: row['body_pt'] as String? ?? '',
        bodyEs: row['body_es'] as String? ?? '',
        isPremium: (row['is_premium'] as int? ?? 0) == 1,
        status: row['status'] as String? ?? 'draft',
      );
}
