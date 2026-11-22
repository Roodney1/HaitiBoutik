-- HaitiBoutik Digital Marketplace — additive schema draft
-- Review before applying in Supabase SQL Editor. This does not replace the legacy physical-shop schema.
-- Product files stay private. Only a trusted server may confirm payments, grant downloads,
-- write seller balances, or issue signed download URLs.

create table if not exists public.seller_accounts (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  display_name text not null,
  status text not null default 'pending' check (status in ('pending','active','suspended')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.seller_subscriptions (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.seller_accounts(user_id) on delete cascade,
  amount_gds numeric(12,2) not null default 500 check (amount_gds = 500),
  status text not null default 'pending' check (status in ('pending','active','expired','cancelled','rejected')),
  starts_at timestamptz,
  ends_at timestamptz,
  payment_reference text,
  verified_by uuid references public.profiles(id),
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  check ((status = 'active' and starts_at is not null and ends_at is not null and ends_at > starts_at)
      or status <> 'active')
);
create index if not exists seller_subscriptions_active_idx
  on public.seller_subscriptions(seller_id, ends_at desc) where status = 'active';

-- The paid period is one calendar month; renewals create a new subscription row.
alter table public.seller_subscriptions drop constraint if exists seller_subscription_one_month;
alter table public.seller_subscriptions add constraint seller_subscription_one_month
  check (status <> 'active' or ends_at <= starts_at + interval '1 month');

create table if not exists public.digital_products (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.seller_accounts(user_id) on delete cascade,
  title text not null check (char_length(title) between 3 and 120),
  description text not null default '',
  category text not null default 'Autre',
  price_gds numeric(12,2) not null check (price_gds > 0),
  cover_image_path text,
  file_path text not null,
  file_name text not null,
  file_size_bytes bigint not null check (file_size_bytes > 0),
  mime_type text not null,
  status text not null default 'draft' check (status in ('draft','pending_review','published','rejected','hidden')),
  rejection_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists digital_products_public_idx
  on public.digital_products(status, created_at desc);
create index if not exists digital_products_seller_idx
  on public.digital_products(seller_id, created_at desc);

create table if not exists public.digital_orders (
  id uuid primary key default gen_random_uuid(),
  buyer_id uuid not null references public.profiles(id),
  status text not null default 'pending_payment' check (status in ('pending_payment','paid','cancelled','refunded','disputed')),
  subtotal_gds numeric(12,2) not null check (subtotal_gds > 0),
  platform_commission_gds numeric(12,2) not null default 0 check (platform_commission_gds >= 0),
  seller_total_gds numeric(12,2) not null default 0 check (seller_total_gds >= 0),
  created_at timestamptz not null default now(),
  paid_at timestamptz,
  check (round(platform_commission_gds + seller_total_gds, 2) = round(subtotal_gds, 2))
);
create index if not exists digital_orders_buyer_idx
  on public.digital_orders(buyer_id, created_at desc);

create table if not exists public.digital_order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.digital_orders(id) on delete cascade,
  product_id uuid references public.digital_products(id) on delete set null,
  seller_id uuid not null references public.seller_accounts(user_id),
  product_title text not null,
  unit_price_gds numeric(12,2) not null check (unit_price_gds > 0),
  platform_commission_gds numeric(12,2) not null check (platform_commission_gds >= 0),
  seller_earning_gds numeric(12,2) not null check (seller_earning_gds >= 0),
  created_at timestamptz not null default now(),
  check (round(platform_commission_gds + seller_earning_gds, 2) = round(unit_price_gds, 2))
);
create index if not exists digital_order_items_order_idx on public.digital_order_items(order_id);
create index if not exists digital_order_items_seller_idx on public.digital_order_items(seller_id, created_at desc);

create table if not exists public.digital_payment_records (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references public.digital_orders(id) on delete restrict,
  seller_id uuid references public.seller_accounts(user_id) on delete restrict,
  purpose text not null check (purpose in ('buyer_order','seller_subscription')),
  method text not null check (method in ('moncash','natcash','other')),
  amount_gds numeric(12,2) not null check (amount_gds > 0),
  status text not null default 'pending' check (status in ('pending','submitted','verified','rejected','refunded')),
  provider_reference text,
  verified_by uuid references public.profiles(id),
  verified_at timestamptz,
  created_at timestamptz not null default now(),
  check ((purpose = 'buyer_order' and order_id is not null and seller_id is null)
      or (purpose = 'seller_subscription' and seller_id is not null and order_id is null))
);
create unique index if not exists digital_payment_provider_reference_unique
  on public.digital_payment_records(method, provider_reference)
  where provider_reference is not null;
create index if not exists digital_payment_order_idx on public.digital_payment_records(order_id);

create table if not exists public.download_entitlements (
  id uuid primary key default gen_random_uuid(),
  order_item_id uuid not null unique references public.digital_order_items(id) on delete cascade,
  buyer_id uuid not null references public.profiles(id) on delete cascade,
  product_id uuid not null references public.digital_products(id) on delete restrict,
  downloads_count integer not null default 0 check (downloads_count >= 0),
  created_at timestamptz not null default now()
);
create index if not exists download_entitlements_buyer_idx
  on public.download_entitlements(buyer_id, created_at desc);

create table if not exists public.seller_ledger (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.seller_accounts(user_id) on delete restrict,
  order_item_id uuid references public.digital_order_items(id) on delete restrict,
  entry_type text not null check (entry_type in ('sale_credit','refund_debit','payout_debit','adjustment')),
  amount_gds numeric(12,2) not null check (amount_gds <> 0),
  description text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists seller_ledger_seller_idx on public.seller_ledger(seller_id, created_at desc);

create table if not exists public.seller_payouts (
  id uuid primary key default gen_random_uuid(),
  seller_id uuid not null references public.seller_accounts(user_id) on delete restrict,
  amount_gds numeric(12,2) not null check (amount_gds > 0),
  method text not null check (method in ('moncash','natcash','other')),
  destination_reference text not null,
  status text not null default 'requested' check (status in ('requested','processing','paid','rejected')),
  requested_at timestamptz not null default now(),
  processed_at timestamptz,
  processed_by uuid references public.profiles(id),
  admin_note text
);
create index if not exists seller_payouts_seller_idx on public.seller_payouts(seller_id, requested_at desc);

-- Enable RLS on every exposed marketplace table.
alter table public.seller_accounts enable row level security;
alter table public.seller_subscriptions enable row level security;
alter table public.digital_products enable row level security;
alter table public.digital_orders enable row level security;
alter table public.digital_order_items enable row level security;
alter table public.digital_payment_records enable row level security;
alter table public.download_entitlements enable row level security;
alter table public.seller_ledger enable row level security;
alter table public.seller_payouts enable row level security;

-- Idempotent policy setup.
drop policy if exists "seller reads own account" on public.seller_accounts;
create policy "seller reads own account" on public.seller_accounts
for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists "seller requests own account" on public.seller_accounts;
create policy "seller requests own account" on public.seller_accounts
for insert to authenticated with check (
  user_id = (select auth.uid()) and status = 'pending'
);
drop policy if exists "admin manages seller accounts" on public.seller_accounts;
create policy "admin manages seller accounts" on public.seller_accounts
for all to authenticated using (
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
) with check (
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
);

drop policy if exists "seller reads own subscriptions" on public.seller_subscriptions;
create policy "seller reads own subscriptions" on public.seller_subscriptions
for select to authenticated using (seller_id = (select auth.uid()));
drop policy if exists "admin manages subscriptions" on public.seller_subscriptions;
create policy "admin manages subscriptions" on public.seller_subscriptions
for all to authenticated using (
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
) with check (
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
);

drop policy if exists "public reads published digital products" on public.digital_products;
create policy "public reads published digital products" on public.digital_products
for select to anon, authenticated using (status = 'published');
drop policy if exists "seller manages own digital products with active subscription" on public.digital_products;
drop policy if exists "seller reads own digital products" on public.digital_products;
create policy "seller reads own digital products" on public.digital_products
for select to authenticated using (seller_id = (select auth.uid()));
drop policy if exists "seller creates draft digital products" on public.digital_products;
create policy "seller creates draft digital products" on public.digital_products
for insert to authenticated with check (
  seller_id = (select auth.uid())
  and status in ('draft','pending_review')
  and exists (
    select 1 from public.seller_accounts sa
    where sa.user_id = (select auth.uid()) and sa.status = 'active'
  )
  and exists (
    select 1 from public.seller_subscriptions ss
    where ss.seller_id = (select auth.uid()) and ss.status = 'active' and ss.ends_at > now()
  )
);
drop policy if exists "seller updates own draft digital products" on public.digital_products;
create policy "seller updates own draft digital products" on public.digital_products
for update to authenticated using (seller_id = (select auth.uid()))
with check (
  seller_id = (select auth.uid())
  and status in ('draft','pending_review')
  and exists (
    select 1 from public.seller_accounts sa
    where sa.user_id = (select auth.uid()) and sa.status = 'active'
  )
  and exists (
    select 1 from public.seller_subscriptions ss
    where ss.seller_id = (select auth.uid()) and ss.status = 'active' and ss.ends_at > now()
  )
);
drop policy if exists "seller deletes own digital products" on public.digital_products;
create policy "seller deletes own digital products" on public.digital_products
for delete to authenticated using (seller_id = (select auth.uid()));
drop policy if exists "admin manages digital products" on public.digital_products;
create policy "admin manages digital products" on public.digital_products
for all to authenticated using (
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
) with check (
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
);

drop policy if exists "buyer reads own digital orders" on public.digital_orders;
create policy "buyer reads own digital orders" on public.digital_orders
for select to authenticated using (buyer_id = (select auth.uid()));
drop policy if exists "admin reads digital orders" on public.digital_orders;
create policy "admin reads digital orders" on public.digital_orders
for select to authenticated using (
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
);

drop policy if exists "buyer reads own digital order items" on public.digital_order_items;
create policy "buyer reads own digital order items" on public.digital_order_items
for select to authenticated using (
  exists (select 1 from public.digital_orders o where o.id = order_id and o.buyer_id = (select auth.uid()))
);
drop policy if exists "seller reads own sold items" on public.digital_order_items;
create policy "seller reads own sold items" on public.digital_order_items
for select to authenticated using (seller_id = (select auth.uid()));
drop policy if exists "admin reads digital order items" on public.digital_order_items;
create policy "admin reads digital order items" on public.digital_order_items
for select to authenticated using (
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
);

drop policy if exists "user reads own digital payments" on public.digital_payment_records;
create policy "user reads own digital payments" on public.digital_payment_records
for select to authenticated using (
  seller_id = (select auth.uid())
  or exists (select 1 from public.digital_orders o where o.id = order_id and o.buyer_id = (select auth.uid()))
);
drop policy if exists "admin manages digital payments" on public.digital_payment_records;
create policy "admin manages digital payments" on public.digital_payment_records
for all to authenticated using (
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
) with check (
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
);

drop policy if exists "buyer reads own download entitlements" on public.download_entitlements;
create policy "buyer reads own download entitlements" on public.download_entitlements
for select to authenticated using (buyer_id = (select auth.uid()));
drop policy if exists "admin reads download entitlements" on public.download_entitlements;
create policy "admin reads download entitlements" on public.download_entitlements
for select to authenticated using (
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
);

drop policy if exists "seller reads own ledger" on public.seller_ledger;
create policy "seller reads own ledger" on public.seller_ledger
for select to authenticated using (seller_id = (select auth.uid()));
drop policy if exists "admin manages seller ledger" on public.seller_ledger;
create policy "admin manages seller ledger" on public.seller_ledger
for all to authenticated using (
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
) with check (
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
);

drop policy if exists "seller reads own payout requests" on public.seller_payouts;
create policy "seller reads own payout requests" on public.seller_payouts
for select to authenticated using (seller_id = (select auth.uid()));
-- Payout requests are created by trusted server code after balance verification.
drop policy if exists "admin manages seller payouts" on public.seller_payouts;
create policy "admin manages seller payouts" on public.seller_payouts
for all to authenticated using (
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
) with check (
  exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.role = 'admin')
);

-- Private bucket for downloadable customer files.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'digital-products',
  'digital-products',
  false,
  52428800,
  array['application/pdf','application/zip','application/epub+zip','application/vnd.openxmlformats-officedocument.wordprocessingml.document','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','application/vnd.openxmlformats-officedocument.presentationml.presentation']
)
on conflict (id) do update set
  public = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "seller uploads own digital product files" on storage.objects;
create policy "seller uploads own digital product files" on storage.objects
for insert to authenticated with check (
  bucket_id = 'digital-products'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (
    select 1 from public.seller_accounts sa
    where sa.user_id = (select auth.uid()) and sa.status = 'active'
  )
  and exists (
    select 1 from public.seller_subscriptions ss
    where ss.seller_id = (select auth.uid()) and ss.status = 'active' and ss.ends_at > now()
  )
);
drop policy if exists "admin reads digital product files" on storage.objects;
create policy "admin reads digital product files" on storage.objects
for select to authenticated using (
  bucket_id = 'digital-products'
  and exists (
    select 1 from public.profiles p
    where p.id = (select auth.uid()) and p.role = 'admin'
  )
);
drop policy if exists "seller reads own digital product files" on storage.objects;
create policy "seller reads own digital product files" on storage.objects
for select to authenticated using (
  bucket_id = 'digital-products'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
drop policy if exists "seller updates own digital product files" on storage.objects;
create policy "seller updates own digital product files" on storage.objects
for update to authenticated using (
  bucket_id = 'digital-products'
  and (storage.foldername(name))[1] = (select auth.uid())::text
) with check (
  bucket_id = 'digital-products'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
drop policy if exists "seller deletes own digital product files" on storage.objects;
create policy "seller deletes own digital product files" on storage.objects
for delete to authenticated using (
  bucket_id = 'digital-products'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

-- IMPORTANT: No client-side INSERT/UPDATE policy exists for orders, payment records,
-- entitlements, or ledger entries. Trusted server code must create and confirm these records.
-- A private object must never be made public. Buyers receive short-lived signed URLs only
-- after the backend verifies a paid order and matching download entitlement.
