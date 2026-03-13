import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/clinical_guide.dart';

/// Reusable card for displaying a [ClinicalGuide] in a list.
///
/// Tapping navigates to the guide's detail screen via `/guide/detail/:slug`.
class GuideCard extends StatelessWidget {
  const GuideCard({super.key, required this.guide});

  final ClinicalGuide guide;

  @override
  Widget build(BuildContext context) {
    final meta = _scenarioMeta[guide.scenario] ??
        (label: 'Geral', color: const Color(0xFF546E7A));

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/guide/detail/${guide.slug}', extra: guide),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: scenario chip + version
              Row(
                children: [
                  _ScenarioBadge(label: meta.label, color: meta.color),
                  const Spacer(),
                  Text(
                    'v${guide.version}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Title
              Text(
                guide.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              // Specialty
              Text(
                guide.specialty,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),
              // Summary preview
              Text(
                guide.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
              ),
              if (guide.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: guide.tags
                      .take(4)
                      .map((t) => _TagBadge(tag: t))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

const _scenarioMeta = {
  'emergencia': (label: 'Emergência', color: Color(0xFFC62828)),
  'enfermaria': (label: 'Enfermaria', color: Color(0xFF004D40)),
  'ubs': (label: 'UBS / APS', color: Color(0xFF2E7D32)),
  'geral': (label: 'Geral', color: Color(0xFF546E7A)),
};

class _ScenarioBadge extends StatelessWidget {
  const _ScenarioBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _TagBadge extends StatelessWidget {
  const _TagBadge({required this.tag});
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '#$tag',
        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
      ),
    );
  }
}
