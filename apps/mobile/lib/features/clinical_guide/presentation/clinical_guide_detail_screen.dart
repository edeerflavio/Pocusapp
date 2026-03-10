import 'package:flutter/material.dart';

import '../data/models/clinical_guide.dart';
import '../data/models/clinical_guide_content.dart';

// ---------------------------------------------------------------------------
// ClinicalGuideDetailScreen
// Route: /guide/detail/:slug   receives ClinicalGuide via GoRouter extra.
// ---------------------------------------------------------------------------

class ClinicalGuideDetailScreen extends StatelessWidget {
  const ClinicalGuideDetailScreen({super.key, required this.guide});

  final ClinicalGuide guide;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        title: Text(
          guide.title,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SummaryHeader(guide: guide),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: Column(
                  children: [
                    _DiagnosisSection(d: guide.content.diagnosis),
                    const SizedBox(height: 8),
                    _SeveritySection(s: guide.content.severity),
                    const SizedBox(height: 8),
                    _TreatmentSection(t: guide.content.treatment),
                    const SizedBox(height: 8),
                    _DischargeSection(
                      redFlags: guide.content.redFlags,
                      dischargeCriteria: guide.content.dischargeCriteria,
                      followUp: guide.content.followUp,
                    ),
                  ],
                ),
              ),
            ),
            _SourceFooter(guide: guide),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary header card
