import 'package:flutter/material.dart';

class SimulatorScreen extends StatelessWidget {
  const SimulatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulador')),
      body: const Center(child: Text('Conteúdo do Simulador')),
    );
  }
}
