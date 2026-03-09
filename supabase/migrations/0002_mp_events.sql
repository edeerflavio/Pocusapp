-- Unique constraint so upsert works (one subscription per user per provider)
alter table public.subscriptions
  add constraint subscriptions_user_provider_unique unique (user_id, provider);

-- Idempotency table for Mercado Pago webhook events
create table public.mp_events (
  event_id     text primary key,
  processed_at timestamptz not null default now(),
  action       text,
  resource_id  text
);

alter table public.mp_events enable row level security;

create policy "no_direct_access_mp_events" on public.mp_events
  for all using (false);

alter table public.entitlements
  add constraint entitlements_user_plan_unique unique (user_id, plan_code);
