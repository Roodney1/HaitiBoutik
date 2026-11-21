-- Let merchants edit storefront details without changing activation or ownership fields.
drop policy if exists "owner updates own shop" on public.shops;
create policy "owner updates own shop details" on public.shops
for update to authenticated
using (owner_id = (select auth.uid()))
with check (owner_id = (select auth.uid()));
revoke update on table public.shops from authenticated;
grant update (name, slug, description, logo_url, category, city, theme_color, delivery_preferences) on public.shops to authenticated;
