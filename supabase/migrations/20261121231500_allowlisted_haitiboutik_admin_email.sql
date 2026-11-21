create table if not exists private.admin_email_allowlist (
  email text primary key,
  created_at timestamptz not null default now()
);
alter table private.admin_email_allowlist enable row level security;
revoke all on private.admin_email_allowlist from public, anon, authenticated;
insert into private.admin_email_allowlist(email)
values ('roodneyjeanpaul522@gmail.com')
on conflict (email) do nothing;

create or replace function private.sync_haitiboutik_admin_role()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_allowed boolean;
  v_role text;
begin
  select exists (
    select 1 from private.admin_email_allowlist a
    where lower(a.email) = lower(new.email)
  ) and new.email_confirmed_at is not null
  into v_allowed;

  v_role := coalesce(new.raw_app_meta_data ->> 'role', '');

  if v_allowed and v_role <> 'admin' then
    update auth.users
    set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || jsonb_build_object('role', 'admin')
    where id = new.id;
    update public.profiles set role = 'admin' where id = new.id;
  elsif not v_allowed and v_role = 'admin' then
    update auth.users
    set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) - 'role'
    where id = new.id;
    update public.profiles set role = 'merchant' where id = new.id;
  end if;
  return new;
end;
$$;
revoke all on function private.sync_haitiboutik_admin_role() from public, anon, authenticated;

drop trigger if exists sync_haitiboutik_admin_role on auth.users;
create trigger sync_haitiboutik_admin_role
after insert or update of email, email_confirmed_at on auth.users
for each row execute function private.sync_haitiboutik_admin_role();

update auth.users u
set raw_app_meta_data = coalesce(u.raw_app_meta_data, '{}'::jsonb) || jsonb_build_object('role', 'admin')
where lower(u.email) = 'roodneyjeanpaul522@gmail.com'
  and u.email_confirmed_at is not null;
update public.profiles p
set role = 'admin'
from auth.users u
where p.id = u.id
  and lower(u.email) = 'roodneyjeanpaul522@gmail.com'
  and u.email_confirmed_at is not null;
