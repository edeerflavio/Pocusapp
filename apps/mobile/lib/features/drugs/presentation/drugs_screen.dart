import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/drugs_repository.dart';
import '../data/models/drug.dart';

// ---------------------------------------------------------------------------
// DrugsScreen — Hub for the Medicamentos module
//
// Two modes:
// 1. Browsing (empty query): alphabetical list grouped by first letter.
// 2. Search (active query): filtered flat list.
// ---------------------------------------------------------------------------

class DrugsScreen extends ConsumerStatefulWidget {
  const DrugsScreen({super.key});

  @override
  ConsumerState<DrugsScreen> createState() => _DrugsScreenState();
}

class _DrugsScreenState extends ConsumerState<DrugsScreen> {
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
    final drugsAsync = ref.watch(watchDrugsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          drugsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Erro: $e')),
            ),
            data: (allDrugs) {
              final drugs = _isSearching
                  ? allDrugs
                      .where((d) =>
                          d.title.toLowerCase().contains(_query) ||
                          d.slug.toLowerCase().contains(_query))
                      .toList()
                  : allDrugs;

              if (drugs.isEmpty && _isSearching) {
                return SliverFillRemaining(
                  child: _SearchEmptyState(query: _query),
                );
              }

              if (drugs.isEmpty) {
                return const SliverFillRemaining(child: _EmptyState());
              }

              if (_isSearching) {
                return _buildFlatList(drugs);
              }

              return _buildGroupedList(drugs);
            },
          ),
        ],
      ),
    );
  }

  // ── App bar with search ─────────────────────────────────────────────────

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      floating: false,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => context.go('/home'),
      ),
      title: const Text(
        'Medicamentos',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xFF004D40),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(62),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar medicamento...',
              hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search_rounded,
                  size: 20, color: Colors.grey[400]),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: Colors.grey[500],
                      onPressed: _clearSearch,
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        ),
      ),
    );
  }

  // ── Flat list (search results) ──────────────────────────────────────────

  SliverPadding _buildFlatList(List<Drug> drugs) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      sliver: SliverList.separated(
        itemCount: drugs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _DrugListItem(drug: drugs[i]),
      ),
    );
  }

  // ── Grouped list (A-Z sections) ─────────────────────────────────────────

  SliverPadding _buildGroupedList(List<Drug> drugs) {
    // Group by first letter.
    final groups = <String, List<Drug>>{};
    for (final drug in drugs) {
      groups.putIfAbsent(drug.indexLetter, () => []).add(drug);
    }
    final sortedKeys = groups.keys.toList()..sort();

    // Build a mixed list of headers + items.
    final items = <_ListEntry>[];
    for (final key in sortedKeys) {
      items.add(_ListEntry.header(key));
      for (final drug in groups[key]!) {
        items.add(_ListEntry.drug(drug));
      }
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      sliver: SliverList.builder(
        itemCount: items.length,
        itemBuilder: (_, i) {
          final entry = items[i];
          if (entry.isHeader) {
            return Padding(
              padding: EdgeInsets.only(
                top: i == 0 ? 0 : 16,
                bottom: 8,
                left: 4,
              ),
              child: Text(
                entry.header!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[500],
                  letterSpacing: 0.5,
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _DrugListItem(drug: entry.drug!),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ListEntry — union type for headers vs drug items
// ---------------------------------------------------------------------------

class _ListEntry {
  const _ListEntry._({this.header, this.drug});
  factory _ListEntry.header(String h) => _ListEntry._(header: h);
  factory _ListEntry.drug(Drug d) => _ListEntry._(drug: d);

  final String? header;
  final Drug? drug;
  bool get isHeader => header != null;
}

// ---------------------------------------------------------------------------
// Drug list item
// ---------------------------------------------------------------------------

class _DrugListItem extends StatelessWidget {
  const _DrugListItem({required this.drug});

  final Drug drug;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            context.go('/home/drugs/detail/${drug.slug}', extra: drug),
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
                  Icons.medication_outlined,
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
                      drug.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    if (drug.isPremium) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.lock_outline,
                              size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            'Premium',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty states
// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.medication_outlined, size: 56, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(
          'Nenhum medicamento disponível',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Os dados serão sincronizados automaticamente',
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
      ],
    );
  }
}

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
          'Tente o nome genérico ou comercial',
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
      ],
    );
  }
}
