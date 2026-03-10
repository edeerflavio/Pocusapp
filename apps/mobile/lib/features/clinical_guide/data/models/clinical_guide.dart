import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'clinical_guide_content.dart';

part 'clinical_guide.freezed.dart';

@freezed
class ClinicalGuide with _$ClinicalGuide {
  const factory ClinicalGuide({
    required String id,
    required String slug,
    required String title,
    required String scenario,   // 'emergencia' | 'enfermaria' | 'ubs' | 'geral'
    required String specialty,
    required String summary,
    required ClinicalGuideContent content,
    required List<String> tags,
    required String source,
    required String version,
    required String status,
  }) = _ClinicalGuide;

  factory ClinicalGuide.fromRow(Map<String, dynamic> row) {
    final rawContent = row['content_json'] as String? ?? '{}';
    final rawTags    = row['tags']         as String? ?? '[]';

    ClinicalGuideContent content;
    try {
      content = ClinicalGuideContent.fromJson(
          jsonDecode(rawContent) as Map<String, dynamic>);
    } catch (_) {
      content = ClinicalGuideContent.empty();
    }

    List<String> tags;
    try {
      tags = List<String>.from(jsonDecode(rawTags) as List);
    } catch (_) {
      tags = const [];
    }

    return ClinicalGuide(
      id:        row['id']        as String,
      slug:      row['slug']      as String? ?? '',
      title:     row['title']     as String? ?? '',
      scenario:  row['scenario']  as String? ?? 'geral',
      specialty: row['specialty'] as String? ?? '',
      summary:   row['summary']   as String? ?? '',
      content:   content,
      tags:      tags,
      source:    row['source']    as String? ?? '',
      version:   row['version']   as String? ?? '1.0',
      status:    row['status']    as String? ?? 'published',
    );
  }
}
