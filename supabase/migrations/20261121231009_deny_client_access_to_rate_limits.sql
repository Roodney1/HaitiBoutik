create policy "no client access to order rate limits" on public.order_rate_limits
for all to anon,authenticated using (false) with check (false);
