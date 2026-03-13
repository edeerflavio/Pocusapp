import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/clinical_catalog.dart';
import '../data/clinical_guides_repository.dart';
import '../data/models/clinical_category.dart';

/// Lists the [ClinicalTopic]s that belong to a [ClinicalCategory].
///
/// Now dynamic: watches [watchClinicalGuidesProvider] to show the actual
/// number of guides per topic from PowerSync. Topics with 0 guides are
/// shown grayed out (but still navigable — data may sync later).
class ClinicalTopicScreen extends ConsumerWidget {
  const ClinicalTopicScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ClinicalCatalog.findCategoryById(categoryId);

    if (category == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          title: const Text('Categoria'),
        ),
        backgroundColor: Colors.grey[50],
        body: const Center(child: Text('Categoria não encontrada.')),
      );
    }

    final guidesAsync = ref.watch(watchClinicalGuidesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, category),
          guidesAsync.when(
            loading: () => SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              sliver: SliverList.separated(
                itemCount: category.topics.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _TopicListItem(
                  topic: category.topics[i],
                  guideCount: null,
                  categoryColor: category.color,
                ),
              ),
            ),
            error: (_, __) => SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              sliver: SliverList.separated(
                itemCount: category.topics.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _TopicListItem(
                  topic: category.topics[i],
                  guideCount: null,
                  categoryColor: category.color,
                ),
              ),
            ),
            data: (allGuides) {
              // Count guides per topic dynamically.
              final counts = <String, int>{};
              for (final topic in category.topics) {
                counts[topic.id] =
                    allGuides.where(topic.matchesGuide).length;
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                sliver: SliverList.separated(
                  itemCount: category.topics.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final topic = category.topics[i];
                    return _TopicListItem(
                      topic: topic,
                      guideCount: counts[topic.id] ?? 0,
                      categoryColor: category.color,
                    );
                  },
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
    ClinicalCategory category,
  ) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
        onPressed: () => context.go('/guide'),
      ),
      title: Text(
        category.title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF004D40),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(36),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              category.subtitle,
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Topic list item — now shows guide count + AMPLE-branded folder icons
// ---------------------------------------------------------------------------

class _TopicListItem extends StatelessWidget {
  const _TopicListItem({
    required this.topic,
    required this.guideCount,
    required this.categoryColor,
  });

  final ClinicalTopic topic;
  final int? guideCount; // null = loading
  final Color categoryColor;

  @override
  Widget build(BuildContext context) {
    final hasGuides = guideCount == null || guideCount! > 0;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.go('/guide/topic/${topic.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.folder_outlined,
                size: 20,
                color: hasGuides ? categoryColor : Colors.grey[400],
              ),
            ),
            title: Text(
              topic.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: hasGuides ? Colors.black87 : Colors.grey[500],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (guideCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: guideCount! > 0
                          ? const Color(0xFF004D40).withValues(alpha: 0.08)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$guideCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: guideCount! > 0
                            ? const Color(0xFF004D40)
                            : Colors.grey[400],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.grey[300],
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
