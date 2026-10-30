-- FieldSales CRM: Lead activity timeline
-- Run this script in Supabase SQL Editor for project daultgsqrvkdoczswhwc.

create table if not exists public.lead_activities (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  lead_id uuid not null references public.leads(id) on delete cascade,
  activity_type text not null check (
    activity_type in ('created', 'status_changed', 'note', 'call', 'meeting', 'email', 'proposal', 'won', 'lost', 'other')
  ),
  description text not null,
  created_at timestamptz not null default now()
);

create index if not exists lead_activities_lead_created_idx
  on public.lead_activities (lead_id, created_at desc);

create index if not exists lead_activities_owner_idx
  on public.lead_activities (owner_id);

alter table public.lead_activities enable row level security;

drop policy if exists "Users can view their own lead activities" on public.lead_activities;
create policy "Users can view their own lead activities"
  on public.lead_activities for select
  to authenticated
  using (owner_id = auth.uid());

drop policy if exists "Users can add their own lead activities" on public.lead_activities;
create policy "Users can add their own lead activities"
  on public.lead_activities for insert
  to authenticated
  with check (
    owner_id = auth.uid()
    and exists (
      select 1
      from public.leads
      where leads.id = lead_activities.lead_id
        and leads.owner_id = auth.uid()
    )
  );

grant select, insert on public.lead_activities to authenticated;
revoke all on public.lead_activities from anon;
