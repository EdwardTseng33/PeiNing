-- Munea billing credits foundation.
-- Run after 001_initial_munea_schema.sql and 003_analytics_admin_foundation.sql.

begin;

create table if not exists public.entitlement_policy_versions (
  id uuid primary key default gen_random_uuid(),
  policy_key text not null,
  version integer not null check (version >= 1),
  active boolean not null default false,
  plan_order text[] not null default array['free', 'plus', 'premium', 'concierge'],
  policy jsonb not null default '{}'::jsonb,
  notes text,
  created_at timestamptz not null default now(),
  activated_at timestamptz,
  unique (policy_key, version)
);

create table if not exists public.credit_wallets (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.accounts(id) on delete cascade,
  person_id uuid references public.persons(id) on delete set null,
  wallet_type text not null check (wallet_type in ('included_monthly', 'purchased')),
  period text,
  balance numeric not null default 0 check (balance >= 0),
  currency_code text not null default 'MUNEA_CREDIT',
  status text not null default 'active' check (status in ('active', 'suspended', 'closed')),
  expires_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (account_id, person_id, wallet_type, period)
);

create table if not exists public.credit_transactions (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.accounts(id) on delete cascade,
  person_id uuid references public.persons(id) on delete set null,
  wallet_id uuid references public.credit_wallets(id) on delete set null,
  transaction_type text not null check (transaction_type in ('grant', 'consume', 'expire', 'refund', 'reversal', 'adjustment')),
  source text not null check (source in (
    'included_monthly',
    'apple_iap',
    'revenuecat',
    'promo',
    'admin_adjustment',
    'refund_reversal',
    'b2b_contract',
    'system'
  )),
  amount numeric not null,
  balance_after numeric check (balance_after is null or balance_after >= 0),
  provider text,
  provider_transaction_id text,
  idempotency_key text not null,
  reason text not null,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (idempotency_key)
);

create table if not exists public.credit_ledger (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.accounts(id) on delete cascade,
  person_id uuid references public.persons(id) on delete set null,
  wallet_id uuid references public.credit_wallets(id) on delete set null,
  credit_transaction_id uuid references public.credit_transactions(id) on delete set null,
  event_type text not null check (event_type in (
    'wallet_created',
    'included_allowance_granted',
    'credits_purchased',
    'credits_consumed',
    'credits_expired',
    'credits_refunded',
    'credits_reversed',
    'admin_adjusted'
  )),
  amount numeric not null default 0,
  balance_after numeric check (balance_after is null or balance_after >= 0),
  feature text,
  source_ref text,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

drop trigger if exists credit_wallets_set_updated_at on public.credit_wallets;
create trigger credit_wallets_set_updated_at
  before update on public.credit_wallets
  for each row execute function public.set_updated_at();

alter table public.entitlement_policy_versions enable row level security;
alter table public.credit_wallets enable row level security;
alter table public.credit_transactions enable row level security;
alter table public.credit_ledger enable row level security;

revoke all on public.entitlement_policy_versions from anon;
revoke all on public.credit_wallets from anon;
revoke all on public.credit_transactions from anon;
revoke all on public.credit_ledger from anon;

grant select on public.entitlement_policy_versions to authenticated;
grant select on public.credit_wallets to authenticated;
grant select on public.credit_transactions to authenticated;
grant select on public.credit_ledger to authenticated;

create policy "entitlement_policy_versions_authenticated_select"
on public.entitlement_policy_versions
for select
to authenticated
using (active = true);

create policy "credit_wallets_account_members_select"
on public.credit_wallets
for select
to authenticated
using (
  exists (
    select 1
    from public.account_members am
    where am.account_id = credit_wallets.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
);

create policy "credit_transactions_account_members_select"
on public.credit_transactions
for select
to authenticated
using (
  exists (
    select 1
    from public.account_members am
    where am.account_id = credit_transactions.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
);

create policy "credit_ledger_account_members_select"
on public.credit_ledger
for select
to authenticated
using (
  exists (
    select 1
    from public.account_members am
    where am.account_id = credit_ledger.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
);

create index if not exists credit_wallets_account_idx
  on public.credit_wallets(account_id, person_id, wallet_type, period);

create index if not exists credit_transactions_account_time_idx
  on public.credit_transactions(account_id, created_at desc);

create index if not exists credit_transactions_provider_idx
  on public.credit_transactions(provider, provider_transaction_id)
  where provider_transaction_id is not null;

create index if not exists credit_ledger_account_time_idx
  on public.credit_ledger(account_id, created_at desc);

insert into public.entitlement_policy_versions (
  policy_key,
  version,
  active,
  plan_order,
  policy,
  notes,
  activated_at
) values (
  'munea_app_store_v1',
  1,
  true,
  array['free', 'plus', 'premium', 'concierge'],
  '{
    "free": {
      "voiceCompanion": "limited",
      "familyMembersMax": 2,
      "premiumAvatarMinutesMonthly": 0
    },
    "plus": {
      "voiceCompanion": true,
      "familyMembersMax": 4,
      "premiumAvatarMinutesMonthly": "small_trial"
    },
    "premium": {
      "voiceCompanion": true,
      "familyMembersMax": 8,
      "premiumAvatarMinutesMonthly": "monthly_grant"
    },
    "concierge": {
      "voiceCompanion": true,
      "familyMembersMax": "custom",
      "premiumAvatarMinutesMonthly": "large_or_custom_grant"
    }
  }'::jsonb,
  'Initial Free / Plus / Premium / Concierge entitlement policy. Exact quotas and prices remain product decisions.',
  now()
)
on conflict (policy_key, version) do update
set
  active = excluded.active,
  plan_order = excluded.plan_order,
  policy = excluded.policy,
  notes = excluded.notes,
  activated_at = coalesce(entitlement_policy_versions.activated_at, excluded.activated_at);

commit;
