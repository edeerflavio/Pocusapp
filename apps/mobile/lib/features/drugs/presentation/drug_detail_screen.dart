import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../shared/widgets/markdown_accordion.dart';
import '../data/models/drug.dart';

// ---------------------------------------------------------------------------
// DrugDetailScreen
// Route: /home/drugs/detail/:slug   receives Drug via GoRouter extra.
//
// Reuses the shared MarkdownSectionCard + parseMarkdownBody from
// lib/shared/widgets/markdown_accordion.dart — same accordion UX as POCUS
// player and Clinical Guide detail screens.
// ---------------------------------------------------------------------------

class DrugDetailScreen extends StatefulWidget {
  const DrugDetailScreen({super.key, required this.drug});

  final Drug drug;

  @override
  State<DrugDetailScreen> createState() => _DrugDetailScreenState();
}

class _DrugDetailScreenState extends State<DrugDetailScreen> {
  late final List<ParsedSection> _sections;
  late final String _intro;

  final _searchCtrl = TextEditingController();
  String _query = '';
  late Set<int> _expandedIndices;

  @override
  void initState() {
    super.initState();
    final parsed = parseMarkdownBody(widget.drug.body);
    _intro = parsed.intro;
    _sections = parsed.sections;
    _expandedIndices = {if (_sections.isNotEmpty) 0};
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final q = value.toLowerCase().trim();
    setState(() {
      _query = q;
      if (q.isEmpty) {
        _expandedIndices = {if (_sections.isNotEmpty) 0};
      } else {
        _expandedIndices = {
          for (var i = 0; i < _sections.length; i++)
            if (_sections[i].matchesQuery(q)) i,
        };
      }
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    _onSearchChanged('');
  }

  int get _matchCount => _query.isEmpty
      ? 0
      : _sections.where((s) => s.matchesQuery(_query)).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(child: _HeaderCard(drug: widget.drug)),
          // ── Internal search bar ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: _InternalSearchBar(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
              matchCount: _matchCount,
              query: _query,
            ),
          ),
          // ── Empty content fallback ──────────────────────────────────────
          if (_sections.isEmpty && _intro.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'Conteúdo em preparação.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ),
            )
          else ...[
            // ── Intro (if any) ──────────────────────────────────────────
            if (_intro.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: MarkdownBody(
                    data: _intro,
                    selectable: true,
                    softLineBreak: true,
                    styleSheet: sharedMarkdownStyle(),
                  ),
                ),
              ),
            // ── Accordion sections ──────────────────────────────────────
            if (_sections.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                sliver: SliverList.builder(
                  itemCount: _sections.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: MarkdownSectionCard(
                      key: ValueKey(
                          'section_${i}_${_expandedIndices.contains(i)}'),
                      section: _sections[i],
                      index: i,
                      initiallyExpanded: _expandedIndices.contains(i),
                      hasSearchMatch:
                          _query.isNotEmpty && _sections[i].matchesQuery(_query),
                      onExpansionChanged: (expanded) {
                        setState(() {
                          if (expanded) {
                            _expandedIndices.add(i);
                          } else {
                            _expandedIndices.remove(i);
                          }
                        });
                      },
                    ),
                  ),
                ),
              ),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: Text(
        widget.drug.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _HeaderCard — drug name + premium badge
// ---------------------------------------------------------------------------

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.drug});

  final Drug drug;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(
            children: [
              Text(
                'Medicamentos',
                style: TextStyle(fontSize: 12, color: Colors.grey[400]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right_rounded,
                    size: 14, color: Colors.grey[350]),
              ),
              Expanded(
                child: Text(
                  drug.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Title
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF004D40).withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medication_outlined,
                  color: Color(0xFF004D40),
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drug.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (drug.isPremium) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6F61).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                size: 13, color: Color(0xFFFF6F61)),
                            SizedBox(width: 4),
                            Text(
                              'Premium',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF6F61),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _InternalSearchBar
// ---------------------------------------------------------------------------

class _InternalSearchBar extends StatelessWidget {
  const _InternalSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.matchCount,
    required this.query,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final int matchCount;
  final String query;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar neste medicamento...',
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: Colors.grey[400],
              ),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: Colors.grey[500],
                      onPressed: onClear,
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
            ),
          ),
          if (query.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              matchCount == 0
                  ? 'Nenhuma seção contém "$query"'
                  : '$matchCount ${matchCount == 1 ? "seção expandida" : "seções expandidas"} com "$query"',
              style: TextStyle(
                fontSize: 12,
                color: matchCount == 0
                    ? Colors.grey[400]
                    : const Color(0xFF004D40),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
