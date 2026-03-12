import 'package:flutter/material.dart';

import '../../domain/entities/alert_level.dart';
import '../../domain/entities/calculation_result.dart';

/// Displays a [CalculationResult] with colour-coded severity feedback.
///
/// Purely presentational — receives an immutable result and renders it.
class CalculationResultCard extends StatelessWidget {
  const CalculationResultCard({super.key, required this.result});

  final CalculationResult result;

  @override
  Widget build(BuildContext context) {
    final style = _AlertStyle.from(result.alertLevel);

    return Card(
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: style.borderColor, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header row
            Row(
              children: [
                const Text(
                  'Resultado',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF424242),
                  ),
                ),
                const Spacer(),
                _AlertBadge(level: result.alertLevel),
              ],
            ),
            const SizedBox(height: 12),

            // Value display
            Container(
              decoration: BoxDecoration(
                color: style.backgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    result.value.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      color: style.textColor,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    result.unit,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: style.textColor.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Interpretation row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(style.icon, size: 16, color: style.textColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    result.interpretation,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF424242),
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

class _AlertBadge extends StatelessWidget {
  const _AlertBadge({required this.level});

  final AlertLevel level;

  @override
  Widget build(BuildContext context) {
    final style = _AlertStyle.from(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.borderColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: style.borderColor.withValues(alpha: 0.4)),
      ),
      child: Text(
        style.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: style.textColor,
        ),
      ),
    );
  }
}

/// Encapsulates all colour and icon decisions for an [AlertLevel].
final class _AlertStyle {
  const _AlertStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.icon,
    required this.label,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData icon;
  final String label;

  static _AlertStyle from(AlertLevel level) => switch (level) {
        AlertLevel.normal => const _AlertStyle(
            backgroundColor: Color(0xFFE8F5E9),
            borderColor: Color(0xFF4CAF50),
            textColor: Color(0xFF2E7D32),
            icon: Icons.check_circle_outline,
            label: 'Normal',
          ),
        AlertLevel.warning => const _AlertStyle(
            backgroundColor: Color(0xFFFFF8E1),
            borderColor: Color(0xFFFFA000),
            textColor: Color(0xFFE65100),
            icon: Icons.warning_amber_outlined,
            label: 'Atenção',
          ),
        AlertLevel.critical => const _AlertStyle(
            backgroundColor: Color(0xFFFFEBEE),
            borderColor: Color(0xFFF44336),
            textColor: Color(0xFFC62828),
            icon: Icons.error_outline,
            label: 'Crítico',
          ),
      };
}
