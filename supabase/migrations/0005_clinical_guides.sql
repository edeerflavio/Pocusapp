-- =============================================================
-- 0005_clinical_guides.sql
-- Tabela de guias clínicos estruturados. Suporta múltiplos
-- cenários (emergência, enfermaria, UBS) e especialidades.
-- content_json: TEXT com JSON — compatível com PowerSync/SQLite.
-- tags: TEXT com JSON array — compatível com PowerSync/SQLite.
-- =============================================================

create table public.clinical_guides (
  id           uuid        primary key default gen_random_uuid(),
  slug         text        unique not null,
  title        text        not null,
  scenario     text        not null default 'geral'
                           check (scenario in ('emergencia', 'enfermaria', 'ubs', 'geral')),
  specialty    text        not null default '',
  summary      text        not null default '',
  content_json text        not null default '{}',
  tags         text        not null default '[]',
  source       text        not null default '',
  version      text        not null default '1.0',
  status       text        not null default 'published'
                           check (status in ('draft', 'review', 'published')),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

alter table public.clinical_guides enable row level security;

create index idx_clinical_guides_slug     on public.clinical_guides(slug);
create index idx_clinical_guides_scenario on public.clinical_guides(scenario);
create index idx_clinical_guides_status   on public.clinical_guides(status);
create index idx_clinical_guides_updated  on public.clinical_guides(updated_at);

-- RLS: qualquer usuário autenticado lê guias publicados; admins gerenciam tudo.
create policy "select_published_guides" on public.clinical_guides
  for select using (status = 'published');

create policy "admin_manage_guides" on public.clinical_guides
  for all using (public.is_admin_or_editor())
  with check (public.is_admin_or_editor());

-- Trigger de updated_at (reutiliza função do 0001_init.sql).
create trigger set_clinical_guides_updated_at
  before update on public.clinical_guides
  for each row execute function public.set_updated_at();

-- =============================================================
-- Seed: Pneumonia Adquirida na Comunidade (PAC)
-- =============================================================

insert into public.clinical_guides
  (slug, title, scenario, specialty, summary, content_json, tags, source, version)
values (
  'pac',
  'Pneumonia Adquirida na Comunidade',
  'emergencia',
  'Pneumologia / Medicina de Emergência',
  'Infecção aguda do parênquima pulmonar adquirida fora do ambiente hospitalar ou até 48h após admissão. Principal causa de morte por doença infecciosa no Brasil. Diagnóstico clínico + radiológico; estratificação de gravidade obrigatória (CURB-65 ou PSI) para definir local de tratamento.',
  $content${
    "diagnosis": {
      "clinical_criteria": [
        "Febre (> 38°C) ou hipotermia (< 36°C) de início recente",
        "Tosse produtiva com expectoração purulenta ou hemoptoica",
        "Dispneia ou taquipneia (FR > 20 irpm)",
        "Dor torácica pleurítica",
        "Crepitações, egofonia ou macicez à percussão no exame físico"
      ],
      "lab_findings": [
        "Leucocitose > 12.000/mm³ ou leucopenia < 4.000/mm³",
        "PCR elevada (> 10× LSN sugere etiologia bacteriana)",
        "Procalcitonina: útil para guiar início e duração do antibiótico",
        "Hemocultura (2 amostras antes do ATB): indicada em CURB-65 ≥ 2 ou hospitalização",
        "Gasometria arterial: se SpO2 < 92% ou suspeita de hipercapnia (DPOC)"
      ],
      "imaging": [
        "Rx tórax PA + perfil: infiltrado alveolar lobar ou broncopneumônico — obrigatório para diagnóstico",
        "TC de tórax: reservada para casos duvidosos, imunocomprometidos ou falha terapêutica",
        "POCUS pulmonar (ultrassom): alternativa ao Rx em emergências — consolidação + broncograma aéreo dinâmico"
      ]
    },
    "severity": {
      "tool": "CURB-65",
      "description": "Escore validado para estratificação de risco e decisão do local de tratamento. Um ponto para cada critério presente.",
      "criteria": [
        "C — Confusão mental (novo ou agudo; excluir causas metabólicas)",
        "U — Ureia > 42 mg/dL (7 mmol/L) — solicitar se internação prevista",
        "R — Frequência respiratória ≥ 30 irpm",
        "B — Pressão arterial: sistólica < 90 mmHg ou diastólica ≤ 60 mmHg",
        "65 — Idade ≥ 65 anos"
      ],
      "scores": [
        {
          "range": "0 – 1",
          "risk": "Baixo risco (mortalidade < 3%)",
          "recommendation": "Tratamento ambulatorial, salvo fatores sociais desfavoráveis"
        },
        {
          "range": "2",
          "risk": "Risco moderado (mortalidade ~9%)",
          "recommendation": "Internação em enfermaria ou observação prolongada no PS"
        },
        {
          "range": "3 – 5",
          "risk": "Alto risco (mortalidade 17–57%)",
          "recommendation": "Internação hospitalar — avaliar UTI se pontuação ≥ 4 ou critérios ATS"
        }
      ]
    },
    "treatment": {
      "outpatient": {
        "title": "Ambulatorial — CURB-65 0–1",
        "first_line": [
          "Amoxicilina 1g VO 8/8h por 5–7 dias (cobertura de S. pneumoniae)",
          "Azitromicina 500mg VO 1x/dia por 5 dias (suspeita de atípicos: Mycoplasma, Chlamydia, Legionella)"
        ],
        "alternative": [
          "Levofloxacino 500mg VO 1x/dia por 7 dias (alergia à penicilina ou falha prévia)",
          "Moxifloxacino 400mg VO 1x/dia por 5 dias"
        ],
        "note": "Reavaliação clínica em 48–72h. Ausência de melhora indica internação. Duração mínima: 5 dias com apirexia ≥ 48h."
      },
      "inpatient": {
        "title": "Internação em Enfermaria — CURB-65 2–3",
        "first_line": [
          "Amoxicilina-clavulanato 875/125mg VO 12/12h + Azitromicina 500mg VO/EV 1x/dia",
          "Ampicilina-sulbactam 1,5g EV 6/6h + Azitromicina 500mg EV 1x/dia"
        ],
        "alternative": [
          "Ceftriaxona 1–2g EV 1x/dia + Levofloxacino 750mg EV 1x/dia (alergia à penicilina)"
        ],
        "note": "Stepdown para VO após 48–72h de melhora clínica e hemodinâmica. Duração total: 5–7 dias."
      },
      "icu": {
        "title": "UTI — CURB-65 ≥ 4 ou Critérios ATS/IDSA",
        "first_line": [
          "Ceftriaxona 2g EV 1x/dia + Levofloxacino 750mg EV 1x/dia",
          "Piperacilina-tazobactam 4,5g EV 6/6h + Azitromicina 500mg EV (risco de Pseudomonas: DPOC grave, bronquiectasia, uso recente de ATB de amplo espectro)"
        ],
        "alternative": [
          "Meropenem 1g EV 8/8h + Levofloxacino 750mg EV (risco elevado de P. aeruginosa ou Enterobactérias ESBL)"
        ],
        "note": "Critérios ATS minor para UTI: FR ≥ 30, PaO2/FiO2 < 250, infiltrado multilobar, PAS < 90 mmHg, confusão, uremia, trombocitopenia, hipotermia, leucopenia."
      }
    },
    "red_flags": [
      "SpO2 < 92% em ar ambiente (ou < 88% em DPOC com hipercapnia habitual)",
      "Frequência respiratória ≥ 30 irpm persistente após estabilização inicial",
      "Pressão arterial sistólica < 90 mmHg (choque séptico)",
      "Alteração do nível de consciência — confusão ou agitação de início agudo",
      "Envolvimento multilobar ou bilateral no Rx de tórax",
      "Ausência de melhora clínica após 72h de antibioticoterapia adequada",
      "Suspeita de derrame pleural complicado, empiema ou abscesso pulmonar",
      "Imunossupressão significativa: HIV com CD4 baixo, quimioterapia, corticoides crônicos"
    ],
    "discharge_criteria": [
      "Apirexia por ≥ 24h (temperatura < 37,8°C)",
      "SpO2 ≥ 94% em ar ambiente (ou basal habitual do paciente)",
      "Frequência cardíaca < 100 bpm e frequência respiratória < 24 irpm",
      "Pressão arterial sistólica ≥ 90 mmHg sem vasopressores",
      "Capacidade de ingestão oral de medicação e dieta adequada",
      "Suporte social e condições de seguimento ambulatorial confirmados"
    ],
    "follow_up": "Revisão ambulatorial em 4–6 semanas com Rx de tórax de controle para confirmar resolução do infiltrado (persistência > 6 semanas levanta suspeita de neoplasia). Oferecer vacinação antipneumocócica (VPC13 + VPPV23) e anti-influenza ao alta hospitalar."
  }$content$,
  '["pneumonia", "respiratorio", "antibioticoterapia", "curb65", "infeccao", "pac"]',
  'IDSA/ATS Guidelines 2019 · SBPT 2022 · UpToDate 2024',
  '1.0'
);
