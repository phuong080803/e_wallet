-- Rate limiting schema and helpers
-- Safe to run multiple times (idempotent where possible)

-- 1) Tables
create table if not exists public.rl_login_attempts (
  id bigserial primary key,
  email text,
  user_id uuid,
  ip inet,
  attempted_at timestamptz not null default now(),
  success boolean
);

create table if not exists public.rl_request_logs (
  id bigserial primary key,
  user_id uuid not null,
  endpoint text,
  ip inet,
  created_at timestamptz not null default now()
);

create table if not exists public.rl_otp_attempts (
  id bigserial primary key,
  user_id uuid not null,
  context text,
  ip inet,
  created_at timestamptz not null default now(),
  success boolean
);

-- 2) Indexes
create index if not exists idx_rl_login_attempts_email_time on public.rl_login_attempts (email, attempted_at desc);
create index if not exists idx_rl_login_attempts_ip_time on public.rl_login_attempts (ip, attempted_at desc);
create index if not exists idx_rl_login_attempts_user_time on public.rl_login_attempts (user_id, attempted_at desc);

create index if not exists idx_rl_request_logs_user_time on public.rl_request_logs (user_id, created_at desc);
create index if not exists idx_rl_request_logs_endpoint_time on public.rl_request_logs (endpoint, created_at desc);

create index if not exists idx_rl_otp_attempts_user_time on public.rl_otp_attempts (user_id, created_at desc);
create index if not exists idx_rl_otp_attempts_context_time on public.rl_otp_attempts (context, created_at desc);

-- 3) RLS (optional but recommended)
alter table public.rl_login_attempts enable row level security;
alter table public.rl_request_logs enable row level security;
alter table public.rl_otp_attempts enable row level security;

-- Policies: allow authenticated users to insert their own logs; restrict read
do $$ begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'rl_login_attempts' and policyname = 'rl_login_attempts_insert'
  ) then
    create policy rl_login_attempts_insert on public.rl_login_attempts
      for insert to public with check (true);
  end if;
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'rl_login_attempts' and policyname = 'rl_login_attempts_select_self'
  ) then
    create policy rl_login_attempts_select_self on public.rl_login_attempts
      for select to authenticated using (coalesce(user_id, auth.uid()) = auth.uid());
  end if;
end $$;

do $$ begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'rl_request_logs' and policyname = 'rl_request_logs_insert'
  ) then
    create policy rl_request_logs_insert on public.rl_request_logs
      for insert to public with check (true);
  end if;
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'rl_request_logs' and policyname = 'rl_request_logs_select_self'
  ) then
    create policy rl_request_logs_select_self on public.rl_request_logs
      for select to authenticated using (user_id = auth.uid());
  end if;
end $$;

do $$ begin
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'rl_otp_attempts' and policyname = 'rl_otp_attempts_insert'
  ) then
    create policy rl_otp_attempts_insert on public.rl_otp_attempts
      for insert to public with check (true);
  end if;
  if not exists (
    select 1 from pg_policies where schemaname = 'public' and tablename = 'rl_otp_attempts' and policyname = 'rl_otp_attempts_select_self'
  ) then
    create policy rl_otp_attempts_select_self on public.rl_otp_attempts
      for select to authenticated using (user_id = auth.uid());
  end if;
end $$;

-- 4) Helper functions (SECURITY DEFINER so they can count rows bypassing RLS)
create or replace function public.assert_login_allowed(
  p_email text,
  p_ip inet,
  p_max_attempts integer default 5,
  p_window_seconds integer default 900 -- 15 minutes
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  -- Block if too many attempts by email or IP in window
  if p_email is not null then
    if (
      select count(*) from public.rl_login_attempts
      where email = p_email
        and attempted_at > now() - make_interval(secs => p_window_seconds)
    ) >= p_max_attempts then
      raise exception 'rate_limit_exceeded: too many login attempts for email' using errcode = '42501';
    end if;
  end if;

  if p_ip is not null then
    if (
      select count(*) from public.rl_login_attempts
      where ip = p_ip
        and attempted_at > now() - make_interval(secs => p_window_seconds)
    ) >= p_max_attempts then
      raise exception 'rate_limit_exceeded: too many login attempts from IP' using errcode = '42501';
    end if;
  end if;
end$$;

create or replace function public.log_login_attempt(
  p_email text,
  p_user_id uuid,
  p_ip inet,
  p_success boolean
) returns void
language sql
security definer
set search_path = public
as $$
  insert into public.rl_login_attempts(email, user_id, ip, success)
  values (p_email, p_user_id, p_ip, p_success);
$$;

create or replace function public.assert_user_request_allowed(
  p_user_id uuid,
  p_max_per_minute integer default 60
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if (
    select count(*) from public.rl_request_logs
    where user_id = p_user_id
      and created_at > now() - interval '1 minute'
  ) >= p_max_per_minute then
    raise exception 'rate_limit_exceeded: too many requests per minute' using errcode = '42501';
  end if;
end$$;

create or replace function public.log_user_request(
  p_user_id uuid,
  p_endpoint text,
  p_ip inet
) returns void
language sql
security definer
set search_path = public
as $$
  insert into public.rl_request_logs(user_id, endpoint, ip)
  values (p_user_id, p_endpoint, p_ip);
$$;

create or replace function public.assert_otp_verify_allowed(
  p_user_id uuid,
  p_max_attempts integer default 5,
  p_window_seconds integer default 300 -- 5 minutes
) returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if (
    select count(*) from public.rl_otp_attempts
    where user_id = p_user_id
      and created_at > now() - make_interval(secs => p_window_seconds)
  ) >= p_max_attempts then
    raise exception 'rate_limit_exceeded: too many OTP attempts' using errcode = '42501';
  end if;
end$$;

create or replace function public.log_otp_attempt(
  p_user_id uuid,
  p_context text,
  p_ip inet,
  p_success boolean
) returns void
language sql
security definer
set search_path = public
as $$
  insert into public.rl_otp_attempts(user_id, context, ip, success)
  values (p_user_id, p_context, p_ip, p_success);
$$;

-- 5) Grants so RPC can be called by authenticated users
grant execute on function public.assert_login_allowed(text, inet, integer, integer) to authenticated, anon;
grant execute on function public.log_login_attempt(text, uuid, inet, boolean) to authenticated, anon;

grant execute on function public.assert_user_request_allowed(uuid, integer) to authenticated;
grant execute on function public.log_user_request(uuid, text, inet) to authenticated;

grant execute on function public.assert_otp_verify_allowed(uuid, integer, integer) to authenticated;
grant execute on function public.log_otp_attempt(uuid, text, inet, boolean) to authenticated;
