import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/abg_provider.dart';
import '../../application/providers/ventilator_params_provider.dart';
import '../../domain/entities/ventilator_entities.dart';
import '../../domain/enums/ventilation_enums.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Theme constants (matches ICU monitor dark theme)
// ═══════════════════════════════════════════════════════════════════════════

const _panelBg = Color(0xFF1A2230);
const _surface = Color(0xFF212B3A);
const _border = Color(0x14FFFFFF);
const _teal = Color(0xFF00897B);
const _tealLight = Color(0xFF4DB6AC);
const _dimWhite = Color(0x8CFFFFFF);
const _brightWhite = Color(0xE6FFFFFF);
const _green = Color(0xFF10B981);
const _cyan = Color(0xFF38BDF8);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFFF6B6B);
const _coral = Color(0xFFFF6B6B);

// ═══════════════════════════════════════════════════════════════════════════
// BedsideGasometryTab — combined ABG input + analysis + apply actions
// ═══════════════════════════════════════════════════════════════════════════

/// Complete bedside gasometry workflow:
///
/// 1. **Input**: physician enters ABG values (pH, PaCO₂, HCO₃, PaO₂, SaO₂,
///    Lactato) using +/− knobs.
/// 2. **Analyze**: runs [AbgAnalyzer.analyze()] crossing ABG values with
///    current ventilator parameters and patient anthropometrics.
/// 3. **Apply**: each actionable recommendation has an "APLICAR" button that
///    directly adjusts the ventilator parameter and updates the simulation
///    in real time.
class BedsideGasometryTab extends ConsumerWidget {
  const BedsideGasometryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abg = ref.watch(abgInputNotifierProvider);
    final abgNotifier = ref.read(abgInputNotifierProvider.notifier);
    final analysis = ref.watch(abgAnalysisNotifierProvider);

