# ADR-004 — Estratégia de Cache de Mídia para o Módulo POCUS

**Status:** Aceito
**Data:** 2026-03-08
**Contexto:** Fase 3 — Módulo POCUS (vídeos MP4 de ultrassonografia)

---

## Contexto

O módulo POCUS exibe vídeos curtos de loops de ultrassom (MP4, tipicamente 2–15 MB
cada). O app precisa funcionar em condições de conectividade precária (plantão
hospitalar, Wi-Fi instável) e deve respeitar o armazenamento limitado do dispositivo.
A solução precisa ser compatível com a arquitetura offline-first já estabelecida
(PowerSync + Supabase) e com as Leis de Segurança do projeto.

---

## Decisão

### 1. Separação clara entre metadados e binários

| Dado | Onde fica | Mecanismo |
|---|---|---|
| Metadados (`path`, `kind`, `owner_id`) | PowerSync SQLite (tabela `media_assets`) | Replicação automática via LogRep |
| Arquivo binário (MP4) | `<cacheDir>/pocus_media/<assetId>.mp4` | Download sob demanda por `MediaCacheManager` |
| Registro de cache | PowerSync local-only (`media_cache_entries`) | Gerenciado pelo app, nunca sincronizado |

Essa separação é intencional: sincronizar binários via PowerSync seria inviável em
termos de volume e cobriria casos de uso diferentes (o usuário precisa do _índice_
offline, mas só do _vídeo_ quando abre o item).

### 2. Algoritmo de evicção: LRU com limite de 250 MB

**`MediaCacheManager`** mantém a coluna `last_accessed_at` em `media_cache_entries`.
Sempre que um arquivo é lido, `last_accessed_at` é atualizado. Ao salvar um novo
arquivo, `_evictIfNeeded()` ordena todas as entradas por `last_accessed_at ASC` e
remove as mais antigas até que o total fique abaixo de 250 MB.

**Justificativa do limite:** 250 MB representa ~20–40 vídeos curtos de POCUS —
suficiente para um plantão offline sem impactar significativamente o armazenamento
do dispositivo (baseline de 64 GB em smartphones modernos).

### 3. Download para offline explícito

O usuário pode iniciar `downloadForOffline(pocusItemId)` para pré-baixar todos os
vídeos de um item antes de entrar em área sem sinal. Isso é transparente no UI com
um botão "Baixar para offline". Sem essa ação, vídeos são baixados individualmente
ao serem abertos (lazy download).

### 4. Tokens de acesso são efêmeros (SECURITY.md: "nunca colocar tokens no app")

O `MediaCacheManager` busca um Signed URL do Supabase Storage com TTL de 5 minutos
**no momento do download** e nunca persiste esse URL em banco ou SharedPreferences.
O download é feito diretamente via `dart:io HttpClient` em modo streaming, sem
carregar o MP4 inteiro na memória. O token expira antes de qualquer janela razoável
de interceptação.

### 5. Controle de downloads simultâneos

Um `Map<assetId, Future>` coalesce chamadas concorrentes para o mesmo asset
(ex.: múltiplos widgets pedindo o mesmo vídeo). Apenas um HTTP request é feito.
Downloads sequenciais em `downloadForOffline` evitam saturar a conexão mobile.

---

## Consequências

**Positivas:**
- Vídeos reproduzem instantaneamente quando já cacheados (sem buffer).
- O índice de itens POCUS funciona 100% offline (metadados via PowerSync).
- Nenhum token ou URL assinado é persistido (compliance com SECURITY.md).
- LRU garante que os vídeos mais usados permanecem no cache automaticamente.
- A evicção é determinística e testável de forma isolada.

**Negativas / Trade-offs:**
- O primeiro acesso a um vídeo requer conexão (lazy load).
- 250 MB é um limite fixo em código — futuras versões podem precisar de
  configuração por usuário (ex.: "usar apenas em Wi-Fi").
- A tabela `media_cache_entries` precisa de limpeza manual se o usuário
  desinstalar e reinstalar o app (os arquivos serão removidos pelo OS, mas a
  tabela PowerSync pode sobrar; `MediaCacheManager` lida com isso verificando
  se o `File` existe antes de retornar o path).

---

## Alternativas Consideradas

| Alternativa | Por que rejeitada |
|---|---|
| `flutter_cache_manager` (lib de terceiros) | Não integra com PowerSync/local-only; cache metadata fica fora do controle do schema |
| Supabase Storage direct download (`Uint8List`) | Carrega MP4 inteiro em memória — inviável para arquivos >5 MB em dispositivos com pouca RAM |
| Sincronizar binários via PowerSync | Fora do escopo do PowerSync; volume de dados inviável |
| TTL fixo (ex.: 7 dias) em vez de LRU | TTL não reflete uso real; um vídeo visto todo plantão seria eviccionado injustamente enquanto um vídeo nunca aberto permaneceria |
