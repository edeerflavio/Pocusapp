import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/clinical_guide_repository.dart';

class ClinicalGuideScreen extends ConsumerStatefulWidget {
  const ClinicalGuideScreen({super.key});

  @override
  ConsumerState<ClinicalGuideScreen> createState() => _ClinicalGuideScreenState();
}

class _ClinicalGuideScreenState extends ConsumerState<ClinicalGuideScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncDiseases = ref.watch(watchDiseasesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Guia Clínico')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nome ou CID...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: asyncDiseases.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erro: $e')),
              data: (diseases) {
                if (diseases.isEmpty) {
                  return const Center(child: Text('Nenhuma doença sincronizada'));
                }
                
                final filteredDiseases = diseases.where((disease) {
                  final titleMatch = disease.titlePt.toLowerCase().contains(_searchQuery);
                  final cidMatch = disease.cid.toLowerCase().contains(_searchQuery);
                  return titleMatch || cidMatch;
                }).toList();

                if (filteredDiseases.isEmpty) {
                  return const Center(child: Text('Nenhum resultado encontrado.'));
                }

                return ListView.builder(
                  itemCount: filteredDiseases.length,
                  itemBuilder: (context, index) {
                    final disease = filteredDiseases[index];
                    return ListTile(
                      title: Text(disease.titlePt),
                      subtitle: Text(disease.cid),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        context.go('/guide/disease/${disease.id}', extra: disease);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
