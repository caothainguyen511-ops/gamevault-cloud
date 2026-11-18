-- GameVault: unique transfer ID + manually reviewed wallet top-ups.
-- Apply to the Supabase project configured for this repository.

alter table public.users add column if not exists account_code text;
update public.users set account_code='GV'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10)) where account_code is null;
create unique index if not exists users_account_code_uidx on public.users(account_code);
alter table public.users alter column account_code set not null;
alter table public.users alter column account_code set default ('GV'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,10)));

create table if not exists public.wallet_balances (
 user_id uuid primary key references public.users(id) on delete cascade,
 balance_vnd bigint not null default 0 check(balance_vnd>=0),
 updated_at timestamptz not null default now()
);
create table if not exists public.wallet_topups (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.users(id) on delete cascade,
 account_code text not null,
 amount_vnd bigint not null check(amount_vnd>=1000),
 transfer_note text not null,
 status text not null default 'pending' check(status in ('pending','approved','rejected')),
 admin_note text, reviewed_by uuid references public.users(id), reviewed_at timestamptz,
 created_at timestamptz not null default now()
);
create table if not exists public.wallet_transactions (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references public.users(id) on delete cascade,
 topup_id uuid unique references public.wallet_topups(id),
 amount_vnd bigint not null,
 transaction_type text not null check(transaction_type in ('topup','purchase','adjustment')),
 description text, created_by uuid references public.users(id), created_at timestamptz not null default now()
);
insert into public.wallet_balances(user_id) select id from public.users on conflict(user_id) do nothing;
alter table public.wallet_balances enable row level security;
alter table public.wallet_topups enable row level security;
alter table public.wallet_transactions enable row level security;
drop policy if exists "wallet balance own read" on public.wallet_balances;
create policy "wallet balance own read" on public.wallet_balances for select to authenticated using(user_id=(select auth.uid()) or public.is_gamevault_admin());
drop policy if exists "wallet topups own read" on public.wallet_topups;
create policy "wallet topups own read" on public.wallet_topups for select to authenticated using(user_id=(select auth.uid()) or public.is_gamevault_admin());
drop policy if exists "wallet transactions own read" on public.wallet_transactions;
create policy "wallet transactions own read" on public.wallet_transactions for select to authenticated using(user_id=(select auth.uid()) or public.is_gamevault_admin());
grant select on public.wallet_balances,public.wallet_topups,public.wallet_transactions to authenticated;

create or replace function public.create_wallet_topup(p_amount_vnd bigint) returns uuid
language plpgsql security definer set search_path='' as $$
declare v_user uuid:=auth.uid(); v_code text; v_id uuid:=gen_random_uuid();
begin
 if v_user is null then raise exception 'Bạn cần đăng nhập.'; end if;
 if p_amount_vnd is null or p_amount_vnd<1000 or p_amount_vnd>100000000 then raise exception 'Số tiền nạp phải từ 1.000đ đến 100.000.000đ.'; end if;
 select account_code into v_code from public.users where id=v_user;
 if v_code is null then raise exception 'Không tìm thấy mã tài khoản.'; end if;
 insert into public.wallet_balances(user_id) values(v_user) on conflict(user_id) do nothing;
 insert into public.wallet_topups(id,user_id,account_code,amount_vnd,transfer_note) values(v_id,v_user,v_code,p_amount_vnd,v_code);
 return v_id;
end; $$;
revoke all on function public.create_wallet_topup(bigint) from public,anon;
grant execute on function public.create_wallet_topup(bigint) to authenticated;

create or replace function public.review_wallet_topup(p_topup_id uuid,p_approve boolean,p_admin_note text default null) returns void
language plpgsql security definer set search_path='' as $$
declare v_topup public.wallet_topups%rowtype;
begin
 if auth.uid() is null or not public.is_gamevault_admin() then raise exception 'Chỉ admin mới được duyệt nạp tiền.'; end if;
 select * into v_topup from public.wallet_topups where id=p_topup_id for update;
 if not found then raise exception 'Không tìm thấy yêu cầu nạp tiền.'; end if;
 if v_topup.status<>'pending' then raise exception 'Yêu cầu này đã được xử lý.'; end if;
 update public.wallet_topups set status=case when p_approve then 'approved' else 'rejected' end,admin_note=p_admin_note,reviewed_by=auth.uid(),reviewed_at=now() where id=p_topup_id;
 if p_approve then
  insert into public.wallet_balances(user_id,balance_vnd) values(v_topup.user_id,v_topup.amount_vnd)
  on conflict(user_id) do update set balance_vnd=public.wallet_balances.balance_vnd+excluded.balance_vnd,updated_at=now();
  insert into public.wallet_transactions(user_id,topup_id,amount_vnd,transaction_type,description,created_by)
  values(v_topup.user_id,p_topup_id,v_topup.amount_vnd,'topup','Nạp tiền thủ công qua chuyển khoản',auth.uid());
 end if;
end; $$;
revoke all on function public.review_wallet_topup(uuid,boolean,text) from public,anon;
grant execute on function public.review_wallet_topup(uuid,boolean,text) to authenticated;
