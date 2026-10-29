-- Server-verified Paystack purchases. Browsers cannot write to this table.
create table if not exists public.coin_purchases (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  reference text not null unique,
  package_id text not null,
  amount_kes integer not null check (amount_kes > 0),
  coins bigint not null check (coins > 0),
  status text not null default 'pending' check (status in ('pending','paid','failed')),
  paystack_reference text,
  created_at timestamptz not null default now(),
  paid_at timestamptz
);
create index if not exists coin_purchases_user_created_idx
  on public.coin_purchases(user_id, created_at desc);
alter table public.coin_purchases enable row level security;
drop policy if exists "Users can view own coin purchases" on public.coin_purchases;
create policy "Users can view own coin purchases"
  on public.coin_purchases for select to authenticated
  using (auth.uid() = user_id);

create or replace function public.complete_coin_purchase(p_reference text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare p public.coin_purchases%rowtype;
begin
  if coalesce(current_setting('request.jwt.claim.role', true), '') <> 'service_role' then
    raise exception 'Not authorized';
  end if;
  select * into p from public.coin_purchases
    where reference = p_reference for update;
  if not found then raise exception 'Purchase not found'; end if;
  if p.status = 'paid' then return false; end if;
  if p.status <> 'pending' then raise exception 'Purchase is not pending'; end if;

  update public.coin_purchases
    set status = 'paid', paystack_reference = p.reference, paid_at = now()
    where id = p.id;
  insert into public.wallets(user_id, balance)
    values (p.user_id, 0) on conflict (user_id) do nothing;
  update public.wallets
    set balance = balance + p.coins, updated_at = now()
    where user_id = p.user_id;
  insert into public.wallet_transactions(user_id, amount, reason, reference_id)
    values (p.user_id, p.coins, 'paystack_coin_purchase', p.id);
  return true;
end;
$$;
revoke all on function public.complete_coin_purchase(text) from public, anon, authenticated;
grant execute on function public.complete_coin_purchase(text) to service_role;
