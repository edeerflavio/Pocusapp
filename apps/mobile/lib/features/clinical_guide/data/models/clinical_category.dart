import 'package:flutter/material.dart';

import 'clinical_guide.dart';

/// Static definition of a top-level clinical category (navigation node).
///
/// Categories are compile-time constants — no DB needed.
/// They act as the first level of the Guia Clínico hierarchy.
final class ClinicalCategory {
  const ClinicalCategory({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.topics,
  });

  final String id;
  final String title;

  /// Short description shown as subtitle in the hub list.
  final String subtitle;

  final IconData icon;
  final Color color;
  final List<ClinicalTopic> topics;
}

/// A clinical sub-area (topic) within a [ClinicalCategory].
///
/// Defines how to match [ClinicalGuide] items fetched from the database.
/// Matching is intentionally broad to tolerate variability in specialty strings
/// and tags entered in the DB.
final class ClinicalTopic {
  const ClinicalTopic({
    required this.id,
    required this.categoryId,
    required this.title,
    this.specialtyKeywords = const [],
    this.tagKeywords = const [],
  });

  final String id;
  final String categoryId;
  final String title;

  /// A guide matches if its `specialty` field (lowercased) contains
  /// any of these strings.
  final List<String> specialtyKeywords;

  /// A guide matches if any of its `tags` (lowercased) contains
  /// any of these strings.
  final List<String> tagKeywords;

  /// Returns true when [guide] belongs to this topic.
  bool matchesGuide(ClinicalGuide guide) {
    final specLower = guide.specialty.toLowerCase();
    if (specialtyKeywords.any((k) => specLower.contains(k))) return true;

    final tagsLower = guide.tags.map((t) => t.toLowerCase()).toList();
    if (tagKeywords.any((k) => tagsLower.any((t) => t.contains(k)))) {
      return true;
    }

    return false;
  }
}
