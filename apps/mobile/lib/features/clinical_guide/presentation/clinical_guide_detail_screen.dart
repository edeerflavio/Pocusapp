import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../data/clinical_catalog.dart';
import '../data/models/clinical_category.dart';
import '../data/models/clinical_guide.dart';
import 'utils/guide_markdown_converter.dart';

// ---------------------------------------------------------------------------
// ClinicalGuideDetailScreen
// Route: /guide/detail/:slug   receives ClinicalGuide via GoRouter extra.
// ---------------------------------------------------------------------------

/// Definitive detail screen for a clinical guide.
///
/// Architecture:
/// - Content is received from PowerSync (offline-first, no network latency).
/// - [GuideMarkdownConverter] converts the structured JSON content to a
///   Markdown string sectioned by `##` headers.
/// - [_parseMarkdownSections] splits the string into [_GuideSection] objects.
/// - Each section is rendered as an [_AccordionCard] (ExpansionTile).
/// - ⚠️ sections receive a red left border as a critical visual alert.
/// - Internal search auto-expands sections containing the query.
class ClinicalGuideDetailScreen extends StatefulWidget {
  const ClinicalGuideDetailScreen({super.key, required this.guide});

  final ClinicalGuide guide;

  @override
  State<ClinicalGuideDetailScreen> createState() =>
      _ClinicalGuideDetailScreenState();
}

class _ClinicalGuideDetailScreenState
    extends State<ClinicalGuideDetailScreen> {
  late final List<_GuideSection> _sections;
  late final String _markdown;

  final _searchCtrl = TextEditingController();
  String _query = '';

  // Indices of expanded sections. Section 0 is expanded by default.
  late Set<int> _expandedIndices;

  // Breadcrumb context derived from ClinicalCatalog (pure static lookup).
  ClinicalCategory? _category;
  ClinicalTopic? _topic;

  @override
  void initState() {
    super.initState();

    // Convert structured content → Markdown → sections (pure, synchronous).
    _markdown = GuideMarkdownConverter.convert(widget.guide.content);
    _sections = _parseMarkdownSections(_markdown);
    _expandedIndices = {if (_sections.isNotEmpty) 0};

    // Resolve breadcrumb from static catalog.
    outer:
    for (final cat in ClinicalCatalog.categories) {
      for (final t in cat.topics) {
        if (t.matchesGuide(widget.guide)) {
          _category = cat;
          _topic = t;
          break outer;
        }
      }
    }
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
        // Restore default state: only first section expanded.
        _expandedIndices = {if (_sections.isNotEmpty) 0};
      } else {
        // Auto-expand every section that matches the query.
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
          // ── Header ───────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _HeaderCard(
              guide: widget.guide,
              categoryTitle: _category?.title,
              topicTitle: _topic?.title,
            ),
          ),
          // ── Internal search bar ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: _InternalSearchBar(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              onClear: _clearSearch,
              matchCount: _matchCount,
              query: _query,
            ),
          ),
          // ── Empty content fallback ────────────────────────────────────────
          if (_sections.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'Conteúdo em preparação.',
                  style: TextStyle(color: Colors.grey[400], fontSize: 14),
                ),
              ),
            )
          else ...[
            // ── Accordion sections ────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverList.builder(
                itemCount: _sections.length,
                itemBuilder: (_, i) => _AccordionCard(
                  // ValueKey changes when expansion state changes → forces
                  // rebuild with updated initiallyExpanded, enabling the
                  // search-driven expand/collapse without ExpansionTileController.
                  key: ValueKey('section_${i}_${_expandedIndices.contains(i)}'),
                  section: _sections[i],
                  initiallyExpanded: _expandedIndices.contains(i),
                  hasSearchMatch: _query.isNotEmpty && _sections[i].matchesQuery(_query),
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
            // ── Source footer ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _SourceFooter(guide: widget.guide),
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
        widget.guide.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Text(
              'v${widget.guide.version}',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// _GuideSection — parsed accordion unit
// ---------------------------------------------------------------------------

final class _GuideSection {
  const _GuideSection({required this.rawTitle, required this.body});

  /// Title as written in the Markdown (e.g. "🩺 Diagnóstico").
  final String rawTitle;

  /// Body Markdown content (everything between this `##` and the next).
  final String body;

  /// Sections containing ⚠️ or clinical risk keywords trigger a red border.
  bool get isCritical =>
      rawTitle.contains('⚠️') ||
      rawTitle.toLowerCase().contains('contraindicaç') ||
      rawTitle.toLowerCase().contains('red flag') ||
      rawTitle.toLowerCase().contains('alarme');

  bool matchesQuery(String q) =>
      rawTitle.toLowerCase().contains(q) ||
      body.toLowerCase().contains(q);
}

// ---------------------------------------------------------------------------
// Markdown → sections parser
// ---------------------------------------------------------------------------

List<_GuideSection> _parseMarkdownSections(String markdown) {
  if (markdown.trim().isEmpty) return const [];

  final sections = <_GuideSection>[];
  final headerRegex = RegExp(r'^## (.+)$', multiLine: true);
  final matches = headerRegex.allMatches(markdown).toList();

  for (var i = 0; i < matches.length; i++) {
    final title = matches[i].group(1)!.trim();
    final bodyStart = matches[i].end;
    final bodyEnd =
        i + 1 < matches.length ? matches[i + 1].start : markdown.length;
    final body = markdown.substring(bodyStart, bodyEnd).trim();

    if (title.isNotEmpty) {
      sections.add(_GuideSection(rawTitle: title, body: body));
    }
  }

  return sections;
}

// ---------------------------------------------------------------------------
// _HeaderCard — breadcrumb + title + summary
// ---------------------------------------------------------------------------

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.guide,
    this.categoryTitle,
    this.topicTitle,
  });

  final ClinicalGuide guide;
  final String? categoryTitle;
  final String? topicTitle;

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
          _Breadcrumb(
            category: categoryTitle,
            topic: topicTitle,
            specialty: guide.specialty,
          ),
          const SizedBox(height: 10),
          // H1 — disease/guide name
          Text(
            guide.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              height: 1.2,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 14),
          // Summary card
          if (guide.summary.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF1565C0).withValues(alpha: 0.18),
                ),
              ),
              child: Text(
                guide.summary,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Colors.black87,
                  height: 1.55,
                ),
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

