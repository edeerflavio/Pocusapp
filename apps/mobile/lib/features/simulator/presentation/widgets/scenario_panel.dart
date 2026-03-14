import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/pathophysiology_provider.dart';
import '../../application/providers/simulation_provider.dart';
import '../../application/providers/ventilator_params_provider.dart';
import '../../data/presets/clinical_presets.dart';
import '../../domain/entities/pathophysiology/pathophysiology_entities.dart';
import '../../domain/enums/ventilation_enums.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Theme constants
// ═══════════════════════════════════════════════════════════════════════════

const _borderColor = Color(0x14FFFFFF);
const _surface = Color(0xFF212B3A);
const _green = Color(0xFF10B981);
const _teal = Color(0xFF00897B);
const _tealLight = Color(0xFF4DB6AC);
const _coral = Color(0xFFFF6B6B);
const _red = Color(0xFFFF6B6B);
const _amber = Color(0xFFF59E0B);
const _dimWhite = Color(0x8CFFFFFF);
const _brightWhite = Color(0xE6FFFFFF);

/// Unified scenario panel — clinical presets + pathophysiology complications.
///
/// ## Section 1: PRESETS CLINICOS
/// Cards for Normal, SDRA, Asma, DPOC, SDRA-APRV. Selecting one applies
/// the preset parameters and resets the simulation.
///
/// ## Section 2: COMPLICACOES
/// Toggle-able pathophysiological events (Auto-PEEP, Pneumothorax, etc.)
/// with severity selector and intensity slider.
class ScenarioPanel extends ConsumerWidget {
  const ScenarioPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePreset = ref.watch(activePresetProvider);
    final pathoState = ref.watch(pathophysiologyNotifierProvider);
    final hasActive = pathoState.hasActiveEvents;

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // ═════════════════════════════════════════════════════════════════
        // Section 1: Clinical presets
        // ═════════════════════════════════════════════════════════════════
        const _SectionHeader(
          icon: Icons.medical_services_rounded,
          label: 'PRESETS CLÍNICOS',
        ),
        const SizedBox(height: 4),
        const Text(
          'Carregue presets validados para simular\ncenários clínicos reais.',
          style: TextStyle(
            color: _dimWhite,
            fontSize: 12,
            fontFamily: 'monospace',
            height: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        ...ClinicalPresetType.values.map(
          (preset) => _PresetCard(
            preset: preset,
            isActive: activePreset == preset,
          ),
        ),

        // ═════════════════════════════════════════════════════════════════
        // Divider
        // ═════════════════════════════════════════════════════════════════
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Divider(color: _borderColor, height: 1),
        ),

        // ═════════════════════════════════════════════════════════════════
        // Section 2: Pathophysiology complications
        // ═════════════════════════════════════════════════════════════════
        Row(
          children: [
            const _SectionHeader(
              icon: Icons.bolt_rounded,
              label: 'COMPLICAÇÕES',
            ),
            const Spacer(),
            if (hasActive)
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref
                      .read(pathophysiologyNotifierProvider.notifier)
                      .clearAll();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: _red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: _red.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'LIMPAR',
                    style: TextStyle(
                      color: _red,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 6),

        // Info box.
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: _green.withValues(alpha: 0.1)),
          ),
          child: const Text(
            'Ative complicações sobre o cenário atual.\n'
            'As curvas reagem em tempo real.',
            style: TextStyle(
              color: _dimWhite,
              fontSize: 12,
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Event cards.
        ...pathoState.events.map(
          (event) => _EventCard(event: event),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// _PresetCard — single clinical preset card
// ═══════════════════════════════════════════════════════════════════════════

class _PresetCard extends ConsumerWidget {
  const _PresetCard({
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
                    : _borderColor,
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
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ClinicalPresets.title(preset),
                        style: TextStyle(
                          color: isActive ? _coral : _brightWhite,
                          fontSize: 13,
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
                            fontSize: 12,
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
                    fontSize: 12,
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
                    if (params.mode == VentMode.aprv) ...[
                      _ParamChip(
                          label: 'P-hi:${params.pHigh.toStringAsFixed(0)}',
                          color: accentColor),
                      _ParamChip(
                          label: 'P-lo:${params.pLow.toStringAsFixed(0)}',
                          color: accentColor),
                    ] else ...[
                      _ParamChip(
                          label: 'PEEP:${params.peep.toStringAsFixed(0)}',
                          color: accentColor),
                      _ParamChip(
                          label: 'I:E 1:${params.ieRatio.toStringAsFixed(1)}',
                          color: accentColor),
                    ],
                    _ParamChip(
                        label: 'FiO₂:${params.fio2}%',
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
        ClinicalPresetType.sdraAprv => '🔄',
      };
}

// ═══════════════════════════════════════════════════════════════════════════
// _EventCard — single pathophysiological event control
// ═══════════════════════════════════════════════════════════════════════════

class _EventCard extends ConsumerWidget {
  const _EventCard({required this.event});

  final PathophysiologyEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(pathophysiologyNotifierProvider.notifier);
    final isActive = event.active;
    final accentColor = isActive ? _red : _dimWhite;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive
              ? _red.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isActive
                ? _red.withValues(alpha: 0.25)
                : _borderColor,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: emoji + label + toggle ────────────────────
            Row(
              children: [
                Text(
                  event.emoji,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    event.label,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                SizedBox(
                  height: 20,
                  width: 32,
                  child: FittedBox(
                    child: Switch(
                      value: isActive,
                      activeTrackColor: _red.withValues(alpha: 0.5),
                      activeThumbColor: _red,
                      inactiveTrackColor: const Color(0x20FFFFFF),
                      onChanged: (_) {
                        HapticFeedback.lightImpact();
                        notifier.toggleEvent(event.type);
                      },
                    ),
                  ),
                ),
              ],
            ),

            // ── Description ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 18),
              child: Text(
                event.description,
                style: TextStyle(
                  color: accentColor.withValues(alpha: 0.5),
                  fontSize: 12,
                  fontFamily: 'monospace',
                  height: 1.3,
                ),
              ),
            ),

            // ── Active controls: severity + intensity ─────────────────
            if (isActive) ...[
              const SizedBox(height: 8),

              // Severity selector.
              Row(
                children: [
                  const Text(
                    'Severidade',
                    style: TextStyle(
                      color: _dimWhite,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  ...PathophysiologySeverity.values.map((sev) {
                    final selected = event.severity == sev;
                    final label = switch (sev) {
                      PathophysiologySeverity.mild => 'Leve',
                      PathophysiologySeverity.moderate => 'Mod',
                      PathophysiologySeverity.severe => 'Grave',
                    };
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          notifier.setSeverity(event.type, sev);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected
                                ? _red.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: selected
                                  ? _red.withValues(alpha: 0.4)
                                  : const Color(0x20FFFFFF),
                            ),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(
                              color: selected ? _red : _dimWhite,
                              fontSize: 12,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),

              const SizedBox(height: 6),

              // Intensity slider.
              Row(
                children: [
                  const Text(
                    'Intensidade',
                    style: TextStyle(
                      color: _dimWhite,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: _red,
                        inactiveTrackColor: _red.withValues(alpha: 0.15),
                        thumbColor: _red,
                        overlayColor: _red.withValues(alpha: 0.1),
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5),
                      ),
                      child: Slider(
                        value: event.intensity,
                        min: 0.1,
                        max: 1.0,
                        onChanged: (v) {
                          notifier.setIntensity(event.type, v);
                        },
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${(event.intensity * 100).round()}%',
                      style: const TextStyle(
                        color: _amber,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared small widgets
// ═══════════════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
