create or replace function public.create_customer_order(
  p_shop_slug text,
  p_customer_name text,
  p_customer_phone text,
  p_delivery_address text,
  p_customer_note text,
  p_delivery_mode public.delivery_mode,
  p_items jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_shop public.shops%rowtype;
  v_order_id uuid;
  v_product_id uuid;
  v_qty integer;
  v_name text;
  v_price numeric(12,2);
  v_catalog_id uuid;
  v_supplier_id uuid;
  v_subtotal numeric(12,2) := 0;
  v_supplier_ids uuid[] := '{}';
  v_item jsonb;
begin
  if p_customer_name is null or length(trim(p_customer_name)) < 2 then raise exception 'Veuillez saisir votre nom complet.'; end if;
  if p_customer_phone is null or length(regexp_replace(p_customer_phone, '[^0-9]', '', 'g')) < 8 then raise exception 'Veuillez saisir un numéro de téléphone valide.'; end if;
  if p_delivery_address is null or length(trim(p_delivery_address)) < 5 then raise exception 'Veuillez préciser une adresse de livraison complète.'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) < 1 or jsonb_array_length(p_items) > 30 then raise exception 'Le panier est vide ou contient trop d’articles.'; end if;
  select * into v_shop from public.shops where slug = p_shop_slug and status = 'active' for update;
  if not found then raise exception 'Cette boutique n’est pas encore active.'; end if;
  if p_delivery_mode = 'platform_courier' and coalesce(v_shop.delivery_preferences ->> 'platform','false') <> 'true' then raise exception 'La livraison par partenaire HaitiBoutik n’est pas proposée par cette boutique.'; end if;
  if p_delivery_mode = 'merchant_courier' and coalesce(v_shop.delivery_preferences ->> 'merchant','false') <> 'true' then raise exception 'La livraison par le livreur du marchand n’est pas proposée par cette boutique.'; end if;
  for v_item in select value from jsonb_array_elements(p_items) loop
    begin v_product_id := (v_item ->> 'product_id')::uuid; v_qty := (v_item ->> 'quantity')::integer;
    exception when others then raise exception 'Un article du panier est invalide.'; end;
    if v_qty < 1 or v_qty > 25 then raise exception 'Quantité invalide.'; end if;
    select p.name,p.price_gds,p.supplier_catalog_id,sc.supplier_id into v_name,v_price,v_catalog_id,v_supplier_id
    from public.products p join public.supplier_catalog sc on sc.id=p.supplier_catalog_id
    join public.suppliers s on s.id=sc.supplier_id and s.status='approved'
    where p.id=v_product_id and p.shop_id=v_shop.id and p.is_published=true and p.stock>=v_qty and sc.is_available=true and sc.stock>=v_qty
    for update of p,sc;
    if not found then raise exception 'Un produit est indisponible ou n’a pas encore de fournisseur vérifié.'; end if;
    v_subtotal := v_subtotal + (v_price * v_qty);
    if not (v_supplier_id = any(v_supplier_ids)) then v_supplier_ids := array_append(v_supplier_ids,v_supplier_id); end if;
  end loop;
  insert into public.orders(shop_id,customer_name,customer_phone,delivery_address,customer_note,status,subtotal_gds,delivery_fee_gds,delivery_fee_payer,total_gds)
  values(v_shop.id,trim(p_customer_name),trim(p_customer_phone),trim(p_delivery_address),nullif(trim(coalesce(p_customer_note,'')),''),'pending',v_subtotal,0,'merchant',v_subtotal)
  returning id into v_order_id;
  for v_item in select value from jsonb_array_elements(p_items) loop
    v_product_id := (v_item ->> 'product_id')::uuid; v_qty := (v_item ->> 'quantity')::integer;
    select p.name,p.price_gds,p.supplier_catalog_id into v_name,v_price,v_catalog_id from public.products p where p.id=v_product_id and p.shop_id=v_shop.id;
    insert into public.order_items(order_id,product_id,product_name,unit_price_gds,quantity) values(v_order_id,v_product_id,v_name,v_price,v_qty);
    update public.products set stock=stock-v_qty where id=v_product_id;
    update public.supplier_catalog set stock=stock-v_qty,updated_at=now() where id=v_catalog_id;
  end loop;
  foreach v_supplier_id in array v_supplier_ids loop insert into public.supplier_fulfillments(order_id,supplier_id,status) values(v_order_id,v_supplier_id,'new'); end loop;
  insert into public.deliveries(order_id,mode,status) values(v_order_id,p_delivery_mode,'not_assigned');
  return v_order_id;
end;
$$;
revoke all on function public.create_customer_order(text,text,text,text,text,public.delivery_mode,jsonb) from public,anon,authenticated;
grant execute on function public.create_customer_order(text,text,text,text,text,public.delivery_mode,jsonb) to anon,authenticated;
