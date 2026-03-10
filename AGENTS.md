# Pocusapp — Instruções do projeto para Codex

## Objetivo deste repositório
Este projeto é um monorepo centrado em um aplicativo médico mobile em Flutter, com foco em POCUS e conteúdo clínico, usando:
- Flutter no app mobile
- Supabase para auth, database, storage e Edge Functions
- PowerSync para sincronização local/offline-first
- Riverpod como padrão de composição e dependências
- organização feature-first
- cache local de mídia sob demanda para vídeos/arquivos pesados

## Como você deve pensar sobre este projeto
Sempre trate este projeto como:

- mobile-first
- offline-first
- local-first para leitura de dados
- Supabase-centered no backend
- feature-first no app mobile
- Riverpod + repositories como padrão dominante
- com separação entre metadata sincronizado e binário baixado sob demanda

## Padrões que devem ser preservados
Preserve e respeite estes padrões existentes:

1. Offline-first com leitura local via PowerSync
2. UI -> provider -> repository -> local DB como fluxo dominante
3. organização por feature em `apps/mobile/lib/features/*`
4. `core` para infraestrutura compartilhada
5. Riverpod como mecanismo principal de composição/injeção
6. segurança concentrada no backend e banco
7. RLS como parte central da segurança
8. Edge Functions para operações sensíveis como billing/webhook
9. separação entre dados sincronizados e mídia binária sob demanda

## O que NÃO fazer por padrão
Não proponha nem implemente, a menos que seja explicitamente solicitado:

- reescrita total do projeto
- migração de offline-first para online-first
- substituição do Riverpod como padrão central
- substituição do PowerSync como centro da leitura local
- reorganização completa de feature-first para camadas horizontais puras
- mover lógica para chamadas remotas por tela como fluxo principal
- transformar o backend em monólito tradicional ou arquitetura de microserviços complexa
- copiar padrões web-first ou admin-first como referência central do produto

## Como avaliar referências externas
Ao analisar outro repositório, sempre compare com esta régua:

### Critérios principais
1. fonte de verdade clara entre banco, sync local e modelos
2. compatibilidade com leitura local/offline-first
3. compatibilidade com organização feature-first
4. compatibilidade com Riverpod ou padrão equivalente
5. fluxo de dados sem acesso direto da UI à rede
6. segurança forte no backend
7. suporte a mídia/binários sob demanda quando aplicável
8. aderência ao que está implementado de fato, não só à documentação

### Classificação esperada
Sempre classifique ideias externas como:
- compatível
- parcialmente compatível
- incompatível

## Como responder
Quando eu pedir análise, diagnóstico ou comparação:

- baseie-se no código real
- cite arquivos reais usados
- separe claramente:
  - fatos confirmados
  - inferências
- diga explicitamente quando algo não puder ser confirmado
- prefira respostas estruturadas e objetivas
- não invente nomes de arquivos, tabelas, colunas, providers ou fluxos
- não assuma que a documentação está atualizada; confira a implementação

## Como propor melhorias
Ao propor melhorias:

1. priorize baixo risco e alto impacto
2. preserve a arquitetura atual sempre que possível
3. prefira correções de desalinhamento entre camadas antes de refatorações cosméticas
4. corrija primeiro fontes de verdade conflitantes
5. proponha evolução incremental, nunca refatoração gigante por padrão

### Ordem de prioridade padrão
1. desalinhamentos entre migrations, schema local, sync rules e modelos
2. inconsistências que possam gerar bug real
3. duplicações e código legado que conflita com a versão atual
4. melhoria de contratos entre camadas
5. refinamentos de organização/nomenclatura

## Uma tarefa por vez
Sempre trabalhe em uma única tarefa por vez.

Fluxo obrigatório:
1. diagnosticar
2. propor a melhor próxima tarefa única
3. justificar por que ela é a melhor
4. só então implementar, se eu pedir

Nunca execute múltiplas refatorações paralelas sem autorização explícita.

## Política para implementação
Se eu pedir para implementar:

- altere apenas o mínimo necessário
- mantenha compatibilidade com a estrutura atual
- não faça mudanças paralelas “aproveitando o embalo”
- no final, liste:
  - arquivos alterados
  - motivo de cada alteração
  - riscos residuais
  - próximos passos opcionais

## Áreas sensíveis do projeto
Tenha atenção especial a:

- `supabase/migrations/*`
- `powersync.yaml`
- schema local do PowerSync
- models Flutter
- repositories
- cache de mídia
- autenticação
- billing, subscription, webhook e entitlement
- regras de storage e RLS

Nessas áreas, priorize consistência entre camadas acima de novas abstrações.

## Preferências de estilo técnico
- prefira soluções simples, explícitas e legíveis
- evite boilerplate desnecessário
- evite abstrações prematuras
- preserve convenções já adotadas pelo projeto
- só introduza novo padrão se houver benefício claro e imediato

## Quando houver conflito entre “ideal” e “real”
Prefira o que encaixa no estado atual do projeto com segurança.

Não proponha arquitetura “mais bonita” se ela exigir ruptura grande.
Prefira adaptação pragmática.

## Quando analisar meu projeto atual
Ao analisar este projeto, responda sempre:
1. o que existe de fato
2. o que está desalinhado
3. o que deve ser preservado
4. o que deve ser corrigido primeiro
5. qual é a próxima tarefa única de maior impacto e menor risco