create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  birth_date date,
  gender text check (gender in ('Male','Female')),
  country text not null default 'Kenya',
  bio text not null default '',
  hobbies text[] not null default '{}',
  photo_url text,
  vip_tier text not null default 'free' check (vip_tier in ('free','silver','gold','platinum','diamond')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.profile_photos (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  photo_url text not null,
  position int not null default 0,
  created_at timestamptz not null default now()
);
create table if not exists public.wallets (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  balance bigint not null default 100 check (balance >= 0),
  updated_at timestamptz not null default now()
);
create table if not exists public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  amount bigint not null,
  reason text not null,
  reference_id uuid,
  created_at timestamptz not null default now()
);
create table if not exists public.likes (
  id uuid primary key default gen_random_uuid(),
  from_user uuid not null references public.profiles(id) on delete cascade,
  to_user uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique(from_user,to_user), check(from_user <> to_user)
);
create table if not exists public.matches (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references public.profiles(id) on delete cascade,
  user_b uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  check(user_a <> user_b),
  unique(user_a,user_b)
);
create table if not exists public.follows (
  follower_id uuid not null references public.profiles(id) on delete cascade,
  following_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(follower_id,following_id), check(follower_id <> following_id)
);
create table if not exists public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'pending' check(status in ('pending','accepted','declined')),
  created_at timestamptz not null default now(),
  unique(sender_id,receiver_id), check(sender_id <> receiver_id)
);
create table if not exists public.profile_visits (
  id uuid primary key default gen_random_uuid(),
  visitor_id uuid not null references public.profiles(id) on delete cascade,
  visited_id uuid not null references public.profiles(id) on delete cascade,
  visited_at timestamptz not null default now(),
  check(visitor_id <> visited_id)
);
create index if not exists profile_visits_visited_idx on public.profile_visits(visited_id, visited_at desc);
create table if not exists public.gifts_catalog (
  id int primary key,
  name text not null unique,
  icon text not null,
  price bigint not null check(price > 0),
  category text not null default 'Love'
);
insert into public.gifts_catalog(id,name,icon,price,category) values
(1,'Single Rose','🌹',10,'Flowers'),
(2,'Red Rose','🌹',15,'Flowers'),
(3,'Pink Rose','🌷',20,'Flowers'),
(4,'White Rose','🥀',25,'Flowers'),
(5,'Tulip','🌷',30,'Flowers'),
(6,'Sunflower','🌻',35,'Flowers'),
(7,'Lily','💐',40,'Flowers'),
(8,'Orchid','🪻',50,'Flowers'),
(9,'Daisy','🌼',55,'Flowers'),
(10,'Lavender Bouquet','💐',70,'Flowers'),
(11,'Wildflower Bunch','🌸',80,'Flowers'),
(12,'Rose Bouquet','💐',100,'Flowers'),
(13,'Heart Bouquet','💐',150,'Flowers'),
(14,'Rainbow Bouquet','🌈',200,'Flowers'),
(15,'Golden Bouquet','💐',300,'Flowers'),
(16,'Love Note','💌',10,'Romance'),
(17,'Heart Sticker','💟',15,'Romance'),
(18,'Kiss Mark','💋',20,'Romance'),
(19,'Love Letter','💌',25,'Romance'),
(20,'Cupid Arrow','💘',30,'Romance'),
(21,'Heart Balloon','🎈',35,'Romance'),
(22,'Pair of Hearts','💕',40,'Romance'),
(23,'Love Potion','🧪',50,'Romance'),
(24,'Promise Ring','💍',75,'Romance'),
(25,'Silver Ring','💍',100,'Romance'),
(26,'Gold Ring','💍',200,'Romance'),
(27,'Diamond Ring','💎',500,'Romance'),
(28,'Love Lock','🔒',650,'Romance'),
(29,'Heart Locket','💝',800,'Romance'),
(30,'Forever Heart','💖',1000,'Romance'),
(31,'Coffee','☕',10,'Treats'),
(32,'Tea Cup','🍵',15,'Treats'),
(33,'Chocolate Bar','🍫',20,'Treats'),
(34,'Cupcake','🧁',25,'Treats'),
(35,'Donut','🍩',30,'Treats'),
(36,'Cookie','🍪',35,'Treats'),
(37,'Ice Cream','🍦',40,'Treats'),
(38,'Strawberry Cake','🍰',50,'Treats'),
(39,'Candy Box','🍬',60,'Treats'),
(40,'Macarons','🍡',75,'Treats'),
(41,'Pizza Slice','🍕',80,'Treats'),
(42,'Sushi Set','🍣',100,'Treats'),
(43,'Fruit Basket','🍉',120,'Treats'),
(44,'Luxury Chocolates','🍫',150,'Treats'),
(45,'Birthday Cake','🎂',200,'Treats'),
(46,'Teddy Bear','🧸',25,'Plush'),
(47,'Tiny Bunny','🐰',30,'Plush'),
(48,'Kitten Plush','🐱',35,'Plush'),
(49,'Puppy Plush','🐶',40,'Plush'),
(50,'Panda Plush','🐼',50,'Plush'),
(51,'Fox Plush','🦊',60,'Plush'),
(52,'Koala Plush','🐨',70,'Plush'),
(53,'Unicorn Plush','🦄',100,'Plush'),
(54,'Giant Teddy','🧸',150,'Plush'),
(55,'Golden Teddy','🧸',250,'Plush'),
(56,'Baby Elephant','🐘',300,'Plush'),
(57,'Royal Bear','🧸',500,'Plush'),
(58,'Cute Penguin','🐧',550,'Plush'),
(59,'Dancing Dino','🦖',600,'Plush'),
(60,'Rainbow Unicorn','🦄',750,'Plush'),
(61,'Sparkle','✨',10,'Sparkles'),
(62,'Shooting Star','🌠',20,'Sparkles'),
(63,'Moon Glow','🌙',30,'Sparkles'),
(64,'Sunshine','☀️',40,'Sparkles'),
(65,'Rainbow','🌈',50,'Sparkles'),
(66,'Firework','🎆',60,'Sparkles'),
(67,'Comet','☄️',75,'Sparkles'),
(68,'Aurora','🌌',100,'Sparkles'),
(69,'Galaxy','🌌',150,'Sparkles'),
(70,'Meteor Shower','🌠',200,'Sparkles'),
(71,'Silver Star','⭐',250,'Sparkles'),
(72,'Golden Star','🌟',350,'Sparkles'),
(73,'Crystal Heart','💎',500,'Sparkles'),
(74,'Moonstone','🔮',650,'Sparkles'),
(75,'Cosmic Crown','👑',900,'Sparkles'),
(76,'Cup of Cocoa','☕',15,'Cozy'),
(77,'Warm Blanket','🧣',25,'Cozy'),
(78,'Cozy Socks','🧦',30,'Cozy'),
(79,'Little Candle','🕯️',35,'Cozy'),
(80,'Book Gift','📚',50,'Cozy'),
(81,'Music Notes','🎶',60,'Cozy'),
(82,'Headphones','🎧',75,'Cozy'),
(83,'Vinyl Record','💿',100,'Cozy'),
(84,'Movie Night','🎬',125,'Cozy'),
(85,'Game Controller','🎮',150,'Cozy'),
(86,'Camera','📸',175,'Cozy'),
(87,'Travel Ticket','🎟️',200,'Adventure'),
(88,'Airplane','✈️',250,'Adventure'),
(89,'Mountain Trip','🏔️',300,'Adventure'),
(90,'Ocean Escape','🌊',350,'Adventure'),
(91,'Camping Kit','⛺',400,'Adventure'),
(92,'Hot Air Balloon','🎈',450,'Adventure'),
(93,'Sailing Boat','⛵',550,'Adventure'),
(94,'Sports Car','🏎️',700,'Adventure'),
(95,'Yacht Ride','🛥️',900,'Adventure'),
(96,'Tiny Crown','👑',100,'Luxury'),
(97,'Silver Crown','👑',250,'Luxury'),
(98,'Gold Crown','👑',500,'Luxury'),
(99,'Royal Crown','👑',1000,'Luxury'),
(100,'Pearl Necklace','📿',1200,'Luxury'),
(101,'Luxury Watch','⌚',1500,'Luxury'),
(102,'Diamond Earrings','💎',2000,'Luxury'),
(103,'Golden Trophy','🏆',2500,'Luxury'),
(104,'Treasure Chest','🪙',3000,'Luxury'),
(105,'Magic Wand','🪄',3500,'Fantasy'),
(106,'Dragon Egg','🥚',4000,'Fantasy'),
(107,'Baby Dragon','🐉',4500,'Fantasy'),
(108,'Phoenix Feather','🪶',5000,'Fantasy'),
(109,'Enchanted Castle','🏰',6000,'Fantasy'),
(110,'Crystal Palace','🏰',7000,'Fantasy'),
(111,'Golden Unicorn','🦄',8000,'Fantasy'),
(112,'Heart Galaxy','💖',9000,'Fantasy'),
(113,'Diamond Galaxy','💎',10000,'Fantasy'),
(114,'HeartMatch Legend','💝',15000,'Exclusive'),
(115,'Eternal Flame','🔥',20000,'Exclusive'),
(116,'World of Hearts','🌍',25000,'Exclusive'),
(117,'Infinity Love','♾️',30000,'Exclusive'),
(118,'Celestial Embrace','🌌',40000,'Exclusive'),
(119,'Diamond Universe','💎',50000,'Exclusive'),
(120,'Royal HeartMatch','👑',75000,'Exclusive'),
(121,'Once in a Lifetime','💖',100000,'Exclusive')
on conflict(id) do nothing;

