-- HaitiBoutik security hardening: profile creation and role protection.
-- Run once in the Supabase SQL Editor after applying schema.sql.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, phone, role)
  values (
    new.id,
    coalesce(nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''), split_part(coalesce(new.email, 'marchand'), '@', 1)),
    nullif(trim(new.raw_user_meta_data ->> 'phone'), ''),
    'merchant'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_haitiboutik on auth.users;
create trigger on_auth_user_created_haitiboutik
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- A merchant must never be able to grant themselves admin privileges.
create or replace function public.prevent_self_role_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is not null
     and auth.uid() = old.id
     and new.role is distinct from old.role then
    raise exception 'Vous ne pouvez pas modifier votre propre rôle.';
  end if;
  return new;
end;
$$;

drop trigger if exists prevent_profile_self_role_change on public.profiles;
create trigger prevent_profile_self_role_change
before update on public.profiles
for each row execute procedure public.prevent_self_role_change();

-- Allow each signed-in user to create only their own merchant profile.
drop policy if exists "profile owner creates own merchant profile" on public.profiles;
create policy "profile owner creates own merchant profile" on public.profiles
for insert to authenticated
with check (id = auth.uid() and role = 'merchant');

-- Keep profile updates limited to the owner; role changes are blocked by the trigger above.
