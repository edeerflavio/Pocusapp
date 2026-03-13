import 'package:flutter/material.dart';

import '../domain/constants/medical_guidelines.dart';
import '../domain/entities/calculation_result.dart';
import '../domain/logic/cardiac_index_calculator.dart';
import '../domain/logic/cardiac_output_calculator.dart';
import '../domain/logic/epss_calculator.dart';
import '../domain/logic/psap_calculator.dart';
import '../domain/logic/rap_calculator.dart';
import 'calculator_definition.dart';

/// Central registry of every calculator available in the app.
///
/// The hub screen iterates [definitions] to build its list automatically.
/// The detail screen uses [findById] to resolve the right definition from
/// a URL path parameter.
///
/// To add a new calculator:
///   1. Create a pure function in `domain/logic/`
///   2. Add a [CalculatorDefinition] constant below
///   3. Append it to [definitions]
///   Done — no other file changes required.
abstract final class CalculatorRegistry {
  static const List<CalculatorDefinition> definitions = [
    _rapDefinition,
    _psapDefinition,
    _dcDefinition,
    _icDefinition,
    _epssDefinition,
  ];

  static CalculatorDefinition? findById(String id) {
    for (final def in definitions) {
      if (def.id == id) return def;
    }
    return null;
  }
}

// ─── RAP ──────────────────────────────────────────────────────────────────────

CalculationResult? _rapExecutor(Map<String, double> inputs) {
  final vci = inputs['vci_diameter_cm'];
  final collapse = inputs['collapse_percent'];
  if (vci == null || collapse == null) return null;
  return calculateRap(vciDiameter: vci, collapsePercent: collapse);
}

const _rapDefinition = CalculatorDefinition(
  id: 'rap',
  name: MedicalGuidelines.rapFullName,
  shortName: MedicalGuidelines.rapName,
  description:
      'Estima a pressão atrial direita a partir do diâmetro da VCI e do '
      'percentual de colapso inspiratório.',
  icon: Icons.waves_outlined,
  accentColor: Color(0xFF004D40),
  fields: [
    FieldDefinition(
      id: 'vci_diameter_cm',
      label: 'Diâmetro da VCI',
      hint: 'ex: 1.8',
      unit: 'cm',
      minValue: 0.1,
      maxValue: 5.0,
    ),
    FieldDefinition(
      id: 'collapse_percent',
      label: 'Colapso inspiratório da VCI',
      hint: 'ex: 60',
      unit: '%',
      minValue: 0,
      maxValue: 100,
      allowZero: true,
    ),
  ],
  executor: _rapExecutor,
  references: [
    'Rudski LG et al. JASE 2010 — Guidelines for Echocardiographic Assessment '
        'of the Right Heart in Adults',
    'ACC/ASE 2015 — Guideline for the Evaluation of Right Heart Physiology',
  ],
);

// ─── PSAP ─────────────────────────────────────────────────────────────────────

CalculationResult? _psapExecutor(Map<String, double> inputs) {
  final vmax = inputs['vmax_m_s'];
  final rap = inputs['rap_mmhg'];
  if (vmax == null || rap == null) return null;
  return calculatePsap(vmax: vmax, rap: rap);
}

const _psapDefinition = CalculatorDefinition(
  id: 'psap',
  name: MedicalGuidelines.psapFullName,
  shortName: MedicalGuidelines.psapName,
  description:
      'Estima a PSAP via gradiente de regurgitação tricúspide + RAP '
      '(equação de Bernoulli simplificada).',
  icon: Icons.favorite_outline,
  accentColor: Color(0xFFC62828),
  fields: [
    FieldDefinition(
      id: 'vmax_m_s',
      label: 'Vmax da regurgitação tricúspide',
      hint: 'ex: 2.8',
      unit: 'm/s',
      minValue: 0.1,
      maxValue: 6.0,
    ),
    FieldDefinition(
      id: 'rap_mmhg',
      label: 'RAP estimada',
      hint: 'ex: 8',
      unit: 'mmHg',
      minValue: 0,
      maxValue: 20,
      allowZero: true,
    ),
  ],
  executor: _psapExecutor,
  references: [
    'Bossone E et al. JASE 2013 — Pulmonary Arterial Hypertension: '
        'Echocardiographic Evaluation',
    'ASE 2010 — Recommendations for Estimation of PA Pressures',
  ],
);

