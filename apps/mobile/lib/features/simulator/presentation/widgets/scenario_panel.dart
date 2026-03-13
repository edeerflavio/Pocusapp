import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers/pathophysiology_provider.dart';
import '../../domain/entities/pathophysiology/pathophysiology_entities.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Theme constants
// ═══════════════════════════════════════════════════════════════════════════

const _borderColor = Color(0x1A00FF88);
const _green = Color(0xFF00FF88);
const _red = Color(0xFFFF4466);
const _amber = Color(0xFFFFAA00);
const _dimWhite = Color(0x80FFFFFF);

/// Scenario panel — displays and controls pathophysiological events
/// that can be overlaid on the base ventilator simulation.
///
/// Each event is shown as a card with toggle, severity selector, and
/// intensity slider. Active events are highlighted in red to draw
/// attention to the ongoing clinical perturbation.
class ScenarioPanel extends ConsumerWidget {
  const ScenarioPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pathoState = ref.watch(pathophysiologyNotifierProvider);
    final hasActive = pathoState.hasActiveEvents;

    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        // ── Header ────────────────────────────────────────────────────
        Row(
          children: [
            const Text(
              'CENARIOS CLINICOS',
              style: TextStyle(
                color: _dimWhite,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                fontFamily: 'monospace',
                letterSpacing: 1.2,
              ),
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
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: _red.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'LIMPAR',
                    style: TextStyle(
                      color: _red,
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 6),

        // ── Info box ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _green.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: _green.withValues(alpha: 0.1)),
          ),
          child: const Text(
            'Ative eventos para simular cenarios\n'
            'clinicos. As curvas reagem em tempo real.',
            style: TextStyle(
              color: _dimWhite,
              fontSize: 7,
              fontFamily: 'monospace',
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Event cards ───────────────────────────────────────────────
        ...pathoState.events.map(
          (event) => _EventCard(event: event),
        ),
      ],
    );
  }
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
                      fontSize: 9,
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
                  fontSize: 7,
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
                      fontSize: 7,
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
                              horizontal: 6, vertical: 2),
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
                              fontSize: 7,
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
                      fontSize: 7,
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
                        fontSize: 7,
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
