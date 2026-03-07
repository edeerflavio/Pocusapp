import 'package:flutter/material.dart';

class PocusScreen extends StatelessWidget {
  const PocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('POCUS')),
      body: const Center(child: Text('Conteúdo do POCUS')),
    );
  }
}
