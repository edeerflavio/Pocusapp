import 'package:flutter/foundation.dart';

import '../../domain/entities/calculation_result.dart';
import '../../registry/calculator_definition.dart';

/// Manages form state and derives [CalculationResult] for a single calculator.
///
/// Responsibilities:
/// - Stores raw string inputs per field id
/// - Parses, validates, and propagates errors per field
/// - Calls the [CalculatorDefinition.executor] only with fully valid inputs
/// - Notifies listeners on every change so the UI rebuilds reactively
///
/// No clinical logic lives here — all rules stay in `domain/`.
final class CalculatorController extends ChangeNotifier {
  CalculatorController(this.definition) {
    _rawInputs = {for (final f in definition.fields) f.id: ''};
  }

  final CalculatorDefinition definition;

  late final Map<String, String> _rawInputs;
  final Map<String, String?> _errors = {};
  CalculationResult? _result;

  /// Latest valid result, or `null` while inputs are incomplete / invalid.
  CalculationResult? get result => _result;

  /// Validation error for [fieldId], or `null` if the field is valid.
  String? fieldError(String fieldId) => _errors[fieldId];

  /// Called by the UI whenever a field value changes.
  void updateField(String fieldId, String value) {
    _rawInputs[fieldId] = value;
    _recompute();
    notifyListeners();
  }

  /// Clears all inputs and the current result.
  void reset() {
    for (final key in _rawInputs.keys) {
      _rawInputs[key] = '';
    }
    _errors.clear();
    _result = null;
    notifyListeners();
  }

  void _recompute() {
    _errors.clear();
    final parsed = <String, double>{};

    for (final field in definition.fields) {
      final raw = (_rawInputs[field.id] ?? '').trim();

      if (raw.isEmpty) {
        // Field not yet filled — silent incomplete state, not an error.
        _result = null;
        return;
      }

      // Accept both dot and comma as decimal separator.
      final value = double.tryParse(raw.replaceAll(',', '.'));
      if (value == null) {
        _errors[field.id] = 'Valor inválido';
        _result = null;
        return;
      }

      if (!field.allowNegative && value < 0) {
        _errors[field.id] = 'Não pode ser negativo';
        _result = null;
        return;
      }

      if (!field.allowZero && value == 0) {
        _errors[field.id] = 'Não pode ser zero';
        _result = null;
        return;
      }

      if (field.minValue != null && value < field.minValue!) {
        _errors[field.id] = 'Mínimo: ${field.minValue} ${field.unit}';
        _result = null;
        return;
      }

      if (field.maxValue != null && value > field.maxValue!) {
        _errors[field.id] = 'Máximo: ${field.maxValue} ${field.unit}';
        _result = null;
        return;
      }

      parsed[field.id] = value;
    }

    // All fields valid — call the domain executor.
    _result = definition.executor(parsed);
  }
}
