-- FieldSales CRM: Client projects and delivery milestones
-- Run in Supabase SQL Editor for project daultgsqrvkdoczswhwc.
-- A project remains if its linked lead is deleted; its lead_id becomes NULL.

create table if not exists public.projects (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  lead_id uuid references public.leads(id) on delete set null,
  name text not null,
  client_name text not null,
  description text not null default '',
  status text not null default 'Not started'
    check (status in ('Not started', 'In progress', 'On hold', 'Completed', 'Cancelled')),
  start_date date,
  due_date date,
  budget numeric(12,2) not null default 0 check (budget >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.project_milestones (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  project_id uuid not null references public.projects(id) on delete cascade,
  title text not null,
  due_date date,
  is_done boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists projects_owner_created_idx
  on public.projects(owner_id, created_at desc);
create index if not exists project_milestones_project_due_idx
  on public.project_milestones(project_id, due_date);

alter table public.projects enable row level security;
alter table public.project_milestones enable row level security;

drop policy if exists "Users can view their own projects" on public.projects;
create policy "Users can view their own projects" on public.projects
  for select to authenticated using (owner_id = auth.uid());
drop policy if exists "Users can create their own projects" on public.projects;
create policy "Users can create their own projects" on public.projects
  for insert to authenticated with check (
    owner_id = auth.uid() and (
      lead_id is null or exists (
        select 1 from public.leads l where l.id = projects.lead_id and l.owner_id = auth.uid()
      )
    )
  );
drop policy if exists "Users can update their own projects" on public.projects;
create policy "Users can update their own projects" on public.projects
  for update to authenticated using (owner_id = auth.uid())
  with check (owner_id = auth.uid() and (
    lead_id is null or exists (
      select 1 from public.leads l where l.id = projects.lead_id and l.owner_id = auth.uid()
    )
  ));
drop policy if exists "Users can delete their own projects" on public.projects;
create policy "Users can delete their own projects" on public.projects
  for delete to authenticated using (owner_id = auth.uid());

drop policy if exists "Users can view their own project milestones" on public.project_milestones;
create policy "Users can view their own project milestones" on public.project_milestones
  for select to authenticated using (owner_id = auth.uid());
drop policy if exists "Users can add their own project milestones" on public.project_milestones;
create policy "Users can add their own project milestones" on public.project_milestones
  for insert to authenticated with check (
    owner_id = auth.uid() and exists (
      select 1 from public.projects p where p.id = project_milestones.project_id and p.owner_id = auth.uid()
    )
  );
drop policy if exists "Users can update their own project milestones" on public.project_milestones;
create policy "Users can update their own project milestones" on public.project_milestones
  for update to authenticated using (owner_id = auth.uid())
  with check (owner_id = auth.uid() and exists (
    select 1 from public.projects p where p.id = project_milestones.project_id and p.owner_id = auth.uid()
  ));
drop policy if exists "Users can delete their own project milestones" on public.project_milestones;
create policy "Users can delete their own project milestones" on public.project_milestones
  for delete to authenticated using (owner_id = auth.uid());

grant select, insert, update, delete on public.projects to authenticated;
grant select, insert, update, delete on public.project_milestones to authenticated;
revoke all on public.projects from anon;
revoke all on public.project_milestones from anon;