// ---------------------------------------------------------------------------

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.guide});
  final ClinicalGuide guide;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _ScenarioBadge(scenario: guide.scenario),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  guide.specialty,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            guide.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.15)),
            ),
            child: Text(
              guide.summary,
              style: const TextStyle(
                  fontSize: 14, color: Colors.black87, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioBadge extends StatelessWidget {
  const _ScenarioBadge({required this.scenario});
  final String scenario;

  static const _meta = {
    'emergencia': (label: 'Emergência', color: Color(0xFFC62828)),
    'enfermaria': (label: 'Enfermaria', color: Color(0xFF1565C0)),
    'ubs':        (label: 'UBS / APS',  color: Color(0xFF2E7D32)),
    'geral':      (label: 'Geral',      color: Color(0xFF546E7A)),
  };

  @override
  Widget build(BuildContext context) {
    final m = _meta[scenario] ??
        (label: 'Geral', color: const Color(0xFF546E7A));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: m.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        m.label.toUpperCase(),
        style: TextStyle(
          color: m.color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared section card wrapper
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: Colors.black12,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon, color: iconColor, size: 22),
        title: Text(
          title,
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Colors.black87),
        ),
        iconColor: Colors.grey[600],
        collapsedIconColor: Colors.grey[400],
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bullet list helper
// ---------------------------------------------------------------------------

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items, this.bulletColor});
  final List<String> items;
  final Color? bulletColor;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((text) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color:
                              bulletColor ?? Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _SubLabel extends StatelessWidget {
  const _SubLabel({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Diagnóstico
// ---------------------------------------------------------------------------

class _DiagnosisSection extends StatelessWidget {
  const _DiagnosisSection({required this.d});
  final DiagnosisSection d;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.biotech_outlined,
      iconColor: const Color(0xFF1565C0),
      title: 'Diagnóstico',
      initiallyExpanded: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (d.clinicalCriteria.isNotEmpty) ...[
            const _SubLabel(
                icon: Icons.person_outline,
                label: 'Critérios Clínicos',
                color: Color(0xFF1565C0)),
            _BulletList(items: d.clinicalCriteria),
            const SizedBox(height: 10),
          ],
          if (d.labFindings.isNotEmpty) ...[
            const _SubLabel(
                icon: Icons.science_outlined,
                label: 'Exames Laboratoriais',
                color: Color(0xFF6A1B9A)),
            _BulletList(items: d.labFindings),
            const SizedBox(height: 10),
          ],
          if (d.imaging.isNotEmpty) ...[
            const _SubLabel(
                icon: Icons.image_search_outlined,
                label: 'Imagem',
                color: Color(0xFF00695C)),
            _BulletList(items: d.imaging),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Estratificação de Gravidade
// ---------------------------------------------------------------------------

class _SeveritySection extends StatelessWidget {
  const _SeveritySection({required this.s});
  final SeveritySection s;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.monitor_heart_outlined,
      iconColor: const Color(0xFFE65100),
      title: 'Estratificação — ${s.tool.isEmpty ? "Gravidade" : s.tool}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (s.description.isNotEmpty) ...[
            Text(s.description,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey[700], height: 1.4)),
            const SizedBox(height: 14),
          ],
          if (s.criteria.isNotEmpty) ...[
            const _SubLabel(
                icon: Icons.checklist_outlined,
                label: 'Critérios',
                color: Color(0xFFE65100)),
            _BulletList(items: s.criteria),
            const SizedBox(height: 14),
          ],
          if (s.scores.isNotEmpty) ...[
            const _SubLabel(
                icon: Icons.bar_chart,
                label: 'Interpretação da Pontuação',
                color: Color(0xFFE65100)),
            const SizedBox(height: 4),
            ...s.scores.map((score) => _ScoreRow(score: score)),
          ],
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.score});
  final SeverityScore score;

  Color get _color {
    if (score.range.contains('0') && !score.range.contains('3')) {
      return const Color(0xFF2E7D32);
    } else if (score.range.contains('2')) {
      return const Color(0xFFE65100);
    }
    return const Color(0xFFC62828);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              score.range,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(score.risk,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _color)),
                const SizedBox(height: 2),
                Text(score.recommendation,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tratamento
// ---------------------------------------------------------------------------

class _TreatmentSection extends StatelessWidget {
  const _TreatmentSection({required this.t});
  final TreatmentSection t;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.medication_outlined,
      iconColor: const Color(0xFF00695C),
      title: 'Tratamento',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (t.outpatient.title.isNotEmpty)
            _TreatmentSubCard(sub: t.outpatient,
                accentColor: const Color(0xFF2E7D32)),
          if (t.inpatient.title.isNotEmpty) ...[
            const SizedBox(height: 12),
            _TreatmentSubCard(sub: t.inpatient,
                accentColor: const Color(0xFF1565C0)),
          ],
          if (t.icu.title.isNotEmpty) ...[
            const SizedBox(height: 12),
            _TreatmentSubCard(sub: t.icu,
                accentColor: const Color(0xFFC62828)),
          ],
        ],
      ),
    );
  }
}

class _TreatmentSubCard extends StatelessWidget {
  const _TreatmentSubCard({
    required this.sub,
    required this.accentColor,
  });
  final TreatmentSubsection sub;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(sub.title,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: accentColor)),
          if (sub.firstLine.isNotEmpty) ...[
            const SizedBox(height: 8),
            _BulletList(
                items: sub.firstLine,
                bulletColor: accentColor),
          ],
          if (sub.alternative.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Alternativa:',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600])),
            const SizedBox(height: 4),
            _BulletList(items: sub.alternative),
          ],
          if (sub.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(sub.note,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            height: 1.4)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Alta e Red Flags
// ---------------------------------------------------------------------------

class _DischargeSection extends StatelessWidget {
  const _DischargeSection({
    required this.redFlags,
    required this.dischargeCriteria,
    required this.followUp,
  });

  final List<String> redFlags;
  final List<String> dischargeCriteria;
  final String followUp;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.exit_to_app_outlined,
      iconColor: const Color(0xFF6A1B9A),
      title: 'Alta e Red Flags',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (redFlags.isNotEmpty) ...[
            const _SubLabel(
                icon: Icons.warning_amber_outlined,
                label: 'Red Flags — Sinais de Alarme',
                color: Color(0xFFC62828)),
            _BulletList(
                items: redFlags,
                bulletColor: const Color(0xFFC62828)),
            const SizedBox(height: 14),
          ],
          if (dischargeCriteria.isNotEmpty) ...[
            const _SubLabel(
                icon: Icons.check_circle_outline,
                label: 'Critérios de Alta',
                color: Color(0xFF2E7D32)),
            _BulletList(
                items: dischargeCriteria,
                bulletColor: const Color(0xFF2E7D32)),
            const SizedBox(height: 14),
          ],
          if (followUp.isNotEmpty) ...[
            const _SubLabel(
                icon: Icons.calendar_today_outlined,
                label: 'Seguimento',
                color: Color(0xFF1565C0)),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0xFF1565C0)
                        .withValues(alpha: 0.15)),
              ),
              child: Text(followUp,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.5)),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Source footer
// ---------------------------------------------------------------------------

class _SourceFooter extends StatelessWidget {
  const _SourceFooter({required this.guide});
  final ClinicalGuide guide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: Colors.grey[200]),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.menu_book_outlined,
                  size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Fonte: ${guide.source}',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey[500]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Versão ${guide.version}  ·  Atualizado automaticamente via sync',
            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}
