import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/clinical_catalog.dart';
import '../data/clinical_guides_repository.dart';
import '../data/models/clinical_category.dart';
import 'widgets/guide_card.dart';

/// Shows all [ClinicalGuide]s that match a given [ClinicalTopic].
///
/// Guides are fetched from PowerSync via [watchClinicalGuidesProvider] and
/// filtered client-side using [ClinicalTopic.matchesGuide].
class ClinicalGuidesByTopicScreen extends ConsumerWidget {
  const ClinicalGuidesByTopicScreen({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topic = ClinicalCatalog.findTopicById(topicId);
    final category = topic != null
        ? ClinicalCatalog.findCategoryById(topic.categoryId)
        : null;

    if (topic == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          title: const Text('Tema'),
        ),
        backgroundColor: Colors.grey[50],
        body: const Center(child: Text('Tema não encontrado.')),
      );
    }

    final guidesAsync = ref.watch(watchClinicalGuidesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, topic, category),
          guidesAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(child: Text('Erro: $e')),
            ),
            data: (allGuides) {
              final guides = ClinicalCatalog.guidesForTopic(topicId, allGuides);
              if (guides.isEmpty) {
                return const SliverFillRemaining(child: _EmptyTopicState());
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                sliver: SliverList.separated(
                  itemCount: guides.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => GuideCard(guide: guides[i]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(
    BuildContext context,
    ClinicalTopic topic,
    ClinicalCategory? category,
  ) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => category != null
            ? context.go('/guide/category/${category.id}')
            : context.go('/guide'),
      ),
      title: Text(
        topic.title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF004D40),
        ),
      ),
      bottom: category != null
          ? PreferredSize(
              preferredSize: const Size.fromHeight(36),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    category.title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyTopicState extends StatelessWidget {
  const _EmptyTopicState();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inbox_outlined, size: 56, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text(
          'Nenhum conteúdo disponível',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Este tema ainda não tem guias publicados',
          style: TextStyle(fontSize: 13, color: Colors.grey[400]),
        ),
      ],
    );
  }
}
