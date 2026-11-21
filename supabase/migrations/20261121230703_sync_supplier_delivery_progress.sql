create or replace function private.sync_supplier_fulfillment_status()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare
  v_delivery_status public.delivery_status;
  v_order_status public.order_status;
  v_tracking text;
  v_courier text;
  v_phone text;
begin
  select
    case
      when bool_and(status='delivered') then 'delivered'::public.delivery_status
      when bool_or(status='shipped') then 'in_transit'::public.delivery_status
      when bool_or(status='ready_to_ship') then 'picked_up'::public.delivery_status
      when bool_or(status in ('accepted','preparing')) then 'assigned'::public.delivery_status
      when bool_or(status in ('rejected','issue')) then 'failed'::public.delivery_status
      else 'assigned'::public.delivery_status
    end,
    case
      when bool_and(status='delivered') then 'delivered'::public.order_status
      when bool_or(status='shipped') then 'shipped'::public.order_status
      when bool_or(status in ('preparing','ready_to_ship')) then 'preparing'::public.order_status
      when bool_or(status='accepted') then 'confirmed'::public.order_status
      else 'pending'::public.order_status
    end,
    string_agg(nullif(tracking_code,''), ', '),
    string_agg(nullif(courier_name,''), ', '),
    string_agg(nullif(courier_phone,''), ', ')
  into v_delivery_status,v_order_status,v_tracking,v_courier,v_phone
  from public.supplier_fulfillments where order_id=new.order_id;
  update public.deliveries set status=v_delivery_status,courier_name=v_courier,courier_phone=v_phone,
    tracking_note=coalesce(v_tracking,tracking_note),updated_at=now() where order_id=new.order_id;
  update public.orders set status=v_order_status where id=new.order_id;
  return new;
end;
$$;
revoke all on function private.sync_supplier_fulfillment_status() from public,anon,authenticated;
drop trigger if exists sync_supplier_fulfillment_status on public.supplier_fulfillments;
create trigger sync_supplier_fulfillment_status after update of status,courier_name,courier_phone,tracking_code,tracking_note
on public.supplier_fulfillments for each row execute function private.sync_supplier_fulfillment_status();
