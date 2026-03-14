import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/pathophysiology_provider.dart';
import '../../application/providers/ventilator_params_provider.dart';
import '../../domain/enums/ventilation_enums.dart';
import 'bedside_gasometry_tab.dart';
import 'scenario_panel.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AMPLE colour system
// ═══════════════════════════════════════════════════════════════════════════

/// Vibrant Coral — used for critical adjustments and active controls.
const _coral = Color(0xFFFF6B6B);

/// Deep Teal — used for navigation and secondary UI elements.
const _teal = Color(0xFF00897B);

/// Teal accent for selected mode chips and section headers.
const _tealLight = Color(0xFF4DB6AC);

/// Panel background matching the ICU monitor theme.
const _panelBg = Color(0xFF1A2230);

/// Surface for cards and soft-key containers.
const _surface = Color(0xFF212B3A);

/// Subtle border for cards and dividers.
const _border = Color(0x14FFFFFF);

/// Dim white for labels.
const _dimWhite = Color(0x8CFFFFFF);

/// Amber for mode-specific highlights.
const _amber = Color(0xFFF59E0B);

// ═══════════════════════════════════════════════════════════════════════════
// VentilatorControlPanel — main responsive control panel widget
// ═══════════════════════════════════════════════════════════════════════════

/// Modern soft-key ventilator control panel with AMPLE colour system.
///
/// ## Layout modes
///
/// - **Narrow** (< 380 px): single-column vertical layout, ideal for
///   phones in portrait or as a side panel.
/// - **Wide** (>= 380 px): two-column grid with controls on the left
///   and clinical scenarios on the right, ideal for tablets.
///
/// ## AMPLE colour coding
///
/// - **Vibrant Coral** (`#FF6B6B`): critical parameter adjustments
///   (VT, PEEP, PIP, PS), active states on soft-keys.
/// - **Deep Teal** (`#00897B`): navigation, mode selectors, section
///   headers, clinical scenario cards.
///
/// All changes update [ventParamsNotifierProvider] in real time.
class VentilatorControlPanel extends ConsumerWidget {
  const VentilatorControlPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasActive = ref.watch(hasActivePathophysiologyProvider);

    return Container(
      color: _panelBg,
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // ── Tab bar ──────────────────────────────────────────────
            TabBar(
              isScrollable: false,
              indicatorColor: _teal,
              indicatorWeight: 2,
              labelColor: _tealLight,
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
              dividerHeight: 0,
              tabs: [
                const Tab(
                  height: 32,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tune_rounded, size: 14),
                      SizedBox(width: 3),
                      Text('VENT'),
                    ],
                  ),
                ),
                const Tab(
                  height: 32,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bloodtype_rounded, size: 14),
                      SizedBox(width: 3),
                      Text('GASO'),
                    ],
                  ),
                ),
                Tab(
                  height: 32,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, size: 14),
                      const SizedBox(width: 3),
                      const Text('CENA'),
                      if (hasActive) ...[
                        const SizedBox(width: 3),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFFF4466),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            Container(height: 1, color: _border),

            // ── Tab views ────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 0: Ventilator controls (existing content).
                  _VentilatorContent(),
                  // Tab 1: Gasometry input + analysis + apply.
                  const BedsideGasometryTab(),
                  // Tab 2: Pathophysiology scenarios.
                  const ScenarioPanel(),
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
// _VentilatorContent — single-column ventilator controls (full width)
// ═══════════════════════════════════════════════════════════════════════════

