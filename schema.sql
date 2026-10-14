-- BiasharaOS production foundation
create extension if not exists pgcrypto;

create table if not exists public.organizations (
 id uuid primary key default gen_random_uuid(),
 name text not null,
 created_at timestamptz not null default now()
);

create table if not exists public.profiles (
 id uuid primary key references auth.users(id) on delete cascade,
 full_name text,
 created_at timestamptz not null default now()
);

create table if not exists public.memberships (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 organization_id uuid not null references public.organizations(id) on delete cascade,
 role text not null check (role in ('owner','admin','manager','staff','member')),
 created_at timestamptz not null default now(),
 unique(user_id, organization_id)
);

create table if not exists public.products (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id) on delete cascade,
 name text not null,
 sku text,
 category text,
 selling_price numeric(14,2) not null default 0,
 cost_price numeric(14,2) not null default 0,
 stock_quantity numeric(14,3) not null default 0,
 reorder_level numeric(14,3) not null default 5,
 created_at timestamptz not null default now()
);

create table if not exists public.customers (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id) on delete cascade,
 name text not null,
 phone text,
 email text,
 created_at timestamptz not null default now()
);

create table if not exists public.sales (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id) on delete cascade,
 user_id uuid references auth.users(id),
 total numeric(14,2) not null default 0,
 payment_method text not null default 'cash',
 created_at timestamptz not null default now()
);

create table if not exists public.sale_items (
 id uuid primary key default gen_random_uuid(),
 sale_id uuid not null references public.sales(id) on delete cascade,
 product_id uuid not null references public.products(id),
 quantity numeric(14,3) not null,
 unit_price numeric(14,2) not null
);

create table if not exists public.payments (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id) on delete cascade,
 sale_id uuid references public.sales(id) on delete set null,
 amount numeric(14,2) not null,
 method text not null,
 reference text,
 created_at timestamptz not null default now()
);

create table if not exists public.inventory_movements (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id) on delete cascade,
 product_id uuid not null references public.products(id) on delete cascade,
 quantity numeric(14,3) not null,
 movement_type text not null,
 reference_id uuid,
 created_at timestamptz not null default now()
);

create table if not exists public.invoices (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id) on delete cascade,
 invoice_number text not null,
 customer_id uuid references public.customers(id) on delete set null,
 total numeric(14,2) not null default 0,
 status text not null default 'unpaid',
 due_date date,
 created_at timestamptz not null default now(),
 unique(organization_id, invoice_number)
);

create table if not exists public.staff (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id) on delete cascade,
 name text not null,
 job_title text,
 phone text,
 commission_percent numeric(6,2) not null default 0,
 status text not null default 'active',
 created_at timestamptz not null default now()
);

create table if not exists public.audit_logs (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid references public.organizations(id) on delete cascade,
 user_id uuid references auth.users(id),
 action text not null,
 entity text,
 entity_id uuid,
 metadata jsonb not null default '{}'::jsonb,
 created_at timestamptz not null default now()
);

create or replace function public.is_member(org uuid)
returns boolean language sql security definer set search_path=public as $$
 select exists(select 1 from public.memberships m where m.organization_id=org and m.user_id=auth.uid());
$$;

create or replace function public.my_org()
returns uuid language sql security definer set search_path=public as $$
 select organization_id from public.memberships where user_id=auth.uid() order by created_at limit 1;
$$;

alter table public.organizations enable row level security;
alter table public.profiles enable row level security;
alter table public.memberships enable row level security;
alter table public.products enable row level security;
alter table public.customers enable row level security;
alter table public.sales enable row level security;
alter table public.sale_items enable row level security;
alter table public.payments enable row level security;
alter table public.inventory_movements enable row level security;
alter table public.invoices enable row level security;
alter table public.staff enable row level security;
alter table public.audit_logs enable row level security;

drop policy if exists org_select on public.organizations;
create policy org_select on public.organizations for select using (id=public.my_org());