create table if not exists public.gift_transactions (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid not null references public.profiles(id) on delete cascade,
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  gift_id int not null references public.gifts_catalog(id),
  gift_name text not null,
  gift_icon text not null,
  coin_value bigint not null,
  redeemed_at timestamptz,
  created_at timestamptz not null default now()
);
create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  match_id uuid not null references public.matches(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  body text not null,
  gift_transaction_id uuid references public.gift_transactions(id) on delete set null,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user() returns trigger language plpgsql security definer set search_path=public as $$
begin
  insert into public.profiles(id,display_name) values(new.id,coalesce(new.raw_user_meta_data->>'display_name',''))
  on conflict(id) do nothing;
  insert into public.wallets(user_id,balance) values(new.id,100) on conflict(user_id) do nothing;
  return new;
end; $$;
drop trigger if exists on_auth_user_created_heartmatch on auth.users;
create trigger on_auth_user_created_heartmatch after insert on auth.users for each row execute procedure public.handle_new_user();

create or replace function public.redeem_received_gift(p_gift_id uuid) returns bigint language plpgsql security definer set search_path=public as $$
declare g public.gift_transactions%rowtype; credited bigint;
begin
  select * into g from public.gift_transactions where id=p_gift_id and recipient_id=auth.uid() and redeemed_at is null for update;
  if not found then raise exception 'Gift already redeemed or not available'; end if;
  credited := floor(g.coin_value * 0.90);
  update public.gift_transactions set redeemed_at=now() where id=g.id;
  insert into public.wallets(user_id,balance) values(auth.uid(),0) on conflict(user_id) do nothing;
  update public.wallets set balance=balance+credited,updated_at=now() where user_id=auth.uid();
  insert into public.wallet_transactions(user_id,amount,reason,reference_id) values(auth.uid(),credited,'gift_redemption',g.id);
  return credited;
end; $$;

create or replace function public.send_virtual_gift(p_recipient uuid,p_gift_id int) returns uuid language plpgsql security definer set search_path=public as $$
declare catalog public.gifts_catalog%rowtype; new_id uuid; sender_balance bigint;
begin
  if auth.uid() is null or auth.uid()=p_recipient then raise exception 'Invalid recipient'; end if;
  select * into catalog from public.gifts_catalog where id=p_gift_id;
  if not found then raise exception 'Gift not found'; end if;
  select balance into sender_balance from public.wallets where user_id=auth.uid() for update;
  if coalesce(sender_balance,0)<catalog.price then raise exception 'Not enough coins'; end if;
  update public.wallets set balance=balance-catalog.price,updated_at=now() where user_id=auth.uid();
  insert into public.wallets(user_id,balance) values(p_recipient,0) on conflict(user_id) do nothing;
  insert into public.gift_transactions(sender_id,recipient_id,gift_id,gift_name,gift_icon,coin_value)
  values(auth.uid(),p_recipient,catalog.id,catalog.name,catalog.icon,catalog.price) returning id into new_id;
  insert into public.wallet_transactions(user_id,amount,reason,reference_id) values(auth.uid(),-catalog.price,'gift_sent',new_id);
  return new_id;
end; $$;

alter table public.profiles enable row level security;
alter table public.profile_photos enable row level security;
alter table public.wallets enable row level security;
alter table public.wallet_transactions enable row level security;
alter table public.likes enable row level security;
alter table public.matches enable row level security;
alter table public.follows enable row level security;
alter table public.friend_requests enable row level security;
alter table public.profile_visits enable row level security;
alter table public.gifts_catalog enable row level security;
alter table public.gift_transactions enable row level security;
alter table public.messages enable row level security;

create policy "Profiles readable by signed in users" on public.profiles for select to authenticated using (true);
create policy "Users update own profile" on public.profiles for update to authenticated using (auth.uid()=id) with check (auth.uid()=id);
create policy "Users insert own profile" on public.profiles for insert to authenticated with check (auth.uid()=id);
create policy "Gallery readable by signed in users" on public.profile_photos for select to authenticated using (true);
create policy "Own gallery insert" on public.profile_photos for insert to authenticated with check (auth.uid()=user_id and (select count(*) from public.profile_photos p where p.user_id=auth.uid()) < 10);
create policy "Own gallery delete" on public.profile_photos for delete to authenticated using (auth.uid()=user_id);
create policy "Own wallet read" on public.wallets for select to authenticated using (auth.uid()=user_id);
create policy "Own transactions read" on public.wallet_transactions for select to authenticated using (auth.uid()=user_id);
create policy "Catalog visible" on public.gifts_catalog for select to authenticated using (true);
create policy "Likes visible to participants" on public.likes for select to authenticated using (auth.uid()=from_user or auth.uid()=to_user);
create policy "Users create own likes" on public.likes for insert to authenticated with check (auth.uid()=from_user);
create policy "Matches visible to participants" on public.matches for select to authenticated using (auth.uid()=user_a or auth.uid()=user_b);
create policy "Follow lists visible" on public.follows for select to authenticated using (true);
create policy "Users follow themselves as actor" on public.follows for insert to authenticated with check (auth.uid()=follower_id);
create policy "Users unfollow themselves" on public.follows for delete to authenticated using (auth.uid()=follower_id);
create policy "Friend requests visible to participants" on public.friend_requests for select to authenticated using (auth.uid()=sender_id or auth.uid()=receiver_id);
create policy "Send own friend request" on public.friend_requests for insert to authenticated with check (auth.uid()=sender_id);
create policy "Receiver responds to request" on public.friend_requests for update to authenticated using (auth.uid()=receiver_id) with check (auth.uid()=receiver_id);
create policy "Catalog gifts visible to sender or recipient" on public.gift_transactions for select to authenticated using (auth.uid()=sender_id or auth.uid()=recipient_id);
create policy "Message participants can read" on public.messages for select to authenticated using (exists(select 1 from public.matches m where m.id=match_id and (m.user_a=auth.uid() or m.user_b=auth.uid())));
create policy "Match participants can send messages" on public.messages for insert to authenticated with check (auth.uid()=sender_id and exists(select 1 from public.matches m where m.id=match_id and (m.user_a=auth.uid() or m.user_b=auth.uid())));

create or replace function public.record_profile_visit(p_profile_id uuid) returns void language plpgsql security definer set search_path=public as $$
begin
 if auth.uid() is null or auth.uid()=p_profile_id then return; end if;
 insert into public.profile_visits(visitor_id,visited_id,visited_at) values(auth.uid(),p_profile_id,now());
end; $$;
create policy "Visitors see own outgoing visits" on public.profile_visits for select to authenticated using (auth.uid()=visitor_id);
create policy "Silver VIP and above see incoming visits" on public.profile_visits for select to authenticated using (auth.uid()=visited_id and exists(select 1 from public.profiles p where p.id=auth.uid() and p.vip_tier in ('silver','gold','platinum','diamond')));
create policy "Users record own visit" on public.profile_visits for insert to authenticated with check (auth.uid()=visitor_id and visitor_id<>visited_id);

grant execute on function public.redeem_received_gift(uuid) to authenticated;
grant execute on function public.send_virtual_gift(uuid,int) to authenticated;
grant execute on function public.record_profile_visit(uuid) to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('profile-media','profile-media',true,5242880,array['image/jpeg','image/png','image/webp'])
on conflict(id) do nothing;
create policy "Public can view profile media" on storage.objects for select using (bucket_id='profile-media');
create policy "Users upload to own profile media folder" on storage.objects for insert to authenticated with check (bucket_id='profile-media' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "Users update own profile media" on storage.objects for update to authenticated using (bucket_id='profile-media' and (storage.foldername(name))[1]=auth.uid()::text) with check (bucket_id='profile-media' and (storage.foldername(name))[1]=auth.uid()::text);
create policy "Users delete own profile media" on storage.objects for delete to authenticated using (bucket_id='profile-media' and (storage.foldername(name))[1]=auth.uid()::text);
