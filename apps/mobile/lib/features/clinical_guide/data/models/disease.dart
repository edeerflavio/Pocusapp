import 'package:freezed_annotation/freezed_annotation.dart';

part 'disease.freezed.dart';

@freezed
class Disease with _$Disease {
  const factory Disease({
    required String id,
    required String slug,
    required String titlePt,
    required String titleEs,
    required String bodyPt,
    required String bodyEs,
    required bool isPremium,
    required String status,
  }) = _Disease;

  factory Disease.fromRow(Map<String, dynamic> row) => Disease(
        id: row['id'] as String,
        slug: row['slug'] as String? ?? '',
        titlePt: row['title_pt'] as String? ?? '',
        titleEs: row['title_es'] as String? ?? '',
        bodyPt: row['body_pt'] as String? ?? '',
        bodyEs: row['body_es'] as String? ?? '',
        isPremium: (row['is_premium'] as int? ?? 0) == 1,
        status: row['status'] as String? ?? 'published',
      );
}
