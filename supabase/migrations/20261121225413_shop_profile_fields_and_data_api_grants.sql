alter table public.shops
  add column if not exists category text,
  add column if not exists city text,
  add column if not exists theme_color text,
  add column if not exists delivery_preferences jsonb not null default '{"platform":true,"merchant":true}'::jsonb;
grant select on public.shops, public.products, public.supplier_catalog to anon, authenticated;
grant insert, update on public.shops to authenticated;
grant insert, update, delete on public.products to authenticated;
grant select, insert, update on public.suppliers to authenticated;
grant select, insert, update, delete on public.supplier_catalog to authenticated;
grant select, update on public.orders, public.order_items, public.deliveries, public.supplier_fulfillments to authenticated;
grant select on public.payment_records to authenticated;