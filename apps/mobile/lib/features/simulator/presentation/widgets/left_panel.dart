import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/abg_provider.dart';
import '../../application/providers/pathophysiology_provider.dart';
import '../../application/providers/patient_provider.dart';
import '../../application/providers/simulation_provider.dart';
import '../../application/providers/ventilator_params_provider.dart';
import '../../data/presets/clinical_presets.dart';
import '../../domain/entities/ventilator_entities.dart';
import '../../domain/enums/ventilation_enums.dart';
import 'blood_gas_panel.dart';
import 'scenario_panel.dart';

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
const _labelStyle = TextStyle(
  color: _dimWhite,
  fontSize: 12,
  fontFamily: 'monospace',
);
const _valueStyle = TextStyle(
  color: Color(0xE6FFFFFF),
  fontSize: 13,
  fontWeight: FontWeight.w700,
  fontFamily: 'monospace',
);

/// Left control panel with 5 tabs: Vent, Paciente, Gaso, Analise, Cenarios.
class LeftPanel extends ConsumerWidget {
  const LeftPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActive = ref.watch(hasActivePathophysiologyProvider);

    return Container(
      decoration: const BoxDecoration(
        color: _panelBg,
        border: Border(right: BorderSide(color: _borderColor, width: 1)),
      ),
      child: DefaultTabController(
        length: 6,
        child: Column(
          children: [
            // Tab bar.
            TabBar(
              isScrollable: false,
              indicatorColor: _green,
              indicatorWeight: 2,
              labelColor: _green,
              unselectedLabelColor: _dimWhite,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              labelPadding: EdgeInsets.zero,
              tabs: [
                const Tab(text: 'VENT', height: 30),
                const Tab(text: 'PAC', height: 30),
                const Tab(text: 'GASO', height: 30),
                const Tab(text: 'ANAL', height: 30),
                const Tab(text: 'LAB', height: 30),
                Tab(
                  height: 30,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('CENA'),
                      if (hasActive) ...[
                        const SizedBox(width: 3),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: _red,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 1, color: _borderColor),

            // Tab views.
            const Expanded(
              child: TabBarView(
                children: [
                  _VentTab(),
                  _PatientTab(),
                  _GasoTab(),
                  _AnalysisTab(),
                  BloodGasPanel(),
                  ScenarioPanel(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 1 — Ventilador
// ═══════════════════════════════════════════════════════════════════════════

class _VentTab extends ConsumerWidget {
  const _VentTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(ventParamsNotifierProvider);
    final activePreset = ref.watch(activePresetProvider);
    final notifier = ref.read(ventParamsNotifierProvider.notifier);
    final presetNotifier = ref.read(activePresetProvider.notifier);
    final simNotifier = ref.read(simulationNotifierProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // ── Mode selector ────────────────────────────────────────────
        const _SectionLabel('MODO'),
        const SizedBox(height: 4),
        Row(
          children: VentMode.values.map((mode) {
            final selected = params.mode == mode;
            final color = _modeColor(mode);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _ChipButton(
                  label: mode.shortLabel,
                  selected: selected,
                  color: color,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    notifier.updateMode(mode);
                    presetNotifier.select(null);
                  },
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 10),

        // ── Presets ──────────────────────────────────────────────────
        const _SectionLabel('PRESET CLÍNICO'),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: ClinicalPresetType.values.map((preset) {
            final selected = activePreset == preset;
            return _ChipButton(
              label: ClinicalPresets.title(preset),
              selected: selected,
              color: _green,
              onTap: () {
                HapticFeedback.lightImpact();
                notifier.applyPreset(preset);
                presetNotifier.select(preset);
                simNotifier.reset();
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 10),
        const Divider(color: _borderColor),

        // ── Common controls ──────────────────────────────────────────
        const _SectionLabel('CONTROLES'),
        const SizedBox(height: 4),
        if (params.mode != VentMode.aprv) ...[
          _NumericRow(
            label: 'FR',
            value: params.rr.toString(),
            unit: 'rpm',
            onDecrement: () {
              notifier.updateRR((params.rr - 1).clamp(6, 40));
              presetNotifier.select(null);
            },
            onIncrement: () {
              notifier.updateRR((params.rr + 1).clamp(6, 40));
              presetNotifier.select(null);
            },
          ),
          _NumericRow(
            label: 'PEEP',
            value: params.peep.toStringAsFixed(0),
            unit: 'cmH₂O',
            onDecrement: () {
              notifier.updatePeep((params.peep - 1).clamp(0, 25));
              presetNotifier.select(null);
            },
            onIncrement: () {
              notifier.updatePeep((params.peep + 1).clamp(0, 25));
              presetNotifier.select(null);
            },
          ),
        ],
        _NumericRow(
          label: 'FiO₂',
          value: '${params.fio2}',
          unit: '%',
          onDecrement: () {
            notifier.updateFio2((params.fio2 - 5).clamp(21, 100));
            presetNotifier.select(null);
          },
          onIncrement: () {
            notifier.updateFio2((params.fio2 + 5).clamp(21, 100));
            presetNotifier.select(null);
          },
        ),
        if (params.mode != VentMode.aprv)
          _NumericRow(
            label: 'I:E',
            value: '1:${params.ieRatio.toStringAsFixed(1)}',
            unit: '',
            onDecrement: () {
              notifier.updateIE((params.ieRatio - 0.5).clamp(1.0, 5.0));
              presetNotifier.select(null);
            },
            onIncrement: () {
              notifier.updateIE((params.ieRatio + 0.5).clamp(1.0, 5.0));
              presetNotifier.select(null);
            },
          ),

        const SizedBox(height: 6),
        const Divider(color: _borderColor),

        // ── Mode-specific controls ───────────────────────────────────
        _SectionLabel(_modeSpecificTitle(params.mode)),
        const SizedBox(height: 4),

        if (params.mode == VentMode.vcv)
          _NumericRow(
            label: 'VT',
            value: '${params.vt}',
            unit: 'mL',
            onDecrement: () {
              notifier.updateVT((params.vt - 10).clamp(200, 800));
              presetNotifier.select(null);
            },
            onIncrement: () {
              notifier.updateVT((params.vt + 10).clamp(200, 800));
              presetNotifier.select(null);
            },
          ),

        if (params.mode == VentMode.pcv)
          _NumericRow(
            label: 'PIP',
            value: params.pip.toStringAsFixed(0),
            unit: 'cmH₂O',
            onDecrement: () {
              notifier.updatePIP((params.pip - 1).clamp(5, 40));
              presetNotifier.select(null);
            },
            onIncrement: () {
              notifier.updatePIP((params.pip + 1).clamp(5, 40));
              presetNotifier.select(null);
            },
          ),

        if (params.mode == VentMode.psv) ...[
          _NumericRow(
            label: 'PS',
            value: params.ps.toStringAsFixed(0),
            unit: 'cmH₂O',
            onDecrement: () {
              notifier.updatePS((params.ps - 1).clamp(5, 30));
              presetNotifier.select(null);
            },
            onIncrement: () {
              notifier.updatePS((params.ps + 1).clamp(5, 30));
              presetNotifier.select(null);
            },
          ),
          _NumericRow(
            label: 'Esforço',
            value: params.patientEffort.toStringAsFixed(0),
            unit: 'cmH₂O',
            onDecrement: () {
              notifier.updateEffort(
                  (params.patientEffort - 1).clamp(0, 10));
              presetNotifier.select(null);
            },
            onIncrement: () {
              notifier.updateEffort(
                  (params.patientEffort + 1).clamp(0, 10));
              presetNotifier.select(null);
            },
          ),
        ],

        if (params.mode == VentMode.aprv) ...[
          _NumericRow(
            label: 'P-high',
            value: params.pHigh.toStringAsFixed(0),
            unit: 'cmH₂O',
            onDecrement: () {
              notifier.updatePHigh((params.pHigh - 1).clamp(15, 40));
              presetNotifier.select(null);
            },
            onIncrement: () {
              notifier.updatePHigh((params.pHigh + 1).clamp(15, 40));
              presetNotifier.select(null);
            },
          ),
          _NumericRow(
            label: 'P-low',
            value: params.pLow.toStringAsFixed(0),
            unit: 'cmH₂O',
            onDecrement: () {
              notifier.updatePLow((params.pLow - 1).clamp(0, 10));
              presetNotifier.select(null);
            },
            onIncrement: () {
              notifier.updatePLow((params.pLow + 1).clamp(0, 10));
              presetNotifier.select(null);
            },
          ),
          _NumericRow(
            label: 'T-high',
            value: params.tHigh.toStringAsFixed(1),
            unit: 's',
            onDecrement: () {
              notifier.updateTHigh(
                  double.parse((params.tHigh - 0.5).clamp(2.0, 8.0).toStringAsFixed(1)));
              presetNotifier.select(null);
            },
            onIncrement: () {
              notifier.updateTHigh(
                  double.parse((params.tHigh + 0.5).clamp(2.0, 8.0).toStringAsFixed(1)));
              presetNotifier.select(null);
            },
          ),
          _NumericRow(
            label: 'T-low',
            value: params.tLow.toStringAsFixed(1),
            unit: 's',
            onDecrement: () {
              notifier.updateTLow(
                  double.parse((params.tLow - 0.1).clamp(0.2, 1.5).toStringAsFixed(1)));
              presetNotifier.select(null);
            },
            onIncrement: () {
              notifier.updateTLow(
                  double.parse((params.tLow + 0.1).clamp(0.2, 1.5).toStringAsFixed(1)));
              presetNotifier.select(null);
            },
          ),
          _NumericRow(
            label: 'Resp.Esp.',
            value: '${params.spontaneousRR}',
            unit: 'rpm',
            onDecrement: () {
              notifier.updateSpontaneousRR(
                  (params.spontaneousRR - 1).clamp(0, 30));
              presetNotifier.select(null);
            },
            onIncrement: () {
              notifier.updateSpontaneousRR(
                  (params.spontaneousRR + 1).clamp(0, 30));
              presetNotifier.select(null);
            },
          ),
          _NumericRow(
            label: 'Esforço',
            value: params.patientEffort.toStringAsFixed(0),
            unit: 'cmH₂O',
            onDecrement: () {
              notifier.updateEffort(
                  (params.patientEffort - 1).clamp(0, 10));
              presetNotifier.select(null);
            },
            onIncrement: () {
              notifier.updateEffort(
                  (params.patientEffort + 1).clamp(0, 10));
              presetNotifier.select(null);
            },
          ),
        ],

        const SizedBox(height: 6),
        const Divider(color: _borderColor),

        // ── Lung mechanics ───────────────────────────────────────────
        const _SectionLabel('MECÂNICA PULMONAR'),
        const SizedBox(height: 4),
        _NumericRow(
          label: 'Compl.',
          value: params.compliance.toStringAsFixed(0),
          unit: 'mL/cmH₂O',
          onDecrement: () {
            notifier.updateCompliance(
                (params.compliance - 5).clamp(10, 100));
            presetNotifier.select(null);
          },
          onIncrement: () {
            notifier.updateCompliance(
                (params.compliance + 5).clamp(10, 100));
            presetNotifier.select(null);
          },
        ),
        _NumericRow(
          label: 'Resist.',
          value: params.resistance.toStringAsFixed(0),
          unit: 'cmH₂O/L/s',
          onDecrement: () {
            notifier.updateResistance(
                (params.resistance - 1).clamp(3, 40));
            presetNotifier.select(null);
          },
          onIncrement: () {
            notifier.updateResistance(
                (params.resistance + 1).clamp(3, 40));
            presetNotifier.select(null);
          },
        ),
      ],
    );
  }

  static String _modeSpecificTitle(VentMode mode) => switch (mode) {
        VentMode.vcv => 'VOLUME (VCV)',
        VentMode.pcv => 'PRESSÃO (PCV)',
        VentMode.psv => 'SUPORTE (PSV)',
        VentMode.aprv => 'APRV',
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 2 — Paciente
// ═══════════════════════════════════════════════════════════════════════════

class _PatientTab extends ConsumerWidget {
  const _PatientTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patient = ref.watch(patientNotifierProvider);
    final notifier = ref.read(patientNotifierProvider.notifier);
    final ibw = ref.watch(ibwProvider);
    final bmi = ref.watch(bmiProvider);
    final vt6 = ref.watch(idealVt6Provider);
    final vt8 = ref.watch(idealVt8Provider);

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // ── Sex ──────────────────────────────────────────────────────
        const _SectionLabel('SEXO BIOLÓGICO'),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: _ChipButton(
                label: 'Masculino',
                selected: patient.sex == Sex.male,
                color: _cyan,
                onTap: () {
                  HapticFeedback.lightImpact();
                  notifier.updateSex(Sex.male);
                },
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _ChipButton(
                label: 'Feminino',
                selected: patient.sex == Sex.female,
                color: _cyan,
                onTap: () {
                  HapticFeedback.lightImpact();
                  notifier.updateSex(Sex.female);
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ── Anthropometrics ──────────────────────────────────────────
        const _SectionLabel('ANTROPOMETRIA'),
        const SizedBox(height: 4),
        _NumericRow(
          label: 'Altura',
          value: '${patient.heightCm}',
          unit: 'cm',
          onDecrement: () => notifier
              .updateHeight((patient.heightCm - 1).clamp(140, 210)),
          onIncrement: () => notifier
              .updateHeight((patient.heightCm + 1).clamp(140, 210)),
        ),
        _NumericRow(
          label: 'Peso',
          value: '${patient.weightKg}',
          unit: 'kg',
          onDecrement: () =>
              notifier.updateWeight((patient.weightKg - 1).clamp(30, 200)),
          onIncrement: () =>
              notifier.updateWeight((patient.weightKg + 1).clamp(30, 200)),
        ),
        _NumericRow(
          label: 'Idade',
          value: '${patient.age}',
          unit: 'anos',
          onDecrement: () =>
              notifier.updateAge((patient.age - 1).clamp(18, 100)),
          onIncrement: () =>
              notifier.updateAge((patient.age + 1).clamp(18, 100)),
        ),

        const SizedBox(height: 10),
        const Divider(color: _borderColor),

        // ── Derived values ───────────────────────────────────────────
        const _SectionLabel('VALORES CALCULADOS'),
        const SizedBox(height: 4),
        _DerivedRow(label: 'IBW', value: ibw.toStringAsFixed(1), unit: 'kg'),
        _DerivedRow(
            label: 'IMC', value: bmi.toStringAsFixed(1), unit: 'kg/m²'),
        _DerivedRow(label: 'VT 6mL/kg', value: '$vt6', unit: 'mL'),
        _DerivedRow(label: 'VT 8mL/kg', value: '$vt8', unit: 'mL'),

        const SizedBox(height: 10),

        // ── Protective range indicator ───────────────────────────────
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _green.withValues(alpha: 0.15)),
          ),
          child: Text(
            'Faixa protetora: $vt6 – $vt8 mL',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tab 3 — Gasometria
// ═══════════════════════════════════════════════════════════════════════════

class _GasoTab extends ConsumerWidget {
  const _GasoTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abg = ref.watch(abgInputNotifierProvider);
    final notifier = ref.read(abgInputNotifierProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        const _SectionLabel('GASOMETRIA ARTERIAL'),
        const SizedBox(height: 6),
        _AbgInput(
          label: 'pH',
          value: abg.ph.toStringAsFixed(2),
          refRange: '7.35 – 7.45',
          onDecrement: () => notifier.updatePH(
              double.parse((abg.ph - 0.01).clamp(6.80, 7.80).toStringAsFixed(2))),
          onIncrement: () => notifier.updatePH(
              double.parse((abg.ph + 0.01).clamp(6.80, 7.80).toStringAsFixed(2))),
          color: abg.ph < 7.35 || abg.ph > 7.45 ? _red : _green,
        ),
        _AbgInput(
          label: 'PaCO₂',
          value: abg.pco2.toStringAsFixed(0),
          refRange: '35 – 45 mmHg',
          onDecrement: () =>
              notifier.updatePCO2((abg.pco2 - 1).clamp(10, 120)),
          onIncrement: () =>
              notifier.updatePCO2((abg.pco2 + 1).clamp(10, 120)),
          color: abg.pco2 < 35 || abg.pco2 > 45 ? _amber : _green,
        ),
        _AbgInput(
          label: 'HCO₃',
          value: abg.hco3.toStringAsFixed(0),
          refRange: '22 – 26 mEq/L',
          onDecrement: () =>
              notifier.updateHCO3((abg.hco3 - 1).clamp(5, 50)),
          onIncrement: () =>
              notifier.updateHCO3((abg.hco3 + 1).clamp(5, 50)),
          color: abg.hco3 < 22 || abg.hco3 > 26 ? _amber : _green,
        ),
        _AbgInput(
          label: 'PaO₂',
          value: abg.pao2.toStringAsFixed(0),
          refRange: '80 – 100 mmHg',
          onDecrement: () =>
              notifier.updatePaO2((abg.pao2 - 5).clamp(20, 600)),
          onIncrement: () =>
              notifier.updatePaO2((abg.pao2 + 5).clamp(20, 600)),
          color: abg.pao2 < 60 ? _red : (abg.pao2 < 80 ? _amber : _green),
        ),
        _AbgInput(
          label: 'SaO₂',
          value: abg.sao2.toStringAsFixed(0),
          refRange: '95 – 100 %',
          onDecrement: () =>
              notifier.updateSaO2((abg.sao2 - 1).clamp(50, 100)),
          onIncrement: () =>
              notifier.updateSaO2((abg.sao2 + 1).clamp(50, 100)),
          color: abg.sao2 < 90 ? _red : (abg.sao2 < 95 ? _amber : _green),
        ),
        _AbgInput(
          label: 'Lactato',
          value: abg.lactato.toStringAsFixed(1),
          refRange: '< 2.0 mmol/L',
          onDecrement: () => notifier.updateLactato(
              double.parse((abg.lactato - 0.5).clamp(0, 30).toStringAsFixed(1))),
          onIncrement: () => notifier.updateLactato(
              double.parse((abg.lactato + 0.5).clamp(0, 30).toStringAsFixed(1))),
          color: abg.lactato > 4
              ? _red
              : (abg.lactato > 2 ? _amber : _green),
        ),

        const SizedBox(height: 12),

        // Analyze button.
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              ref.read(abgAnalysisNotifierProvider.notifier).analyze();
              DefaultTabController.of(context).animateTo(3); // → Análise
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
              backgroundColor: _green.withValues(alpha: 0.15),
              foregroundColor: _green,
              side: BorderSide(color: _green.withValues(alpha: 0.3)),
              padding: const EdgeInsets.symmetric(vertical: 10),
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
// Tab 4 — Análise
// ═══════════════════════════════════════════════════════════════════════════

class _AnalysisTab extends ConsumerWidget {
  const _AnalysisTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysis = ref.watch(abgAnalysisNotifierProvider);

    if (analysis == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Insira os valores na aba GASO\ne clique "Analisar Gasometria"',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _dimWhite,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // ── Primary disorder ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _cyan.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _cyan.withValues(alpha: 0.2)),
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

        const SizedBox(height: 10),

        // ── Derived metrics ──────────────────────────────────────────
        const _SectionLabel('MÉTRICAS'),
        const SizedBox(height: 4),
        _DerivedRow(
          label: 'P/F',
          value: analysis.pfRatio.toStringAsFixed(0),
          unit: '',
          color: analysis.pfRatio < 100
              ? _red
              : (analysis.pfRatio < 200 ? _amber : _green),
        ),
        _DerivedRow(
          label: 'ΔP',
          value: analysis.drivingPressure.toStringAsFixed(1),
          unit: 'cmH₂O',
          color: analysis.drivingPressure > 15 ? _red : _green,
        ),
        _DerivedRow(
          label: 'Pplat',
          value: analysis.pplat.toStringAsFixed(0),
          unit: 'cmH₂O',
          color: analysis.pplat > 30 ? _red : _green,
        ),
        _DerivedRow(
          label: 'VT/kg',
          value: analysis.vtPerKg.toStringAsFixed(1),
          unit: 'mL/kg',
          color: analysis.vtPerKg > 8 ? _red : _green,
        ),

        const SizedBox(height: 10),

        // ── Findings ─────────────────────────────────────────────────
        const _SectionLabel('ACHADOS'),
        const SizedBox(height: 4),
        ...analysis.findings.map(_buildFinding),

        const SizedBox(height: 10),

        // ── Actions ──────────────────────────────────────────────────
        if (analysis.actions.isNotEmpty) ...[
          const _SectionLabel('RECOMENDAÇÕES'),
          const SizedBox(height: 4),
          ...analysis.actions.map(_buildAction),
        ],
      ],
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
          borderRadius: BorderRadius.circular(3),
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

  Widget _buildAction(AbgAction action) {
    final urgencyColor =
        action.priority == 0 ? _red : (action.priority == 1 ? _amber : _green);
    return _ActionCardWithApply(action: action, urgencyColor: urgencyColor);
  }

  static Color _alertColor(AlertLevel level) => switch (level) {
        AlertLevel.ok => _green,
        AlertLevel.info => _cyan,
        AlertLevel.warning => _amber,
        AlertLevel.danger => _red,
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared small widgets
// ═══════════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
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

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.5)
                  : const Color(0x14FFFFFF),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? color : _dimWhite,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }
}

/// Numeric row with label, value, unit, and +/- buttons.
class _NumericRow extends StatelessWidget {
  const _NumericRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final String value;
  final String unit;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(label, style: _labelStyle),
          ),
          _PmButton(icon: Icons.remove, onTap: () {
            HapticFeedback.lightImpact();
            onDecrement();
          }),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: _valueStyle,
            ),
          ),
          _PmButton(icon: Icons.add, onTap: () {
            HapticFeedback.lightImpact();
            onIncrement();
          }),
          SizedBox(
            width: 52,
            child: Text(
              unit,
              style: _labelStyle,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _PmButton extends StatelessWidget {
  const _PmButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0x14FFFFFF)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: _dimWhite),
        ),
      ),
    );
  }
}

/// Read-only derived value row.
class _DerivedRow extends StatelessWidget {
  const _DerivedRow({
    required this.label,
    required this.value,
    required this.unit,
    this.color = const Color(0xE0FFFFFF),
  });

  final String label;
  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label, style: _labelStyle)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(unit, style: _labelStyle),
        ],
      ),
    );
  }
}

/// ABG input row with ref range and colour feedback.
class _AbgInput extends StatelessWidget {
  const _AbgInput({
    required this.label,
    required this.value,
    required this.refRange,
    required this.onDecrement,
    required this.onIncrement,
    required this.color,
  });

  final String label;
  final String value;
  final String refRange;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(label, style: _labelStyle),
              ),
              _PmButton(icon: Icons.remove, onTap: () {
                HapticFeedback.lightImpact();
                onDecrement();
              }),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              _PmButton(icon: Icons.add, onTap: () {
                HapticFeedback.lightImpact();
                onIncrement();
              }),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 52, top: 1),
            child: Text(
              refRange,
              style: TextStyle(
                color: color.withValues(alpha: 0.4),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _modeColor(VentMode mode) => switch (mode) {
      VentMode.vcv => _green,
      VentMode.pcv => _cyan,
      VentMode.psv => _amber,
      VentMode.aprv => const Color(0xFFA78BFA),
    };

// ═══════════════════════════════════════════════════════════════════════════
// _ActionCardWithApply — recommendation card with optional APLICAR button
// ═══════════════════════════════════════════════════════════════════════════

class _ActionCardWithApply extends ConsumerWidget {
  const _ActionCardWithApply({
    required this.action,
    required this.urgencyColor,
  });

  final AbgAction action;
  final Color urgencyColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canApply = _isApplicable(action.param);
    final targetValue = canApply ? _extractTarget(action.action) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: urgencyColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: urgencyColor.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(action.icon,
                    style: const TextStyle(fontSize: 10)),
                const SizedBox(width: 4),
                Text(
                  action.param,
                  style: TextStyle(
                    color: urgencyColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'monospace',
                  ),
                ),
                const Spacer(),
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
            Text(
              action.action,
              style: const TextStyle(
                color: Color(0xD0FFFFFF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
                height: 1.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              action.reason,
              style: const TextStyle(
                color: _dimWhite,
                fontSize: 12,
                fontFamily: 'monospace',
                height: 1.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '\uD83D\uDCCD ${action.where}',
              style: TextStyle(
                color: urgencyColor.withValues(alpha: 0.6),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),

            // APLICAR button.
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
                    backgroundColor: _red.withValues(alpha: 0.15),
                    foregroundColor: _red,
                    side: BorderSide(color: _red.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static bool _isApplicable(String param) =>
      param == 'VT' ||
      param == 'FR' ||
      param == 'FiO\u2082' ||
      param == 'PEEP';

  static double? _extractTarget(String actionText) {
    final paraMatch =
        RegExp(r'para\s+(\d+(?:\.\d+)?)').firstMatch(actionText);
    if (paraMatch != null) return double.tryParse(paraMatch.group(1)!);

    final ateMatch =
        RegExp(r'até\s+(\d+(?:\.\d+)?)').firstMatch(actionText);
    if (ateMatch != null) return double.tryParse(ateMatch.group(1)!);

    return null;
  }

  static String _applyLabel(String param, double target) => switch (param) {
        'VT' => 'VT ${target.round()} mL',
        'FR' => 'FR ${target.round()} rpm',
        'FiO\u2082' => 'FiO\u2082 ${target.round()}%',
        'PEEP' => 'PEEP ${target.round()} cmH\u2082O',
        _ => '$param $target',
      };

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
