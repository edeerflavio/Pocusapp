import 'clinical_guide.dart';

/// A [ClinicalGuide] enriched with its hierarchical context.
///
/// Used to power global search results — the breadcrumb lets the user
/// understand where the content sits in the category tree without
/// having to navigate manually.
final class GuideSearchResult {
  const GuideSearchResult({
    required this.guide,
    this.categoryTitle,
    this.topicTitle,
  });

  final ClinicalGuide guide;

  /// Top-level category name, if a matching category was found.
  final String? categoryTitle;

  /// Topic name within the category, if a matching topic was found.
  final String? topicTitle;

  /// Formatted breadcrumb for display (e.g. "Medicina Interna › Pneumologia").
  /// Returns `null` when no category could be inferred.
  String? get breadcrumb {
    if (categoryTitle == null) return null;
    if (topicTitle == null) return categoryTitle;
    return '$categoryTitle › $topicTitle';
  }
}
