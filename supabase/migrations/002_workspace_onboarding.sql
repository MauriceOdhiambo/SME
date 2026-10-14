-- Create a first organization for the authenticated user safely and idempotently.
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
  order by m.created_at asc
  limit 1;

  if workspace_id is not null then
    return workspace_id;
  end if;

  workspace_name := nullif(trim(coalesce(
    (select raw_user_meta_data->>'business_name' from auth.users where id = current_user_id),
    ''
  )), '');
  if workspace_name is null then
    workspace_name := 'My Business';
  end if;

  workspace_slug := trim(both '-' from regexp_replace(lower(workspace_name), '[^a-z0-9]+', '-', 'g'));
  if workspace_slug = '' then workspace_slug := 'business'; end if;
  workspace_slug := left(workspace_slug, 35) || '-' || substr(replace(current_user_id::text, '-', ''), 1, 8);

  insert into public.organizations(name, slug)
  values (workspace_name, workspace_slug)
  returning id into workspace_id;

  insert into public.memberships(organization_id, user_id, role, status)
  values (workspace_id, current_user_id, 'owner', 'active')
  on conflict (organization_id, user_id) do nothing;

  return workspace_id;
end;
$$;
revoke all on function public.ensure_my_workspace() from public;
grant execute on function public.ensure_my_workspace() to authenticated;
