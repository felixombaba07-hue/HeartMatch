-- Enforce the 10-photo gallery limit even for concurrent upload requests.
create or replace function public.enforce_gallery_limit() returns trigger language plpgsql set search_path=public as $$
begin
  if (select count(*) from public.profile_photos where user_id=new.user_id) >= 10 then
    raise exception 'Gallery limit is 10 photos';
  end if;
  return new;
end; $$;
drop trigger if exists enforce_gallery_limit_heartmatch on public.profile_photos;
create trigger enforce_gallery_limit_heartmatch before insert on public.profile_photos for each row execute procedure public.enforce_gallery_limit();

-- Enable realtime notifications for the app's live screens where the publication is available.
do $$
declare t text;
begin
  if exists(select 1 from pg_publication where pubname='supabase_realtime') then
    foreach t in array array['profiles','profile_visits','gift_transactions','messages','matches','follows','friend_requests'] loop
      if not exists(select 1 from pg_publication_tables where pubname='supabase_realtime' and schemaname='public' and tablename=t) then
        execute format('alter publication supabase_realtime add table public.%I',t);
      end if;
    end loop;
  end if;
end $$;