class _VentilatorContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: _panelBg,
      child: ListView(
        padding: const EdgeInsets.all(10),
        children: const [
          _ModeSelector(),
          SizedBox(height: 10),
          _ControlsSection(),
          SizedBox(height: 10),
          _ModeSpecificControls(),
          SizedBox(height: 10),
          _LungMechanicsSection(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _ModeSelector — VCV / PCV / PSV soft-key row
// ═══════════════════════════════════════════════════════════════════════════

class _ModeSelector extends ConsumerWidget {
  const _ModeSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(ventParamsNotifierProvider);
    final notifier = ref.read(ventParamsNotifierProvider.notifier);
    final presetNotifier = ref.read(activePresetProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(icon: Icons.air_rounded, label: 'MODO'),
        const SizedBox(height: 6),
        Row(
          children: VentMode.values.map((mode) {
            final selected = params.mode == mode;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _SoftKey(
                  label: mode.shortLabel,
                  subtitle: _modeSubtitle(mode),
                  selected: selected,
                  selectedColor: _teal,
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
        const SizedBox(height: 4),
        // Mode description.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _teal.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _teal.withValues(alpha: 0.12)),
          ),
          child: Text(
            params.mode.label,
            style: const TextStyle(
              color: _tealLight,
              fontSize: 12,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  static String _modeSubtitle(VentMode mode) => switch (mode) {
        VentMode.vcv => 'Vol',
        VentMode.pcv => 'Press',
        VentMode.psv => 'Suporte',
        VentMode.aprv => 'Bi-nível',
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// _ControlsSection — common parameters (RR, PEEP, FiO2, I:E)
// ═══════════════════════════════════════════════════════════════════════════

class _ControlsSection extends ConsumerWidget {
  const _ControlsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(ventParamsNotifierProvider);
    final notifier = ref.read(ventParamsNotifierProvider.notifier);
    final presetNotifier = ref.read(activePresetProvider.notifier);

    void clearPreset() => presetNotifier.select(null);

    final isAprv = params.mode == VentMode.aprv;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.tune_rounded,
          label: 'CONTROLES',
        ),
        const SizedBox(height: 6),

        if (!isAprv) ...[
          _ParamKnob(
            label: 'FR',
            value: '${params.rr}',
            unit: 'rpm',
            color: _coral,
            onDecrement: () {
              notifier.updateRR((params.rr - 1).clamp(6, 40));
              clearPreset();
            },
            onIncrement: () {
              notifier.updateRR((params.rr + 1).clamp(6, 40));
              clearPreset();
            },
          ),
          _ParamKnob(
            label: 'PEEP',
            value: params.peep.toStringAsFixed(0),
            unit: 'cmH₂O',
            color: _coral,
            onDecrement: () {
              notifier.updatePeep((params.peep - 1).clamp(0, 25));
              clearPreset();
            },
            onIncrement: () {
              notifier.updatePeep((params.peep + 1).clamp(0, 25));
              clearPreset();
            },
          ),
        ],
        _ParamKnob(
          label: 'FiO₂',
          value: '${params.fio2}',
          unit: '%',
          color: _coral,
          onDecrement: () {
            notifier.updateFio2((params.fio2 - 5).clamp(21, 100));
            clearPreset();
          },
          onIncrement: () {
            notifier.updateFio2((params.fio2 + 5).clamp(21, 100));
            clearPreset();
          },
        ),
        if (!isAprv)
          _ParamKnob(
            label: 'I:E',
            value: '1:${params.ieRatio.toStringAsFixed(1)}',
            unit: '',
            color: _tealLight,
            onDecrement: () {
              notifier.updateIE((params.ieRatio - 0.5).clamp(1.0, 5.0));
              clearPreset();
            },
            onIncrement: () {
              notifier.updateIE((params.ieRatio + 0.5).clamp(1.0, 5.0));
              clearPreset();
            },
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _ModeSpecificControls — VT (VCV), PIP (PCV), PS+Effort (PSV)
// ═══════════════════════════════════════════════════════════════════════════

class _ModeSpecificControls extends ConsumerWidget {
  const _ModeSpecificControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(ventParamsNotifierProvider);
    final notifier = ref.read(ventParamsNotifierProvider.notifier);
    final presetNotifier = ref.read(activePresetProvider.notifier);

    void clearPreset() => presetNotifier.select(null);

    final title = switch (params.mode) {
      VentMode.vcv => 'VOLUME (VCV)',
      VentMode.pcv => 'PRESSÃO (PCV)',
      VentMode.psv => 'SUPORTE (PSV)',
      VentMode.aprv => 'APRV',
    };

    final icon = switch (params.mode) {
      VentMode.vcv => Icons.straighten_rounded,
      VentMode.pcv => Icons.compress_rounded,
      VentMode.psv => Icons.self_improvement_rounded,
      VentMode.aprv => Icons.swap_vert_rounded,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: icon, label: title),
        const SizedBox(height: 6),

        if (params.mode == VentMode.vcv)
          _ParamKnob(
            label: 'VT',
            value: '${params.vt}',
            unit: 'mL',
            color: _coral,
            onDecrement: () {
              notifier.updateVT((params.vt - 10).clamp(200, 800));
              clearPreset();
            },
            onIncrement: () {
              notifier.updateVT((params.vt + 10).clamp(200, 800));
              clearPreset();
            },
          ),

        if (params.mode == VentMode.pcv)
          _ParamKnob(
            label: 'PIP',
            value: params.pip.toStringAsFixed(0),
            unit: 'cmH₂O',
            color: _coral,
            onDecrement: () {
              notifier.updatePIP((params.pip - 1).clamp(5, 40));
              clearPreset();
            },
            onIncrement: () {
              notifier.updatePIP((params.pip + 1).clamp(5, 40));
              clearPreset();
            },
          ),

        if (params.mode == VentMode.psv) ...[
          _ParamKnob(
            label: 'PS',
            value: params.ps.toStringAsFixed(0),
            unit: 'cmH₂O',
            color: _coral,
            onDecrement: () {
              notifier.updatePS((params.ps - 1).clamp(5, 30));
              clearPreset();
            },
            onIncrement: () {
              notifier.updatePS((params.ps + 1).clamp(5, 30));
              clearPreset();
            },
          ),
          _ParamKnob(
            label: 'Esforço',
            value: params.patientEffort.toStringAsFixed(0),
            unit: 'cmH₂O',
            color: _amber,
            onDecrement: () {
              notifier.updateEffort(
                  (params.patientEffort - 1).clamp(0, 10));
              clearPreset();
            },
            onIncrement: () {
              notifier.updateEffort(
                  (params.patientEffort + 1).clamp(0, 10));
              clearPreset();
            },
          ),
        ],

        if (params.mode == VentMode.aprv) ...[
          _ParamKnob(
            label: 'P-high',
            value: params.pHigh.toStringAsFixed(0),
            unit: 'cmH₂O',
            color: _coral,
            onDecrement: () {
              notifier.updatePHigh((params.pHigh - 1).clamp(15, 40));
              clearPreset();
            },
            onIncrement: () {
              notifier.updatePHigh((params.pHigh + 1).clamp(15, 40));
              clearPreset();
            },
          ),
          _ParamKnob(
            label: 'P-low',
            value: params.pLow.toStringAsFixed(0),
            unit: 'cmH₂O',
            color: _coral,
            onDecrement: () {
              notifier.updatePLow((params.pLow - 1).clamp(0, 10));
              clearPreset();
            },
            onIncrement: () {
              notifier.updatePLow((params.pLow + 1).clamp(0, 10));
              clearPreset();
            },
          ),
          _ParamKnob(
            label: 'T-high',
            value: params.tHigh.toStringAsFixed(1),
            unit: 's',
            color: _tealLight,
            onDecrement: () {
              notifier.updateTHigh(
                  double.parse((params.tHigh - 0.5).clamp(2.0, 8.0).toStringAsFixed(1)));
              clearPreset();
            },
            onIncrement: () {
              notifier.updateTHigh(
                  double.parse((params.tHigh + 0.5).clamp(2.0, 8.0).toStringAsFixed(1)));
              clearPreset();
            },
          ),
          _ParamKnob(
            label: 'T-low',
            value: params.tLow.toStringAsFixed(1),
            unit: 's',
            color: _tealLight,
            onDecrement: () {
              notifier.updateTLow(
                  double.parse((params.tLow - 0.1).clamp(0.2, 1.5).toStringAsFixed(1)));
              clearPreset();
            },
            onIncrement: () {
              notifier.updateTLow(
                  double.parse((params.tLow + 0.1).clamp(0.2, 1.5).toStringAsFixed(1)));
              clearPreset();
            },
          ),
          _ParamKnob(
            label: 'Resp.Esp.',
            value: '${params.spontaneousRR}',
            unit: 'rpm',
            color: _amber,
            onDecrement: () {
              notifier.updateSpontaneousRR(
                  (params.spontaneousRR - 1).clamp(0, 30));
              clearPreset();
            },
            onIncrement: () {
              notifier.updateSpontaneousRR(
                  (params.spontaneousRR + 1).clamp(0, 30));
              clearPreset();
            },
          ),
          _ParamKnob(
            label: 'Esforço',
            value: params.patientEffort.toStringAsFixed(0),
            unit: 'cmH₂O',
            color: _amber,
            onDecrement: () {
              notifier.updateEffort(
                  (params.patientEffort - 1).clamp(0, 10));
              clearPreset();
            },
            onIncrement: () {
              notifier.updateEffort(
                  (params.patientEffort + 1).clamp(0, 10));
              clearPreset();
            },
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _LungMechanicsSection — Compliance + Resistance
// ═══════════════════════════════════════════════════════════════════════════

class _LungMechanicsSection extends ConsumerWidget {
  const _LungMechanicsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ref.watch(ventParamsNotifierProvider);
    final notifier = ref.read(ventParamsNotifierProvider.notifier);
    final presetNotifier = ref.read(activePresetProvider.notifier);

    void clearPreset() => presetNotifier.select(null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.biotech_rounded,
          label: 'MECÂNICA PULMONAR',
        ),
        const SizedBox(height: 6),
        _ParamKnob(
          label: 'Compl.',
          value: params.compliance.toStringAsFixed(0),
          unit: 'mL/cmH₂O',
          color: _tealLight,
          onDecrement: () {
            notifier.updateCompliance(
                (params.compliance - 5).clamp(10, 100));
            clearPreset();
          },
          onIncrement: () {
            notifier.updateCompliance(
                (params.compliance + 5).clamp(10, 100));
            clearPreset();
          },
        ),
        _ParamKnob(
          label: 'Resist.',
          value: params.resistance.toStringAsFixed(0),
          unit: 'cmH₂O/L/s',
          color: _tealLight,
          onDecrement: () {
            notifier.updateResistance(
                (params.resistance - 1).clamp(3, 40));
            clearPreset();
          },
          onIncrement: () {
            notifier.updateResistance(
                (params.resistance + 1).clamp(3, 40));
            clearPreset();
          },
        ),

        // Tau display.
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              const SizedBox(width: 56),
              Text(
                'τ = ${params.tau.toStringAsFixed(2)}s',
                style: TextStyle(
                  color: params.tau > 1.0 ? _coral : _tealLight,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 6),
              Text(
                params.tau > 1.0 ? '(risco air trapping)' : '(normal)',
                style: TextStyle(
                  color: (params.tau > 1.0 ? _coral : _tealLight)
                      .withValues(alpha: 0.5),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared building blocks
// ═══════════════════════════════════════════════════════════════════════════

/// Section header with icon and label in Deep Teal.
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

/// Modern ventilator soft-key button with active state.
class _SoftKey extends StatelessWidget {
  const _SoftKey({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? selectedColor.withValues(alpha: 0.15)
                : _surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected
                  ? selectedColor.withValues(alpha: 0.6)
                  : _border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: selectedColor.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected ? selectedColor : _dimWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: (selected ? selectedColor : _dimWhite)
                      .withValues(alpha: 0.5),
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Parameter knob — soft-key style +/- control with coral accent.
class _ParamKnob extends StatelessWidget {
  const _ParamKnob({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final String value;
  final String unit;
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
            // Label.
            SizedBox(
              width: 50,
              child: Text(
                label,
                style: const TextStyle(
                  color: _dimWhite,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),

            // Decrement button.
            _KnobButton(
              icon: Icons.remove,
              color: color,
              onTap: () {
                HapticFeedback.lightImpact();
                onDecrement();
              },
            ),
            const SizedBox(width: 4),

            // Value.
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

            // Increment button.
            _KnobButton(
              icon: Icons.add,
              color: color,
              onTap: () {
                HapticFeedback.lightImpact();
                onIncrement();
              },
            ),

            // Unit.
            SizedBox(
              width: 52,
              child: Text(
                unit,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: _dimWhite,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Round +/- button for parameter knobs — styled as ventilator soft-key.
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

