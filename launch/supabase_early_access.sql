-- MACRO'S Early Access: tabella iscritti + funzione di iscrizione.
-- Da eseguire una volta in Supabase → SQL Editor (progetto già usato dal totem).
--
-- La tabella non è leggibile né scrivibile direttamente dal browser (RLS attiva, nessuna policy):
-- la landing passa solo dalla funzione join_early_access, che valida i dati e restituisce
-- codice invito e posizione in lista. La classifica delle città si legge dalla dashboard Supabase.

create extension if not exists pgcrypto;

create table if not exists public.early_access (
  id              uuid primary key default gen_random_uuid(),
  created_at      timestamptz not null default now(),
  name            text check (char_length(name) <= 80),
  email           text not null check (char_length(email) <= 160),
  city            text not null check (char_length(city) between 2 and 60),
  goal            text check (goal in ('definizione', 'massa', 'mantenimento', 'performance', 'salute')),
  meals_per_week  text check (meals_per_week in ('1', '2-3', '4-6', '7+')),
  spend           text check (spend in ('<10', '10-13', '13-16', '16+')),
  instagram       text check (char_length(instagram) <= 60),
  ref_code        text not null unique,
  referred_by     text,
  consent         boolean not null,
  utm_source      text check (char_length(utm_source) <= 60),
  utm_campaign    text check (char_length(utm_campaign) <= 60)
);

create unique index if not exists early_access_email_key on public.early_access (lower(email));
create index if not exists early_access_city_idx on public.early_access (city);
create index if not exists early_access_referred_by_idx on public.early_access (referred_by);

alter table public.early_access enable row level security;
revoke all on public.early_access from anon, authenticated;

create or replace function public.join_early_access(
  p_name text, p_email text, p_city text, p_goal text, p_meals text, p_spend text,
  p_instagram text, p_referred_by text, p_consent boolean,
  p_utm_source text default null, p_utm_campaign text default null
) returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_created timestamptz;
begin
  if p_consent is not true then
    raise exception 'consent_required';
  end if;
  if p_email is null or p_email !~* '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'invalid_email';
  end if;

  select ref_code, created_at into v_code, v_created
    from early_access where lower(email) = lower(trim(p_email));

  if v_code is null then
    loop
      v_code := upper(substr(encode(gen_random_bytes(6), 'hex'), 1, 6));
      exit when not exists (select 1 from early_access where ref_code = v_code);
    end loop;
    insert into early_access (name, email, city, goal, meals_per_week, spend, instagram,
                              ref_code, referred_by, consent, utm_source, utm_campaign)
    values (nullif(trim(p_name), ''), lower(trim(p_email)), initcap(trim(p_city)),
            nullif(p_goal, ''), nullif(p_meals, ''), nullif(p_spend, ''),
            nullif(trim(p_instagram), ''), v_code,
            (select ref_code from early_access where ref_code = upper(trim(p_referred_by))),
            true, nullif(p_utm_source, ''), nullif(p_utm_campaign, ''))
    returning created_at into v_created;
  end if;

  return json_build_object(
    'code', v_code,
    'position', (select count(*) from early_access where created_at <= v_created),
    'referrals', (select count(*) from early_access where referred_by = v_code)
  );
end;
$$;

revoke all on function public.join_early_access from public;
grant execute on function public.join_early_access to anon, authenticated;

-- Classifica delle città (solo dashboard / service role: decide dove aprire la Ghost Kitchen).
create or replace view public.early_access_by_city as
  select city,
         count(*)                                                   as iscritti,
         count(*) filter (where meals_per_week in ('2-3', '4-6', '7+')) as iscritti_2_pasti_piu,
         round(100.0 * count(*) filter (where meals_per_week in ('2-3', '4-6', '7+')) / count(*), 1) as perc_2_pasti_piu,
         count(*) filter (where referred_by is not null)            as da_invito
    from public.early_access
   group by city
   order by iscritti desc;

revoke all on public.early_access_by_city from anon, authenticated;
