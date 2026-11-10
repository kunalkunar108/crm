-- Initial personal CRM schema. All records are isolated by authenticated owner.
create table if not exists public.leads (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  business text not null,
  phone text,
  source text not null default 'Other',
  status text not null default 'New'
    check (status in ('New','Contacted','Qualified','Proposal','Won','Lost')),
  value numeric(12,2) not null default 0 check (value >= 0),
  follow_up date,
  notes text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.follow_up_tasks (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  due_date date not null,
  is_done boolean not null default false,
  created_at timestamptz not null default now()
);

create table if not exists public.lead_activities (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  lead_id uuid not null references public.leads(id) on delete cascade,
  activity_type text not null default 'note',
  description text not null,
  created_at timestamptz not null default now()
);

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

create index if not exists leads_owner_created_idx on public.leads(owner_id, created_at desc);
create index if not exists follow_up_tasks_owner_due_idx on public.follow_up_tasks(owner_id, due_date);
create index if not exists lead_activities_lead_created_idx on public.lead_activities(lead_id, created_at desc);
create index if not exists projects_owner_created_idx on public.projects(owner_id, created_at desc);
create index if not exists project_milestones_project_due_idx on public.project_milestones(project_id, due_date);

alter table public.leads enable row level security;
alter table public.follow_up_tasks enable row level security;
alter table public.lead_activities enable row level security;
alter table public.projects enable row level security;
alter table public.project_milestones enable row level security;

create policy "leads_select_own" on public.leads for select to authenticated using ((select auth.uid()) = owner_id);
create policy "leads_insert_own" on public.leads for insert to authenticated with check ((select auth.uid()) = owner_id);
create policy "leads_update_own" on public.leads for update to authenticated using ((select auth.uid()) = owner_id) with check ((select auth.uid()) = owner_id);
create policy "leads_delete_own" on public.leads for delete to authenticated using ((select auth.uid()) = owner_id);

create policy "follow_up_tasks_select_own" on public.follow_up_tasks for select to authenticated using ((select auth.uid()) = owner_id);
create policy "follow_up_tasks_insert_own" on public.follow_up_tasks for insert to authenticated with check ((select auth.uid()) = owner_id);
create policy "follow_up_tasks_update_own" on public.follow_up_tasks for update to authenticated using ((select auth.uid()) = owner_id) with check ((select auth.uid()) = owner_id);
create policy "follow_up_tasks_delete_own" on public.follow_up_tasks for delete to authenticated using ((select auth.uid()) = owner_id);

create policy "lead_activities_select_own" on public.lead_activities for select to authenticated using ((select auth.uid()) = owner_id);
create policy "lead_activities_insert_own" on public.lead_activities for insert to authenticated with check (
  (select auth.uid()) = owner_id and exists (select 1 from public.leads l where l.id = lead_activities.lead_id and l.owner_id = (select auth.uid()))
);
create policy "lead_activities_update_own" on public.lead_activities for update to authenticated using ((select auth.uid()) = owner_id) with check (
  (select auth.uid()) = owner_id and exists (select 1 from public.leads l where l.id = lead_activities.lead_id and l.owner_id = (select auth.uid()))
);
create policy "lead_activities_delete_own" on public.lead_activities for delete to authenticated using ((select auth.uid()) = owner_id);

create policy "projects_select_own" on public.projects for select to authenticated using ((select auth.uid()) = owner_id);
create policy "projects_insert_own" on public.projects for insert to authenticated with check (
  (select auth.uid()) = owner_id and (lead_id is null or exists (select 1 from public.leads l where l.id = projects.lead_id and l.owner_id = (select auth.uid())))
);
create policy "projects_update_own" on public.projects for update to authenticated using ((select auth.uid()) = owner_id) with check (
  (select auth.uid()) = owner_id and (lead_id is null or exists (select 1 from public.leads l where l.id = projects.lead_id and l.owner_id = (select auth.uid())))
);
create policy "projects_delete_own" on public.projects for delete to authenticated using ((select auth.uid()) = owner_id);

create policy "project_milestones_select_own" on public.project_milestones for select to authenticated using ((select auth.uid()) = owner_id);
create policy "project_milestones_insert_own" on public.project_milestones for insert to authenticated with check (
  (select auth.uid()) = owner_id and exists (select 1 from public.projects p where p.id = project_milestones.project_id and p.owner_id = (select auth.uid()))
);
create policy "project_milestones_update_own" on public.project_milestones for update to authenticated using ((select auth.uid()) = owner_id) with check (
  (select auth.uid()) = owner_id and exists (select 1 from public.projects p where p.id = project_milestones.project_id and p.owner_id = (select auth.uid()))
);
create policy "project_milestones_delete_own" on public.project_milestones for delete to authenticated using ((select auth.uid()) = owner_id);

grant select, insert, update, delete on public.leads, public.follow_up_tasks, public.lead_activities, public.projects, public.project_milestones to authenticated;
revoke all on public.leads, public.follow_up_tasks, public.lead_activities, public.projects, public.project_milestones from anon;
