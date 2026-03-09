import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/pocus_repository.dart';

class PocusScreen extends ConsumerWidget {
  const PocusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(watchPocusItemsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('POCUS')),
      body: asyncItems.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Nenhum vídeo POCUS sincronizado'));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: const Icon(Icons.videocam),
                title: Text(item.category),
                subtitle: Text(item.titlePt),
                trailing: const Icon(Icons.play_arrow),
                onTap: () {
                  context.go('/pocus/player/${item.id}', extra: item);
                },
              );
            },
          );
        },
      ),
    );
  }
}
