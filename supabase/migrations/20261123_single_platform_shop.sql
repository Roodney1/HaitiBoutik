-- HaitiBoutik devient une boutique unique appartenant à l'administration.
-- Conserver les données existantes; vérifier que l'unique boutique existante est administrée par le compte officiel.
drop policy if exists "owner creates own pending shop" on public.shops;
drop policy if exists "owner updates own shop" on public.shops;

create policy "platform admins manage the single shop" on public.shops
for all to authenticated
using (exists (select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'))
with check (exists (select 1 from public.profiles p where p.id=auth.uid() and p.role='admin'));

create or replace function private.enforce_single_platform_shop()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  if exists (select 1 from public.shops s where s.id <> coalesce(new.id,'00000000-0000-0000-0000-000000000000'::uuid)) then
    raise exception 'HaitiBoutik utilise une boutique unique. La création de boutiques clientes est désactivée.';
  end if;
  if not exists (select 1 from public.profiles p where p.id=auth.uid() and p.role='admin') then
    raise exception 'Seul l’administrateur HaitiBoutik peut gérer la boutique officielle.';
  end if;
  return new;
end;
$$;
revoke all on function private.enforce_single_platform_shop() from public,anon,authenticated;
drop trigger if exists enforce_single_platform_shop on public.shops;
create trigger enforce_single_platform_shop
before insert or update on public.shops
for each row execute function private.enforce_single_platform_shop();

-- Cette politique n'autorise pas les comptes marchands à créer ni modifier des boutiques.
-- Les commandes et produits restent rattachés à l'unique boutique officielle.
