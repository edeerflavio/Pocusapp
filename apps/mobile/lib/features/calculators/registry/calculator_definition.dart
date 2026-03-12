import 'package:flutter/material.dart';

import '../domain/entities/calculation_result.dart';

/// Specification for a single input field of a calculator.
final class FieldDefinition {
  const FieldDefinition({
    required this.id,
    required this.label,
    required this.hint,
    required this.unit,
    this.allowNegative = false,
    this.allowZero = false,
    this.minValue,
    this.maxValue,
  });

  /// Stable key matching the key in [CalculationResult.inputSnapshot].
  final String id;

  /// Displayed label (e.g. "Diâmetro da VCI").
  final String label;

  /// Placeholder hint text (e.g. "ex: 1.8").
  final String hint;

  /// Unit suffix shown inside the text field (e.g. "cm").
  final String unit;

  /// Whether negative values are valid for this field.
  final bool allowNegative;

  /// Whether zero is a valid value for this field.
  final bool allowZero;

  /// Optional lower bound for validation (inclusive).
  final double? minValue;

  /// Optional upper bound for validation (inclusive).
  final double? maxValue;
}

/// Signature for a pure calculator function.
///
/// Returns [CalculationResult] on success, or `null` when inputs are
/// insufficient or structurally invalid (non-null errors are handled in
/// [CalculatorController] before this is invoked).
typedef CalculatorExecutor = CalculationResult? Function(
  Map<String, double> inputs,
);

/// Complete self-describing definition of a calculator.
///
/// Combines domain metadata (id, fields, executor) with UI metadata
/// (name, description, icon, color) so that hub and detail screens
/// can render any calculator without a switch-case.
///
/// **Adding a new calculator requires only:**
/// 1. Implement a pure function in `domain/logic/`
/// 2. Add a [CalculatorDefinition] entry in [CalculatorRegistry]
/// No other file needs to change.
final class CalculatorDefinition {
  const CalculatorDefinition({
    required this.id,
    required this.name,
    required this.shortName,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.fields,
    required this.executor,
    this.references = const [],
  });

  /// Stable lowercase identifier (used in URLs and DB keys).
  final String id;

  /// Full display name (e.g. "Pressão Atrial Direita").
  final String name;

  /// Abbreviated name for AppBar (e.g. "RAP").
  final String shortName;

  /// One-sentence description shown in the hub card.
  final String description;

  final IconData icon;
  final Color accentColor;

  /// Ordered list of input fields the calculator requires.
  final List<FieldDefinition> fields;

  /// Pure function that produces the result. Must be a top-level function
  /// to satisfy const-constructor requirements.
  final CalculatorExecutor executor;

  /// Optional guideline / literature references shown at the bottom of
  /// the detail screen.
  final List<String> references;
}
