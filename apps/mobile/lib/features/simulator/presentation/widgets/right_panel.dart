import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/abg_provider.dart';
import '../../application/providers/simulation_provider.dart';
import '../../application/providers/ventilator_params_provider.dart';


// ═══════════════════════════════════════════════════════════════════════════
// Theme constants
// ═══════════════════════════════════════════════════════════════════════════

const _panelBg = Color(0xFF1A2230);
const _borderColor = Color(0x14FFFFFF);
const _green = Color(0xFF10B981);
const _cyan = Color(0xFF38BDF8);
const _amber = Color(0xFFF59E0B);
const _red = Color(0xFFFF6B6B);
const _dimWhite = Color(0x8CFFFFFF);

/// Right monitoring panel — Ventilatory Mechanics + Last ABG.
class RightPanel extends ConsumerWidget {
  const RightPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: _panelBg,
        border: Border(left: BorderSide(color: _borderColor, width: 1)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          _MechanicsSection(),
          const SizedBox(height: 8),
          const Divider(color: _borderColor),
          const SizedBox(height: 4),
          _AbgSection(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Ventilatory Mechanics section
// ═══════════════════════════════════════════════════════════════════════════

class _MechanicsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(ventParamsNotifierProvider);
    final metrics = ref.watch(cycleMetricsProvider);
    final dp = ref.watch(drivingPressureProvider);
    final pplat = ref.watch(plateauPressureProvider);
    final vtKg = ref.watch(vtPerKgProvider);
    final mp = ref.watch(mechanicalPowerProvider);

    // Static compliance = Vte / DP (mL/cmH₂O).
    final cst = dp > 0
        ? (metrics.vte > 0 ? metrics.vte / dp : params.vt / dp)
        : params.compliance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('MECÂNICA VENTILATÓRIA'),
        const SizedBox(height: 6),

        _MetricTile(
          label: 'ΔP (Driving)',
          value: dp.toStringAsFixed(1),
          unit: 'cmH₂O',
          color: dp > 15 ? _red : (dp > 12 ? _amber : _green),
          target: '≤ 15',
        ),
        _MetricTile(
          label: 'Pplatô',
          value: pplat.toStringAsFixed(0),
          unit: 'cmH₂O',
          color: pplat > 30 ? _red : (pplat > 28 ? _amber : _green),
          target: '≤ 30',
        ),
        _MetricTile(
          label: 'VT/kg IBW',
          value: vtKg.toStringAsFixed(1),
          unit: 'mL/kg',
          color: vtKg > 8 ? _red : (vtKg < 6 ? _cyan : _green),
          target: '6–8',
        ),
        _MetricTile(
          label: 'Cst (estática)',
          value: cst.toStringAsFixed(0),
          unit: 'mL/cmH₂O',
          color: cst < 25 ? _amber : _green,
          target: '> 30',
        ),
        _MetricTile(
          label: 'τ (tau)',
          value: params.tau.toStringAsFixed(2),
          unit: 's',
          color: params.tau > 1.0 ? _amber : _green,
          target: '< 1.0',
        ),
        _MetricTile(
          label: 'Pot. Mecânica',
          value: mp.toStringAsFixed(1),
          unit: 'J/min',
          color: mp > 17 ? _red : (mp > 12 ? _amber : _green),
          target: '< 17',
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Last ABG section
// ═══════════════════════════════════════════════════════════════════════════

class _AbgSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(abgAnalysisNotifierProvider);
    final abg = ref.watch(abgInputNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader('ÚLTIMA GASOMETRIA'),
        const SizedBox(height: 6),

        if (analysis == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Nenhuma gasometria\nanalisada',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _dimWhite,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          )
        else ...[
          // Primary disorder badge.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(6),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: _cyan.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: _cyan.withValues(alpha: 0.15)),
            ),
            child: Text(
              analysis.primaryDisorder,
              style: const TextStyle(
                color: _cyan,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                height: 1.2,
              ),
            ),
          ),

          // Key ABG values.
          _MetricTile(
            label: 'pH',
            value: abg.ph.toStringAsFixed(2),
            unit: '',
            color: abg.ph < 7.35 || abg.ph > 7.45 ? _red : _green,
            target: '7.35–7.45',
          ),
          _MetricTile(
            label: 'PaCO₂',
            value: abg.pco2.toStringAsFixed(0),
            unit: 'mmHg',
            color: abg.pco2 < 35 || abg.pco2 > 45 ? _amber : _green,
            target: '35–45',
          ),
          _MetricTile(
            label: 'PaO₂',
            value: abg.pao2.toStringAsFixed(0),
            unit: 'mmHg',
            color: abg.pao2 < 60
                ? _red
                : (abg.pao2 < 80 ? _amber : _green),
            target: '80–100',
          ),
          _MetricTile(
            label: 'HCO₃',
            value: abg.hco3.toStringAsFixed(0),
            unit: 'mEq/L',
            color: abg.hco3 < 22 || abg.hco3 > 26 ? _amber : _green,
            target: '22–26',
          ),
          _MetricTile(
            label: 'Lactato',
            value: abg.lactato.toStringAsFixed(1),
            unit: 'mmol/L',
            color: abg.lactato > 4
                ? _red
                : (abg.lactato > 2 ? _amber : _green),
            target: '< 2.0',
          ),
          _MetricTile(
            label: 'P/F',
            value: analysis.pfRatio.toStringAsFixed(0),
            unit: '',
            color: analysis.pfRatio < 100
                ? _red
                : (analysis.pfRatio < 200
                    ? _amber
                    : (analysis.pfRatio < 300 ? _cyan : _green)),
            target: '> 300',
          ),
        ],

        const SizedBox(height: 8),

        // Button to insert new ABG.
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              // Switch to left panel Gaso tab — find the DefaultTabController.
              // This is a simple approach; the user can also tap the tab directly.
            },
            icon: const Icon(Icons.add_rounded, size: 14),
            label: const Text(
              'NOVA GASOMETRIA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _green,
              side: BorderSide(color: _green.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4)),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared small widgets
// ═══════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: _dimWhite,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        fontFamily: 'monospace',
        letterSpacing: 1.2,
      ),
    );
  }
}

/// Single metric tile with label, value, unit, colour coding, and target.
class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.target,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;
  final String target;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          children: [
            // Colour indicator dot.
            Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
            // Label.
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _dimWhite,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            // Value.
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 2),
            // Unit.
            SizedBox(
              width: 36,
              child: Text(
                unit,
                style: TextStyle(
                  color: color.withValues(alpha: 0.4),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            // Target.
            Text(
              target,
              style: TextStyle(
                color: color.withValues(alpha: 0.3),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
