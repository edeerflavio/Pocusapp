import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/clinical_guides_repository.dart';
import '../data/models/clinical_guide.dart';

// ---------------------------------------------------------------------------
// Cenário labels e cores
// ---------------------------------------------------------------------------

const _scenarioMeta = {
  'emergencia': (label: 'Emergência',  color: Color(0xFFC62828)),
  'enfermaria': (label: 'Enfermaria',  color: Color(0xFF1565C0)),
  'ubs':        (label: 'UBS / APS',   color: Color(0xFF2E7D32)),
  'geral':      (label: 'Geral',       color: Color(0xFF546E7A)),
};

// ---------------------------------------------------------------------------
// ClinicalGuidesScreen
// ---------------------------------------------------------------------------

class ClinicalGuidesScreen extends ConsumerStatefulWidget {
  const ClinicalGuidesScreen({super.key});

  @override
  ConsumerState<ClinicalGuidesScreen> createState() =>
      _ClinicalGuidesScreenState();
}

class _ClinicalGuidesScreenState
    extends ConsumerState<ClinicalGuidesScreen> {
  final _searchCtrl = TextEditingController();
  String _query       = '';
  String _scenario    = 'todos'; // 'todos' | 'emergencia' | 'enfermaria' | 'ubs' | 'geral'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ClinicalGuide> _filter(List<ClinicalGuide> guides) {
    return guides.where((g) {
      final matchSearch = _query.isEmpty ||
          g.title.toLowerCase().contains(_query) ||
          g.specialty.toLowerCase().contains(_query) ||
          g.tags.any((t) => t.toLowerCase().contains(_query));
      final matchScenario = _scenario == 'todos' || g.scenario == _scenario;
      return matchSearch && matchScenario;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final asyncGuides = ref.watch(watchClinicalGuidesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          asyncGuides.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Erro: $e')),
            ),
            data: (guides) {
              final filtered = _filter(guides);
              if (filtered.isEmpty) {
                return const SliverFillRemaining(
                  child: _EmptyState(),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _GuideCard(guide: filtered[i]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 180,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        title: const Text(
          'Guia Clínico',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        background: Container(color: Colors.white),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(96),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search bar
              TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v.toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Buscar por título, especialidade ou tag...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Scenario filter chips
              SizedBox(
                height: 32,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _FilterChip(
                        label: 'Todos',
                        value: 'todos',
                        selected: _scenario,
                        onTap: (v) => setState(() => _scenario = v)),
                    ...(_scenarioMeta.entries.map(
                      (e) => _FilterChip(
                          label: e.value.label,
                          value: e.key,
                          selected: _scenario,
                          color: e.value.color,
                          onTap: (v) => setState(() => _scenario = v)),
                    )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Filter chip
// ---------------------------------------------------------------------------

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
    this.color = const Color(0xFF546E7A),
  });

  final String label;
  final String value;
  final String selected;
  final Color color;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Guide card
// ---------------------------------------------------------------------------

class _GuideCard extends StatelessWidget {
  const _GuideCard({required this.guide});

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
        onTap: () =>
            context.go('/guide/detail/${guide.slug}', extra: guide),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: scenario chip + version
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: meta.color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      meta.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: meta.color,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
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

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off_outlined, size: 56, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(
          'Nenhum guia encontrado',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Ajuste os filtros ou a busca',
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
      ],
    );
  }
}
