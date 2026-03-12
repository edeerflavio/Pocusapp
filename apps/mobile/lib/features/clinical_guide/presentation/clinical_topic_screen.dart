import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/clinical_catalog.dart';
import '../data/models/clinical_category.dart';

/// Lists the [ClinicalTopic]s that belong to a [ClinicalCategory].
///
/// Pure static widget — all data comes from [ClinicalCatalog], no DB access.
/// Tapping a topic navigates to [ClinicalGuidesByTopicScreen].
class ClinicalTopicScreen extends StatelessWidget {
  const ClinicalTopicScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, category),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            sliver: SliverList.separated(
              itemCount: category.topics.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) =>
                  _TopicListItem(topic: category.topics[i]),
            ),
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
          color: Colors.black87,
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
// Topic list item
// ---------------------------------------------------------------------------

class _TopicListItem extends StatelessWidget {
  const _TopicListItem({required this.topic});

  final ClinicalTopic topic;

  @override
  Widget build(BuildContext context) {
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
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.folder_outlined,
                size: 20,
                color: Colors.grey[600],
              ),
            ),
            title: Text(
              topic.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
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
