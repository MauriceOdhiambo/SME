-- BiasharaOS subscription entitlements and platform Watchtower.
-- Run after 001_initial.sql and 002_workspace_onboarding.sql.
create table if not exists public.subscription_plans (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,
  name text not null,
  description text not null default '',
  price_monthly_kes integer not null default 0 check (price_monthly_kes >= 0),
  max_users integer not null default 1 check (max_users > 0),
  max_branches integer not null default 1 check (max_branches > 0),
  features jsonb not null default '{}'::jsonb,
  is_public boolean not null default true,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

insert into public.subscription_plans(slug,name,description,price_monthly_kes,max_users,max_branches,features)
values
 ('starter','Starter','Core tools for a single-operator business',1000,1,1,'{"pos":true,"inventory":true,"invoices":false,"customers":true,"staff":false,"advanced_reports":false,"multi_branch":false,"integrations":false}'::jsonb),
 ('business','Business','Connected operations for a growing team',2500,5,1,'{"pos":true,"inventory":true,"invoices":true,"customers":true,"staff":true,"advanced_reports":false,"multi_branch":false,"integrations":false}'::jsonb),
 ('pro','Pro','Advanced visibility and multi-branch operations',5000,15,5,'{"pos":true,"inventory":true,"invoices":true,"customers":true,"staff":true,"advanced_reports":true,"multi_branch":true,"integrations":true}'::jsonb)
on conflict(slug) do update set name=excluded.name,description=excluded.description,price_monthly_kes=excluded.price_monthly_kes,max_users=excluded.max_users,max_branches=excluded.max_branches,features=excluded.features,updated_at=now();

create table if not exists public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null unique references public.organizations(id) on delete cascade,
  plan_id uuid not null references public.subscription_plans(id),
  status text not null default 'trialing' check (status in ('trialing','active','past_due','paused','cancelled','expired')),
  billing_interval text not null default 'monthly' check (billing_interval in ('monthly','yearly')),
  started_at timestamptz not null default now(),
  trial_ends_at timestamptz not null default (now() + interval '14 days'),
  current_period_start timestamptz not null default now(),
  current_period_end timestamptz not null default (now() + interval '14 days'),
  cancelled_at timestamptz,
  provider text,
  provider_reference text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists subscriptions_status_period_idx on public.subscriptions(status,current_period_end);

create table if not exists public.platform_operators (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null default 'operator' check (role in ('owner','operator','support','billing_readonly')),
  created_at timestamptz not null default now()
);

alter table public.subscription_plans enable row level security;
alter table public.subscriptions enable row level security;
alter table public.platform_operators enable row level security;

create or replace function public.is_platform_operator()
returns boolean language sql stable security definer set search_path=public as $$
  select exists(select 1 from public.platform_operators p where p.user_id=auth.uid())
$$;
revoke all on function public.is_platform_operator() from public;
grant execute on function public.is_platform_operator() to authenticated;

drop policy if exists "public can view active plans" on public.subscription_plans;
create policy "public can view active plans" on public.subscription_plans for select to anon, authenticated using (is_active=true and is_public=true);
drop policy if exists "operators manage plans" on public.subscription_plans;
create policy "operators manage plans" on public.subscription_plans for all to authenticated using (public.is_platform_operator()) with check (public.is_platform_operator());
drop policy if exists "members read own subscription" on public.subscriptions;
create policy "members read own subscription" on public.subscriptions for select to authenticated using (exists(select 1 from public.memberships m where m.organization_id=subscriptions.organization_id and m.user_id=auth.uid() and m.status='active'));
drop policy if exists "operators read subscriptions" on public.subscriptions;
create policy "operators read subscriptions" on public.subscriptions for select to authenticated using (public.is_platform_operator());
drop policy if exists "operators update subscriptions" on public.subscriptions;
create policy "operators update subscriptions" on public.subscriptions for update to authenticated using (public.is_platform_operator()) with check (public.is_platform_operator());
drop policy if exists "operators read all organizations" on public.organizations;
create policy "operators read all organizations" on public.organizations for select to authenticated using (public.is_platform_operator());
drop policy if exists "operators read all memberships" on public.memberships;
create policy "operators read all memberships" on public.memberships for select to authenticated using (public.is_platform_operator());
drop policy if exists "operators read platform operators" on public.platform_operators;
create policy "operators read platform operators" on public.platform_operators for select to authenticated using (user_id=auth.uid() or public.is_platform_operator());

create or replace function public.get_my_entitlements()
returns jsonb language plpgsql stable security definer set search_path=public as $$
declare result jsonb;
begin
  select jsonb_build_object(
    'plan_slug',p.slug,'plan_name',p.name,'status',s.status,
    'max_users',p.max_users,'max_branches',p.max_branches,'features',p.features,
    'period_end',s.current_period_end,
    'access_limited',(s.status='trialing' and s.trial_ends_at < now()) or (s.status in ('past_due','paused','cancelled','expired') and (s.current_period_end < now() or s.status in ('paused','cancelled','expired')))
  ) into result
  from public.subscriptions s join public.subscription_plans p on p.id=s.plan_id
  join public.memberships m on m.organization_id=s.organization_id
  where m.user_id=auth.uid() and m.status='active'
  order by m.created_at limit 1;
  return coalesce(result,'{"plan_slug":"starter","plan_name":"Starter","status":"setup_required","max_users":1,"max_branches":1,"features":{"pos":true,"inventory":true,"invoices":false,"customers":true,"staff":false,"advanced_reports":false,"multi_branch":false,"integrations":false},"access_limited":false}'::jsonb);
end;
$$;
revoke all on function public.get_my_entitlements() from public;
grant execute on function public.get_my_entitlements() to authenticated;

-- Signup metadata selects a plan; all new accounts receive a 14-day trial and entitlements.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public as $$
declare org_name text; org_slug text; org_id uuid; selected_plan text; selected_plan_id uuid;
begin
  insert into public.profiles(id,full_name) values(new.id,new.raw_user_meta_data->>'full_name') on conflict(id) do nothing;
  org_name := nullif(trim(new.raw_user_meta_data->>'business_name'),'');
  if org_name is null then org_name := 'My Business'; end if;
  org_slug := trim(both '-' from regexp_replace(lower(org_name),'[^a-z0-9]+','-','g'));
  if org_slug='' then org_slug:='business'; end if;
  org_slug := left(org_slug,35)||'-'||substr(replace(new.id::text,'-',''),1,8);
  insert into public.organizations(name,slug) values(org_name,org_slug) returning id into org_id;
  insert into public.memberships(organization_id,user_id,role,status) values(org_id,new.id,'owner','active') on conflict(organization_id,user_id) do nothing;
  selected_plan := coalesce(new.raw_user_meta_data->>'subscription_plan','starter');
  select id into selected_plan_id from public.subscription_plans where slug=selected_plan and is_active=true and is_public=true;
  if selected_plan_id is null then select id into selected_plan_id from public.subscription_plans where slug='starter'; end if;
  insert into public.subscriptions(organization_id,plan_id,status,trial_ends_at,current_period_end)
  values(org_id,selected_plan_id,'trialing',now()+interval '14 days',now()+interval '14 days')
  on conflict(organization_id) do nothing;
  return new;
end;
$$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

-- Backfill existing workspaces onto Starter if they do not yet have a subscription.
insert into public.subscriptions(organization_id,plan_id,status,trial_ends_at,current_period_end)
select o.id,p.id,'trialing',now()+interval '14 days',now()+interval '14 days'
from public.organizations o cross join public.subscription_plans p
where p.slug='starter' and not exists(select 1 from public.subscriptions s where s.organization_id=o.id);
