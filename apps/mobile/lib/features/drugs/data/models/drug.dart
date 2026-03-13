/// A pharmaceutical drug synced offline via PowerSync from the `drugs` table.
class Drug {
  const Drug({
    required this.id,
    required this.slug,
    required this.titlePt,
    required this.titleEs,
    required this.bodyPt,
    required this.bodyEs,
    required this.isPremium,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final String slug;
  final String titlePt;
  final String titleEs;
  final String bodyPt;
  final String bodyEs;
  final bool isPremium;
  final String status;
  final String updatedAt;

  /// Display title (Portuguese).
  String get title => titlePt;

  /// Display body (Portuguese markdown).
  String get body => bodyPt;

  /// First letter of the title, uppercase — used for alphabetical grouping.
  String get indexLetter {
    if (titlePt.isEmpty) return '#';
    final first = titlePt[0].toUpperCase();
    return RegExp(r'[A-Z]').hasMatch(first) ? first : '#';
  }

  factory Drug.fromRow(Map<String, dynamic> row) => Drug(
        id: row['id'] as String,
        slug: row['slug'] as String? ?? '',
        titlePt: row['title_pt'] as String? ?? '',
        titleEs: row['title_es'] as String? ?? '',
        bodyPt: row['body_pt'] as String? ?? '',
        bodyEs: row['body_es'] as String? ?? '',
        isPremium: (row['is_premium'] as int? ?? 0) == 1,
        status: row['status'] as String? ?? 'published',
        updatedAt: row['updated_at'] as String? ?? '',
      );
}
