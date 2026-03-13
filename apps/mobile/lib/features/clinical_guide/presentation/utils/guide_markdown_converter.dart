import '../../data/models/clinical_guide_content.dart';

/// Converts the structured [ClinicalGuideContent] (stored as JSON in PowerSync)
/// into a Markdown string divided by `### ` headers.
///
/// Each `### ` section becomes an [ExpansionTile] accordion in the detail screen
/// via the shared [parseMarkdownBody] parser. Subsections use `#### `.
///
/// Emoji prefixes in the header are intentional — they:
///   - provide quick visual cues for stressed clinicians
///   - drive the "critical section" detection (⚠️ → red left border)
///
/// This converter is a pure function of the content model.
/// No Flutter/UI imports — fully testable without a widget tree.
abstract final class GuideMarkdownConverter {
  static String convert(ClinicalGuideContent c) {
    final sb = StringBuffer();
    _diagnosis(sb, c.diagnosis);
    _severity(sb, c.severity);
    _treatment(sb, c.treatment);
    _redFlags(sb, c.redFlags);
    _discharge(sb, c.dischargeCriteria, c.followUp);
    _references(sb, c.references);
    return sb.toString().trimRight();
  }

  // ── Diagnóstico ──────────────────────────────────────────────────────────

  static void _diagnosis(StringBuffer sb, DiagnosisSection d) {
    final hasContent = d.clinicalCriteria.isNotEmpty ||
        d.labFindings.isNotEmpty ||
        d.imaging.isNotEmpty;
    if (!hasContent) return;

    sb.writeln('### 🩺 Diagnóstico');
    sb.writeln();

    if (d.clinicalCriteria.isNotEmpty) {
      sb.writeln('#### Critérios Clínicos');
      for (final item in d.clinicalCriteria) {
        sb.writeln('- $item');
      }
      sb.writeln();
    }

    if (d.labFindings.isNotEmpty) {
      sb.writeln('#### Exames Laboratoriais');
      for (final item in d.labFindings) {
        sb.writeln('- $item');
      }
      sb.writeln();
    }

    if (d.imaging.isNotEmpty) {
      sb.writeln('#### Imagem');
      for (final item in d.imaging) {
        sb.writeln('- $item');
      }
      sb.writeln();
    }
  }

  // ── Estratificação de Gravidade ───────────────────────────────────────────

  static void _severity(StringBuffer sb, SeveritySection s) {
    final hasContent = s.tool.isNotEmpty ||
        s.description.isNotEmpty ||
        s.criteria.isNotEmpty ||
        s.scores.isNotEmpty;
    if (!hasContent) return;

    final toolSuffix = s.tool.isNotEmpty ? ' — ${s.tool}' : '';
    sb.writeln('### ⚡ Estratificação$toolSuffix');
    sb.writeln();

    if (s.description.isNotEmpty) {
      sb.writeln(s.description);
      sb.writeln();
    }

    if (s.criteria.isNotEmpty) {
      sb.writeln('#### Critérios de Gravidade');
      for (final item in s.criteria) {
        sb.writeln('- $item');
      }
      sb.writeln();
    }

    if (s.scores.isNotEmpty) {
      sb.writeln('#### Pontuação e Conduta');
      sb.writeln();
      for (final score in s.scores) {
        sb.writeln('**${score.range}** · **${score.risk}**');
        sb.writeln();
        sb.writeln('${score.recommendation}');
        sb.writeln();
      }
    }
  }

  // ── Tratamento ────────────────────────────────────────────────────────────

  static void _treatment(StringBuffer sb, TreatmentSection t) {
    final hasContent = t.outpatient.title.isNotEmpty ||
        t.inpatient.title.isNotEmpty ||
        t.icu.title.isNotEmpty;
    if (!hasContent) return;

    sb.writeln('### 💊 Tratamento');
    sb.writeln();
    _subsection(sb, t.outpatient);
    _subsection(sb, t.inpatient);
    _subsection(sb, t.icu);
  }

  static void _subsection(StringBuffer sb, TreatmentSubsection sub) {
    if (sub.title.isEmpty && sub.firstLine.isEmpty) return;

    if (sub.title.isNotEmpty) {
      sb.writeln('#### ${sub.title}');
      sb.writeln();
    }

    if (sub.firstLine.isNotEmpty) {
      sb.writeln('**Primeira linha:**');
      sb.writeln();
      for (final item in sub.firstLine) {
        sb.writeln('- $item');
      }
      sb.writeln();
    }

    if (sub.alternative.isNotEmpty) {
      sb.writeln('**Alternativas:**');
      sb.writeln();
      for (final item in sub.alternative) {
        sb.writeln('- $item');
      }
      sb.writeln();
    }

    if (sub.note.isNotEmpty) {
      sb.writeln('> 💡 ${sub.note}');
      sb.writeln();
    }
  }

  // ── Red Flags ─────────────────────────────────────────────────────────────

  static void _redFlags(StringBuffer sb, List<String> flags) {
    if (flags.isEmpty) return;
    sb.writeln('### ⚠️ Red Flags — Sinais de Alarme');
    sb.writeln();
    for (final item in flags) {
      sb.writeln('- $item');
    }
    sb.writeln();
  }

  // ── Alta e Seguimento ─────────────────────────────────────────────────────

  static void _discharge(
    StringBuffer sb,
    List<String> criteria,
    String followUp,
  ) {
    if (criteria.isEmpty && followUp.isEmpty) return;
    sb.writeln('### 🏥 Alta e Seguimento');
    sb.writeln();

    if (criteria.isNotEmpty) {
      sb.writeln('#### Critérios de Alta');
      for (final item in criteria) {
        sb.writeln('- $item');
      }
      sb.writeln();
    }

    if (followUp.isNotEmpty) {
      sb.writeln('#### Seguimento');
      sb.writeln();
      sb.writeln(followUp);
      sb.writeln();
    }
  }

  // ── Referências ───────────────────────────────────────────────────────────

  static void _references(StringBuffer sb, List<GuideReference> refs) {
    if (refs.isEmpty) return;
    sb.writeln('### 📚 Referências');
    sb.writeln();
    for (var i = 0; i < refs.length; i++) {
      final ref = refs[i];
      final number = i + 1;
      if (ref.url != null && ref.url!.isNotEmpty) {
        sb.writeln('$number. ${ref.citation} (${ref.year}) — [link](${ref.url})');
      } else {
        sb.writeln('$number. ${ref.citation} (${ref.year})');
      }
    }
    sb.writeln();
  }
}
