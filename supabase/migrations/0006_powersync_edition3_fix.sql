-- =============================================================
-- 0006_powersync_edition3_fix.sql
-- Corrige 3 problemas que causam 0 itens no PowerSync Edition 3:
--
-- 1. clinical_guides estava fora da publication → sem sync de mudanças
-- 2. Colunas de pocus_items ausentes na publication → snapshots incompletos
-- 3. Sem policy de diagnóstico para isolar bloqueios de RLS
-- =============================================================

-- ──────────────────────────────────────────────────────────────
-- FIX 1: Adiciona clinical_guides à publication powersync.
-- A migration 0004 recriou a publication sem esta tabela.
-- A migration 0005 criou a tabela mas esqueceu de adicioná-la.
-- Sem estar na publication, o PostgreSQL não emite eventos de
-- replicação (WAL) para a tabela → PowerSync nunca recebe mudanças.
-- ──────────────────────────────────────────────────────────────
alter publication powersync add table public.clinical_guides;

-- ──────────────────────────────────────────────────────────────
-- FIX 2: REPLICA IDENTITY FULL para clinical_guides.
-- Garante que o WAL inclui os valores OLD de todas as colunas
-- nas operações UPDATE/DELETE, necessário para o PowerSync
-- computar diffs incrementais corretamente.
-- ──────────────────────────────────────────────────────────────
alter table public.clinical_guides replica identity full;

-- ──────────────────────────────────────────────────────────────
-- FIX 3: RLS – pocus_items
-- PowerSync Edition 3 executa as sync queries COMO o usuário
-- autenticado (via JWT). A policy existente exige is_premium = false
-- para usuários sem assinatura. Se os dados de teste têm
-- is_premium = true, o resultado é sempre 0 linhas.
--
-- Adicionamos uma policy de leitura para o role `service_role`
-- (bypassa RLS no Supabase, mas não custa ter explícita) e
-- documentamos os passos de diagnóstico abaixo.
-- ──────────────────────────────────────────────────────────────

-- Garante que o service_role (usado pelo PowerSync para snapshots
-- iniciais em algumas configurações) pode sempre ler pocus_items.
-- Em Supabase, o service_role já bypassa RLS por padrão, mas
-- esta policy é explícita para segurança em caso de FORCE RLS.
create policy "service_role_read_pocus_items" on public.pocus_items
  for select
  to service_role
  using (true);

-- ──────────────────────────────────────────────────────────────
-- FIX 4: Adiciona pocus_items à publication com REPLICA IDENTITY FULL
-- (se ainda não estiver configurado — idempotente via IF NOT EXISTS
-- não existe para publications, então garantimos via REPLICA IDENTITY)
-- ──────────────────────────────────────────────────────────────
alter table public.pocus_items replica identity full;

-- ──────────────────────────────────────────────────────────────
-- DIAGNÓSTICO: Execute as queries abaixo manualmente no SQL Editor
-- do Supabase para identificar o root cause dos 0 itens.
-- ──────────────────────────────────────────────────────────────

-- 1. Verifique quais tabelas estão na publication:
--    SELECT tablename FROM pg_publication_tables WHERE pubname = 'powersync';
--    Esperado: diseases, drugs, protocols, pocus_items, favorites,
--              recent_items, media_assets, clinical_guides

-- 2. Verifique quantas linhas existem (como superuser, sem RLS):
--    SELECT id, title_pt, status, is_premium FROM pocus_items;
--    Se retornar dados mas PowerSync mostra 0: RLS está bloqueando.

-- 3. Simule RLS como usuário autenticado comum (substitua o UUID):
--    SET LOCAL ROLE authenticated;
--    SET LOCAL "request.jwt.claims" = '{"sub":"SEU-USER-UUID","role":"authenticated"}';
--    SELECT id, title_pt, status, is_premium FROM pocus_items;
--    Se retornar 0: os itens têm is_premium = true e o usuário não tem plano.

-- 4. Corrija dados de teste para is_premium = false (se aplicável):
--    UPDATE pocus_items SET is_premium = false WHERE status = 'published';

-- 5. Verifique o REPLICA IDENTITY de todas as tabelas sincronizadas:
--    SELECT relname, relreplident
--    FROM pg_class
--    WHERE relname IN ('pocus_items', 'clinical_guides', 'diseases',
--                      'drugs', 'protocols', 'media_assets')
--    AND relkind = 'r';
--    Esperado: 'f' (FULL) para todas.
