-- Security hardening and server-side matching for HeartMatch.
-- Apply after 202610290001_heartmatch.sql.

-- VIP tier must only be changed by a trusted admin/server, never by a browser update.
revoke update on public.profiles from authenticated;
grant update (display_name,birth_date,gender,country,bio,hobbies,photo_url,updated_at) on public.profiles to authenticated;
revoke insert on public.profiles from authenticated;
grant insert (id,display_name,birth_date,gender,country,bio,hobbies,photo_url) on public.profiles to authenticated;

create or replace function public.guard_profile_age() returns trigger language plpgsql set search_path=public as $$
begin
  if new.birth_date is not null and new.birth_date > (current_date - interval '18 years')::date then
    raise exception 'HeartMatch is for adults aged 18 and over';
  end if;
  if tg_op='UPDATE' and old.birth_date is not null and new.birth_date is distinct from old.birth_date then
    raise exception 'Date of birth cannot be changed after it has been set';
  end if;
  if tg_op='UPDATE' and new.vip_tier is distinct from old.vip_tier then
    raise exception 'VIP tier changes must be processed by the membership service';
  end if;
  return new;
end; $$;
drop trigger if exists guard_profile_age_heartmatch on public.profiles;
create trigger guard_profile_age_heartmatch before insert or update on public.profiles for each row execute procedure public.guard_profile_age();

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
declare dob date;
begin
  if coalesce(new.raw_user_meta_data->>'birth_date','') <> '' then
    dob := (new.raw_user_meta_data->>'birth_date')::date;
  end if;
  if dob is null or dob > (current_date - interval '18 years')::date then
    raise exception 'HeartMatch is for adults aged 18 and over';
  end if;
  insert into public.profiles(id,display_name,birth_date,gender,country)
  values(new.id,coalesce(new.raw_user_meta_data->>'display_name',''),dob,new.raw_user_meta_data->>'gender',coalesce(new.raw_user_meta_data->>'country','Kenya'))
  on conflict(id) do nothing;
  insert into public.wallets(user_id,balance) values(new.id,100) on conflict(user_id) do nothing;
  return new;
end; $$;

create or replace function public.send_like(p_target uuid) returns boolean language plpgsql security definer set search_path=public as $$
declare matched boolean := false; a uuid; b uuid;
begin
  if auth.uid() is null or p_target is null or p_target=auth.uid() then raise exception 'Invalid profile'; end if;
  if not exists(select 1 from public.profiles where id=p_target) then raise exception 'Profile not found'; end if;
  insert into public.likes(from_user,to_user) values(auth.uid(),p_target) on conflict(from_user,to_user) do nothing;
  select exists(select 1 from public.likes where from_user=p_target and to_user=auth.uid()) into matched;
  if matched then
    a := least(auth.uid(),p_target); b := greatest(auth.uid(),p_target);
    insert into public.matches(user_a,user_b) values(a,b) on conflict(user_a,user_b) do nothing;
  end if;
  return matched;
end; $$;
grant execute on function public.send_like(uuid) to authenticated;
