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
              'CID: ${disease.cid}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Descrição',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(disease.description),
            const SizedBox(height: 24),
            Text(
              'Tratamento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(disease.treatment),
          ],
        ),
      ),
    );
  }
}
