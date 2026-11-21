-- HaitiBoutik: schema initiale Supabase/PostgreSQL
-- IMPORTANT: ceci crée la structure de données, pas les comptes ni les intégrations de paiement.
create extension if not exists pgcrypto;

create type public.shop_status as enum ('pending_activation','active','suspended');
create type public.order_status as enum ('pending','confirmed','preparing','shipped','delivered','cancelled');
create type public.delivery_mode as enum ('platform_courier','merchant_courier');
create type public.delivery_status as enum ('not_assigned','assigned','picked_up','in_transit','delivered','failed');
create type public.payment_method as enum ('moncash','natcash','cash_on_delivery');
create type public.payment_status as enum ('pending','submitted','verified','rejected','refunded');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  phone text,
  role text not null default 'merchant' check (role in ('merchant','admin')),
  created_at timestamptz not null default now()
);

create table public.shops (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null,
  slug text not null unique,
  description text,
  logo_url text,
  status public.shop_status not null default 'pending_activation',
  activation_fee_gds integer not null default 750 check (activation_fee_gds = 750),
  activation_paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.products (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id) on delete cascade,
  name text not null,
  description text,
  price_gds numeric(12,2) not null check (price_gds >= 0),
  stock integer not null default 0 check (stock >= 0),
  image_url text,
  is_published boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid not null references public.shops(id),
  customer_name text not null,
  customer_phone text not null,
  delivery_address text not null,
  customer_note text,
  status public.order_status not null default 'pending',
  subtotal_gds numeric(12,2) not null check (subtotal_gds >= 0),
  delivery_fee_gds numeric(12,2) not null default 0 check (delivery_fee_gds >= 0),
  delivery_fee_payer text not null default 'merchant' check (delivery_fee_payer = 'merchant'),
  total_gds numeric(12,2) not null check (total_gds >= 0),
  created_at timestamptz not null default now()
);

create table public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid references public.products(id) on delete set null,
  product_name text not null,
  unit_price_gds numeric(12,2) not null check (unit_price_gds >= 0),
  quantity integer not null check (quantity > 0)
);

create table public.deliveries (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  mode public.delivery_mode not null,
  status public.delivery_status not null default 'not_assigned',
  courier_name text,
  courier_phone text,
  tracking_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.payment_records (
  id uuid primary key default gen_random_uuid(),
  shop_id uuid references public.shops(id) on delete cascade,
  order_id uuid references public.orders(id) on delete cascade,
  purpose text not null check (purpose in ('shop_activation','customer_order')),
  method public.payment_method not null,
  amount_gds numeric(12,2) not null check (amount_gds > 0),
  status public.payment_status not null default 'pending',
  provider_reference text,
  verified_by uuid references public.profiles(id),
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  check (
    (purpose = 'shop_activation' and shop_id is not null and order_id is null and amount_gds = 750)
    or (purpose = 'customer_order' and order_id is not null)
  )
);

create index products_shop_idx on public.products(shop_id);
create index orders_shop_created_idx on public.orders(shop_id, created_at desc);
create index payment_records_shop_idx on public.payment_records(shop_id);

-- Row Level Security: active storefront products are public; private business data stays private.
alter table public.profiles enable row level security;
alter table public.shops enable row level security;
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.deliveries enable row level security;
alter table public.payment_records enable row level security;

create policy "profile owner reads own profile" on public.profiles
for select to authenticated using (id = auth.uid());
create policy "profile owner updates own profile" on public.profiles
for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy "public sees active shops" on public.shops
for select to anon, authenticated using (status = 'active');
create policy "owner sees own shop" on public.shops
for select to authenticated using (owner_id = auth.uid());
create policy "owner creates own pending shop" on public.shops
for insert to authenticated with check (owner_id = auth.uid() and status = 'pending_activation');
create policy "owner updates own shop" on public.shops
for update to authenticated using (owner_id = auth.uid()) with check (owner_id = auth.uid() and status <> 'active');

create policy "public sees published products of active shops" on public.products
for select to anon, authenticated using (
  is_published = true and exists (
    select 1 from public.shops s where s.id = shop_id and s.status = 'active'
  )
);
create policy "merchant manages own products" on public.products
for all to authenticated using (
  exists (select 1 from public.shops s where s.id = shop_id and s.owner_id = auth.uid())
) with check (
  exists (select 1 from public.shops s where s.id = shop_id and s.owner_id = auth.uid())
);

create policy "merchant reads own orders" on public.orders
for select to authenticated using (
  exists (select 1 from public.shops s where s.id = shop_id and s.owner_id = auth.uid())
);
create policy "merchant updates own orders" on public.orders
for update to authenticated using (
  exists (select 1 from public.shops s where s.id = shop_id and s.owner_id = auth.uid())
) with check (
  exists (select 1 from public.shops s where s.id = shop_id and s.owner_id = auth.uid())
);
create policy "merchant reads order items" on public.order_items
for select to authenticated using (
  exists (select 1 from public.orders o join public.shops s on s.id=o.shop_id where o.id=order_id and s.owner_id=auth.uid())
);
create policy "merchant reads deliveries" on public.deliveries
for select to authenticated using (
  exists (select 1 from public.orders o join public.shops s on s.id=o.shop_id where o.id=order_id and s.owner_id=auth.uid())
);
create policy "merchant updates deliveries" on public.deliveries
for update to authenticated using (
  exists (select 1 from public.orders o join public.shops s on s.id=o.shop_id where o.id=order_id and s.owner_id=auth.uid())
) with check (
  exists (select 1 from public.orders o join public.shops s on s.id=o.shop_id where o.id=order_id and s.owner_id=auth.uid())
);
create policy "merchant reads own payments" on public.payment_records
for select to authenticated using (
  shop_id is not null and exists (select 1 from public.shops s where s.id=shop_id and s.owner_id=auth.uid())
);

-- No public policy can mark a payment as verified or activate a shop.
-- A trusted server/admin process must verify provider transactions before changing status.
