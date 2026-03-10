import 'package:flutter/material.dart';
import '../data/models/disease.dart';

class DiseaseDetailsScreen extends StatelessWidget {
  const DiseaseDetailsScreen({
    super.key,
    required this.disease,
  });

  final Disease disease;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(disease.titlePt),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Slug: ${disease.slug}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Conteúdo (PT)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(disease.bodyPt.isEmpty ? '—' : disease.bodyPt),
            const SizedBox(height: 24),
            Text(
              'Conteúdo (ES)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(disease.bodyEs.isEmpty ? '—' : disease.bodyEs),
          ],
        ),
      ),
    );
  }
}