drop policy if exists products_all on public.products;
create policy products_all on public.products for all using (organization_id=public.my_org()) with check (organization_id=public.my_org());

drop policy if exists customers_all on public.customers;
create policy customers_all on public.customers for all using (organization_id=public.my_org()) with check (organization_id=public.my_org());

drop policy if exists sales_all on public.sales;
create policy sales_all on public.sales for all using (organization_id=public.my_org()) with check (organization_id=public.my_org());

drop policy if exists payments_all on public.payments;
create policy payments_all on public.payments for all using (organization_id=public.my_org()) with check (organization_id=public.my_org());

drop policy if exists movements_all on public.inventory_movements;
create policy movements_all on public.inventory_movements for all using (organization_id=public.my_org()) with check (organization_id=public.my_org());

drop policy if exists invoices_all on public.invoices;
create policy invoices_all on public.invoices for all using (organization_id=public.my_org()) with check (organization_id=public.my_org());

drop policy if exists staff_all on public.staff;
create policy staff_all on public.staff for all using (organization_id=public.my_org()) with check (organization_id=public.my_org());

drop policy if exists audit_all on public.audit_logs;
create policy audit_all on public.audit_logs for select using (organization_id=public.my_org());

drop policy if exists sale_items_all on public.sale_items;
create policy sale_items_all on public.sale_items for all using (exists(select 1 from public.sales s where s.id=sale_id and s.organization_id=public.my_org())) with check (exists(select 1 from public.sales s where s.id=sale_id and s.organization_id=public.my_org()));

drop policy if exists profiles_self on public.profiles;
create policy profiles_self on public.profiles for all using (id=auth.uid()) with check (id=auth.uid());

drop policy if exists memberships_self on public.memberships;
create policy memberships_self on public.memberships for select using (user_id=auth.uid());

create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path=public as $$
declare org_id uuid;
begin
 insert into public.profiles(id,full_name) values(new.id,new.raw_user_meta_data->>'full_name') on conflict(id) do nothing;
 insert into public.organizations(name) values(coalesce(new.raw_user_meta_data->>'business_name','My Business')) returning id into org_id;
 insert into public.memberships(user_id,organization_id,role) values(new.id,org_id,'owner');
 return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace function public.record_sale(p_items jsonb, p_payment_method text default 'cash')
returns uuid language plpgsql security definer set search_path=public as $$
declare
 org uuid := public.my_org();
 sale uuid;
 item jsonb;
 product_row record;
 total numeric := 0;
 qty numeric;
begin
 if org is null then raise exception 'No business membership found'; end if;
 insert into public.sales(organization_id,user_id,total,payment_method) values(org,auth.uid(),0,p_payment_method) returning id into sale;
 for item in select * from jsonb_array_elements(p_items) loop
   qty := (item->>'quantity')::numeric;
   select * into product_row from public.products where id=(item->>'product_id')::uuid and organization_id=org for update;
   if not found then raise exception 'Product not found'; end if;
   if product_row.stock_quantity < qty then raise exception 'Insufficient stock for %', product_row.name; end if;
   total := total + qty * (item->>'unit_price')::numeric;
   insert into public.sale_items(sale_id,product_id,quantity,unit_price) values(sale,(item->>'product_id')::uuid,qty,(item->>'unit_price')::numeric);
   update public.products set stock_quantity=stock_quantity-qty where id=product_row.id;
   insert into public.inventory_movements(organization_id,product_id,quantity,movement_type,reference_id) values(org,product_row.id,-qty,'sale',sale);
 end loop;
 update public.sales set total=total where id=sale;
 insert into public.payments(organization_id,sale_id,amount,method) values(org,sale,total,p_payment_method);
 insert into public.audit_logs(organization_id,user_id,action,entity,entity_id,metadata) values(org,auth.uid(),'sale.created','sales',sale,jsonb_build_object('total',total));
 return sale;
end;
$$;

grant execute on function public.record_sale(jsonb,text) to authenticated;
