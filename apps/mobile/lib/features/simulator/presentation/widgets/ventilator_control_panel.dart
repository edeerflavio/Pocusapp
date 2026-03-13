import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/simulation_provider.dart';
import '../../application/providers/ventilator_params_provider.dart';
import '../../data/presets/clinical_presets.dart';
import '../../domain/enums/ventilation_enums.dart';

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
const _panelBg = Color(0xFF0A0E16);

/// Surface for cards and soft-key containers.
const _surface = Color(0xFF111822);

/// Subtle border for cards and dividers.
const _border = Color(0x1A4DB6AC);

/// Dim white for labels.
const _dimWhite = Color(0x80FFFFFF);

/// Bright white for values.
const _brightWhite = Color(0xE0FFFFFF);

/// Amber for mode-specific highlights.
const _amber = Color(0xFFFFAA00);

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 380;

        if (isWide) {
          return _WideLayout();
        }
        return _NarrowLayout();
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _NarrowLayout — single-column for phones / side panel
// ═══════════════════════════════════════════════════════════════════════════

class _NarrowLayout extends ConsumerWidget {
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
          SizedBox(height: 12),
          _ScenariosSection(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _WideLayout — two-column for tablets
// ═══════════════════════════════════════════════════════════════════════════

class _WideLayout extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: _panelBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: controls.
          Expanded(
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
          ),

          // Vertical divider.
          Container(width: 1, color: _border),

          // Right: scenarios.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(10),
              children: const [
                _ScenariosSection(),
              ],
            ),
          ),
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
              fontSize: 8,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.tune_rounded,
          label: 'CONTROLES',
        ),
        const SizedBox(height: 6),

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
    };

    final icon = switch (params.mode) {
      VentMode.vcv => Icons.straighten_rounded,
      VentMode.pcv => Icons.compress_rounded,
      VentMode.psv => Icons.self_improvement_rounded,
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
                  fontSize: 9,
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
                  fontSize: 7,
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
// _ScenariosSection — clinical preset cards
// ═══════════════════════════════════════════════════════════════════════════

class _ScenariosSection extends ConsumerWidget {
  const _ScenariosSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePreset = ref.watch(activePresetProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.medical_services_rounded,
          label: 'CENÁRIOS CLÍNICOS',
        ),
        const SizedBox(height: 4),
        const Text(
          'Carregue presets validados para simular\ncenários clínicos reais.',
          style: TextStyle(
            color: _dimWhite,
            fontSize: 7,
            fontFamily: 'monospace',
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        ...ClinicalPresetType.values.map(
          (preset) => _ScenarioCard(
            preset: preset,
            isActive: activePreset == preset,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _ScenarioCard — single clinical scenario card
// ═══════════════════════════════════════════════════════════════════════════

class _ScenarioCard extends ConsumerWidget {
  const _ScenarioCard({
    required this.preset,
    required this.isActive,
  });

  final ClinicalPresetType preset;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(ventParamsNotifierProvider.notifier);
    final presetNotifier = ref.read(activePresetProvider.notifier);
    final simNotifier = ref.read(simulationNotifierProvider.notifier);
    final params = ClinicalPresets.presets[preset]!;

    final accentColor = isActive ? _coral : _teal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            notifier.applyPreset(preset);
            presetNotifier.select(preset);
            simNotifier.reset();
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive
                  ? accentColor.withValues(alpha: 0.08)
                  : _surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isActive
                    ? accentColor.withValues(alpha: 0.4)
                    : _border,
                width: isActive ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title row.
                Row(
                  children: [
                    Text(
                      _scenarioEmoji(preset),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ClinicalPresets.title(preset),
                        style: TextStyle(
                          color: isActive ? _coral : _brightWhite,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: _coral.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'ATIVO',
                          style: TextStyle(
                            color: _coral,
                            fontSize: 7,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),

                // Description.
                Text(
                  ClinicalPresets.description(preset),
                  style: TextStyle(
                    color: accentColor.withValues(alpha: 0.6),
                    fontSize: 7,
                    fontFamily: 'monospace',
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),

                // Key parameters chips.
                Wrap(
                  spacing: 4,
                  runSpacing: 3,
                  children: [
                    _ParamChip(
                        label: params.mode.shortLabel, color: accentColor),
                    _ParamChip(
                        label: 'C:${params.compliance.toStringAsFixed(0)}',
                        color: accentColor),
                    _ParamChip(
                        label: 'R:${params.resistance.toStringAsFixed(0)}',
                        color: accentColor),
                    _ParamChip(
                        label: 'PEEP:${params.peep.toStringAsFixed(0)}',
                        color: accentColor),
                    _ParamChip(
                        label: 'FiO₂:${params.fio2}%',
                        color: accentColor),
                    _ParamChip(
                        label: 'I:E 1:${params.ieRatio.toStringAsFixed(1)}',
                        color: accentColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _scenarioEmoji(ClinicalPresetType type) => switch (type) {
        ClinicalPresetType.normal => '🫁',
        ClinicalPresetType.sdra => '🔴',
        ClinicalPresetType.asma => '💨',
        ClinicalPresetType.dpoc => '🌬️',
      };
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
        Icon(icon, size: 11, color: _tealLight),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: _tealLight,
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
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: (selected ? selectedColor : _dimWhite)
                      .withValues(alpha: 0.5),
                  fontSize: 7,
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
                  fontSize: 9,
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
                  fontSize: 14,
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
                  fontSize: 8,
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.08),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, size: 13, color: color),
        ),
      ),
    );
  }
}

/// Small parameter chip displayed inside scenario cards.
class _ParamChip extends StatelessWidget {
  const _ParamChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color.withValues(alpha: 0.7),
          fontSize: 7,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
