import '../entities/ventilator_entities.dart';
import '../enums/ventilation_enums.dart';

/// Pure, stateless arterial blood gas (ABG) analysis engine.
///
/// Translates raw gasometric values into a structured clinical interpretation
/// with prioritised ventilator adjustment recommendations.
///
/// All thresholds follow current evidence-based guidelines:
///   - ARDSNet (Berlin 2012) for P/F ratio classification
///   - Winter's formula for metabolic compensation assessment
///   - Lung-protective ventilation targets (Vt 6–8 mL/kg IBW, DP ≤ 15,
///     Pplat ≤ 30)
///
/// **100 % pure Dart** — no Flutter, no UI, no mutable state.
abstract final class AbgAnalyzer {
  /// Analyse an arterial blood gas in the context of current ventilator
  /// settings and patient anthropometrics.
  ///
  /// Returns a complete [AbgAnalysis] with:
  ///   - [AbgAnalysis.primaryDisorder]: the dominant acid-base disturbance
  ///   - [AbgAnalysis.findings]: ordered clinical findings (most severe first)
  ///   - [AbgAnalysis.actions]: prioritised ventilator adjustments
  ///   - Derived metrics: P/F ratio, driving pressure, Pplat, Vt/kg, MV, VA
  static AbgAnalysis analyze({
    required AbgInput abg,
    required VentParams ventParams,
    required PatientData patient,
  }) {
    final ibw = patient.ibw;
    final fio2Frac = ventParams.fio2 / 100.0;
    final pfRatio = abg.pao2 / fio2Frac;
    final vtPerKg = ventParams.vt / ibw;
    final dp = ventParams.vt / ventParams.compliance; // Driving Pressure
    final pplat = ventParams.peep + dp;
    final mv = (ventParams.vt * ventParams.rr) / 1000.0; // Volume-minuto
    final vd = 2.2 * ibw; // Espaço morto estimado (mL)
    final va =
        ((ventParams.vt - vd) * ventParams.rr) / 1000.0; // Vent. alveolar

    final findings = <AbgFinding>[];
    final actions = <AbgAction>[];
    String primaryDisorder = '';

    // ═══════════════════════════════════════════════════════════════════════
    // DISTÚRBIO ÁCIDO-BASE
    // ═══════════════════════════════════════════════════════════════════════

    if (abg.ph < 7.35) {
      // ─── ACIDOSE ─────────────────────────────────────────────────────
      if (abg.pco2 > 45) {
        // Acidose Respiratória
        primaryDisorder = abg.ph < 7.20
            ? 'Acidose respiratória grave'
            : 'Acidose respiratória';

        if (abg.ph < 7.20) {
          findings.add(const AbgFinding(
            level: AlertLevel.danger,
            text: 'URGENTE: pH < 7.20 — acidose respiratória grave. '
                'Risco de arritmias e instabilidade hemodinâmica.',
          ));
        } else {
          findings.add(AbgFinding(
            level: AlertLevel.warning,
            text: 'Acidose respiratória: pH ${abg.ph.toStringAsFixed(2)}, '
                'PaCO₂ ${abg.pco2.toStringAsFixed(0)} mmHg. '
                'Ventilação alveolar insuficiente.',
          ));
        }

        // Recomendações para corrigir hipercapnia
        if (vtPerKg < 6) {
          actions.add(AbgAction(
            priority: abg.ph < 7.20 ? 0 : 1,
            icon: '🔺',
            param: 'VT',
            action:
                'Aumentar VT de ${ventParams.vt} para ${(ibw * 6).round()} mL '
                '(6 mL/kg IBW)',
            reason: 'VT/kg atual = ${vtPerKg.toStringAsFixed(1)} mL/kg — '
                'abaixo do mínimo protetor. Aumentar VT para melhorar '
                'ventilação alveolar e reduzir PaCO₂.',
            where: 'Painel principal → VT',
          ));
        } else if (vtPerKg < 8 && dp <= 15) {
          actions.add(AbgAction(
            priority: abg.ph < 7.20 ? 0 : 1,
            icon: '🔺',
            param: 'VT',
            action:
                'Considerar aumento de VT até ${(ibw * 8).round()} mL '
                '(8 mL/kg IBW)',
            reason: 'VT/kg = ${vtPerKg.toStringAsFixed(1)} mL/kg, DP = '
                '${dp.toStringAsFixed(1)} cmH₂O — há margem para aumentar '
                'VT mantendo ventilação protetora.',
            where: 'Painel principal → VT',
          ));
        }

        if (ventParams.rr < 30 && dp <= 15) {
          actions.add(AbgAction(
            priority: abg.ph < 7.20 ? 0 : 1,
            icon: '🔺',
            param: 'FR',
            action:
                'Aumentar FR de ${ventParams.rr} para ${(ventParams.rr + 4).clamp(0, 35)} rpm',
            reason: 'Aumentar frequência respiratória para elevar volume-'
                'minuto e reduzir PaCO₂. Monitorar auto-PEEP.',
            where: 'Painel principal → FR',
          ));
        } else if (dp > 15) {
          actions.add(AbgAction(
            priority: 1,
            icon: '⚠️',
            param: 'FR',
            action:
                'Preferir aumento de FR sobre VT (DP > 15 cmH₂O)',
            reason: 'Driving pressure = ${dp.toStringAsFixed(1)} cmH₂O '
                '(> 15). Aumentar VT elevaria ainda mais a DP, '
                'aumentando risco de VILI. Preferir aumento de FR.',
            where: 'Painel principal → FR',
          ));
        }
      }

      if (abg.hco3 < 22) {
        // Acidose Metabólica
        if (primaryDisorder.isEmpty) {
          primaryDisorder = 'Acidose metabólica';
        } else {
          primaryDisorder = 'Distúrbio misto: acidose respiratória + metabólica';
        }

        // Fórmula de Winter: PCO₂ esperado = 1.5 × HCO₃ + 8 (±2)
        final winterPco2 = 1.5 * abg.hco3 + 8;
        final winterMin = winterPco2 - 2;
        final winterMax = winterPco2 + 2;

        findings.add(AbgFinding(
          level: AlertLevel.warning,
          text: 'Acidose metabólica: HCO₃ ${abg.hco3.toStringAsFixed(1)} '
              'mEq/L. PCO₂ esperado (Winter): '
              '${winterMin.toStringAsFixed(0)}–${winterMax.toStringAsFixed(0)} '
              'mmHg.',
        ));

        if (abg.pco2 > winterMax) {
          findings.add(const AbgFinding(
            level: AlertLevel.warning,
            text: 'Compensação respiratória inadequada — PaCO₂ acima do '
                'esperado pela fórmula de Winter. Considerar componente '
                'respiratório associado.',
          ));
        } else if (abg.pco2 < winterMin) {
          findings.add(const AbgFinding(
            level: AlertLevel.info,
            text: 'PaCO₂ abaixo do esperado por Winter — possível alcalose '
                'respiratória sobreposta (hiperventilação compensatória '
                'excessiva).',
          ));
        } else {
          findings.add(const AbgFinding(
            level: AlertLevel.info,
            text: 'Compensação respiratória adequada pela fórmula de Winter.',
          ));
        }

        if (abg.lactato > 4) {
          findings.add(AbgFinding(
            level: AlertLevel.danger,
            text: 'Hiperlactatemia grave: lactato '
                '${abg.lactato.toStringAsFixed(1)} mmol/L (> 4). '
                'Associada a hipoperfusão tecidual e maior mortalidade. '
                'Investigar causa (sepse, choque, isquemia).',
          ));
        } else if (abg.lactato > 2) {
          findings.add(AbgFinding(
            level: AlertLevel.warning,
            text: 'Hiperlactatemia: lactato '
                '${abg.lactato.toStringAsFixed(1)} mmol/L (> 2). '
                'Marcador de metabolismo anaeróbio. Reavaliar perfusão.',
          ));
        }
      }
    } else if (abg.ph > 7.45) {
      // ─── ALCALOSE ────────────────────────────────────────────────────
      if (abg.pco2 < 35) {
        // Alcalose Respiratória
        primaryDisorder = 'Alcalose respiratória';

        findings.add(AbgFinding(
          level: AlertLevel.warning,
          text: 'Alcalose respiratória: pH ${abg.ph.toStringAsFixed(2)}, '
              'PaCO₂ ${abg.pco2.toStringAsFixed(0)} mmHg. '
              'Hiperventilação — excesso de ventilação alveolar.',
        ));

        // Reduzir ventilação
        if (ventParams.rr > 10) {
          actions.add(AbgAction(
            priority: 1,
            icon: '🔻',
            param: 'FR',
            action:
                'Reduzir FR de ${ventParams.rr} para ${(ventParams.rr - 2).clamp(6, 40)} rpm',
            reason: 'Hiperventilação → alcalose respiratória. Reduzir FR '
                'para normalizar PaCO₂ e pH.',
            where: 'Painel principal → FR',
          ));
        }
        if (vtPerKg > 8) {
          actions.add(AbgAction(
            priority: 1,
            icon: '🔻',
            param: 'VT',
            action:
                'Reduzir VT de ${ventParams.vt} para ${(ibw * 7).round()} mL '
                '(7 mL/kg IBW)',
            reason: 'VT/kg = ${vtPerKg.toStringAsFixed(1)} — acima de '
                '8 mL/kg. Reduzir para faixa protetora e diminuir '
                'eliminação de CO₂.',
            where: 'Painel principal → VT',
          ));
        }
      }

      if (abg.hco3 > 26) {
        // Alcalose Metabólica
        if (primaryDisorder.isEmpty) {
          primaryDisorder = 'Alcalose metabólica';
        } else {
          primaryDisorder =
              'Distúrbio misto: alcalose respiratória + metabólica';
        }

        findings.add(AbgFinding(
          level: AlertLevel.warning,
          text: 'Alcalose metabólica: HCO₃ ${abg.hco3.toStringAsFixed(1)} '
              'mEq/L (> 26). Causas comuns: vômitos, diuréticos, '
              'hipocalemia.',
        ));
      }
    } else {
      // ─── pH NORMAL ───────────────────────────────────────────────────
      primaryDisorder = 'Equilíbrio ácido-base normal';

      findings.add(AbgFinding(
        level: AlertLevel.ok,
        text: 'pH ${abg.ph.toStringAsFixed(2)} — dentro da faixa normal '
            '(7.35–7.45).',
      ));

      // Verificar compensação mascarando distúrbio misto
      if (abg.pco2 > 45 && abg.hco3 > 26) {
        primaryDisorder = 'Distúrbio misto compensado: acidose respiratória '
            '+ alcalose metabólica';
        findings.add(const AbgFinding(
          level: AlertLevel.info,
          text: 'pH normal, porém PaCO₂ elevada e HCO₃ elevado — possível '
              'distúrbio misto compensado. Avaliar contexto clínico.',
        ));
      } else if (abg.pco2 < 35 && abg.hco3 < 22) {
        primaryDisorder = 'Distúrbio misto compensado: alcalose respiratória '
            '+ acidose metabólica';
        findings.add(const AbgFinding(
          level: AlertLevel.info,
          text: 'pH normal, porém PaCO₂ baixa e HCO₃ baixo — possível '
              'distúrbio misto compensado. Avaliar contexto clínico.',
        ));
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // OXIGENAÇÃO
    // ═══════════════════════════════════════════════════════════════════════

    if (abg.pao2 < 60) {
      findings.add(AbgFinding(
        level: AlertLevel.danger,
        text: 'Hipoxemia grave: PaO₂ ${abg.pao2.toStringAsFixed(0)} mmHg '
            '(< 60). Corresponde a SaO₂ ≈ 90% na curva de dissociação. '
            'Risco imediato de hipóxia tecidual.',
      ));

      if (ventParams.fio2 < 100) {
        actions.add(AbgAction(
          priority: 0,
          icon: '🔺',
          param: 'FiO₂',
          action: 'Aumentar FiO₂ de ${ventParams.fio2}% para '
              '${(ventParams.fio2 + 20).clamp(21, 100)}%',
          reason: 'Hipoxemia grave — aumentar FiO₂ imediatamente para '
              'garantir oxigenação tecidual adequada.',
          where: 'Painel principal → FiO₂',
        ));
      }

      if (ventParams.peep < 20) {
        actions.add(AbgAction(
          priority: 0,
          icon: '🔺',
          param: 'PEEP',
          action: 'Considerar aumento de PEEP de '
              '${ventParams.peep.toStringAsFixed(0)} para '
              '${(ventParams.peep + 2).clamp(0, 24).toStringAsFixed(0)} '
              'cmH₂O',
          reason: 'PEEP recruta alvéolos colapsados, melhorando a relação '
              'V/Q e a oxigenação. Monitorar hemodinâmica.',
          where: 'Painel principal → PEEP',
        ));
      }
    } else if (abg.pao2 < 80) {
      findings.add(AbgFinding(
        level: AlertLevel.warning,
        text: 'Hipoxemia leve-moderada: PaO₂ '
            '${abg.pao2.toStringAsFixed(0)} mmHg (< 80).',
      ));

      if (ventParams.fio2 < 80) {
        actions.add(AbgAction(
          priority: 1,
          icon: '🔺',
          param: 'FiO₂',
          action: 'Considerar aumento de FiO₂ de ${ventParams.fio2}% para '
              '${(ventParams.fio2 + 10).clamp(21, 100)}%',
          reason: 'Hipoxemia leve-moderada. Ajustar FiO₂ para PaO₂ alvo '
              '> 80 mmHg (SaO₂ > 95%).',
          where: 'Painel principal → FiO₂',
        ));
      }
    }

    // ── P/F Ratio — Classificação de Berlin para SDRA ──────────────────

    if (pfRatio < 100) {
      findings.add(AbgFinding(
        level: AlertLevel.danger,
        text: 'SDRA GRAVE (Berlin): P/F = ${pfRatio.toStringAsFixed(0)} '
            '(< 100). Mortalidade 40–50%. Considerar prona, PEEP alta, '
            'bloqueio neuromuscular.',
      ));
      actions.add(const AbgAction(
        priority: 0,
        icon: '🚨',
        param: 'Estratégia',
        action: 'Iniciar posição prona (≥ 16h/dia), PEEP alta conforme '
            'tabela ARDSNet, considerar BNM por 48h',
        reason: 'SDRA grave com P/F < 100 — evidência de benefício '
            'com prona precoce (PROSEVA), PEEP alta (ART/EPVent) e '
            'BNM (ACURASYS) nas primeiras 48h.',
        where: 'Protocolo institucional SDRA',
      ));
    } else if (pfRatio < 200) {
      findings.add(AbgFinding(
        level: AlertLevel.warning,
        text: 'SDRA MODERADA (Berlin): P/F = '
            '${pfRatio.toStringAsFixed(0)} (100–200). '
            'Otimizar PEEP/FiO₂ conforme tabela ARDSNet.',
      ));
      actions.add(const AbgAction(
        priority: 1,
        icon: '📋',
        param: 'PEEP/FiO₂',
        action: 'Otimizar combinação PEEP/FiO₂ conforme tabela ARDSNet '
            '(PEEP alta)',
        reason: 'SDRA moderada — titular PEEP para melhor compliance e '
            'oxigenação, mantendo DP ≤ 15 e Pplat ≤ 30.',
        where: 'Protocolo ARDSNet → Tabela PEEP/FiO₂',
      ));
    } else if (pfRatio < 300) {
      findings.add(AbgFinding(
        level: AlertLevel.info,
        text: 'SDRA LEVE (Berlin): P/F = ${pfRatio.toStringAsFixed(0)} '
            '(200–300). Manter ventilação protetora.',
      ));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // DESMAME DE FiO₂ (hiperóxia)
    // ═══════════════════════════════════════════════════════════════════════

    if (abg.pao2 > 100 && ventParams.fio2 > 40) {
      findings.add(AbgFinding(
        level: AlertLevel.info,
        text: 'PaO₂ ${abg.pao2.toStringAsFixed(0)} mmHg com FiO₂ '
            '${ventParams.fio2}% — hiperóxia. Risco de toxicidade por O₂ '
            'se FiO₂ mantida elevada.',
      ));

      actions.add(AbgAction(
        priority: 2,
        icon: '⬇️',
        param: 'FiO₂',
        action: 'Reduzir FiO₂ de ${ventParams.fio2}% para '
            '${(ventParams.fio2 - 10).clamp(21, 100)}% — alvo PaO₂ '
            '80–100 mmHg',
        reason: 'Hiperóxia desnecessária. FiO₂ > 60% por período '
            'prolongado associa-se a toxicidade pulmonar por O₂. '
            'Desmamar para o menor FiO₂ que mantenha SaO₂ > 92%.',
        where: 'Painel principal → FiO₂',
      ));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // PROTEÇÃO PULMONAR
    // ═══════════════════════════════════════════════════════════════════════

    // ── VT/kg ──────────────────────────────────────────────────────────

    if (vtPerKg > 8) {
      findings.add(AbgFinding(
        level: AlertLevel.danger,
        text: 'VT/kg = ${vtPerKg.toStringAsFixed(1)} mL/kg IBW (> 8). '
            'RISCO DE VILI — volume corrente excessivo. ARDSNet recomenda '
            '6–8 mL/kg IBW.',
      ));

      actions.add(AbgAction(
        priority: 1,
        icon: '🔻',
        param: 'VT',
        action: 'Reduzir VT de ${ventParams.vt} para '
            '${(ibw * 6).round()}–${(ibw * 8).round()} mL '
            '(6–8 mL/kg IBW)',
        reason: 'Volume corrente > 8 mL/kg IBW associa-se a volutrauma, '
            'biotrauma e aumento de mortalidade (ARMA trial). '
            'Manter VT 6–8 mL/kg IBW.',
        where: 'Painel principal → VT',
      ));
    } else if (vtPerKg >= 6 && vtPerKg <= 8) {
      findings.add(AbgFinding(
        level: AlertLevel.ok,
        text: 'VT/kg = ${vtPerKg.toStringAsFixed(1)} mL/kg IBW — '
            'dentro da faixa protetora (6–8 mL/kg).',
      ));
    } else if (vtPerKg < 6) {
      findings.add(AbgFinding(
        level: AlertLevel.info,
        text: 'VT/kg = ${vtPerKg.toStringAsFixed(1)} mL/kg IBW (< 6). '
            'Volume corrente baixo — avaliar se hipercapnia permissiva é '
            'aceitável no contexto clínico.',
      ));
    }

    // ── Driving Pressure ───────────────────────────────────────────────

    if (dp > 15) {
      findings.add(AbgFinding(
        level: AlertLevel.danger,
        text: 'Driving Pressure = ${dp.toStringAsFixed(1)} cmH₂O (> 15). '
            'Associada a aumento de mortalidade em SDRA (Amato 2015). '
            'Meta ≤ 15 cmH₂O.',
      ));

      actions.add(AbgAction(
        priority: 1,
        icon: '⚠️',
        param: 'DP',
        action: 'Reduzir driving pressure: ↓VT e/ou ↑compliance '
            '(otimizar PEEP para melhor recrutamento)',
        reason: 'DP > 15 cmH₂O é o parâmetro com maior associação '
            'independente com mortalidade em SDRA. Reduzir VT ou '
            'otimizar PEEP para melhorar compliance e reduzir DP.',
        where: 'Painel principal → VT / PEEP',
      ));
    } else if (dp > 12) {
      findings.add(AbgFinding(
        level: AlertLevel.warning,
        text: 'Driving Pressure = ${dp.toStringAsFixed(1)} cmH₂O '
            '(12–15). Aceitável, porém monitorar — alvo ideal ≤ 12 cmH₂O.',
      ));
    } else {
      findings.add(AbgFinding(
        level: AlertLevel.ok,
        text: 'Driving Pressure = ${dp.toStringAsFixed(1)} cmH₂O '
            '(≤ 12) — dentro da meta de proteção pulmonar.',
      ));
    }

    // ── Plateau Pressure ───────────────────────────────────────────────

    if (pplat > 30) {
      findings.add(AbgFinding(
        level: AlertLevel.danger,
        text: 'Pplat = ${pplat.toStringAsFixed(1)} cmH₂O (> 30). '
            'RISCO DE BAROTRAUMA. Limite absoluto = 30 cmH₂O '
            '(ARDSNet).',
      ));

      actions.add(AbgAction(
        priority: 0,
        icon: '🚨',
        param: 'Pplat',
        action: 'Reduzir Pplat: ↓VT (prioridade) e/ou ↓PEEP '
            'se recrutamento adequado',
        reason: 'Pplat > 30 cmH₂O associa-se a barotrauma '
            '(pneumotórax, pneumomediastino) e VILI. Limite '
            'não-negociável do ARDSNet.',
        where: 'Painel principal → VT / PEEP',
      ));
    } else if (pplat > 28) {
      findings.add(AbgFinding(
        level: AlertLevel.warning,
        text: 'Pplat = ${pplat.toStringAsFixed(1)} cmH₂O (28–30). '
            'Próximo do limite — monitorar rigorosamente.',
      ));
    } else {
      findings.add(AbgFinding(
        level: AlertLevel.ok,
        text: 'Pplat = ${pplat.toStringAsFixed(1)} cmH₂O (≤ 28) — '
            'dentro da meta de proteção pulmonar.',
      ));
    }

    // ═══════════════════════════════════════════════════════════════════════
    // Sort actions by priority (0 = urgent first)
    // ═══════════════════════════════════════════════════════════════════════

    actions.sort((a, b) => a.priority.compareTo(b.priority));

    // Sort findings: danger first, then warning, info, ok.
    findings.sort((a, b) => _alertOrder(a.level).compareTo(_alertOrder(b.level)));

    return AbgAnalysis(
      primaryDisorder: primaryDisorder,
      findings: findings,
      actions: actions,
      pfRatio: pfRatio,
      drivingPressure: dp,
      pplat: pplat,
      vtPerKg: vtPerKg,
      minuteVolume: mv,
      alveolarVentilation: va,
    );
  }

  /// Returns a sort key for [AlertLevel] — lower = more severe = first.
  static int _alertOrder(AlertLevel level) => switch (level) {
        AlertLevel.danger => 0,
        AlertLevel.warning => 1,
        AlertLevel.info => 2,
        AlertLevel.ok => 3,
      };
}
