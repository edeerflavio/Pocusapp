/// Severity classification for a [CalculationResult].
///
/// Used to drive color coding, badge labels, and clinical interpretation
/// across the entire calculators module.
enum AlertLevel {
  normal,
  warning,
  critical;

  /// True for any level that requires clinical attention.
  bool get isAbnormal => this != normal;
}
