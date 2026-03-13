import 'package:flutter/material.dart';

import 'models/clinical_category.dart';
import 'models/clinical_guide.dart';
import 'models/guide_search_result.dart';

/// Static catalogue of clinical categories, topics, and the logic to:
/// - match guides to topics (for the topic-filtered list screen)
/// - build a flat search index (for global search)
/// - filter the index by a text query
///
/// Matching rules (since Phase 8):
/// - **Folder structure**: uses ONLY `specialty` (exact) and `tags` (exact).
/// - **Search bar**: uses title + specialty + summary + tags (substring).
/// - `content_json` / `body` are NEVER used for folder categorisation.
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
  /// This is the ONLY place where broad substring matching is appropriate.
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
// specialtyKeywords: full exact specialty names (lowercased).
// tagKeywords: full exact tag values (lowercased).
// No prefixes, no substrings — prevents false positives like "ira" ⊂ "respiratória".

// ── Medicina Interna ──────────────────────────────────────────────────────

const _medicinaInterna = ClinicalCategory(
  id: 'medicina_interna',
  title: 'Medicina Interna',
  subtitle: 'Cardiologia, Pneumologia, Neurologia e mais',
  icon: Icons.local_hospital_outlined,
  color: Color(0xFF004D40),
  topics: [
    ClinicalTopic(
      id: 'cardiologia',
      categoryId: 'medicina_interna',
      title: 'Cardiologia',
      specialtyKeywords: ['cardiologia'],
      tagKeywords: [
        'cardiologia', 'iam', 'infarto', 'coronariana', 'arritmia', 'angina',
        'insuficiencia cardiaca', 'insuficiência cardíaca',
        'taquicardia', 'bradicardia', 'fibrilacao atrial', 'fibrilação atrial',
        'edema agudo de pulmao', 'edema agudo de pulmão', 'eap',
        'sindrome coronariana', 'síndrome coronariana',
      ],
    ),
    ClinicalTopic(
      id: 'pneumologia',
      categoryId: 'medicina_interna',
      title: 'Pneumologia',
      specialtyKeywords: ['pneumologia'],
      tagKeywords: [
        'pneumologia', 'pneumonia', 'dpoc', 'asma', 'derrame pleural',
        'bronquite', 'tosse', 'dispneia', 'embolia pulmonar',
        'tromboembolismo pulmonar', 'tep', 'insuficiencia respiratoria',
        'insuficiência respiratória',
      ],
    ),
    ClinicalTopic(
      id: 'neurologia',
      categoryId: 'medicina_interna',
      title: 'Neurologia',
      specialtyKeywords: ['neurologia'],
      tagKeywords: [
        'neurologia', 'avc', 'stroke', 'cefaleia', 'enxaqueca', 'epilepsia',
        'convulsao', 'convulsão', 'coma', 'meningite', 'estado de mal epileptico',
      ],
    ),
    ClinicalTopic(
      id: 'gastroenterologia',
      categoryId: 'medicina_interna',
      title: 'Gastroenterologia',
      specialtyKeywords: ['gastroenterologia', 'hepatologia'],
      tagKeywords: [
        'gastroenterologia', 'hepatite', 'cirrose', 'pancreatite',
        'diarreia', 'hemorragia digestiva', 'sangramento gastrointestinal',
        'doenca hepatica', 'doença hepática',
      ],
    ),
    ClinicalTopic(
      id: 'infectologia',
      categoryId: 'medicina_interna',
      title: 'Infectologia',
      specialtyKeywords: ['infectologia'],
      tagKeywords: [
        'infectologia', 'sepse', 'meningite', 'dengue', 'malaria', 'malária',
        'infeccao', 'infecção', 'endocardite', 'tuberculose',
        'hiv', 'aids', 'leptospirose',
      ],
    ),
    ClinicalTopic(
      id: 'endocrinologia',
      categoryId: 'medicina_interna',
      title: 'Endocrinologia',
      specialtyKeywords: ['endocrinologia'],
      tagKeywords: [
        'endocrinologia', 'diabetes', 'cetoacidose diabetica',
        'cetoacidose diabética', 'cad',
        'hipoglicemia', 'hiperglicemia', 'tireoidite', 'hipotireoidismo',
        'hipertireoidismo', 'crise tireotoxica', 'crise tireotóxica',
        'insuficiencia adrenal', 'insuficiência adrenal',
      ],
    ),
    ClinicalTopic(
      id: 'nefrologia',
      categoryId: 'medicina_interna',
      title: 'Nefrologia',
      specialtyKeywords: ['nefrologia'],
      tagKeywords: [
        'nefrologia', 'insuficiencia renal aguda', 'insuficiência renal aguda',
        'insuficiencia renal cronica', 'insuficiência renal crônica',
        'ira', 'irc', 'dialise', 'diálise', 'hipercalemia', 'hipocalemia',
        'glomerulonefrite', 'sindrome nefrotica', 'síndrome nefrótica',
      ],
    ),
    ClinicalTopic(
      id: 'reumatologia',
      categoryId: 'medicina_interna',
      title: 'Reumatologia',
      specialtyKeywords: ['reumatologia'],
      tagKeywords: [
        'reumatologia', 'artrite reumatoide', 'artrite reumatóide',
        'lupus', 'lúpus', 'gota', 'fibromialgia', 'vasculite',
        'espondilite', 'esclerose sistemica', 'esclerose sistêmica',
      ],
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
      specialtyKeywords: ['emergencia cardiovascular', 'emergência cardiovascular'],
      tagKeywords: [
        'pcr', 'rcp', 'parada cardiorrespiratoria', 'parada cardiorrespiratória',
        'fibrilacao ventricular', 'fibrilação ventricular',
        'taquicardia ventricular', 'choque cardiogenico', 'choque cardiogênico',
        'acls',
      ],
    ),
    ClinicalTopic(
      id: 'em_choque',
      categoryId: 'emergencia_uti',
      title: 'Choque e Hemodinâmica',
      specialtyKeywords: ['medicina intensiva', 'terapia intensiva'],
      tagKeywords: [
        'choque', 'choque septico', 'choque séptico',
        'choque hipovolemico', 'choque hipovolêmico',
        'choque distributivo', 'choque obstrutivo',
        'vasopressor', 'noradrenalina', 'hipotensao', 'hipotensão',
        'lactato', 'hemodinamica', 'hemodinâmica',
      ],
    ),
    ClinicalTopic(
      id: 'em_via_aerea',
      categoryId: 'emergencia_uti',
      title: 'Via Aérea',
      specialtyKeywords: ['anestesiologia'],
      tagKeywords: [
        'intubacao', 'intubação', 'via aerea', 'via aérea',
        'cricotireoidostomia', 'ventilacao mecanica', 'ventilação mecânica',
        'laringoscopia', 'sequencia rapida de intubacao',
        'sequência rápida de intubação', 'rsi',
      ],
    ),
    ClinicalTopic(
      id: 'em_infecciosas',
      categoryId: 'emergencia_uti',
      title: 'Infecciosas Críticas',
      specialtyKeywords: ['infectologia'],
      tagKeywords: [
        'sepse', 'choque septico', 'choque séptico',
        'meningite bacteriana', 'encefalite',
        'antibiotico empirico', 'antibiótico empírico',
        'fasciite necrotizante',
      ],
    ),
    ClinicalTopic(
      id: 'em_trauma',
      categoryId: 'emergencia_uti',
      title: 'Trauma',
      specialtyKeywords: ['traumatologia', 'cirurgia do trauma'],
      tagKeywords: [
        'trauma', 'tce', 'traumatismo cranioencefalico',
        'traumatismo cranioencefálico',
        'trauma toracico', 'trauma torácico',
        'trauma abdominal', 'hemorragia', 'atls', 'politrauma',
        'fast', 'efast',
      ],
    ),
    ClinicalTopic(
      id: 'em_procedimentos',
      categoryId: 'emergencia_uti',
      title: 'Procedimentos',
      specialtyKeywords: [],
      tagKeywords: [
        'acesso venoso central', 'drenagem toracica', 'drenagem torácica',
        'paracentese', 'toracocentese', 'pericardiocentese',
        'procedimento', 'punção lombar',
      ],
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
      specialtyKeywords: ['pediatria'],
      tagKeywords: ['pediatria', 'pediatrica', 'pediátrica'],
    ),
    ClinicalTopic(
      id: 'ped_neonatologia',
      categoryId: 'pediatria',
      title: 'Neonatologia',
      specialtyKeywords: ['neonatologia'],
      tagKeywords: [
        'neonatologia', 'neonato', 'recem-nascido', 'recém-nascido',
        'prematuro', 'prematuridade',
      ],
    ),
    ClinicalTopic(
      id: 'ped_infecciosas',
      categoryId: 'pediatria',
      title: 'Infecciosas Pediátricas',
      specialtyKeywords: ['infectologia pediatrica', 'infectologia pediátrica'],
      tagKeywords: [
        'otite', 'amigdalite', 'bronquiolite', 'croup', 'crupe',
        'febre pediatrica', 'febre pediátrica',
        'meningite pediatrica', 'meningite pediátrica',
      ],
    ),
    ClinicalTopic(
      id: 'ped_respiratorio',
      categoryId: 'pediatria',
      title: 'Respiratório Pediátrico',
      specialtyKeywords: ['pneumologia pediatrica', 'pneumologia pediátrica'],
      tagKeywords: [
        'asma pediatrica', 'asma pediátrica', 'bronquiolite',
        'pneumonia pediatrica', 'pneumonia pediátrica',
        'insuficiencia respiratoria pediatrica',
      ],
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
      specialtyKeywords: ['cirurgia geral', 'cirurgia'],
      tagKeywords: [
        'cirurgia geral', 'pos-operatorio', 'pós-operatório',
        'laparoscopia', 'laparotomia',
      ],
    ),
    ClinicalTopic(
      id: 'cir_abdome',
      categoryId: 'cirurgia',
      title: 'Abdome Agudo',
      specialtyKeywords: ['cirurgia geral'],
      tagKeywords: [
        'abdome agudo', 'apendicite', 'colecistite',
        'obstrucao intestinal', 'obstrução intestinal',
        'perfuracao', 'perfuração', 'peritonite',
      ],
    ),
    ClinicalTopic(
      id: 'cir_vascular',
      categoryId: 'cirurgia',
      title: 'Cirurgia Vascular',
      specialtyKeywords: ['cirurgia vascular'],
      tagKeywords: [
        'cirurgia vascular', 'aneurisma de aorta',
        'isquemia de membro', 'trombose venosa profunda', 'tvp',
        'embolia arterial',
      ],
    ),
  ],
);
