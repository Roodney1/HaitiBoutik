-- Combine same-action permissive policies into one expression per table.
drop policy if exists "public sees active shops" on public.shops;
drop policy if exists "owner sees own shop" on public.shops;
create policy "public and owner read shops" on public.shops
for select to anon, authenticated using (status = 'active' or owner_id = (select auth.uid()));

drop policy if exists "public sees published products of active shops" on public.products;
drop policy if exists "merchant manages own products" on public.products;
create policy "public and owner read products" on public.products
for select to anon, authenticated using (
  (is_published = true and exists (select 1 from public.shops s where s.id = shop_id and s.status = 'active'))
  or exists (select 1 from public.shops s where s.id = shop_id and s.owner_id = (select auth.uid()))
);
create policy "merchant inserts own products" on public.products for insert to authenticated
with check (exists (select 1 from public.shops s where s.id = shop_id and s.owner_id = (select auth.uid())));
create policy "merchant updates own products" on public.products for update to authenticated
using (exists (select 1 from public.shops s where s.id = shop_id and s.owner_id = (select auth.uid())))
with check (exists (select 1 from public.shops s where s.id = shop_id and s.owner_id = (select auth.uid())));
create policy "merchant deletes own products" on public.products for delete to authenticated
using (exists (select 1 from public.shops s where s.id = shop_id and s.owner_id = (select auth.uid())));

drop policy if exists "merchant reads own orders" on public.orders;
drop policy if exists "supplier sees orders assigned to them" on public.orders;
create policy "merchant and assigned supplier read orders" on public.orders for select to authenticated
using (
  exists (select 1 from public.shops s where s.id = shop_id and s.owner_id = (select auth.uid()))
  or exists (select 1 from public.supplier_fulfillments f join public.suppliers s on s.id=f.supplier_id
    where f.order_id=orders.id and s.owner_id=(select auth.uid()))
);

drop policy if exists "merchant reads order items" on public.order_items;
drop policy if exists "supplier sees items assigned to them" on public.order_items;
create policy "merchant and assigned supplier read order items" on public.order_items for select to authenticated
using (
  exists (select 1 from public.orders o join public.shops s on s.id=o.shop_id
    where o.id=order_id and s.owner_id=(select auth.uid()))
  or exists (select 1 from public.supplier_fulfillments f join public.suppliers s on s.id=f.supplier_id
    join public.products p on p.id=order_items.product_id join public.supplier_catalog sc on sc.id=p.supplier_catalog_id
    where f.order_id=order_items.order_id and s.id=sc.supplier_id and s.owner_id=(select auth.uid()))
);

drop policy if exists "public sees available products from approved suppliers" on public.supplier_catalog;
drop policy if exists "supplier manages own catalog" on public.supplier_catalog;
create policy "public and supplier read catalog" on public.supplier_catalog for select to anon, authenticated
using (
  (is_available = true and stock > 0 and exists (select 1 from public.suppliers s where s.id=supplier_id and s.status='approved'))
  or exists (select 1 from public.suppliers s where s.id=supplier_id and s.owner_id=(select auth.uid()))
);
create policy "supplier inserts own catalog" on public.supplier_catalog for insert to authenticated
with check (exists (select 1 from public.suppliers s where s.id=supplier_id and s.owner_id=(select auth.uid())));
create policy "supplier updates own catalog" on public.supplier_catalog for update to authenticated
using (exists (select 1 from public.suppliers s where s.id=supplier_id and s.owner_id=(select auth.uid())))
with check (exists (select 1 from public.suppliers s where s.id=supplier_id and s.owner_id=(select auth.uid())));
create policy "supplier deletes own catalog" on public.supplier_catalog for delete to authenticated
using (exists (select 1 from public.suppliers s where s.id=supplier_id and s.owner_id=(select auth.uid())));
