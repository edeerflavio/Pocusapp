/// Single source of truth for all clinical thresholds, cut-offs, units,
/// labels and interpretive messages used in the calculators domain.
///
/// Never reference raw numbers in UI or controller code. Import from here.
abstract final class MedicalGuidelines {
  // ── RAP — Right Atrial Pressure ──────────────────────────────────────────

  /// IVC (VCI) diameter threshold — small vs. dilated (cm)
  static const double rapVciSmallThreshold = 2.1;

  /// IVC inspiratory collapse threshold — high vs. low (%)
  static const double rapCollapseHighThreshold = 50.0;

  /// RAP when IVC small + collapse high — normal (mmHg)
  static const double rapLow = 3.0;

  /// RAP when IVC dilated + collapse low — elevated (mmHg)
  static const double rapHigh = 15.0;

  /// RAP for all intermediate/discordant combinations (mmHg)
  static const double rapIntermediate = 8.0;

  static const String rapUnit = 'mmHg';
  static const String rapName = 'RAP';
  static const String rapFullName = 'Pressão Atrial Direita';

  static String rapInterpretation(double value) {
    if (value == rapLow) {
      return 'PAD normal — VCI colabável (>50%) e calibre reduzido (≤2,1 cm).';
    }
    if (value == rapHigh) {
      return 'PAD elevada — VCI dilatada (>2,1 cm) e sem colapso (<50%).';
    }
    return 'PAD intermediária — achados discordantes; correlação clínica necessária.';
  }

  // ── PSAP — Pulmonary Systolic Arterial Pressure ───────────────────────────

  /// PSAP warning threshold — mild pulmonary hypertension (mmHg)
  static const double psapWarningThreshold = 35.0;

  /// PSAP critical threshold — significant pulmonary hypertension (mmHg)
  static const double psapCriticalThreshold = 50.0;

  static const String psapUnit = 'mmHg';
  static const String psapName = 'PSAP';
  static const String psapFullName = 'Pressão Sistólica Arterial Pulmonar';

  static String psapInterpretation(double value) {
    if (value < psapWarningThreshold) {
      return 'PSAP normal — sem evidência de hipertensão pulmonar.';
    }
    if (value < psapCriticalThreshold) {
      return 'PSAP elevada — hipertensão pulmonar leve a moderada. Investigar etiologia.';
    }
    return 'PSAP criticamente elevada — hipertensão pulmonar grave. Avaliação urgente indicada.';
  }

  // ── DC — Débito Cardíaco ──────────────────────────────────────────────────

  /// Normal cardiac output lower bound (L/min)
  static const double dcNormalMin = 4.0;

  /// Normal cardiac output upper bound (L/min)
  static const double dcNormalMax = 8.0;

  static const String dcUnit = 'L/min';
  static const String dcName = 'DC';
  static const String dcFullName = 'Débito Cardíaco';

  static String dcInterpretation(double value) {
    if (value < dcNormalMin) {
      return 'Débito cardíaco reduzido — avaliar perfusão tecidual e sinais de baixo débito.';
    }
    if (value > dcNormalMax) {
      return 'Débito cardíaco elevado — considerar estado hiperdinâmico (sepse, anemia, tireotoxicose).';
    }
    return 'Débito cardíaco dentro dos limites de normalidade.';
  }

  // ── IC — Índice Cardíaco ──────────────────────────────────────────────────

  /// IC critical threshold — cardiogenic shock risk (L/min/m²)
  static const double icCriticalThreshold = 2.2;

  /// IC warning threshold — borderline low perfusion (L/min/m²)
  static const double icWarningThreshold = 2.5;

  static const String icUnit = 'L/min/m²';
  static const String icName = 'IC';
  static const String icFullName = 'Índice Cardíaco';

  static String icInterpretation(double value) {
    if (value < icCriticalThreshold) {
      return 'IC criticamente baixo — alto risco de choque cardiogênico. Intervenção imediata.';
    }
    if (value < icWarningThreshold) {
      return 'IC limítrofe — perfusão comprometida. Monitorização intensiva.';
    }
    return 'IC dentro dos limites normais.';
  }

  // ── EPSS — E-Point Septal Separation ─────────────────────────────────────

  /// Default EPSS threshold for systolic dysfunction (mm)
  static const double epssWarningThreshold = 7.0;

  static const String epssUnit = 'mm';
  static const String epssName = 'EPSS';
  static const String epssFullName = 'Separação Ponto E–Septo';

  static String epssInterpretation(
    double value, {
    double threshold = epssWarningThreshold,
  }) {
    if (value > threshold) {
      return 'EPSS elevado (>${threshold.toStringAsFixed(0)} mm) — disfunção sistólica do VE provável. '
          'Considerar avaliação formal da FEVE.';
    }
    return 'EPSS normal (≤${threshold.toStringAsFixed(0)} mm) — função sistólica do VE provavelmente preservada.';
  }
}