// ─── DC ───────────────────────────────────────────────────────────────────────

CalculationResult? _dcExecutor(Map<String, double> inputs) {
  final d = inputs['lvot_diameter_cm'];
  final vti = inputs['vti_cm'];
  final hr = inputs['heart_rate_bpm'];
  if (d == null || vti == null || hr == null) return null;
  return calculateCardiacOutput(lvotDiameter: d, vti: vti, heartRate: hr);
}

const _dcDefinition = CalculatorDefinition(
  id: 'dc',
  name: MedicalGuidelines.dcFullName,
  shortName: MedicalGuidelines.dcName,
  description:
      'Calcula o débito cardíaco por Doppler pulsado na VSVE '
      '(método área × VTI × FC).',
  icon: Icons.monitor_heart_outlined,
  accentColor: Color(0xFF00695C),
  fields: [
    FieldDefinition(
      id: 'lvot_diameter_cm',
      label: 'Diâmetro da VSVE',
      hint: 'ex: 2.1',
      unit: 'cm',
      minValue: 0.5,
      maxValue: 4.0,
    ),
    FieldDefinition(
      id: 'vti_cm',
      label: 'VTI da VSVE',
      hint: 'ex: 18',
      unit: 'cm',
      minValue: 1,
      maxValue: 60,
    ),
    FieldDefinition(
      id: 'heart_rate_bpm',
      label: 'Frequência cardíaca',
      hint: 'ex: 72',
      unit: 'bpm',
      minValue: 20,
      maxValue: 300,
    ),
  ],
  executor: _dcExecutor,
  references: [
    'Lang RM et al. JASE 2015 — Recommendations for Cardiac Chamber '
        'Quantification by Echocardiography',
  ],
);

// ─── IC ───────────────────────────────────────────────────────────────────────

CalculationResult? _icExecutor(Map<String, double> inputs) {
  final co = inputs['cardiac_output_l_min'];
  final bsa = inputs['bsa_m2'];
  if (co == null || bsa == null) return null;
  return calculateCardiacIndex(cardiacOutput: co, bsa: bsa);
}

const _icDefinition = CalculatorDefinition(
  id: 'ic',
  name: MedicalGuidelines.icFullName,
  shortName: MedicalGuidelines.icName,
  description:
      'Corrige o débito cardíaco pela superfície corporal, permitindo '
      'comparação entre diferentes biótipos.',
  icon: Icons.person_outline,
  accentColor: Color(0xFF6A1B9A),
  fields: [
    FieldDefinition(
      id: 'cardiac_output_l_min',
      label: 'Débito cardíaco',
      hint: 'ex: 5.2',
      unit: 'L/min',
      minValue: 0.1,
      maxValue: 20,
    ),
    FieldDefinition(
      id: 'bsa_m2',
      label: 'Superfície corporal (SC)',
      hint: 'ex: 1.75',
      unit: 'm²',
      minValue: 0.5,
      maxValue: 3.0,
    ),
  ],
  executor: _icExecutor,
  references: [
    'Fick principle — corrected for body surface area (Mosteller / Du Bois)',
    'Ander DS et al. — Cardiac Index in Critical Care',
  ],
);

// ─── EPSS ─────────────────────────────────────────────────────────────────────

CalculationResult? _epssExecutor(Map<String, double> inputs) {
  final epss = inputs['epss_mm'];
  if (epss == null) return null;
  return calculateEpss(epss: epss);
}

const _epssDefinition = CalculatorDefinition(
  id: 'epss',
  name: MedicalGuidelines.epssFullName,
  shortName: MedicalGuidelines.epssName,
  description:
      'Avalia disfunção sistólica do VE pela distância entre o ponto E '
      'da valva mitral e o septo interventricular em modo M.',
  icon: Icons.linear_scale_outlined,
  accentColor: Color(0xFFE65100),
  fields: [
    FieldDefinition(
      id: 'epss_mm',
      label: 'Valor do EPSS medido',
      hint: 'ex: 9.5',
      unit: 'mm',
      minValue: 0,
      maxValue: 40,
      allowZero: true,
    ),
  ],
  executor: _epssExecutor,
  references: [
    'Silverstein JR et al. JACC 2006 — EPSS as a predictor of reduced LVEF',
    'McKaigney CJ et al. Am J Emerg Med 2014 — E-point septal separation '
        'and LV function',
  ],
);
