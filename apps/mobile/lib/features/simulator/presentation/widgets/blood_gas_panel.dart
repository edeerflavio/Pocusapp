import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/blood_gas_lab_provider.dart';
import '../../application/providers/ventilator_params_provider.dart';
import '../../domain/enums/ventilation_enums.dart';
import '../../domain/services/blood_gas_engine.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Theme constants
// ═══════════════════════════════════════════════════════════════════════════

const _panelBg = Color(0xFF0A0E16);
const _surface = Color(0xFF111822);
const _border = Color(0x1A00FF88);
const _green = Color(0xFF00E676);
const _cyan = Color(0xFF00CCFF);
const _amber = Color(0xFFFFAA00);
const _red = Color(0xFFFF4466);
const _teal = Color(0xFF00897B);
const _dimWhite = Color(0x80FFFFFF);

// ═══════════════════════════════════════════════════════════════════════════
// BloodGasPanel — main widget
// ═══════════════════════════════════════════════════════════════════════════

/// Laboratory and weaning panel that displays dynamically computed
/// arterial blood gas values and weaning readiness criteria.
///
/// ## Features
///
/// - **Live ABG preview**: real-time pH, PaCO₂, PaO₂, HCO₃, SaO₂ that
///   respond to ventilator changes with physiological CO₂ washout delay.
/// - **"Solicitar Gasometria" button**: freezes a lab result after a
///   3-second simulated processing delay.
/// - **Frozen lab results**: displayed as a formal "exam result" card.
/// - **Weaning criteria** (PSV mode only): RSBI/Tobin index plus 6 other
///   criteria with pass/fail indicators.
class BloodGasPanel extends ConsumerWidget {
  const BloodGasPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labState = ref.watch(bloodGasLabNotifierProvider);
    final preview = ref.watch(liveAbgPreviewProvider);
    final params = ref.watch(ventParamsNotifierProvider);
    final isPSV = params.mode == VentMode.psv;

