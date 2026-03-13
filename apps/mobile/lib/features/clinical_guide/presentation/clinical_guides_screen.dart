import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/clinical_catalog.dart';
import '../data/clinical_guides_repository.dart';
import '../data/models/clinical_category.dart';
import '../data/models/guide_search_result.dart';

// ---------------------------------------------------------------------------
// ClinicalGuidesScreen
// ---------------------------------------------------------------------------

/// Hub screen for the Guia Clínico module.
///
/// Two modes:
/// 1. **Browsing** (empty query): displays the static [ClinicalCatalog]
///    category hierarchy — no DB access needed for this view.
/// 2. **Search** (active query): runs a full-text search across all published
///    guides fetched from PowerSync and shows results with breadcrumbs.
class ClinicalGuidesScreen extends ConsumerStatefulWidget {
  const ClinicalGuidesScreen({super.key});

  @override
  ConsumerState<ClinicalGuidesScreen> createState() =>
      _ClinicalGuidesScreenState();
}

class _ClinicalGuidesScreenState extends ConsumerState<ClinicalGuidesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() => _query = '');
  }

  bool get _isSearching => _query.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    // Always watch the stream so search is instant when the user starts typing.
    final guidesAsync = ref.watch(watchClinicalGuidesProvider);

    // Build flat search index only when data is available.
    final searchIndex = guidesAsync.valueOrNull != null
        ? ClinicalCatalog.buildSearchIndex(guidesAsync.valueOrNull!)
        : const <GuideSearchResult>[];

    final searchResults = _isSearching
        ? ClinicalCatalog.search(searchIndex, _query)
        : const <GuideSearchResult>[];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          if (!_isSearching) ...[
            // ── Browsing mode: category list ───────────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Categorias',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              sliver: SliverList.separated(
                itemCount: ClinicalCatalog.categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) =>
                    _CategoryListItem(category: ClinicalCatalog.categories[i]),
              ),
            ),
          ] else ...[
            // ── Search mode: results ───────────────────────────────────────
            if (guidesAsync.isLoading && searchIndex.isEmpty)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (searchResults.isEmpty)
              SliverFillRemaining(child: _SearchEmptyState(query: _query))
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                sliver: SliverList.separated(
                  itemCount: searchResults.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      _SearchResultItem(result: searchResults[i]),
                ),
              ),
          ],
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      title: const Text(
        'Guia Clínico',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF004D40),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: _SearchBar(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
          onClear: _clearSearch,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search bar
// ---------------------------------------------------------------------------

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar protocolos, doenças, procedimentos...',
          hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
          prefixIcon: Icon(Icons.search_rounded, size: 20, color: Colors.grey[400]),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: Colors.grey[500],
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category list item
// ---------------------------------------------------------------------------

class _CategoryListItem extends StatelessWidget {
  const _CategoryListItem({required this.category});

  final ClinicalCategory category;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: () => context.go('/guide/category/${category.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _CircleIconBadge(
              icon: category.icon,
              color: category.color,
            ),
            title: Text(
              category.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            subtitle: Text(
              category.subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
                height: 1.3,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleIconBadge extends StatelessWidget {
  const _CircleIconBadge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }
}

// ---------------------------------------------------------------------------
// Search result item
// ---------------------------------------------------------------------------

class _SearchResultItem extends StatelessWidget {
  const _SearchResultItem({required this.result});

  final GuideSearchResult result;

  @override
  Widget build(BuildContext context) {
    final guide = result.guide;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/guide/detail/${guide.slug}', extra: guide),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF004D40).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.article_outlined,
                  color: Color(0xFF004D40),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    if (result.breadcrumb != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        result.breadcrumb!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ] else if (guide.specialty.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        guide.specialty,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty search state
// ---------------------------------------------------------------------------

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off_rounded, size: 56, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(
          'Nenhum resultado para "$query"',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Tente outros termos clínicos',
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
      ],
    );
  }
}
