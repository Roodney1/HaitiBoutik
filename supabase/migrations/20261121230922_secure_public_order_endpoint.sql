create table if not exists public.order_rate_limits (
  ip_hash text primary key,
  window_started_at timestamptz not null,
  request_count integer not null default 0
);
alter table public.order_rate_limits enable row level security;
revoke all on table public.order_rate_limits from public,anon,authenticated;
grant all on table public.order_rate_limits to service_role;
create or replace function public.consume_order_rate_limit(p_ip_hash text)
returns boolean language plpgsql security definer set search_path = ''
as $$
declare v_count integer;
begin
  insert into public.order_rate_limits(ip_hash,window_started_at,request_count) values(p_ip_hash,now(),1)
  on conflict(ip_hash) do update
  set window_started_at=case when public.order_rate_limits.window_started_at < now()-interval '10 minutes' then now() else public.order_rate_limits.window_started_at end,
      request_count=case when public.order_rate_limits.window_started_at < now()-interval '10 minutes' then 1 else public.order_rate_limits.request_count+1 end
  returning request_count into v_count;
  return v_count <= 8;
end;
$$;
revoke all on function public.consume_order_rate_limit(text) from public,anon,authenticated;
grant execute on function public.consume_order_rate_limit(text) to service_role;
revoke all on function public.create_customer_order(text,text,text,text,text,public.delivery_mode,jsonb) from public,anon,authenticated;
grant execute on function public.create_customer_order(text,text,text,text,text,public.delivery_mode,jsonb) to service_role;
