import 'alert_level.dart';

/// Standardised output of any calculator in this module.
///
/// Designed for:
/// - immediate display in the UI
/// - future serialisation to local DB or Supabase
/// - future injection into a clinical AI context
///
/// All fields are immutable. Snapshots allow full audit trail reconstruction.
final class CalculationResult {
  const CalculationResult({
    required this.calculatorId,
    required this.calculatorName,
    required this.value,
    required this.unit,
    required this.alertLevel,
    required this.interpretation,
    required this.inputSnapshot,
    required this.calculatedAt,
  });

  /// Stable identifier matching [CalculatorDefinition.id].
  final String calculatorId;

  /// Human-readable calculator name (e.g. "Débito Cardíaco").
  final String calculatorName;

  /// The computed numeric result.
  final double value;

  /// Clinical unit (e.g. "mmHg", "L/min").
  final String unit;

  /// Severity classification driving UI color and badge.
  final AlertLevel alertLevel;

  /// Plain-language interpretation ready for display.
  final String interpretation;

  /// Exact inputs that produced [value] — preserves intermediate steps
  /// when clinically relevant (e.g. LVOT area, stroke volume).
  final Map<String, dynamic> inputSnapshot;

  /// Timestamp for future history / audit features.
  final DateTime calculatedAt;

  /// Serialises to a plain map for local DB or remote persistence.
  Map<String, dynamic> toJson() => {
        'calculator_id': calculatorId,
        'calculator_name': calculatorName,
        'value': value,
        'unit': unit,
        'alert_level': alertLevel.name,
        'interpretation': interpretation,
        'input_snapshot': inputSnapshot,
        'calculated_at': calculatedAt.toIso8601String(),
      };
}
