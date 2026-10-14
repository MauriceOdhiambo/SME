-- BiasharaOS account/workspace onboarding. Run after 001_initial.sql in Supabase SQL Editor.
-- Creates one workspace for every newly registered user and safely repairs existing users on login.

create or replace function public.ensure_my_workspace()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  current_user_id uuid := auth.uid();
  workspace_id uuid;
  workspace_name text;
  workspace_slug text;
begin
  if current_user_id is null then
    raise exception 'You must be signed in to create a workspace.';
  end if;

  select m.organization_id into workspace_id
  from public.memberships m
  where m.user_id = current_user_id and m.status = 'active'
  order by m.created_at asc limit 1;
  if workspace_id is not null then return workspace_id; end if;

  select nullif(trim(u.raw_user_meta_data->>'business_name'), '')
    into workspace_name from auth.users u where u.id = current_user_id;
  if workspace_name is null then workspace_name := 'My Business'; end if;
  workspace_slug := trim(both '-' from regexp_replace(lower(workspace_name), '[^a-z0-9]+', '-', 'g'));
  if workspace_slug = '' then workspace_slug := 'business'; end if;
  workspace_slug := left(workspace_slug, 35) || '-' || substr(replace(current_user_id::text, '-', ''), 1, 8);

  insert into public.organizations(name, slug)
  values (workspace_name, workspace_slug) returning id into workspace_id;
  insert into public.memberships(organization_id, user_id, role, status)
  values (workspace_id, current_user_id, 'owner', 'active')
  on conflict (organization_id, user_id) do nothing;
  return workspace_id;
end;
$$;

revoke all on function public.ensure_my_workspace() from public;
grant execute on function public.ensure_my_workspace() to authenticated;

-- Trigger runs in the database as a trusted function, so workspace creation does not
-- depend on the browser receiving a session (email-confirmation-enabled projects included).
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  org_name text;
  org_slug text;
  org_id uuid;
begin
  insert into public.profiles(id, full_name)
  values (new.id, new.raw_user_meta_data->>'full_name')
  on conflict (id) do nothing;

  org_name := nullif(trim(new.raw_user_meta_data->>'business_name'), '');
  if org_name is null then org_name := 'My Business'; end if;
  org_slug := trim(both '-' from regexp_replace(lower(org_name), '[^a-z0-9]+', '-', 'g'));
  if org_slug = '' then org_slug := 'business'; end if;
  org_slug := left(org_slug, 35) || '-' || substr(replace(new.id::text, '-', ''), 1, 8);

  insert into public.organizations(name, slug) values (org_name, org_slug)
  returning id into org_id;
  insert into public.memberships(organization_id, user_id, role, status)
  values (org_id, new.id, 'owner', 'active')
  on conflict (organization_id, user_id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
for each row execute procedure public.handle_new_user();
