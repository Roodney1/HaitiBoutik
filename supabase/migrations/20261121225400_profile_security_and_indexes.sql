-- Prevent users from changing their own role through the profile API.
drop policy if exists "profile owner updates own profile" on public.profiles;
revoke update on table public.profiles from anon, authenticated;
grant update (full_name, phone) on public.profiles to authenticated;
create index if not exists shops_owner_id_idx on public.shops(owner_id);
create index if not exists order_items_order_id_idx on public.order_items(order_id);
create index if not exists order_items_product_id_idx on public.order_items(product_id);
create index if not exists payment_records_order_id_idx on public.payment_records(order_id);
create index if not exists payment_records_verified_by_idx on public.payment_records(verified_by);
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
create or replace function private.handle_new_haitiboutik_user()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, phone, role)
  values (new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''), 'Utilisateur'),
    nullif(trim(new.raw_user_meta_data ->> 'phone'), ''),
    'merchant')
  on conflict (id) do nothing;
  return new;
end;
$$;
revoke all on function private.handle_new_haitiboutik_user() from public, anon, authenticated;
drop trigger if exists on_auth_user_created_haitiboutik on auth.users;
create trigger on_auth_user_created_haitiboutik
after insert on auth.users for each row
execute function private.handle_new_haitiboutik_user();