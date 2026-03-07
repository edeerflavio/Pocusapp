import 'package:flutter/material.dart';

class ClinicalGuideScreen extends StatelessWidget {
  const ClinicalGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guia Clínico')),
      body: const Center(child: Text('Conteúdo do Guia Clínico')),
    );
  }
}
