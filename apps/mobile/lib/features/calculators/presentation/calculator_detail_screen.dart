import 'package:flutter/material.dart';

import '../registry/calculator_definition.dart';
import '../registry/calculator_registry.dart';
import 'controllers/calculator_controller.dart';
import 'widgets/calculation_result_card.dart';
import 'widgets/calculator_input_field.dart';

/// Generic detail screen for any registered calculator.
///
/// Resolves the [CalculatorDefinition] by [calculatorId] (URL path param).
/// The UI is fully reactive — every keystroke triggers [CalculatorController]
/// which recomputes and notifies, causing an immediate rebuild of the result.
///
/// This file contains zero clinical logic. All domain rules live in
/// `domain/logic/` and `domain/constants/`.
class CalculatorDetailScreen extends StatefulWidget {
  const CalculatorDetailScreen({super.key, required this.calculatorId});

  final String calculatorId;

  @override
  State<CalculatorDetailScreen> createState() => _CalculatorDetailScreenState();
}

class _CalculatorDetailScreenState extends State<CalculatorDetailScreen> {
  CalculatorDefinition? _definition;
  CalculatorController? _controller;

  // Incremented on reset to give _InputsSection a new key, which forces
  // Flutter to recreate the widget subtree and clear all TextEditingControllers.
  int _resetCount = 0;

  @override
  void initState() {
    super.initState();
    final def = CalculatorRegistry.findById(widget.calculatorId);
    if (def != null) {
      _definition = def;
      _controller = CalculatorController(def)..addListener(_onControllerChange);
    }
  }

  @override
  void dispose() {
    _controller
      ?..removeListener(_onControllerChange)
      ..dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  void _handleReset() {
    _controller?.reset(); // triggers _onControllerChange → setState
    if (mounted) setState(() => _resetCount++); // rebuilds inputs with new key
  }

  @override
  Widget build(BuildContext context) {
    if (_definition == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey[50],
          elevation: 0,
          title: const Text('Calculadora'),
        ),
        backgroundColor: Colors.grey[50],
        body: const Center(
          child: Text(
            'Calculadora não encontrada.',
            style: TextStyle(color: Color(0xFF757575)),
          ),
        ),
      );
    }

    final def = _definition!;
    final ctrl = _controller!;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[50],
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          def.shortName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _handleReset,
            icon: const Icon(Icons.refresh_outlined, size: 18),
            label: const Text('Limpar'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderCard(definition: def),
            const SizedBox(height: 14),
            _InputsSection(
              key: ValueKey(_resetCount),
              definition: def,
              controller: ctrl,
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: ctrl.result != null
                  ? CalculationResultCard(
                      key: const ValueKey('result'),
                      result: ctrl.result!,
                    )
                  : const _EmptyResultPlaceholder(key: ValueKey('empty')),
            ),
            if (def.references.isNotEmpty) ...[
              const SizedBox(height: 20),
              _ReferencesSection(references: def.references),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets — purely presentational
// ---------------------------------------------------------------------------

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.definition});

  final CalculatorDefinition definition;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: definition.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                definition.icon,
                color: definition.accentColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    definition.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    definition.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputsSection extends StatelessWidget {
  const _InputsSection({
    super.key,
    required this.definition,
    required this.controller,
  });

  final CalculatorDefinition definition;
  final CalculatorController controller;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dados de entrada',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF424242),
              ),
            ),
            const SizedBox(height: 14),
            ...definition.fields.map(
              (field) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CalculatorInputField(
                  field: field,
                  errorText: controller.fieldError(field.id),
                  onChanged: (value) =>
                      controller.updateField(field.id, value),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyResultPlaceholder extends StatelessWidget {
  const _EmptyResultPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(Icons.calculate_outlined, size: 42, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(
              'Preencha os campos acima\npara calcular o resultado',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferencesSection extends StatelessWidget {
  const _ReferencesSection({required this.references});

  final List<String> references;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Referências',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        ...references.map(
          (ref) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $ref',
              style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}
