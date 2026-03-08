import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/clinical_guide_repository.dart';

class ClinicalGuideScreen extends ConsumerWidget {
  const ClinicalGuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncDiseases = ref.watch(watchDiseasesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Guia Clínico')),
      body: asyncDiseases.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (diseases) {
          if (diseases.isEmpty) {
            return const Center(child: Text('Nenhuma doença sincronizada'));
          }
          return ListView.builder(
            itemCount: diseases.length,
            itemBuilder: (context, index) {
              final disease = diseases[index];
              return ListTile(
                title: Text(disease.titlePt),
                subtitle: Text(disease.cid),
              );
            },
          );
        },
      ),
    );
  }
}