    return Container(
      color: _panelBg,
      child: ListView(
        padding: const EdgeInsets.all(10),
        children: [
          // ── Live preview ──────────────────────────────────────────
          _LivePreviewSection(preview: preview),

          const SizedBox(height: 10),

          // ── Request button ────────────────────────────────────────
          _RequestButton(pending: labState.pendingResult),

          const SizedBox(height: 10),

          // ── Frozen lab result ─────────────────────────────────────
          if (labState.lastResult != null)
            _LabResultCard(
              result: labState.lastResult!,
              resultNumber: labState.resultCount,
            ),

          if (labState.lastResult == null && !labState.pendingResult)
            _EmptyResultCard(),

          // ── Weaning section (PSV only) ────────────────────────────
          if (isPSV) ...[
            const SizedBox(height: 12),
            _WeaningSection(),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _LivePreviewSection — real-time ABG values
// ═══════════════════════════════════════════════════════════════════════════

class _LivePreviewSection extends StatelessWidget {
  const _LivePreviewSection({required this.preview});

  final DynamicAbgResult preview;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header(icon: Icons.monitor_heart_rounded, label: 'MONITOR GASOMÉTRICO'),
        const SizedBox(height: 4),
        const Text(
          'Valores estimados em tempo real (CO₂ washout ~45s)',
          style: TextStyle(
            color: _dimWhite,
            fontSize: 7,
            fontFamily: 'monospace',
            height: 1.3,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _LiveValue(
                      label: 'pH',
                      value: preview.ph.toStringAsFixed(2),
                      color: _phColor(preview.ph),
                    ),
                  ),
                  Expanded(
                    child: _LiveValue(
                      label: 'PaCO₂',
                      value: preview.paco2.toStringAsFixed(1),
                      unit: 'mmHg',
                      color: _pco2Color(preview.paco2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _LiveValue(
                      label: 'PaO₂',
                      value: preview.pao2.toStringAsFixed(0),
                      unit: 'mmHg',
                      color: _pao2Color(preview.pao2),
                    ),
                  ),
                  Expanded(
                    child: _LiveValue(
                      label: 'SaO₂',
                      value: '${preview.sao2.toStringAsFixed(1)}%',
                      color: _sao2Color(preview.sao2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _LiveValue(
                      label: 'HCO₃',
                      value: preview.hco3.toStringAsFixed(1),
                      unit: 'mEq/L',
                      color: _hco3Color(preview.hco3),
                    ),
                  ),
                  Expanded(
                    child: _LiveValue(
                      label: 'P/F',
                      value: preview.pfRatio.toStringAsFixed(0),
                      color: _pfColor(preview.pfRatio),
                    ),
                  ),
                ],
              ),
              const Divider(color: _border, height: 10),
              Row(
                children: [
                  Expanded(
                    child: _LiveValue(
                      label: 'VA',
                      value: preview.alveolarVentilation.toStringAsFixed(1),
                      unit: 'L/min',
                      color: _cyan,
                    ),
                  ),
                  Expanded(
                    child: _LiveValue(
                      label: 'VM',
                      value: preview.minuteVolume.toStringAsFixed(1),
                      unit: 'L/min',
                      color: _cyan,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _RequestButton — "Solicitar Gasometria" with loading state
// ═══════════════════════════════════════════════════════════════════════════

class _RequestButton extends ConsumerWidget {
  const _RequestButton({required this.pending});

  final bool pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: pending
            ? null
            : () {
                HapticFeedback.mediumImpact();
                ref
                    .read(bloodGasLabNotifierProvider.notifier)
                    .requestGasometry();
              },
        icon: pending
            ? const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: _amber,
                ),
              )
            : const Icon(Icons.science_rounded, size: 14),
        label: Text(
          pending ? 'PROCESSANDO...' : 'SOLICITAR GASOMETRIA',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              pending ? _amber.withValues(alpha: 0.08) : _teal.withValues(alpha: 0.15),
          foregroundColor: pending ? _amber : _teal,
          disabledBackgroundColor: _amber.withValues(alpha: 0.08),
          disabledForegroundColor: _amber,
          side: BorderSide(
            color: (pending ? _amber : _teal).withValues(alpha: 0.3),
          ),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _LabResultCard — frozen lab result
// ═══════════════════════════════════════════════════════════════════════════

class _LabResultCard extends StatelessWidget {
  const _LabResultCard({
    required this.result,
    required this.resultNumber,
  });

  final DynamicAbgResult result;
  final int resultNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _teal.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _teal.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header.
          Row(
            children: [
              Icon(Icons.assignment_rounded, size: 12, color: _teal),
              const SizedBox(width: 4),
              Text(
                'GASOMETRIA #$resultNumber',
                style: const TextStyle(
                  color: _teal,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  'RESULTADO',
                  style: TextStyle(
                    color: _green,
                    fontSize: 6,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Values grid.
          _ResultRow(
            label: 'pH',
            value: result.ph.toStringAsFixed(2),
            ref: '7.35 – 7.45',
            color: _phColor(result.ph),
          ),
          _ResultRow(
            label: 'PaCO₂',
            value: '${result.paco2.toStringAsFixed(1)} mmHg',
            ref: '35 – 45',
            color: _pco2Color(result.paco2),
          ),
          _ResultRow(
            label: 'PaO₂',
            value: '${result.pao2.toStringAsFixed(0)} mmHg',
            ref: '80 – 100',
            color: _pao2Color(result.pao2),
          ),
          _ResultRow(
            label: 'HCO₃',
            value: '${result.hco3.toStringAsFixed(1)} mEq/L',
            ref: '22 – 26',
            color: _hco3Color(result.hco3),
          ),
          _ResultRow(
            label: 'SaO₂',
            value: '${result.sao2.toStringAsFixed(1)}%',
            ref: '95 – 100',
            color: _sao2Color(result.sao2),
          ),
          const Divider(color: _border, height: 8),
          _ResultRow(
            label: 'P/F',
            value: result.pfRatio.toStringAsFixed(0),
            ref: '> 300',
            color: _pfColor(result.pfRatio),
          ),
          _ResultRow(
            label: 'VA',
            value: '${result.alveolarVentilation.toStringAsFixed(1)} L/min',
            ref: '4–6',
            color: _cyan,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _EmptyResultCard — placeholder before first gasometry
// ═══════════════════════════════════════════════════════════════════════════

class _EmptyResultCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _border),
      ),
      child: const Column(
        children: [
          Icon(Icons.science_outlined, size: 20, color: _dimWhite),
          SizedBox(height: 6),
          Text(
            'Nenhuma gasometria solicitada.\n'
            'Clique acima para coletar amostra.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _dimWhite,
              fontSize: 8,
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _WeaningSection — PSV weaning readiness criteria
// ═══════════════════════════════════════════════════════════════════════════

class _WeaningSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weaning = ref.watch(weaningAssessmentProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header(icon: Icons.trending_up_rounded, label: 'DESMAME VENTILATÓRIO'),
        const SizedBox(height: 4),

        // RSBI highlight.
        _RsbiCard(rsbi: weaning.rsbi),
        const SizedBox(height: 6),

        // Readiness badge.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: (weaning.readyToWean ? _green : _amber)
                .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: (weaning.readyToWean ? _green : _amber)
                  .withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            weaning.readyToWean
                ? '✓ APTO PARA DESMAME (${weaning.passedCount}/${weaning.totalCount})'
                : '✗ NÃO APTO (${weaning.passedCount}/${weaning.totalCount} critérios)',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: weaning.readyToWean ? _green : _amber,
              fontSize: 9,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Criteria list.
        ...weaning.criteria.map(_buildCriterion),
      ],
    );
  }

  Widget _buildCriterion(WeaningCriterion c) {
    final color = c.passed ? _green : _red;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          children: [
            // Pass/fail icon.
            Icon(
              c.passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
              size: 10,
              color: color,
            ),
            const SizedBox(width: 6),
            // Name.
            Expanded(
              child: Text(
                c.name,
                style: const TextStyle(
                  color: _dimWhite,
                  fontSize: 8,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            // Value.
            Text(
              '${c.value} ${c.unit}',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 6),
            // Target.
            Text(
              c.target,
              style: TextStyle(
                color: color.withValues(alpha: 0.4),
                fontSize: 7,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _RsbiCard — prominent Tobin index display
// ═══════════════════════════════════════════════════════════════════════════

class _RsbiCard extends StatelessWidget {
  const _RsbiCard({required this.rsbi});

  final double rsbi;

  @override
  Widget build(BuildContext context) {
    final passed = rsbi < 105;
    final color = passed ? _green : _red;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'RSBI (Tobin)',
                style: TextStyle(
                  color: color.withValues(alpha: 0.6),
                  fontSize: 7,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'FR / VT(L)',
                style: TextStyle(
                  color: color.withValues(alpha: 0.35),
                  fontSize: 6,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            rsbi > 900 ? '---' : rsbi.toStringAsFixed(0),
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                passed ? 'FAVORÁVEL' : 'DESFAVORÁVEL',
                style: TextStyle(
                  color: color,
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                'meta < 105',
                style: TextStyle(
                  color: color.withValues(alpha: 0.4),
                  fontSize: 6,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared building blocks
// ═══════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 11, color: _teal),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: _teal,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            fontFamily: 'monospace',
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

class _LiveValue extends StatelessWidget {
  const _LiveValue({
    required this.label,
    required this.value,
    this.unit = '',
    required this.color,
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: const TextStyle(
                color: _dimWhite,
                fontSize: 7,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
              ),
            ),
          ),
          if (unit.isNotEmpty)
            Text(
              unit,
              style: TextStyle(
                color: color.withValues(alpha: 0.35),
                fontSize: 7,
                fontFamily: 'monospace',
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    required this.ref,
    required this.color,
  });

  final String label;
  final String value;
  final String ref;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 3),
              ],
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(
              label,
              style: const TextStyle(
                color: _dimWhite,
                fontSize: 8,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            ref,
            style: TextStyle(
              color: color.withValues(alpha: 0.3),
              fontSize: 6,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Colour helpers
// ═══════════════════════════════════════════════════════════════════════════

Color _phColor(double ph) =>
    ph < 7.35 || ph > 7.45 ? _red : _green;

Color _pco2Color(double pco2) =>
    pco2 > 45 || pco2 < 35 ? _amber : _green;

Color _pao2Color(double pao2) =>
    pao2 < 60 ? _red : (pao2 < 80 ? _amber : _green);

Color _sao2Color(double sao2) =>
    sao2 < 90 ? _red : (sao2 < 95 ? _amber : _green);

Color _hco3Color(double hco3) =>
    hco3 < 22 || hco3 > 26 ? _amber : _green;

Color _pfColor(double pf) =>
    pf < 100 ? _red : (pf < 200 ? _amber : (pf < 300 ? _cyan : _green));
