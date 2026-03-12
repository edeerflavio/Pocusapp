import 'package:flutter/material.dart';

import 'models/clinical_category.dart';
import 'models/clinical_guide.dart';
import 'models/guide_search_result.dart';

/// Static catalogue of clinical categories, topics, and the logic to:
/// - match guides to topics (for the topic-filtered list screen)
/// - build a flat search index (for global search)
/// - filter the index by a text query
///
/// To add a new category or topic:
///   1. Add a [ClinicalTopic] constant with appropriate keywords
///   2. Include it in the parent [ClinicalCategory.topics] list
///   Done — no screen code changes required.
abstract final class ClinicalCatalog {
  // ─── Category / Topic definitions ─────────────────────────────────────────

  static const List<ClinicalCategory> categories = [
    _medicinaInterna,
    _emergenciaUti,
    _pediatria,
    _cirurgia,
  ];

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// All topics from all categories in definition order.
  static List<ClinicalTopic> get allTopics =>
      categories.expand((c) => c.topics).toList();

  /// Finds a [ClinicalCategory] by id, or null.
  static ClinicalCategory? findCategoryById(String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Finds a [ClinicalTopic] by id, or null.
  static ClinicalTopic? findTopicById(String id) {
    for (final t in allTopics) {
      if (t.id == id) return t;
    }
    return null;
  }

  /// Returns all [guide]s that match [topicId].
  static List<ClinicalGuide> guidesForTopic(
    String topicId,
    List<ClinicalGuide> allGuides,
  ) {
    final topic = findTopicById(topicId);
    if (topic == null) return allGuides;
    return allGuides.where(topic.matchesGuide).toList();
  }

  /// Builds a flat search index by assigning each guide its best-matching
  /// category + topic breadcrumb. Priority follows the order of [categories].
  ///
  /// Guides that match no topic still appear in the index (breadcrumb = null).
  static List<GuideSearchResult> buildSearchIndex(List<ClinicalGuide> guides) {
    final index = <GuideSearchResult>[];
    for (final guide in guides) {
      ClinicalCategory? cat;
      ClinicalTopic? topic;

      outer:
      for (final c in categories) {
        for (final t in c.topics) {
          if (t.matchesGuide(guide)) {
            cat = c;
            topic = t;
            break outer;
          }
        }
      }

      index.add(
        GuideSearchResult(
          guide: guide,
          categoryTitle: cat?.title,
          topicTitle: topic?.title,
        ),
      );
    }
    return index;
  }

  /// Filters a pre-built [index] by [query].
  ///
  /// Matches against title, specialty, tags, and summary so that users
  /// can type clinical terms ("pneumonia", "sepse") and find the right content.
  static List<GuideSearchResult> search(
    List<GuideSearchResult> index,
    String query,
  ) {
    if (query.isEmpty) return const [];
    final q = query.toLowerCase();
    return index.where((r) {
      final g = r.guide;
      if (g.title.toLowerCase().contains(q)) return true;
      if (g.specialty.toLowerCase().contains(q)) return true;
      if (g.summary.toLowerCase().contains(q)) return true;
      if (g.tags.any((t) => t.toLowerCase().contains(q))) return true;
      return false;
    }).toList();
  }
}

// ─── Static definitions ────────────────────────────────────────────────────
// Using top-level functions as executors allows const constructors.

// ── Medicina Interna ──────────────────────────────────────────────────────

const _medicinaInterna = ClinicalCategory(
  id: 'medicina_interna',
  title: 'Medicina Interna',
  subtitle: 'Cardiologia, Pneumologia, Neurologia e mais',
  icon: Icons.local_hospital_outlined,
  color: Color(0xFF1565C0),
  topics: [
    ClinicalTopic(
      id: 'cardiologia',
      categoryId: 'medicina_interna',
      title: 'Cardiologia',
      specialtyKeywords: ['cardiol', 'cardio', 'cardiaco'],
      tagKeywords: ['iam', 'infarto', 'coronar', 'arritmia', 'angina', 'cardiac',
                    'insuf', 'taquicardia', 'bradicardia', 'fibrilacao'],
    ),
    ClinicalTopic(
      id: 'pneumologia',
      categoryId: 'medicina_interna',
      title: 'Pneumologia',
      specialtyKeywords: ['pneumol', 'pulm', 'respirat'],
      tagKeywords: ['pneumonia', 'dpoc', 'asma', 'pleural', 'bronq', 'tosse',
                    'dispneia', 'pulmonar', 'respirator'],
    ),
    ClinicalTopic(
      id: 'neurologia',
      categoryId: 'medicina_interna',
      title: 'Neurologia',
      specialtyKeywords: ['neurol'],
      tagKeywords: ['avc', 'stroke', 'cefaleia', 'enxaqueca', 'epilepsia',
                    'convulsao', 'coma', 'neurolog'],
    ),
    ClinicalTopic(
      id: 'gastroenterologia',
      categoryId: 'medicina_interna',
      title: 'Gastroenterologia',
      specialtyKeywords: ['gastro', 'hepatol', 'digest'],
      tagKeywords: ['hepatite', 'cirrose', 'pancreat', 'diarreia', 'vomito',
                    'sangramento', 'gastrointestinal'],
    ),
    ClinicalTopic(
      id: 'infectologia',
      categoryId: 'medicina_interna',
      title: 'Infectologia',
      specialtyKeywords: ['infect'],
      tagKeywords: ['sepse', 'antibio', 'meningite', 'dengue', 'malaria',
                    'infeccao', 'bacteriana', 'viral', 'fungica'],
    ),
    ClinicalTopic(
      id: 'endocrinologia',
      categoryId: 'medicina_interna',
      title: 'Endocrinologia',
      specialtyKeywords: ['endocrin'],
      tagKeywords: ['diabetes', 'tireoid', 'insulina', 'hipoglicemia',
                    'hiperglicemia', 'adrenal', 'hormon'],
    ),
    ClinicalTopic(
      id: 'nefrologia',
      categoryId: 'medicina_interna',
      title: 'Nefrologia',
      specialtyKeywords: ['nefrol', 'renal'],
      tagKeywords: ['ira', 'irc', 'dialise', 'rim', 'proteinuria',
                    'glomerulo', 'tubular'],
    ),
    ClinicalTopic(
      id: 'reumatologia',
      categoryId: 'medicina_interna',
      title: 'Reumatologia',
      specialtyKeywords: ['reumat'],
      tagKeywords: ['artrite', 'lupus', 'artralgia', 'reumatoide',
                    'gota', 'fibromialgia'],
    ),
  ],
);

// ── Emergência e UTI ──────────────────────────────────────────────────────

const _emergenciaUti = ClinicalCategory(
  id: 'emergencia_uti',
  title: 'Emergência e UTI',
  subtitle: 'Protocolos críticos, choque e procedimentos',
  icon: Icons.monitor_heart_outlined,
  color: Color(0xFFC62828),
  topics: [
    ClinicalTopic(
      id: 'em_cardiovascular',
      categoryId: 'emergencia_uti',
      title: 'Cardiovascular',
      specialtyKeywords: ['cardiol'],
      tagKeywords: ['pcr', 'rcp', 'fibrilacao', 'choque cardiogenico',
                    'taquicardia ventricular', 'parada'],
    ),
    ClinicalTopic(
      id: 'em_choque',
      categoryId: 'emergencia_uti',
      title: 'Choque e Hemodinâmica',
      specialtyKeywords: ['intensiv', 'uti'],
      tagKeywords: ['choque', 'hemodi', 'vasopressor', 'noradren',
                    'hipotensao', 'perfusao', 'lactato'],
    ),
    ClinicalTopic(
      id: 'em_via_aerea',
      categoryId: 'emergencia_uti',
      title: 'Via Aérea',
      specialtyKeywords: ['anest'],
      tagKeywords: ['intubacao', 'via aerea', 'cricotiroid', 'ventilacao',
                    'laringoscopia', 'rsi', 'sequencia rapida'],
    ),
    ClinicalTopic(
      id: 'em_infecciosas',
      categoryId: 'emergencia_uti',
      title: 'Infecciosas Críticas',
      specialtyKeywords: ['infect'],
      tagKeywords: ['sepse', 'choque septico', 'meningite bacteriana',
                    'encefalite', 'antibiotico empirico'],
    ),
    ClinicalTopic(
      id: 'em_trauma',
      categoryId: 'emergencia_uti',
      title: 'Trauma',
      specialtyKeywords: ['trauma', 'cirurg'],
      tagKeywords: ['trauma', 'tce', 'torax', 'abdominal', 'hemorragia',
                    'atls', 'politrauma'],
    ),
    ClinicalTopic(
      id: 'em_procedimentos',
      categoryId: 'emergencia_uti',
      title: 'Procedimentos',
      specialtyKeywords: [],
      tagKeywords: ['acesso venoso', 'drenagem', 'paracentese',
                    'toracocentese', 'pericardiocentese'],
    ),
  ],
);

// ── Pediatria ─────────────────────────────────────────────────────────────

const _pediatria = ClinicalCategory(
  id: 'pediatria',
  title: 'Pediatria',
  subtitle: 'Pediatria geral, neonatologia e urgências',
  icon: Icons.child_care_outlined,
  color: Color(0xFF00695C),
  topics: [
    ClinicalTopic(
      id: 'ped_geral',
      categoryId: 'pediatria',
      title: 'Pediatria Geral',
      specialtyKeywords: ['pediat'],
      tagKeywords: ['crianca', 'lactente', 'pediatrica'],
    ),
    ClinicalTopic(
      id: 'ped_neonatologia',
      categoryId: 'pediatria',
      title: 'Neonatologia',
      specialtyKeywords: ['neonat'],
      tagKeywords: ['neonato', 'recem-nascido', 'rn', 'prematuro'],
    ),
    ClinicalTopic(
      id: 'ped_infecciosas',
      categoryId: 'pediatria',
      title: 'Infecciosas Pediátricas',
      specialtyKeywords: ['pediat', 'infect'],
      tagKeywords: ['febre pediatr', 'otite', 'amigdalite', 'bronquiolite',
                    'croup', 'meningite pediatr'],
    ),
    ClinicalTopic(
      id: 'ped_respiratorio',
      categoryId: 'pediatria',
      title: 'Respiratório Pediátrico',
      specialtyKeywords: ['pediat', 'pneumol'],
      tagKeywords: ['asma pediatr', 'bronquiolite', 'pneumonia pediatr',
                    'crupe', 'insuf respirat'],
    ),
  ],
);

// ── Cirurgia ──────────────────────────────────────────────────────────────

const _cirurgia = ClinicalCategory(
  id: 'cirurgia',
  title: 'Cirurgia',
  subtitle: 'Abdome agudo, trauma e pós-operatório',
  icon: Icons.medical_services_outlined,
  color: Color(0xFFE65100),
  topics: [
    ClinicalTopic(
      id: 'cir_geral',
      categoryId: 'cirurgia',
      title: 'Cirurgia Geral',
      specialtyKeywords: ['cirurg'],
      tagKeywords: ['cirurgia', 'operacao', 'pos-op', 'pos operatorio',
                    'laparoscop', 'laparotomia'],
    ),
    ClinicalTopic(
      id: 'cir_abdome',
      categoryId: 'cirurgia',
      title: 'Abdome Agudo',
      specialtyKeywords: ['cirurg'],
      tagKeywords: ['apendicite', 'colecistite', 'obstrucao', 'perfuracao',
                    'peritonite', 'abdome agudo'],
    ),
    ClinicalTopic(
      id: 'cir_vascular',
      categoryId: 'cirurgia',
      title: 'Cirurgia Vascular',
      specialtyKeywords: ['vascul'],
      tagKeywords: ['aorta', 'isquemia', 'aneurisma', 'trombose', 'embolia'],
    ),
  ],
);
