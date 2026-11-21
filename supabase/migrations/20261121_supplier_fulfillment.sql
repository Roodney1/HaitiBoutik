-- HaitiBoutik: fournisseurs et expédition directe au client
-- À appliquer après schema.sql dans Supabase SQL Editor.
create extension if not exists pgcrypto;

create type public.supplier_status as enum ('pending_review','approved','suspended');
create type public.supplier_fulfillment_status as enum ('new','accepted','preparing','ready_to_ship','shipped','delivered','rejected','issue');

create table public.suppliers (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  business_name text not null,
  contact_name text not null,
  phone text not null,
  email text,
  address text,
  service_areas text[] not null default '{}',
  status public.supplier_status not null default 'pending_review',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(owner_id)
);

create table public.supplier_catalog (
  id uuid primary key default gen_random_uuid(),
  supplier_id uuid not null references public.suppliers(id) on delete cascade,
  name text not null,
  description text,
  supplier_price_gds numeric(12,2) not null check (supplier_price_gds >= 0),
  stock integer not null default 0 check (stock >= 0),
  image_url text,
  is_available boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.products
  add column if not exists supplier_catalog_id uuid references public.supplier_catalog(id) on delete set null;

create table public.supplier_fulfillments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  supplier_id uuid not null references public.suppliers(id),
  status public.supplier_fulfillment_status not null default 'new',
  supplier_reference text,
  delivery_fee_gds numeric(12,2) not null default 0 check (delivery_fee_gds >= 0),
  courier_name text,
  courier_phone text,
  tracking_code text,
  tracking_note text,
  accepted_at timestamptz,
  shipped_at timestamptz,
  delivered_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(order_id,supplier_id)
);

create index supplier_catalog_supplier_idx on public.supplier_catalog(supplier_id);
create index supplier_fulfillments_supplier_status_idx on public.supplier_fulfillments(supplier_id,status,created_at desc);
create index products_supplier_catalog_idx on public.products(supplier_catalog_id);

alter table public.suppliers enable row level security;
alter table public.supplier_catalog enable row level security;
alter table public.supplier_fulfillments enable row level security;

create policy "supplier owner reads own account" on public.suppliers
for select to authenticated using (owner_id = auth.uid());
create policy "supplier owner creates pending account" on public.suppliers
for insert to authenticated with check (owner_id = auth.uid() and status = 'pending_review');
create policy "supplier owner updates own contact details" on public.suppliers
for update to authenticated using (owner_id = auth.uid())
with check (owner_id = auth.uid() and status = 'pending_review');

create policy "public sees available products from approved suppliers" on public.supplier_catalog
for select to anon, authenticated using (
  is_available = true and stock > 0 and exists (
    select 1 from public.suppliers s where s.id = supplier_id and s.status = 'approved'
  )
);
create policy "supplier manages own catalog" on public.supplier_catalog
for all to authenticated using (
  exists (select 1 from public.suppliers s where s.id = supplier_id and s.owner_id = auth.uid())
) with check (
  exists (select 1 from public.suppliers s where s.id = supplier_id and s.owner_id = auth.uid())
);

create policy "supplier sees orders assigned to them" on public.orders
for select to authenticated using (
  exists (
    select 1 from public.supplier_fulfillments f
    join public.suppliers s on s.id=f.supplier_id
    where f.order_id=orders.id and s.owner_id=auth.uid()
  )
);
create policy "supplier sees items assigned to them" on public.order_items
for select to authenticated using (
  exists (
    select 1 from public.supplier_fulfillments f
    join public.suppliers s on s.id=f.supplier_id
    join public.products p on p.id=order_items.product_id
    where f.order_id=order_items.order_id
      and p.supplier_catalog_id is not null
      and s.id=(select sc.supplier_id from public.supplier_catalog sc where sc.id=p.supplier_catalog_id)
      and s.owner_id=auth.uid()
  )
);

create policy "supplier reads own fulfillment tasks" on public.supplier_fulfillments
for select to authenticated using (
  exists (select 1 from public.suppliers s where s.id=supplier_id and s.owner_id=auth.uid())
);
create policy "supplier updates own fulfillment progress" on public.supplier_fulfillments
for update to authenticated using (
  exists (select 1 from public.suppliers s where s.id=supplier_id and s.owner_id=auth.uid() and s.status='approved')
) with check (
  exists (select 1 from public.suppliers s where s.id=supplier_id and s.owner_id=auth.uid() and s.status='approved')
);

-- IMPORTANT:
-- A trusted server function must create supplier_fulfillments after a paid/accepted order,
-- group order items by supplier, and send only the necessary customer delivery details.
-- Never let a public browser create assignments, confirm payment, or activate suppliers.
-- Supplier dispatch/transport contracts and customer privacy rules must be agreed before launch.