class _Breadcrumb extends StatelessWidget {
  const _Breadcrumb({
    required this.category,
    required this.topic,
    required this.specialty,
  });

  final String? category;
  final String? topic;
  final String specialty;

  @override
  Widget build(BuildContext context) {
    final parts = <String>['Guia Clínico'];
    if (category != null) parts.add(category!);
    if (topic != null) {
      parts.add(topic!);
    } else if (specialty.isNotEmpty) {
      parts.add(specialty);
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          Text(
            parts[i],
            style: TextStyle(
              fontSize: 12,
              color: i == parts.length - 1
                  ? Colors.grey[600]
                  : Colors.grey[400],
              fontWeight: i == parts.length - 1
                  ? FontWeight.w500
                  : FontWeight.normal,
            ),
          ),
          if (i < parts.length - 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 14,
                color: Colors.grey[350],
              ),
            ),
        ],
      ],
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
              hintText: 'Buscar neste guia...',
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
                borderSide:
                    BorderSide(color: Colors.grey[300]!, width: 1),
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
                color: matchCount == 0 ? Colors.grey[400] : const Color(0xFF1565C0),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _AccordionCard — single expandable section
// ---------------------------------------------------------------------------

class _AccordionCard extends StatelessWidget {
  const _AccordionCard({
    super.key,
    required this.section,
    required this.initiallyExpanded,
    required this.hasSearchMatch,
    required this.onExpansionChanged,
  });

  final _GuideSection section;
  final bool initiallyExpanded;
  final bool hasSearchMatch;
  final ValueChanged<bool> onExpansionChanged;

  @override
  Widget build(BuildContext context) {
    final isCritical = section.isCritical;

    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildExpansionTile(context, isCritical),
    );

    // Critical sections: red left border via IntrinsicHeight Row.
    if (isCritical) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: const Color(0xFFE53935)),
                Expanded(child: card),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: card,
    );
  }

  Widget _buildExpansionTile(BuildContext context, bool isCritical) {
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      onExpansionChanged: onExpansionChanged,
      backgroundColor: Colors.white,
      collapsedBackgroundColor: Colors.white,
      iconColor: Colors.grey[600],
      collapsedIconColor: Colors.grey[400],
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      childrenPadding: EdgeInsets.zero,
      title: Row(
        children: [
          Expanded(
            child: Text(
              section.rawTitle,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isCritical
                    ? const Color(0xFFE53935)
                    : Colors.black87,
                height: 1.3,
              ),
            ),
          ),
          // Blue dot indicator when a search match is found.
          if (hasSearchMatch)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 6),
              decoration: const BoxDecoration(
                color: Color(0xFF1565C0),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
      children: [
        const Divider(height: 1, thickness: 1, color: Color(0xFFF0F0F0)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: MarkdownBody(
            data: section.body,
            softLineBreak: true,
            selectable: true,
            styleSheet: _buildStyleSheet(context),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Markdown style sheet
// ---------------------------------------------------------------------------

MarkdownStyleSheet _buildStyleSheet(BuildContext context) {
  return MarkdownStyleSheet(
    p: const TextStyle(
      fontSize: 13.5,
      height: 1.6,
      color: Colors.black87,
    ),
    h3: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: Color(0xFF424242),
      height: 1.8,
    ),
    h4: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF546E7A),
    ),
    strong: const TextStyle(
      fontWeight: FontWeight.w700,
      color: Colors.black87,
    ),
    listBullet: const TextStyle(
      fontSize: 13.5,
      height: 1.6,
      color: Colors.black87,
    ),
    listIndent: 16,
    blockquote: const TextStyle(
      fontSize: 13,
      color: Color(0xFF37474F),
      height: 1.5,
    ),
    blockquoteDecoration: BoxDecoration(
      color: const Color(0xFFFFF8E1),
      borderRadius: BorderRadius.circular(6),
      border: const Border(
        left: BorderSide(color: Color(0xFFFFA000), width: 3),
      ),
    ),
    blockquotePadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    code: const TextStyle(
      fontSize: 12.5,
      backgroundColor: Color(0xFFF5F5F5),
      fontFamily: 'monospace',
      color: Color(0xFF6A1B9A),
    ),
    codeblockDecoration: BoxDecoration(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(8),
    ),
    horizontalRuleDecoration: BoxDecoration(
      border: Border(
        top: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// _SourceFooter
// ---------------------------------------------------------------------------

class _SourceFooter extends StatelessWidget {
  const _SourceFooter({required this.guide});
  final ClinicalGuide guide;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 14,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Fonte: ${guide.source}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Versão ${guide.version}  ·  Sincronizado offline via PowerSync',
              style: TextStyle(fontSize: 11, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
