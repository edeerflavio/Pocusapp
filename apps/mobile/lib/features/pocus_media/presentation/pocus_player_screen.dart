import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../data/models/pocus_item.dart';

// ---------------------------------------------------------------------------
// PocusPlayerScreen — Multi-window protocol detail screen.
// Route: /pocus/player/:id   receives PocusItem via GoRouter extra.
// ---------------------------------------------------------------------------

class PocusPlayerScreen extends StatelessWidget {
  const PocusPlayerScreen({super.key, required this.pocusItem});

  final PocusItem pocusItem;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
        title: Text(
          pocusItem.titlePt,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSection(pocusItem: pocusItem),
            _WindowSections(pocusItem: pocusItem),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header — category chip + title + premium badge
// ---------------------------------------------------------------------------

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.pocusItem});

  final PocusItem pocusItem;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              pocusItem.category.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFF1565C0),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            pocusItem.titlePt,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
          ),
          if (pocusItem.isPremium) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.workspace_premium, size: 14, color: Colors.amber[700]),
                const SizedBox(width: 4),
                Text(
                  'Conteúdo Premium',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ===========================================================================
// DATA LAYER — Protocol window registry
// ===========================================================================

class _WindowData {
  const _WindowData({
    required this.title,
    required this.subtitle,
    required this.positioning,
    required this.normalFindings,
    required this.abnormalFindings,
  });

  final String title;
  final String subtitle;
  final List<String> positioning;
  final List<String> normalFindings;
  final List<String> abnormalFindings;
}

// ---------------------------------------------------------------------------
// E-FAST — Extended Focused Assessment with Sonography in Trauma
// ---------------------------------------------------------------------------

const List<_WindowData> _efastWindows = [
  _WindowData(
    title: 'Janela Subxifoide',
    subtitle: 'Saco pericárdico e atividade cardíaca',
    positioning: [
      'Transdutor abaixo do processo xifóide, ângulo de 15–20° em relação ao abdome.',
      'Marcador orientado para a esquerda do paciente (corte subxifoide 4 câmaras).',
    ],
    normalFindings: [
      'Saco pericárdico sem coleção anecoica.',
      'Contratilidade cardíaca preservada, câmaras simétricas.',
    ],
    abnormalFindings: [
      'Coleção anecoica ao redor do coração → tamponamento cardíaco.',
      'Coração imóvel e dilatado → suspeitar PCR em assistolia.',
    ],
  ),
  _WindowData(
    title: 'Espaço de Morrison (HDF)',
    subtitle: 'Hemoperitônio hepatorrenal direito',
    positioning: [
      'Transdutor na linha axilar média direita, entre 8.º e 11.º espaços intercostais.',
      'Marcador cefálico; deslize inferolateral para visualizar o polo inferior renal.',
    ],
    normalFindings: [
      'Interface hepatorrenal sem coleção anecoica.',
      'Espaço de Morrison seco; cápsula renal direita íntegra.',
    ],
    abnormalFindings: [
      'Coleção anecoica no espaço hepatorrenal → sangue livre peritoneal.',
      'Extensão ao polo inferior do rim direito indica grande volume de sangue.',
    ],
  ),
  _WindowData(
    title: 'Espaço de Koller (Esplenorrenal)',
    subtitle: 'Hemoperitônio esplenorrenal esquerdo',
    positioning: [
      'Transdutor na linha axilar posterior esquerda, 10.º–11.º espaços intercostais.',
      'Marcador cefálico; angule posteriormente para otimizar a janela acústica.',
    ],
    normalFindings: [
      'Interface baço-rim sem coleção.',
      'Recesso esplênico seco; diafragma esquerdo íntegro.',
    ],
    abnormalFindings: [
      'Coleção anecoica no espaço esplenorrenal → hemoperitônio esquerdo.',
      'Líquido acima do diafragma esquerdo → hemotórax esquerdo associado.',
    ],
  ),
  _WindowData(
    title: 'Janela Suprapúbica',
    subtitle: 'Pelve — bexiga e fundo de saco de Douglas',
    positioning: [
      'Transdutor 2–3 cm acima da sínfise púbica; cortes sagital e transverso.',
      'Bexiga cheia melhora a janela acústica — use-a como referência anatômica.',
    ],
    normalFindings: [
      'Bexiga visualizada como estrutura anecoica e regular.',
      'Ausência de líquido livre periuterino ou perivesical.',
    ],
    abnormalFindings: [
      'Líquido no fundo de saco de Douglas → hemoperitônio pélvico.',
      'Coleção perivesical lateral indica grande volume de sangue intraperitoneal.',
    ],
  ),
  _WindowData(
    title: 'Janela Pleural Bilateral',
    subtitle: 'Pneumotórax e hemotórax — componente torácico do E-FAST',
    positioning: [
      'Transdutor longitudinal na linha hemiclavicular, 2.º–3.º espaço intercostal bilateral.',
      'Identificar a linha pleural como linha hiperecoica entre duas costelas ("bat sign").',
    ],
    normalFindings: [
      'Lung sliding bilateral presente — deslizamento rítmico da pleura visceral.',
      'Seashore sign ao modo M — granularidade abaixo da linha pleural.',
    ],
    abnormalFindings: [
      'Ausência de lung sliding + barcode sign ao modo M → pneumotórax.',
      'Lung point visível (patognomônico de PTX) — transição sliding/ausência lateral.',
      'Coleção anecoica acima do diafragma → hemotórax.',
    ],
  ),
];

// ---------------------------------------------------------------------------
// BLUE — Bedside Lung Ultrasound in Emergency (Protocolo Pulmonar)
// ---------------------------------------------------------------------------

const List<_WindowData> _blueWindows = [
  _WindowData(
    title: 'Zona Anterior — BLUE Points',
    subtitle: 'Pesquisa de linhas A/B e lung sliding',
    positioning: [
      'Sobrepor as duas mãos ao tórax: zona da mão superior = BLUE point superior; zona da mão inferior = BLUE point inferior.',
      'Transdutor longitudinal na linha hemiclavicular; identificar a linha pleural entre dois arcos costais.',
    ],
    normalFindings: [
      'Lung sliding presente — "formiga andando" ao longo da pleura (perfil A normal).',
      'Predomínio de linhas A (reverberações horizontais equidistantes — interface ar normal).',
      'Seashore sign ao modo M: granularidade abaixo da linha pleural.',
    ],
    abnormalFindings: [
      'Ausência de lung sliding → pneumotórax, intubação seletiva ou pleurodese prévia.',
      '≥ 3 linhas B por janela intercostal (perfil B) → edema pulmonar cardiogênico ou pneumonia intersticial.',
      'Consolidação (hepatização) com broncograma aéreo dinâmico → pneumonia lobar.',
    ],
  ),
  _WindowData(
    title: 'Ponto PLAPS (PosteroLateral)',
    subtitle: 'Derrame pleural e consolidação basal',
    positioning: [
      'Transdutor na linha axilar posterior, ao nível do 5.º–7.º espaço intercostal.',
      'Probe em posição coronal; identificar diafragma, fígado/baço e base pulmonar adjacente.',
    ],
    normalFindings: [
      'Sinal espelho (mirror sign) do fígado/baço preservado acima do diafragma — pulmão aerado.',
      'Ausência de coleção anecoica acima do diafragma.',
    ],
    abnormalFindings: [
      'Espaço anecoico acima do diafragma → derrame pleural (spine sign confirma).',
      'Shred sign (interface irregular parênquima aerado/não aerado) → consolidação periférica.',
      'Spine sign: visualização das vértebras acima do diafragma — confirma derrame volumoso.',
    ],
  ),
  _WindowData(
    title: 'Lung Point e Modo M',
    subtitle: 'Confirmação de pneumotórax — ponto de transição',
    positioning: [
      'Após identificar ausência de sliding, deslizar o transdutor lateralmente até o ponto onde o sliding retorna.',
      'Aplicar modo M sobre a linha pleural para capturar o padrão de seashore vs. barcode.',
    ],
    normalFindings: [
      'Seashore sign contínuo ao modo M — granularidade abaixo da linha pleural.',
      'Lung sliding ininterrupto; ausência de zona de transição.',
    ],
    abnormalFindings: [
      'Barcode sign (stratosphere sign): linhas horizontais paralelas abaixo da pleura → confirmação de PTX.',
      'Lung point visível (patognomônico): transição brusca entre sliding presente e ausente durante o ciclo respiratório.',
    ],
  ),
  _WindowData(
    title: 'Zonas Posteriores (BLUE-Plus)',
    subtitle: 'Consolidação posterior e perfis A/B laterais',
    positioning: [
      'Paciente em decúbito lateral ou semissupino; transdutor entre a coluna e a escápula.',
      'Avaliar bilateralmente os campos basais posteriores em busca de perfis B e consolidação.',
    ],
    normalFindings: [
      'Lung sliding preservado bilateralmente com predomínio de linhas A.',
      'Ausência de condensação posterior ou derrame.',
    ],
    abnormalFindings: [
      'Perfil C (consolidação com broncograma aéreo) posterior bilateral → pneumonia grave.',
      'Perfil A anterior + perfil B lateral → padrão sugestivo de TEP (algoritmo BLUE).',
      'Efusão pleural posterior bilateral volumosa → descartar ICC descompensada.',
    ],
  ),
];

// ---------------------------------------------------------------------------
// RUSH — Rapid Ultrasound in Shock (técnica HI-MAP)
// ---------------------------------------------------------------------------

const List<_WindowData> _rushWindows = [
  _WindowData(
    title: 'H — Heart (Coração)',
    subtitle: 'Contratilidade, tamponamento e relação VD/VE',
    positioning: [
      'Vista subxifoide (preferida em emergências): transdutor abaixo do xifóide, angulação cefálica de 15–20°.',
      'Alternativa: paraesternal eixo longo ou apical 4 câmaras para melhor avaliação de câmaras.',
    ],
    normalFindings: [
      'VE com boa contratilidade — fração de ejeção visual estimada > 50% (squeeze test positivo).',
      'Ausência de derrame pericárdico; saco pericárdico seco.',
      'Relação VD/VE < 0,6 na diástole.',
    ],
    abnormalFindings: [
      'Hipocinesia global do VE → choque cardiogênico (FE < 30%).',
      'Derrame pericárdico com colapso do AD ou VD na diástole → tamponamento cardíaco.',
      'VD dilatado (≥ VE) + septo paradoxal → cor pulmonale agudo (TEP maciço).',
    ],
  ),
  _WindowData(
    title: 'I — IVC (Veia Cava Inferior)',
    subtitle: 'Estimativa de volemia e responsividade a fluidos',
    positioning: [
      'Vista subcostal longitudinal; transdutor 2–3 cm abaixo do apêndice xifóide na linha média.',
      'Modo M posicionado 2 cm distal ao óstio da veia hepática direita para medir colapso inspiratório.',
    ],
    normalFindings: [
      'Diâmetro VCI 1,5–2,5 cm com colapso inspiratório > 50% (IVC-CI > 50%) → responsiva a fluidos.',
      'VCI < 1,5 cm colabável → hipovolemia grave; provável resposta à reposição volêmica.',
    ],
    abnormalFindings: [
      'VCI > 2,5 cm sem colapso inspiratório → pressão venosa elevada (ICC, tamponamento, choque obstrutivo).',
      'VCI dilatada e fixa em paciente ventilado mecanicamente → usar variação de pressão de pulso como guia.',
    ],
  ),
  _WindowData(
    title: 'M — Main Pump / Aorta Abdominal',
    subtitle: 'Pesquisa de aneurisma de aorta abdominal (AAA)',
    positioning: [
      'Transdutor transversal logo abaixo do processo xifóide; rastrear a aorta da origem celíaca até a bifurcação ilíaca.',
      'Medir sempre o diâmetro externo da aorta no maior eixo transversal, parede a parede.',
    ],
    normalFindings: [
      'Diâmetro aórtico < 3,0 cm em toda a extensão abdominal.',
      'Paredes lisas e simétricas; ausência de trombo mural ou hematoma periaórtico.',
    ],
    abnormalFindings: [
      'Diâmetro ≥ 3,0 cm → AAA; ≥ 5,5 cm com dor lombar ou abdominal → cirurgia de urgência.',
      'Hematoma retroperitoneal ou líquido livre ao redor da aorta → ruptura iminente ou estabelecida.',
    ],
  ),
  _WindowData(
    title: 'A — Abdomen (FAST Rápido)',
    subtitle: 'Hemoperitônio — espaços hepatorrenal, esplenorrenal e pélvico',
    positioning: [
      'Repetir sequência FAST: Morrison (LMD, 8–11.º espaço), Koller (LP esquerda, 10–11.º espaço) e suprapúbico.',
      'Focar nas áreas dependentes da gravidade onde o sangue se acumula preferencialmente.',
    ],
    normalFindings: [
      'Interfaces sólido-viscerais sem coleção anecoica em todos os quadrantes.',
      'Bexiga distendida e visível sem líquido perivesical.',
    ],
    abnormalFindings: [
      'Coleção anecoica em qualquer espaço peritoneal → hemoperitônio; acionar cirurgia.',
      'Vísceras flutuando em líquido livre → hemoperitônio maciço com instabilidade hemodinâmica.',
    ],
  ),
  _WindowData(
    title: 'P — Pipes (Veias Profundas)',
    subtitle: 'Trombose venosa profunda proximal — etiologia de choque obstrutivo',
    positioning: [
      'Transdutor linear de alta frequência (7–12 MHz) na veia femoral comum (virilha) e veia poplítea (fossa poplítea).',
      'Técnica de compressão: pressão suficiente para colabar a veia — artéria adjacente permanece visível.',
    ],
    normalFindings: [
      'Veia femoral comum e poplítea completamente compressíveis → ausência de TVP proximal.',
      'Fluxo venoso espontâneo e fásico ao Doppler colorido.',
    ],
    abnormalFindings: [
      'Veia não compressível com material hiperecóico intraluminal → TVP proximal confirmada.',
      'TVP bilateral proximal + choque distributivo ou obstrutivo → suspeita de TEP maciço.',
    ],
  ),
];

// ---------------------------------------------------------------------------
// FOCUS — Focused Cardiac Ultrasound (Protocolo Cardíaco)
// ---------------------------------------------------------------------------

const List<_WindowData> _focusWindows = [
  _WindowData(
    title: 'Paraesternal Eixo Longo (PLAX)',
    subtitle: 'Função sistólica do VE, valvas e raiz aórtica',
    positioning: [
      'Transdutor no 3.º–4.º espaço intercostal esquerdo, borda paraesternal esquerda.',
      'Marcador cefálico apontando para o ombro direito do paciente; visualizar raiz aórtica, VE e valva mitral.',
    ],
    normalFindings: [
      'EPSS (E-Point Septal Separation) < 8 mm — folheto anterior da mitral próximo ao septo.',
      'Raiz aórtica < 3,7 cm; átrio esquerdo < 4,0 cm.',
      'Espessura de parede posterior do VE e septo 0,6–1,2 cm na diástole.',
    ],
    abnormalFindings: [
      'EPSS > 10 mm → disfunção sistólica grave do VE (FE estimada < 30%).',
      'Raiz aórtica ≥ 4,5 cm → dilatação aórtica significativa; excluir dissecção.',
      'Efusão pericárdica posterior ao VE → derrame pericárdico.',
    ],
  ),
  _WindowData(
    title: 'Paraesternal Eixo Curto (PSAX)',
    subtitle: 'Avaliação segmentar do VE e geometria do VD',
    positioning: [
      'Rotacionar 90° a partir do PLAX no sentido horário; marcador para o ombro esquerdo do paciente.',
      'Tiltar de apical (músculo papilar) a basal (valva aórtica) para avaliar todos os segmentos miocárdicos.',
    ],
    normalFindings: [
      'VE em corte circular simétrico ("O shape") com movimentação concêntrica de todos os segmentos.',
      'Septo interventricular curvo em direção ao VD — geometria normal.',
    ],
    abnormalFindings: [
      'Septo em forma de "D" (D-sign) → sobrecarga de pressão do VD (TEP, hipertensão pulmonar).',
      'Hipocinesia segmentar (parede anterior → CDA; inferolateral → CX; inferior → CD) → IAM.',
      'Regurgitação mitral com jato colorido ao Doppler → valvopatia significativa.',
    ],
  ),
  _WindowData(
    title: 'Apical 4 Câmaras (A4C)',
    subtitle: 'Comparação VD/VE, função diastólica e trombo apical',
    positioning: [
      'Transdutor no ápice cardíaco palpável (5.º espaço intercostal, linha hemiclavicular esquerda).',
      'Marcador para as 3 horas; otimizar para visualizar as 4 câmaras simetricamente com o septo vertical.',
    ],
    normalFindings: [
      'VD < 2/3 do diâmetro do VE na diástole; ápice formado pelo VE.',
      'Anulus medial (e\') ≥ 8 cm/s ao TDI → ausência de disfunção diastólica significativa.',
      'Ausência de massa ou trombo intracavitário.',
    ],
    abnormalFindings: [
      'VD ≥ VE + septo paradoxal → cor pulmonale agudo; sinal de McConnell confirma TEP.',
      'Sinal de McConnell: discinesia da parede livre do VD com ápice preservado — patognomônico de TEP maciço.',
      'Trombo apical do VE (massa ecoica apical) → sequela de IAM anterior extenso.',
    ],
  ),
  _WindowData(
    title: 'Subcostal + VCI',
    subtitle: 'Atividade cardíaca global, tamponamento e pressão venosa central estimada',
    positioning: [
      'Transdutor logo abaixo do xifóide, angulação cefálica de 15–20°; primeira opção em PCR e DPOC grave.',
      'Girar 90° para corte longitudinal da VCI — medir 2 cm distal ao óstio da veia hepática direita.',
    ],
    normalFindings: [
      'Quatro câmaras visíveis com contratilidade preservada.',
      'VCI < 2,1 cm com colapso inspiratório > 50% → PVC estimada 0–5 mmHg.',
    ],
    abnormalFindings: [
      'Coração imóvel → confirmar assistolia ou atividade elétrica sem pulso (AESP).',
      'Colapso do átrio direito durante a diástole ventricular → tamponamento incipiente.',
      'VCI dilatada (> 2,5 cm) sem colapso + VD dilatado → choque obstrutivo ou ICC direita.',
    ],
  ),
];

// ---------------------------------------------------------------------------
// DTC — Doppler Transcraniano
// ---------------------------------------------------------------------------

const List<_WindowData> _dtcWindows = [
  _WindowData(
    title: 'Janela Transtemporal — ACM',
    subtitle: 'Artéria Cerebral Média — principal índice de vasospasmo',
    positioning: [
      'Probe setorial de baixa frequência (1–2 MHz) na janela óssea temporal, 1–2 cm acima do arco zigomático entre o tragus e o canto lateral do olho.',
      'Profundidade de insonação 45–65 mm para a ACM; ângulo de insonação < 30° para Doppler preciso.',
    ],
    normalFindings: [
      'Velocidade média da ACM (VMACM): 55–80 cm/s em adultos; fluxo em direção à sonda (codificado em vermelho).',
      'Índice de Pulsatilidade (IP) de Gosling: 0,6–1,1.',
    ],
    abnormalFindings: [
      'VMACM > 120 cm/s → vasospasmo moderado; > 200 cm/s → vasospasmo grave (pós-HSA).',
      'IP > 1,4 → hipertensão intracraniana; ausência de fluxo diastólico → PIC crítica (> 60 mmHg).',
      'Índice de Lindegaard > 6 → vasospasmo verdadeiro vs. hiperemia global.',
    ],
  ),
  _WindowData(
    title: 'Janela Transtemporal — ACA e ACP',
    subtitle: 'Artérias Cerebrais Anterior e Posterior — polígono de Willis',
    positioning: [
      'A partir da mesma janela transtemporal, aumentar profundidade para 60–75 mm.',
      'ACP ipsilateral: profundidade 55–75 mm, fluxo em direção ao transdutor. ACA: profundidade 60–70 mm, fluxo se afastando.',
    ],
    normalFindings: [
      'ACP: velocidade média 35–55 cm/s; IP 0,6–1,1.',
      'ACA: velocidade média 45–65 cm/s; assimetria inter-hemisférica < 30%.',
    ],
    abnormalFindings: [
      'Assimetria de VMACM > 30% entre hemisférios → estenose ou oclusão significativa ipsilateral.',
      'Inversão do fluxo na ACA → oclusão da ACI ipsilateral com colateral cruzada via polígono.',
      'Velocidades muito baixas ou ausentes bilateralmente → suspeitar morte encefálica.',
    ],
  ),
  _WindowData(
    title: 'Janela Transforaminal — Artéria Basilar e Vertebrais',
    subtitle: 'Circulação posterior e critério de morte encefálica',
    positioning: [
      'Paciente com cabeça fletida (queixo ao tórax) ou em decúbito lateral.',
      'Transdutor no forame magno (suboccipital) com angulação cefálica; artéria basilar a 80–110 mm, vertebrais a 50–80 mm.',
    ],
    normalFindings: [
      'Artéria basilar: velocidade 30–55 cm/s, fluxo anterógrado (afastando-se do transdutor).',
      'Artérias vertebrais: velocidade 35–55 cm/s; IP 0,6–1,1.',
    ],
    abnormalFindings: [
      'Fluxo reverso nas artérias vertebrais → síndrome de roubo da subclávia ipsilateral.',
      'Ausência de fluxo diastólico ou padrão "vela de veleiro" (fluxo reverso diastólico) → critério de morte encefálica.',
      'Velocidade basilar > 100 cm/s → vasospasmo da circulação posterior (pós-HSA).',
    ],
  ),
];

// ---------------------------------------------------------------------------
// CASA — Cardiac Arrest Sonographic Assessment
// ---------------------------------------------------------------------------

const List<_WindowData> _casaWindows = [
  _WindowData(
    title: 'Subcostal — Atividade Cardíaca',
    subtitle: 'Detecção de atividade mecânica e pseudo-AESP',
    positioning: [
      'Transdutor subxifoide durante pausas de RCP (≤ 10 s); angulação cefálica para visualizar as 4 câmaras.',
      'Otimizar ganho para distinguir contrações reais de movimentos passivos induzidos pela massagem.',
    ],
    normalFindings: [
      'Contrações cardíacas espontâneas e organizadas → atividade mecânica presente (pseudo-AESP ou retorno à circulação).',
      'Fibrillation ventricular: movimentos caóticos sem organização — indica FV fina tratável.',
    ],
    abnormalFindings: [
      'Coração completamente imóvel (assistolia verdadeira) → prognóstico reservado; considerar suspensão da RCP.',
      'Câmaras progressivamente dilatadas sem contratilidade → ausência de fluxo sistêmico efetivo.',
    ],
  ),
  _WindowData(
    title: 'Causas Reversíveis — 4H e 4T',
    subtitle: 'Busca ultrasonográfica das causas tratáveis durante a RCP',
    positioning: [
      'Avaliação sequencial na ordem de maior impacto: subxifoide (tamponamento/cardíaco) → janela pleural (pneumotórax) → VCI (hipovolemia) → Morrison/Koller (hemoperitônio).',
      'Cada janela deve ser obtida e interpretada em < 10 s para minimizar interrupção da RCP.',
    ],
    normalFindings: [
      'Ausência de derrame pericárdico, pneumotórax bilateral e hemoperitônio.',
      'VCI com alguma variação — descarta hipovolemia profunda.',
    ],
    abnormalFindings: [
      'Derrame pericárdico com colapso de câmaras → tamponamento (indicação de pericardiocentese de emergência).',
      'Ausência bilateral de lung sliding → pneumotórax hipertensivo bilateral (descompressão imediata).',
      'VCI colabada (< 1,0 cm) → hipovolemia profunda; reposição volêmica agressiva.',
      'VD dilatado + septo em D → TEP maciço (considerar trombólise em PCR refratária).',
    ],
  ),
  _WindowData(
    title: 'Pós-RCE — Avaliação Hemodinâmica',
    subtitle: 'Otimização após retorno da circulação espontânea',
    positioning: [
      'Apical 4 câmaras para estimativa visual da FE pós-RCE.',
      'VCI subcostal para guiar reposição volêmica inicial; repetir a cada 10–15 min.',
    ],
    normalFindings: [
      'FE visual estimada ≥ 40% com hemodinâmica progressivamente estável.',
      'VCI com colapso > 50% em ventilação espontânea → normovolemia.',
    ],
    abnormalFindings: [
      'Hipocinesia grave do VE pós-RCE → atordoamento miocárdico pós-PCR ou IAM subjacente como causa.',
      'VD dilatado persistente → disfunção de VD por TEP ou sobrecarga pressórica iatrogênica.',
      'Derrame pericárdico novo pós-RCP → complicação mecânica (pneumopericárdio, laceração).',
    ],
  ),
];

// ---------------------------------------------------------------------------
// Protocol registry — lookup by pocusItem.id
// ---------------------------------------------------------------------------

const Map<String, List<_WindowData>> _protocolWindows = {
  'pocus-fast':     _efastWindows,
  'pocus-pulmonar': _blueWindows,
  'pocus-rush':     _rushWindows,
  'pocus-cardiac':  _focusWindows,
  'pocus-dtc':      _dtcWindows,
  'pocus-casa':     _casaWindows,
};

// ===========================================================================
// UI — Window sections
// ===========================================================================

class _WindowSections extends StatelessWidget {
  const _WindowSections({required this.pocusItem});

  final PocusItem pocusItem;

  @override
  Widget build(BuildContext context) {
    final windows = _protocolWindows[pocusItem.id] ?? _efastWindows;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: Column(
          children: [
            for (int i = 0; i < windows.length; i++) ...[
              _WindowCard(window: windows[i], index: i),
              if (i < windows.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Window card — ExpansionTile wrapping placeholder + 3 info subsections
// ---------------------------------------------------------------------------

class _WindowCard extends StatelessWidget {
  const _WindowCard({required this.window, required this.index});

  final _WindowData window;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 1,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: index == 0,
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: Color(0xFF1565C0),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        title: Text(
          window.title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          window.subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        iconColor: Colors.grey[600],
        collapsedIconColor: Colors.grey[400],
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          const Divider(height: 1, thickness: 1, color: Color(0xFFF5F5F5)),
          const SizedBox(height: 12),
          _VideoWindowPlaceholder(windowTitle: window.title),
          const SizedBox(height: 16),
          _InfoSubsection(
            icon: Icons.adjust,
            iconColor: const Color(0xFF00695C),
            label: 'Posicionamento da Sonda',
            bullets: window.positioning,
          ),
          const SizedBox(height: 12),
          _InfoSubsection(
            icon: Icons.check_circle_outline,
            iconColor: const Color(0xFF2E7D32),
            label: 'Achados Normais',
            bullets: window.normalFindings,
          ),
          const SizedBox(height: 12),
          _InfoSubsection(
            icon: Icons.warning_amber_outlined,
            iconColor: const Color(0xFFC62828),
            label: 'Achados Patológicos',
            bullets: window.abnormalFindings,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 16:9 video placeholder inside each window
// ---------------------------------------------------------------------------

class _VideoWindowPlaceholder extends StatelessWidget {
  const _VideoWindowPlaceholder({required this.windowTitle});

  final String windowTitle;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0D1B2A),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_circle_outline,
                size: 36,
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              windowTitle,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Vídeo em breve',
              style: TextStyle(color: Colors.white24, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Info subsection — label row + bullet list
// ---------------------------------------------------------------------------

class _InfoSubsection extends StatelessWidget {
  const _InfoSubsection({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.bullets,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final bullet in bullets)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    bullet,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// LocalVideoPlayer — kept for future per-window video integration.
// Will replace _VideoWindowPlaceholder once backend delivers video assets.
// ---------------------------------------------------------------------------

class LocalVideoPlayer extends StatefulWidget {
  const LocalVideoPlayer({super.key, required this.localPath});
  final String localPath;

  @override
  State<LocalVideoPlayer> createState() => _LocalVideoPlayerState();
}

class _LocalVideoPlayerState extends State<LocalVideoPlayer> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final file = File(widget.localPath);
    final exists = await file.exists();
    final size = exists ? await file.length() : 0;

    if (!exists || size == 0) {
      if (mounted) setState(() => _error = 'Arquivo de vídeo inválido ou vazio.');
      return;
    }

    try {
      final controller = VideoPlayerController.file(file);
      await controller.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException(
          'VideoPlayerController.initialize() excedeu 15s.',
        ),
      );

      if (!mounted) {
        controller.dispose();
        return;
      }

      setState(() => _controller = controller);
      controller.setLooping(true);
      controller.setVolume(0.0);
      controller.play();
    } on TimeoutException {
      if (mounted) setState(() => _error = 'Tempo limite ao carregar o vídeo.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Erro ao reproduzir o vídeo.');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _VideoWindowPlaceholder(windowTitle: _error!);
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: VideoPlayer(_controller!),
    );
  }
}
