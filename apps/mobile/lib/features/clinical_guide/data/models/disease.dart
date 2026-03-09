import 'package:freezed_annotation/freezed_annotation.dart';

part 'disease.freezed.dart';

@freezed
class Disease with _$Disease {
  const factory Disease({
    required String id,
    required String titlePt,
    required String description,
    required String cid,
    required String treatment,
  }) = _Disease;

  factory Disease.fromRow(Map<String, dynamic> row) => Disease(
        id: row['id'] as String,
        titlePt: row['title_pt'] as String? ?? '',
        description: row['description'] as String? ?? '',
        cid: row['cid'] as String? ?? '',
        treatment: row['treatment'] as String? ?? '',
      );
}
