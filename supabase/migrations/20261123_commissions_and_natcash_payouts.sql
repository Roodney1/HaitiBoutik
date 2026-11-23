-- HaitiBoutik: commissions de plateforme et demandes de retrait NatCash.
-- À exécuter dans Supabase SQL Editor après les migrations existantes.
-- Aucun transfert d'argent n'est exécuté par cette migration.

alter type public.payment_method add value if not exists 'card';

alter table public.orders
  add column if not exists customer_country text not null default 'HT'
    check (customer_country in ('HT','FR','US')),
  add column if not exists payment_method_text text
    check (payment_method_text is null or payment_method_text in ('moncash','natcash','cash','cash_on_delivery','card')),
  add column if not exists payment_status_text text not null default 'pending'
    check (payment_status_text in ('pending','awaiting_confirmation','verified','failed','refunded'));

create table if not exists public.platform_commissions (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete restrict,
  gross_gds numeric(12,2) not null check (gross_gds >= 0),
  supplier_cost_gds numeric(12,2) not null check (supplier_cost_gds >= 0),
  commission_rate numeric(5,2) not null default 10.00 check (commission_rate between 0 and 20),
  commission_gds numeric(12,2) not null check (commission_gds >= 0),
  currency text not null default 'GDS' check (currency='GDS'),
  created_at timestamptz not null default now()
);

create table if not exists public.platform_payout_requests (
  id uuid primary key default gen_random_uuid(),
  amount_gds numeric(12,2) not null check (amount_gds > 0),
  method text not null default 'natcash' check (method='natcash'),
  destination_phone text not null,
  status text not null default 'requested'
    check (status in ('requested','approved','paid','rejected')),
  admin_note text,
  requested_by uuid not null references auth.users(id),
  requested_at timestamptz not null default now(),
  processed_at timestamptz
);

alter table public.platform_commissions enable row level security;
alter table public.platform_payout_requests enable row level security;

drop policy if exists "platform admins read commissions" on public.platform_commissions;
create policy "platform admins read commissions" on public.platform_commissions
for select to authenticated using (
  exists (select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')
);

drop policy if exists "platform admins read payout requests" on public.platform_payout_requests;
create policy "platform admins read payout requests" on public.platform_payout_requests
for select to authenticated using (
  exists (select 1 from public.profiles p where p.id=auth.uid() and p.role='admin')
);

create or replace function private.refresh_platform_commission(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_gross numeric(12,2);
  v_cost numeric(12,2);
  v_fee numeric(12,2);
begin
  select o.subtotal_gds into v_gross
  from public.orders o
  where o.id=p_order_id and o.status='delivered'
    and exists (
      select 1 from public.payment_records pr
      where pr.order_id=o.id and pr.purpose='customer_order' and pr.status='verified'
    );

  if not found then
    -- Retirer toute commission si la commande n'est plus livrée ou si le paiement est invalidé.
    delete from public.platform_commissions where order_id=p_order_id;
    return;
  end if;

  select coalesce(sum(sc.supplier_price_gds * oi.quantity),0)
  into v_cost
  from public.order_items oi
  join public.products p on p.id=oi.product_id
  left join public.supplier_catalog sc on sc.id=p.supplier_catalog_id
  where oi.order_id=p_order_id;

  v_fee := greatest(0, least(v_gross-v_cost, round(v_gross*0.10,2)));

  insert into public.platform_commissions(order_id,gross_gds,supplier_cost_gds,commission_rate,commission_gds)
  values(p_order_id,v_gross,v_cost,10.00,v_fee)
  on conflict(order_id) do update set
    gross_gds=excluded.gross_gds,
    supplier_cost_gds=excluded.supplier_cost_gds,
    commission_rate=excluded.commission_rate,
    commission_gds=excluded.commission_gds;
end;
$$;

create or replace function private.commission_after_order_change()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  perform private.refresh_platform_commission(new.id);
  return new;
end;
$$;

create or replace function private.commission_after_payment_change()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if new.order_id is not null and new.purpose='customer_order' then
    perform private.refresh_platform_commission(new.order_id);
  end if;
  return new;
end;
$$;

drop trigger if exists platform_commission_order_update on public.orders;
create trigger platform_commission_order_update
after update of status on public.orders
for each row execute function private.commission_after_order_change();

drop trigger if exists platform_commission_payment_update on public.payment_records;
create trigger platform_commission_payment_update
after insert or update of status on public.payment_records
for each row execute function private.commission_after_payment_change();

create or replace function public.request_platform_natcash_withdrawal(
  p_amount_gds numeric,
  p_destination_phone text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user uuid := auth.uid();
  v_available numeric(12,2);
  v_reserved numeric(12,2);
  v_id uuid;
begin
  if v_user is null or not exists (
    select 1 from public.profiles p where p.id=v_user and p.role='admin'
  ) then raise exception 'Accès administrateur requis.'; end if;
  if p_amount_gds is null or p_amount_gds < 100 then raise exception 'Le retrait minimum est de 100 GDS.'; end if;
  if p_destination_phone is null or length(regexp_replace(p_destination_phone,'[^0-9]','','g')) < 8 then
    raise exception 'Veuillez saisir un numéro NatCash valide.';
  end if;

  select coalesce(sum(commission_gds),0) into v_available
  from public.platform_commissions;
  select coalesce(sum(amount_gds),0) into v_reserved
  from public.platform_payout_requests where status in ('requested','approved','paid');
  if p_amount_gds > v_available-v_reserved then raise exception 'Solde disponible insuffisant.'; end if;

  insert into public.platform_payout_requests(amount_gds,destination_phone,requested_by)
  values(round(p_amount_gds,2),trim(p_destination_phone),v_user)
  returning id into v_id;
  return v_id;
end;
$$;

revoke all on function public.request_platform_natcash_withdrawal(numeric,text) from public,anon;
grant execute on function public.request_platform_natcash_withdrawal(numeric,text) to authenticated;
revoke all on function private.refresh_platform_commission(uuid) from public,anon,authenticated;
revoke all on function private.commission_after_order_change() from public,anon,authenticated;
revoke all on function private.commission_after_payment_change() from public,anon,authenticated;

grant select on public.platform_commissions,public.platform_payout_requests to authenticated;

-- IMPORTANT:
-- La commission n'est créée qu'après livraison ET vérification d'un paiement.
-- Le retrait crée une demande; le versement NatCash reste manuel jusqu'à intégration
-- d'une API marchande officielle et vérifiée.
