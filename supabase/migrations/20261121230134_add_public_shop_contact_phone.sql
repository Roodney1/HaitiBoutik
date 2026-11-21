alter table public.shops add column if not exists contact_phone text;
revoke update on table public.shops from authenticated;
grant update (name, slug, description, logo_url, category, city, theme_color, delivery_preferences, contact_phone) on public.shops to authenticated;
