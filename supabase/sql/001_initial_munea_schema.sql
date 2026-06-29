-- Munea initial Supabase schema draft.
-- Intended first use: paste into Supabase SQL Editor for the new project.
-- After Supabase CLI is available, convert this into a timestamped migration.

begin;

create extension if not exists pgcrypto;

create table if not exists public.accounts (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'Munea account',
  locale text not null default 'zh-TW',
  preferred_languages text[] not null default array['zh-TW', 'en'],
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.account_members (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.accounts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner', 'admin', 'member', 'viewer')),
  status text not null default 'active' check (status in ('active', 'invited', 'removed')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (account_id, user_id)
);

create table if not exists public.persons (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.accounts(id) on delete cascade,
  display_name text not null,
  relationship text not null default 'self',
  locale text not null default 'zh-TW',
  timezone text not null default 'Asia/Taipei',
  is_primary_care_recipient boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.family_groups (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.accounts(id) on delete cascade,
  name text not null default 'Munea care circle',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.family_memberships (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.accounts(id) on delete cascade,
  family_group_id uuid not null references public.family_groups(id) on delete cascade,
  person_id uuid not null references public.persons(id) on delete cascade,
  role text not null check (role in ('primary_user', 'family_contact', 'caregiver', 'viewer')),
  permissions jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (family_group_id, person_id)
);

create table if not exists public.companion_profiles (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.accounts(id) on delete cascade,
  person_id uuid not null references public.persons(id) on delete cascade,
  template_id text not null default 'nening-real-female',
  display_name text not null default 'Nening',
  name_touched boolean not null default false,
  backend_char text,
  avatar_asset text,
  voice_profile text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  unique (person_id)
);

create table if not exists public.routine_reminders (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.accounts(id) on delete cascade,
  person_id uuid not null references public.persons(id) on delete cascade,
  title text not null,
  reminder_type text not null check (reminder_type in ('medication', 'routine', 'check_in', 'custom')),
  schedule jsonb not null default '{}'::jsonb,
  status text not null default 'active' check (status in ('active', 'paused', 'archived')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.voice_sessions (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.accounts(id) on delete cascade,
  person_id uuid references public.persons(id) on delete set null,
  companion_profile_id uuid references public.companion_profiles(id) on delete set null,
  provider text not null,
  locale text not null default 'zh-TW',
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  duration_ms integer not null default 0 check (duration_ms >= 0),
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists public.conversation_summaries (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.accounts(id) on delete cascade,
  person_id uuid references public.persons(id) on delete set null,
  voice_session_id uuid references public.voice_sessions(id) on delete set null,
  summary text not null,
  memory_tags text[] not null default '{}',
  safety_relevant boolean not null default false,
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table if not exists public.safety_events (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.accounts(id) on delete cascade,
  person_id uuid references public.persons(id) on delete set null,
  event_type text not null,
  severity text not null check (severity in ('info', 'low', 'medium', 'high', 'critical')),
  status text not null default 'open' check (status in ('open', 'notified', 'resolved', 'dismissed')),
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table if not exists public.subscription_ledger (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.accounts(id) on delete cascade,
  platform text not null default 'ios',
  provider text not null,
  product_id text,
  original_transaction_id text,
  status text not null check (status in ('inactive', 'trial', 'active', 'grace_period', 'expired', 'revoked')),
  active_plan text not null default 'free',
  entitlements jsonb not null default '{}'::jsonb,
  verified_at timestamptz,
  expires_at timestamptz,
  will_renew boolean,
  raw_event_ref text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.usage_ledger (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.accounts(id) on delete cascade,
  period text not null,
  metric text not null check (metric in ('voice_minutes', 'avatar_minutes', 'family_members', 'storage_mb')),
  used numeric not null default 0 check (used >= 0),
  granted numeric not null default 0 check (granted >= 0),
  source text not null default 'system',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (account_id, period, metric)
);

create table if not exists public.privacy_requests (
  id uuid primary key default gen_random_uuid(),
  account_id uuid not null references public.accounts(id) on delete cascade,
  request_type text not null check (request_type in ('export', 'account_deletion')),
  status text not null default 'requested' check (status in ('requested', 'processing', 'completed', 'cancelled', 'failed')),
  reason text,
  requires_reauth boolean not null default true,
  subscription_notice_required boolean not null default false,
  requested_at timestamptz not null default now(),
  completed_at timestamptz,
  metadata jsonb not null default '{}'::jsonb
);

create table if not exists public.audit_events (
  id uuid primary key default gen_random_uuid(),
  account_id uuid references public.accounts(id) on delete set null,
  actor_user_id uuid references auth.users(id) on delete set null,
  event_type text not null,
  target_table text,
  target_id uuid,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists accounts_set_updated_at on public.accounts;
create trigger accounts_set_updated_at
  before update on public.accounts
  for each row execute function public.set_updated_at();

drop trigger if exists account_members_set_updated_at on public.account_members;
create trigger account_members_set_updated_at
  before update on public.account_members
  for each row execute function public.set_updated_at();

drop trigger if exists persons_set_updated_at on public.persons;
create trigger persons_set_updated_at
  before update on public.persons
  for each row execute function public.set_updated_at();

drop trigger if exists family_groups_set_updated_at on public.family_groups;
create trigger family_groups_set_updated_at
  before update on public.family_groups
  for each row execute function public.set_updated_at();

drop trigger if exists family_memberships_set_updated_at on public.family_memberships;
create trigger family_memberships_set_updated_at
  before update on public.family_memberships
  for each row execute function public.set_updated_at();

drop trigger if exists companion_profiles_set_updated_at on public.companion_profiles;
create trigger companion_profiles_set_updated_at
  before update on public.companion_profiles
  for each row execute function public.set_updated_at();

drop trigger if exists routine_reminders_set_updated_at on public.routine_reminders;
create trigger routine_reminders_set_updated_at
  before update on public.routine_reminders
  for each row execute function public.set_updated_at();

drop trigger if exists subscription_ledger_set_updated_at on public.subscription_ledger;
create trigger subscription_ledger_set_updated_at
  before update on public.subscription_ledger
  for each row execute function public.set_updated_at();

drop trigger if exists usage_ledger_set_updated_at on public.usage_ledger;
create trigger usage_ledger_set_updated_at
  before update on public.usage_ledger
  for each row execute function public.set_updated_at();

alter table public.accounts enable row level security;
alter table public.account_members enable row level security;
alter table public.persons enable row level security;
alter table public.family_groups enable row level security;
alter table public.family_memberships enable row level security;
alter table public.companion_profiles enable row level security;
alter table public.routine_reminders enable row level security;
alter table public.voice_sessions enable row level security;
alter table public.conversation_summaries enable row level security;
alter table public.safety_events enable row level security;
alter table public.subscription_ledger enable row level security;
alter table public.usage_ledger enable row level security;
alter table public.privacy_requests enable row level security;
alter table public.audit_events enable row level security;

revoke all on all tables in schema public from anon;
grant usage on schema public to authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant usage, select on all sequences in schema public to authenticated;

drop policy if exists account_members_select_own_account on public.account_members;
create policy account_members_select_own_account
on public.account_members for select
to authenticated
using (user_id = (select auth.uid()) and status = 'active');

drop policy if exists account_members_insert_self_owner on public.account_members;
create policy account_members_insert_self_owner
on public.account_members for insert
to authenticated
with check (user_id = (select auth.uid()));

drop policy if exists accounts_select_member on public.accounts;
create policy accounts_select_member
on public.accounts for select
to authenticated
using (
  exists (
    select 1 from public.account_members am
    where am.account_id = accounts.id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
);

drop policy if exists accounts_update_owner on public.accounts;
create policy accounts_update_owner
on public.accounts for update
to authenticated
using (
  exists (
    select 1 from public.account_members am
    where am.account_id = accounts.id
      and am.user_id = (select auth.uid())
      and am.role in ('owner', 'admin')
      and am.status = 'active'
  )
)
with check (
  exists (
    select 1 from public.account_members am
    where am.account_id = accounts.id
      and am.user_id = (select auth.uid())
      and am.role in ('owner', 'admin')
      and am.status = 'active'
  )
);

drop policy if exists persons_account_member_all on public.persons;
create policy persons_account_member_all
on public.persons for all
to authenticated
using (
  exists (
    select 1 from public.account_members am
    where am.account_id = persons.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
)
with check (
  exists (
    select 1 from public.account_members am
    where am.account_id = persons.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
);

drop policy if exists family_groups_account_member_all on public.family_groups;
create policy family_groups_account_member_all
on public.family_groups for all
to authenticated
using (
  exists (
    select 1 from public.account_members am
    where am.account_id = family_groups.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
)
with check (
  exists (
    select 1 from public.account_members am
    where am.account_id = family_groups.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
);

drop policy if exists family_memberships_account_member_all on public.family_memberships;
create policy family_memberships_account_member_all
on public.family_memberships for all
to authenticated
using (
  exists (
    select 1 from public.account_members am
    where am.account_id = family_memberships.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
)
with check (
  exists (
    select 1 from public.account_members am
    where am.account_id = family_memberships.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
);

drop policy if exists companion_profiles_account_member_all on public.companion_profiles;
create policy companion_profiles_account_member_all
on public.companion_profiles for all
to authenticated
using (
  exists (
    select 1 from public.account_members am
    where am.account_id = companion_profiles.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
)
with check (
  exists (
    select 1 from public.account_members am
    where am.account_id = companion_profiles.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
);

drop policy if exists routine_reminders_account_member_all on public.routine_reminders;
create policy routine_reminders_account_member_all
on public.routine_reminders for all
to authenticated
using (
  exists (
    select 1 from public.account_members am
    where am.account_id = routine_reminders.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
)
with check (
  exists (
    select 1 from public.account_members am
    where am.account_id = routine_reminders.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
);

drop policy if exists voice_sessions_account_member_all on public.voice_sessions;
create policy voice_sessions_account_member_all
on public.voice_sessions for all
to authenticated
using (
  exists (
    select 1 from public.account_members am
    where am.account_id = voice_sessions.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
)
with check (
  exists (
    select 1 from public.account_members am
    where am.account_id = voice_sessions.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
);

drop policy if exists conversation_summaries_account_member_all on public.conversation_summaries;
create policy conversation_summaries_account_member_all
on public.conversation_summaries for all
to authenticated
using (
  exists (
    select 1 from public.account_members am
    where am.account_id = conversation_summaries.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
)
with check (
  exists (
    select 1 from public.account_members am
    where am.account_id = conversation_summaries.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
);

drop policy if exists safety_events_account_member_all on public.safety_events;
create policy safety_events_account_member_all
on public.safety_events for all
to authenticated
using (
  exists (
    select 1 from public.account_members am
    where am.account_id = safety_events.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
)
with check (
  exists (
    select 1 from public.account_members am
    where am.account_id = safety_events.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
);

drop policy if exists subscription_ledger_account_member_select on public.subscription_ledger;
create policy subscription_ledger_account_member_select
on public.subscription_ledger for select
to authenticated
using (
  exists (
    select 1 from public.account_members am
    where am.account_id = subscription_ledger.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
);

drop policy if exists usage_ledger_account_member_select on public.usage_ledger;
create policy usage_ledger_account_member_select
on public.usage_ledger for select
to authenticated
using (
  exists (
    select 1 from public.account_members am
    where am.account_id = usage_ledger.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
);

drop policy if exists privacy_requests_account_member_all on public.privacy_requests;
create policy privacy_requests_account_member_all
on public.privacy_requests for all
to authenticated
using (
  exists (
    select 1 from public.account_members am
    where am.account_id = privacy_requests.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
)
with check (
  exists (
    select 1 from public.account_members am
    where am.account_id = privacy_requests.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
);

drop policy if exists audit_events_account_member_select on public.audit_events;
create policy audit_events_account_member_select
on public.audit_events for select
to authenticated
using (
  exists (
    select 1 from public.account_members am
    where am.account_id = audit_events.account_id
      and am.user_id = (select auth.uid())
      and am.status = 'active'
  )
);

create index if not exists account_members_user_id_idx on public.account_members(user_id);
create index if not exists account_members_account_id_idx on public.account_members(account_id);
create index if not exists persons_account_id_idx on public.persons(account_id);
create index if not exists family_groups_account_id_idx on public.family_groups(account_id);
create index if not exists family_memberships_account_id_idx on public.family_memberships(account_id);
create index if not exists companion_profiles_account_id_idx on public.companion_profiles(account_id);
create index if not exists routine_reminders_account_id_idx on public.routine_reminders(account_id);
create index if not exists voice_sessions_account_id_idx on public.voice_sessions(account_id);
create index if not exists conversation_summaries_account_id_idx on public.conversation_summaries(account_id);
create index if not exists safety_events_account_id_idx on public.safety_events(account_id);
create index if not exists subscription_ledger_account_id_idx on public.subscription_ledger(account_id);
create index if not exists usage_ledger_account_id_idx on public.usage_ledger(account_id);
create index if not exists privacy_requests_account_id_idx on public.privacy_requests(account_id);
create index if not exists audit_events_account_id_idx on public.audit_events(account_id);

commit;
