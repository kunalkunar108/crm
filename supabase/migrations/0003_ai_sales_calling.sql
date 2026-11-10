-- AI sales calling foundation. Outbound execution is intentionally disabled by default.
create table if not exists public.ai_call_rules (
  owner_id uuid primary key references auth.users(id) on delete cascade,
  assistant_enabled boolean not null default true,
  voice_agent_enabled boolean not null default false,
  outbound_enabled boolean not null default false,
  require_recorded_consent boolean not null default true,
  allowed_start_hour integer not null default 10 check (allowed_start_hour between 0 and 23),
  allowed_end_hour integer not null default 18 check (allowed_end_hour between 1 and 24),
  max_calls_per_day integer not null default 20 check (max_calls_per_day between 1 and 100),
  cooldown_hours integer not null default 24 check (cooldown_hours between 1 and 720),
  updated_at timestamptz not null default now(),
  constraint valid_call_window check (allowed_end_hour > allowed_start_hour)
);

create table if not exists public.ai_call_queue (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  lead_id uuid references public.leads(id) on delete set null,
  contact_name text not null,
  phone text not null,
  purpose text not null,
  call_mode text not null check (call_mode in ('human_assisted','ai_voice')),
  script text not null,
  status text not null default 'queued' check (status in ('queued','blocked','cancelled','completed')),
  eligibility_snapshot jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists ai_call_queue_owner_created_idx
  on public.ai_call_queue(owner_id, created_at desc);
create index if not exists ai_call_queue_owner_status_idx
  on public.ai_call_queue(owner_id, status);

alter table public.ai_call_rules enable row level security;
alter table public.ai_call_queue enable row level security;

drop policy if exists "Users manage own AI call rules" on public.ai_call_rules;
create policy "Users manage own AI call rules"
  on public.ai_call_rules for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

drop policy if exists "Users manage own AI call queue" on public.ai_call_queue;
create policy "Users manage own AI call queue"
  on public.ai_call_queue for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

comment on table public.ai_call_rules is 'Per-user guardrails for AI-assisted and AI voice sales calling.';
comment on table public.ai_call_queue is 'Call preparation queue only; no telephony provider is invoked by this table.';