    return Container(
      color: _panelBg,
      child: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          // ── ABG Input section ────────────────────────────────────────
          const _SectionHeader(
            icon: Icons.bloodtype_rounded,
            label: 'GASOMETRIA ARTERIAL',
          ),
          const SizedBox(height: 4),
          const Text(
            'Insira os valores da gasometria do paciente.',
            style: TextStyle(
              color: _dimWhite,
              fontSize: 12,
              fontFamily: 'monospace',
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),

          _AbgInputRow(
            label: 'pH',
            value: abg.ph.toStringAsFixed(2),
            refRange: '7.35 – 7.45',
            color: abg.ph < 7.35 || abg.ph > 7.45 ? _red : _green,
            onDecrement: () => abgNotifier.updatePH(double.parse(
                (abg.ph - 0.01).clamp(6.80, 7.80).toStringAsFixed(2))),
            onIncrement: () => abgNotifier.updatePH(double.parse(
                (abg.ph + 0.01).clamp(6.80, 7.80).toStringAsFixed(2))),
          ),
          _AbgInputRow(
            label: 'PaCO\u2082',
            value: abg.pco2.toStringAsFixed(0),
            refRange: '35 – 45 mmHg',
            color: abg.pco2 < 35 || abg.pco2 > 45 ? _amber : _green,
            onDecrement: () =>
                abgNotifier.updatePCO2((abg.pco2 - 1).clamp(10, 120)),
            onIncrement: () =>
                abgNotifier.updatePCO2((abg.pco2 + 1).clamp(10, 120)),
          ),
          _AbgInputRow(
            label: 'HCO\u2083',
            value: abg.hco3.toStringAsFixed(0),
            refRange: '22 – 26 mEq/L',
            color: abg.hco3 < 22 || abg.hco3 > 26 ? _amber : _green,
            onDecrement: () =>
                abgNotifier.updateHCO3((abg.hco3 - 1).clamp(5, 50)),
            onIncrement: () =>
                abgNotifier.updateHCO3((abg.hco3 + 1).clamp(5, 50)),
          ),
          _AbgInputRow(
            label: 'PaO\u2082',
            value: abg.pao2.toStringAsFixed(0),
            refRange: '80 – 100 mmHg',
            color:
                abg.pao2 < 60 ? _red : (abg.pao2 < 80 ? _amber : _green),
            onDecrement: () =>
                abgNotifier.updatePaO2((abg.pao2 - 5).clamp(20, 600)),
            onIncrement: () =>
                abgNotifier.updatePaO2((abg.pao2 + 5).clamp(20, 600)),
          ),
          _AbgInputRow(
            label: 'SaO\u2082',
            value: abg.sao2.toStringAsFixed(0),
            refRange: '95 – 100 %',
            color:
                abg.sao2 < 90 ? _red : (abg.sao2 < 95 ? _amber : _green),
            onDecrement: () =>
                abgNotifier.updateSaO2((abg.sao2 - 1).clamp(50, 100)),
            onIncrement: () =>
                abgNotifier.updateSaO2((abg.sao2 + 1).clamp(50, 100)),
          ),
          _AbgInputRow(
            label: 'Lactato',
            value: abg.lactato.toStringAsFixed(1),
            refRange: '< 2.0 mmol/L',
            color: abg.lactato > 4
                ? _red
                : (abg.lactato > 2 ? _amber : _green),
            onDecrement: () => abgNotifier.updateLactato(double.parse(
                (abg.lactato - 0.5).clamp(0, 30).toStringAsFixed(1))),
            onIncrement: () => abgNotifier.updateLactato(double.parse(
                (abg.lactato + 0.5).clamp(0, 30).toStringAsFixed(1))),
          ),

          const SizedBox(height: 12),

          // ── Analyze button ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                ref.read(abgAnalysisNotifierProvider.notifier).analyze();
              },
              icon: const Icon(Icons.science_rounded, size: 16),
              label: const Text(
                'ANALISAR GASOMETRIA',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal.withValues(alpha: 0.15),
                foregroundColor: _tealLight,
                side: BorderSide(color: _teal.withValues(alpha: 0.3)),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),

          // ── Analysis result ──────────────────────────────────────────
          if (analysis != null) ...[
            const SizedBox(height: 14),

            // Primary disorder.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _cyan.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _cyan.withValues(alpha: 0.25)),
              ),
              child: Text(
                analysis.primaryDisorder,
                style: const TextStyle(
                  color: _cyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Derived metrics strip.
            _MetricsStrip(analysis: analysis),

            const SizedBox(height: 10),

            // Findings.
            const _SectionHeader(
                icon: Icons.find_in_page_rounded, label: 'ACHADOS'),
            const SizedBox(height: 4),
            ...analysis.findings.map(_buildFinding),

            // Actions with APLICAR buttons.
            if (analysis.actions.isNotEmpty) ...[
              const SizedBox(height: 10),
              const _SectionHeader(
                  icon: Icons.play_circle_rounded,
                  label: 'RECOMENDACOES'),
              const SizedBox(height: 4),
              ...analysis.actions
                  .map((action) => _ActionCard(action: action)),
            ],
          ],

          if (analysis == null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.science_outlined, size: 24, color: _dimWhite),
                    SizedBox(height: 6),
                    Text(
                      'Insira os valores acima e clique\n"Analisar Gasometria" para obter\ndiagnostico e recomendacoes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _dimWhite,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFinding(AbgFinding finding) {
    final color = _alertColor(finding.level);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(4),
          border: Border(left: BorderSide(color: color, width: 2)),
        ),
        child: Text(
          finding.text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontFamily: 'monospace',
            height: 1.3,
          ),
        ),
      ),
    );
  }

  static Color _alertColor(AlertLevel level) => switch (level) {
        AlertLevel.ok => _green,
        AlertLevel.info => _cyan,
        AlertLevel.warning => _amber,
        AlertLevel.danger => _red,
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// _MetricsStrip — compact derived metrics from the analysis
// ═══════════════════════════════════════════════════════════════════════════

class _MetricsStrip extends StatelessWidget {
  const _MetricsStrip({required this.analysis});

  final AbgAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          _MiniMetric(
            label: 'P/F',
            value: analysis.pfRatio.toStringAsFixed(0),
            color: analysis.pfRatio < 100
                ? _red
                : (analysis.pfRatio < 200
                    ? _amber
                    : (analysis.pfRatio < 300 ? _cyan : _green)),
          ),
          _MiniMetric(
            label: '\u0394P',
            value: analysis.drivingPressure.toStringAsFixed(1),
            color: analysis.drivingPressure > 15 ? _red : _green,
          ),
          _MiniMetric(
            label: 'Pplat',
            value: analysis.pplat.toStringAsFixed(0),
            color: analysis.pplat > 30 ? _red : _green,
          ),
          _MiniMetric(
            label: 'VT/kg',
            value: analysis.vtPerKg.toStringAsFixed(1),
            color: analysis.vtPerKg > 8 ? _red : _green,
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.5),
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _ActionCard — single recommendation with optional APLICAR button
// ═══════════════════════════════════════════════════════════════════════════

class _ActionCard extends ConsumerWidget {
  const _ActionCard({required this.action});

  final AbgAction action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urgencyColor = action.priority == 0
        ? _red
        : (action.priority == 1 ? _amber : _green);
    final canApply = _isApplicable(action.param);
    final targetValue = canApply ? _extractTarget(action.action) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: urgencyColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: urgencyColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: icon + param + priority.
            Row(
              children: [
                Text(action.icon, style: const TextStyle(fontSize: 10)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    action.param,
                    style: TextStyle(
                      color: urgencyColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: urgencyColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    'P${action.priority}',
                    style: TextStyle(
                      color: urgencyColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),

            // Action text.
            Text(
              action.action,
              style: const TextStyle(
                color: _brightWhite,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                height: 1.3,
              ),
            ),
            const SizedBox(height: 2),

            // Reason.
            Text(
              action.reason,
              style: const TextStyle(
                color: _dimWhite,
                fontSize: 12,
                fontFamily: 'monospace',
                height: 1.3,
              ),
            ),

            // APLICAR button (only for directly adjustable params).
            if (canApply && targetValue != null) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _applyAction(
                      ref: ref,
                      param: action.param,
                      target: targetValue,
                      context: context,
                    );
                  },
                  icon: const Icon(Icons.check_circle_rounded, size: 14),
                  label: Text(
                    'APLICAR: ${_applyLabel(action.param, targetValue)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _coral.withValues(alpha: 0.15),
                    foregroundColor: _coral,
                    side: BorderSide(color: _coral.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Whether this param can be directly applied to the ventilator.
  static bool _isApplicable(String param) =>
      param == 'VT' || param == 'FR' || param == 'FiO\u2082' || param == 'PEEP';

  /// Extract the target numeric value from action text.
  ///
  /// Looks for "para X" or "até X" patterns in Portuguese.
  static double? _extractTarget(String action) {
    final paraMatch =
        RegExp(r'para\s+(\d+(?:\.\d+)?)').firstMatch(action);
    if (paraMatch != null) return double.tryParse(paraMatch.group(1)!);

    final ateMatch = RegExp(r'até\s+(\d+(?:\.\d+)?)').firstMatch(action);
    if (ateMatch != null) return double.tryParse(ateMatch.group(1)!);

    return null;
  }

  /// Human-readable label for the apply button.
  static String _applyLabel(String param, double target) => switch (param) {
        'VT' => 'VT ${target.round()} mL',
        'FR' => 'FR ${target.round()} rpm',
        'FiO\u2082' => 'FiO\u2082 ${target.round()}%',
        'PEEP' => 'PEEP ${target.round()} cmH\u2082O',
        _ => '$param $target',
      };

  /// Apply the recommended value to the ventilator and show confirmation.
  static void _applyAction({
    required WidgetRef ref,
    required String param,
    required double target,
    required BuildContext context,
  }) {
    final notifier = ref.read(ventParamsNotifierProvider.notifier);
    final presetNotifier = ref.read(activePresetProvider.notifier);

    String confirmation;

    switch (param) {
      case 'VT':
        final v = target.round().clamp(200, 800);
        notifier.updateVT(v);
        confirmation = 'VT ajustado para $v mL';
      case 'FR':
        final v = target.round().clamp(6, 40);
        notifier.updateRR(v);
        confirmation = 'FR ajustada para $v rpm';
      case 'FiO\u2082':
        final v = target.round().clamp(21, 100);
        notifier.updateFio2(v);
        confirmation = 'FiO\u2082 ajustada para $v%';
      case 'PEEP':
        final v = target.clamp(0, 25).toDouble();
        notifier.updatePeep(v);
        confirmation = 'PEEP ajustada para ${v.round()} cmH\u2082O';
      default:
        return;
    }

    presetNotifier.select(null);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$confirmation \u2713',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFF1A2A1A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared building blocks
// ═══════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: _tealLight),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: _tealLight,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _AbgInputRow extends StatelessWidget {
  const _AbgInputRow({
    required this.label,
    required this.value,
    required this.refRange,
    required this.color,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final String value;
  final String refRange;
  final Color color;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: _dimWhite,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    refRange,
                    style: TextStyle(
                      color: color.withValues(alpha: 0.35),
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            _KnobButton(
              icon: Icons.remove,
              color: color,
              onTap: () {
                HapticFeedback.lightImpact();
                onDecrement();
              },
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 4),
            _KnobButton(
              icon: Icons.add,
              color: color,
              onTap: () {
                HapticFeedback.lightImpact();
                onIncrement();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _KnobButton extends StatelessWidget {
  const _KnobButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.08),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
