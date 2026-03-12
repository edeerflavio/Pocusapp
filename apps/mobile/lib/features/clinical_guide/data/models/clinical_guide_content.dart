// ---------------------------------------------------------------------------
// ClinicalGuideContent — structured sections parsed from content_json.
// Plain Dart classes (no codegen) — fromJson handles missing keys gracefully.
// ---------------------------------------------------------------------------

class ClinicalGuideContent {
  const ClinicalGuideContent({
    required this.diagnosis,
    required this.severity,
    required this.treatment,
    required this.redFlags,
    required this.dischargeCriteria,
    required this.followUp,
    required this.references,
  });

  final DiagnosisSection diagnosis;
  final SeveritySection severity;
  final TreatmentSection treatment;
  final List<String> redFlags;
  final List<String> dischargeCriteria;
  final String followUp;
  final List<GuideReference> references;

  static ClinicalGuideContent empty() => ClinicalGuideContent(
        diagnosis: DiagnosisSection.empty(),
        severity: SeveritySection.empty(),
        treatment: TreatmentSection.empty(),
        redFlags: const [],
        dischargeCriteria: const [],
        followUp: '',
        references: const [],
      );

  factory ClinicalGuideContent.fromJson(Map<String, dynamic> json) {
    return ClinicalGuideContent(
      diagnosis: DiagnosisSection.fromJson(
          json['diagnosis'] as Map<String, dynamic>? ?? {}),
      severity: SeveritySection.fromJson(
          json['severity'] as Map<String, dynamic>? ?? {}),
      treatment: TreatmentSection.fromJson(
          json['treatment'] as Map<String, dynamic>? ?? {}),
      redFlags: _strings(json['red_flags']),
      dischargeCriteria: _strings(json['discharge_criteria']),
      followUp: json['follow_up'] as String? ?? '',
      references: json['references'] == null
          ? []
          : (json['references'] as List)
              .map((e) => GuideReference.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }

  static List<String> _strings(dynamic value) =>
      value == null ? [] : List<String>.from(value as List);
}

// ---------------------------------------------------------------------------

class DiagnosisSection {
  const DiagnosisSection({
    required this.clinicalCriteria,
    required this.labFindings,
    required this.imaging,
  });

  final List<String> clinicalCriteria;
  final List<String> labFindings;
  final List<String> imaging;

  static DiagnosisSection empty() => const DiagnosisSection(
      clinicalCriteria: [], labFindings: [], imaging: []);

  factory DiagnosisSection.fromJson(Map<String, dynamic> json) =>
      DiagnosisSection(
        clinicalCriteria: _str(json['clinical_criteria']),
        labFindings: _str(json['lab_findings']),
        imaging: _str(json['imaging']),
      );

  static List<String> _str(dynamic v) =>
      v == null ? [] : List<String>.from(v as List);
}

// ---------------------------------------------------------------------------

class SeveritySection {
  const SeveritySection({
    required this.tool,
    required this.description,
    required this.criteria,
    required this.scores,
  });

  final String tool;
  final String description;
  final List<String> criteria;
  final List<SeverityScore> scores;

  static SeveritySection empty() => const SeveritySection(
      tool: '', description: '', criteria: [], scores: []);

  factory SeveritySection.fromJson(Map<String, dynamic> json) =>
      SeveritySection(
        tool: json['tool'] as String? ?? '',
        description: json['description'] as String? ?? '',
        criteria: json['criteria'] == null
            ? []
            : List<String>.from(json['criteria'] as List),
        scores: json['scores'] == null
            ? []
            : (json['scores'] as List)
                .map((e) =>
                    SeverityScore.fromJson(e as Map<String, dynamic>))
                .toList(),
      );
}

class SeverityScore {
  const SeverityScore({
    required this.range,
    required this.risk,
    required this.recommendation,
  });

  final String range;
  final String risk;
  final String recommendation;

  factory SeverityScore.fromJson(Map<String, dynamic> json) => SeverityScore(
        range: json['range'] as String? ?? '',
        risk: json['risk'] as String? ?? '',
        recommendation: json['recommendation'] as String? ?? '',
      );
}

// ---------------------------------------------------------------------------

class TreatmentSection {
  const TreatmentSection({
    required this.outpatient,
    required this.inpatient,
    required this.icu,
  });

  final TreatmentSubsection outpatient;
  final TreatmentSubsection inpatient;
  final TreatmentSubsection icu;

  static TreatmentSection empty() => TreatmentSection(
        outpatient: TreatmentSubsection.empty(),
        inpatient: TreatmentSubsection.empty(),
        icu: TreatmentSubsection.empty(),
      );

  factory TreatmentSection.fromJson(Map<String, dynamic> json) =>
      TreatmentSection(
        outpatient: TreatmentSubsection.fromJson(
            json['outpatient'] as Map<String, dynamic>? ?? {}),
        inpatient: TreatmentSubsection.fromJson(
            json['inpatient'] as Map<String, dynamic>? ?? {}),
        icu: TreatmentSubsection.fromJson(
            json['icu'] as Map<String, dynamic>? ?? {}),
      );
}

class TreatmentSubsection {
  const TreatmentSubsection({
    required this.title,
    required this.firstLine,
    required this.alternative,
    required this.note,
  });

  final String title;
  final List<String> firstLine;
  final List<String> alternative;
  final String note;

  static TreatmentSubsection empty() => const TreatmentSubsection(
      title: '', firstLine: [], alternative: [], note: '');

  factory TreatmentSubsection.fromJson(Map<String, dynamic> json) =>
      TreatmentSubsection(
        title: json['title'] as String? ?? '',
        firstLine: _str(json['first_line']),
        alternative: _str(json['alternative']),
        note: json['note'] as String? ?? '',
      );

  static List<String> _str(dynamic v) =>
      v == null ? [] : List<String>.from(v as List);
}

// ---------------------------------------------------------------------------

class GuideReference {
  const GuideReference({
    required this.citation,
    required this.year,
    this.url,
  });

  final String citation;
  final String year;
  final String? url;

  factory GuideReference.fromJson(Map<String, dynamic> json) => GuideReference(
        citation: json['citation'] as String? ?? '',
        year: json['year'] as String? ?? '',
        url: json['url'] as String?,
      );
}
