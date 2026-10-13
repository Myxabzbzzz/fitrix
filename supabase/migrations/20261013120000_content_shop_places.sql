-- FITRIX content, shop and places.
--
-- Public catalog tables (products, programs, articles, challenges, places) are
-- readable by everyone and written only by migrations / the service role.
-- Per-user rows (orders, order_items, challenge_participants) are visible to
-- their owner only. Orders are created exclusively through place_order(), so
-- prices always come from the catalog, never from the client.

-- ---------------------------------------------------------------------------
-- Shop
-- ---------------------------------------------------------------------------
create table public.products (
  id text primary key check (char_length(id) <= 60),
  name text not null check (char_length(name) between 1 and 100),
  category text not null check (category in ('supplements', 'equipment', 'apparel')),
  price_cents integer not null check (price_cents between 0 and 10000000),
  currency text not null default 'USD' check (currency in ('USD', 'UZS')),
  image text check (char_length(image) <= 100),       -- asset name, e.g. 'tile_workouts'
  word text check (char_length(word) <= 12),           -- typographic placeholder when no image
  position integer not null default 0,
  active boolean not null default true
);

create table public.orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  status text not null default 'placed' check (status in ('placed', 'cancelled', 'fulfilled')),
  total_cents integer not null check (total_cents >= 0),
  currency text not null check (currency in ('USD', 'UZS')),
  created_at timestamptz not null default now()
);
create index orders_user_id_idx on public.orders (user_id, created_at desc);

create table public.order_items (
  order_id uuid not null references public.orders (id) on delete cascade,
  product_id text not null references public.products (id),
  quantity integer not null check (quantity between 1 and 20),
  price_cents integer not null check (price_cents >= 0),
  primary key (order_id, product_id)
);

-- ---------------------------------------------------------------------------
-- Discover
-- ---------------------------------------------------------------------------
create table public.programs (
  id text primary key,
  title text not null,
  meta text not null,
  level text not null check (level in ('beginner', 'medium', 'advanced')),
  sport text not null,
  image text,
  position integer not null default 0
);

create table public.articles (
  id text primary key,
  tag text not null,
  title text not null,
  minutes smallint not null check (minutes between 1 and 60),
  body text not null,
  position integer not null default 0
);

create table public.challenges (
  id text primary key,
  title text not null,
  description text not null,
  days smallint not null check (days between 1 and 60),
  daily_target text not null,
  starts_on date not null,
  ends_on date not null,
  check (ends_on >= starts_on)
);

create table public.challenge_participants (
  challenge_id text not null references public.challenges (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (challenge_id, user_id)
);
create index challenge_participants_user_id_idx on public.challenge_participants (user_id);

-- ---------------------------------------------------------------------------
-- Map
-- ---------------------------------------------------------------------------
create table public.places (
  id text primary key,
  name text not null,
  kind text not null check (kind in ('gyms', 'parks', 'tracks', 'pools')),
  type text not null,
  lat double precision not null,
  lon double precision not null,
  hours text,
  note text,
  osm_ref text
);

-- ---------------------------------------------------------------------------
-- Placing an order
-- ---------------------------------------------------------------------------
-- Orders are only created through this function so prices come from the
-- catalog, never from the client. Anything wrong with the cart aborts the
-- whole call, which rolls the order back.
create function public.place_order(p_items jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_order uuid;
  v_total integer := 0;
  v_currency text;
  v_item_currency text;
  v_price integer;
  r record;
begin
  if auth.uid() is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  if jsonb_typeof(p_items) <> 'array'
     or jsonb_array_length(p_items) = 0
     or jsonb_array_length(p_items) > 30 then
    raise exception 'invalid items' using errcode = '22023';
  end if;

  -- The currency is fixed below, once the first catalog row is known.
  insert into public.orders (user_id, total_cents, currency)
  values (auth.uid(), 0, 'USD')
  returning id into v_order;

  for r in
    select (e->>'product_id') as pid, (e->>'quantity')::int as qty
    from jsonb_array_elements(p_items) e
  loop
    select p.price_cents, p.currency into v_price, v_item_currency
    from public.products p
    where p.id = r.pid and p.active;
    if not found then
      raise exception 'unknown product %', r.pid using errcode = '22023';
    end if;
    if v_currency is null then
      v_currency := v_item_currency;
    elsif v_currency <> v_item_currency then
      raise exception 'mixed currencies' using errcode = '22023';
    end if;

    insert into public.order_items (order_id, product_id, quantity, price_cents)
    values (v_order, r.pid, r.qty, v_price);
  end loop;

  select sum(quantity * price_cents) into v_total
  from public.order_items where order_id = v_order;
  update public.orders
  set total_cents = v_total, currency = v_currency
  where id = v_order;
  return v_order;
end
$$;

revoke all on function public.place_order(jsonb) from public, anon;
grant execute on function public.place_order(jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- Row level security
-- ---------------------------------------------------------------------------
alter table public.products enable row level security;
alter table public.orders enable row level security;
alter table public.order_items enable row level security;
alter table public.programs enable row level security;
alter table public.articles enable row level security;
alter table public.challenges enable row level security;
alter table public.challenge_participants enable row level security;
alter table public.places enable row level security;

-- Defence in depth: Supabase grants broad table privileges by default. Strip
-- everything, then give back only what the policies below intend.
revoke all on public.products, public.orders, public.order_items,
  public.programs, public.articles, public.challenges,
  public.challenge_participants, public.places from anon, authenticated;

grant select on public.products, public.programs, public.articles,
  public.challenges, public.places to anon, authenticated;
grant select on public.orders, public.order_items to authenticated;
grant select, delete on public.challenge_participants to authenticated;
-- Column-level insert so clients cannot set joined_at.
grant insert (challenge_id, user_id) on public.challenge_participants to authenticated;

create policy "Catalog: read active"
  on public.products for select to anon, authenticated using (active);
create policy "Programs: read"
  on public.programs for select to anon, authenticated using (true);
create policy "Articles: read"
  on public.articles for select to anon, authenticated using (true);
create policy "Challenges: read"
  on public.challenges for select to anon, authenticated using (true);
create policy "Places: read"
  on public.places for select to anon, authenticated using (true);

create policy "Own orders: read"
  on public.orders for select to authenticated using ((select auth.uid()) = user_id);
create policy "Own order items: read"
  on public.order_items for select to authenticated
  using (exists (select 1 from public.orders o
                 where o.id = order_id and o.user_id = (select auth.uid())));

create policy "Own participation: read"
  on public.challenge_participants for select to authenticated
  using ((select auth.uid()) = user_id);
create policy "Own participation: join"
  on public.challenge_participants for insert to authenticated
  with check ((select auth.uid()) = user_id);
create policy "Own participation: leave"
  on public.challenge_participants for delete to authenticated
  using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------------
-- Seed (mirrors assets/data/seed_content.json, which the app bundles offline)
-- ---------------------------------------------------------------------------
insert into public.products (id, name, category, price_cents, currency, image, word, position, active) values
  ('home-training-set', 'Home training set', 'equipment', 5900, 'USD', 'tile_workouts', null, 1, true),
  ('shaker-meal-planner', 'Shaker & meal planner', 'equipment', 1800, 'USD', 'tile_nutrition', null, 2, true),
  ('whey-protein-2-kg', 'Whey protein, 2 kg', 'supplements', 5400, 'USD', null, 'WHEY', 3, true),
  ('creatine-300-g', 'Creatine, 300 g', 'supplements', 2200, 'USD', null, 'CREA', 4, true),
  ('starter-box', 'Starter box', 'equipment', 3500, 'USD', 'tile_shop', null, 5, true),
  ('fitrix-tee', 'FITRIX tee', 'apparel', 2500, 'USD', null, 'TEE', 6, true),
  ('resistance-bands', 'Resistance bands', 'equipment', 1600, 'USD', null, 'BANDS', 7, true),
  ('training-shorts', 'Training shorts', 'apparel', 2900, 'USD', null, 'SHORTS', 8, true)
on conflict (id) do nothing;

insert into public.programs (id, title, meta, level, sport, image, position) values
  ('strength-base', 'Strength base', '8 weeks · 3× a week', 'beginner', 'gym', 'sport_gym', 1),
  ('fat-burn', 'Fat burn', '6 weeks · 4× a week', 'medium', 'fitness', 'sport_fitness', 2),
  ('ride-100-km', 'Ride 100 km', '4 weeks · 3 rides', 'medium', 'cycling', 'sport_cycling', 3)
on conflict (id) do nothing;

insert into public.articles (id, tag, title, minutes, body, position) values
  ('why-rest-days-make-you-stronger', 'Recovery', 'Why rest days make you stronger', 4, 'Training is the stimulus, but the adaptation happens afterwards. When you lift or run hard, you create small amounts of fatigue and muscle stress. Your body repairs that during rest and comes back slightly more capable.

Most people do well with at least one or two easier days a week. If you train hard four or five days, spread the rest days out rather than stacking them at the end of the week.

Rest does not have to mean sitting still. A short walk, light stretching or an easy ride keeps you moving without adding real load.

Sleep is the biggest recovery tool you have. Aim for a regular bedtime and seven to nine hours when you can.

Watch for signs you need more rest: workouts feeling much harder than usual, poor sleep, or a lack of motivation lasting several days. Take an easy day, then reassess.', 1),
  ('how-much-protein-you-actually-need', 'Nutrition', 'How much protein you actually need', 6, 'Protein helps your body repair and build muscle. Most active adults do well with roughly 1.4 to 2.0 grams per kilogram of body weight per day.

For a 70 kg person that is about 100 to 140 grams a day. If you are just starting out, the lower end is plenty.

Spread it across the day. Three or four meals with 25 to 40 grams each is easier than one huge serving at dinner.

Food first: eggs, chicken, fish, dairy, beans, lentils and tofu all work. A powder is a convenience, not a requirement.

If you have a kidney condition or any health concern, check with a doctor before raising your protein intake.', 2),
  ('bench-press-5-mistakes-that-stall-progress', 'Technique', 'Bench press: 5 mistakes that stall progress', 5, 'The bench press looks simple, but small errors cost strength and put stress on your shoulders. Here are five to fix.

First, a loose setup. Pull your shoulder blades back and down, keep your feet planted and keep your upper back tight against the bench.

Second, flaring your elbows straight out. Aim for roughly 45 to 70 degrees from your torso, so the bar travels over your lower chest.

Third, bouncing the bar off your chest. Lower it under control, touch lightly and press back up.

Fourth, adding weight too fast. Increase in small steps and keep every rep clean. Fifth, skipping warm-up sets: do two or three lighter sets before your working weight.', 3)
on conflict (id) do nothing;

insert into public.challenges (id, title, description, days, daily_target, starts_on, ends_on) values
  ('steps-7', '7-day steps challenge', 'Walk 10,000 steps a day for 7 days in a row, starting the day you join.', 7, '10,000 steps a day', '2026-10-12', '2027-12-31')
on conflict (id) do nothing;

insert into public.places (id, name, kind, type, lat, lon, hours, note, osm_ref) values
  ('proform-gym', 'Proform Gym', 'gyms', 'Gym', 41.31158, 69.27419, null, null, null),
  ('centris', 'Centris', 'gyms', 'Fitness club', 41.3109, 69.27682, null, null, null),
  ('inside-fit', 'Inside Fit', 'gyms', 'Fitness club', 41.2986, 69.28749, 'Mon–Fri 07:00–23:00, Sat 08:00–21:00', null, null),
  ('world-gym', 'World Gym', 'gyms', 'Gym', 41.29531, 69.28177, null, null, null),
  ('chekhov-light-sport-club', 'Chekhov Light Sport Club', 'gyms', 'Fitness club', 41.29912, 69.2764, null, null, null),
  ('chekhov-yulduz', 'Chekhov “Yulduz”', 'gyms', 'Fitness club', 41.32326, 69.28286, null, null, null),
  ('befit', 'BEFIT', 'gyms', 'Fitness club', 41.32427, 69.29595, null, null, null),
  ('amir-timur-square', 'Amir Timur Square', 'parks', 'Park', 41.31143, 69.27966, 'Open 24/7', null, null),
  ('central-park', 'Central Park', 'parks', 'Park', 41.31233, 69.29872, 'Daily 10:00–22:00', null, null),
  ('babur-eco-park', 'Babur Eco Park', 'parks', 'Park', 41.30982, 69.29562, null, null, null),
  ('outdoor-workout-area', 'Outdoor workout area', 'parks', 'Workout bars', 41.30898, 69.29535, 'Daily 06:00–23:00', null, null),
  ('gogol-alley', 'Gogol Alley', 'parks', 'Alley', 41.31604, 69.28675, 'Open 24/7', null, null),
  ('navruz-park', 'Navruz Park', 'parks', 'Park', 41.32581, 69.26698, null, null, null),
  ('yakub-kolas-park', 'Yakub Kolas Park', 'parks', 'Park', 41.3022, 69.27703, null, null, null),
  ('anhor-canal-run', 'Anhor canal run', 'tracks', 'Running route', 41.31642, 69.2653, null, 'Route follows the Anhor canal embankment', null),
  ('pakhtakor-central-stadium', 'Pakhtakor Central Stadium', 'tracks', 'Stadium', 41.31549, 69.26028, null, null, null),
  ('athletics-federation-track', 'Athletics Federation track', 'tracks', 'Running track', 41.3144, 69.26255, null, null, null),
  ('running-track', 'Running track', 'tracks', 'Running track', 41.29991, 69.28065, null, null, null),
  ('yoshlik-sports-complex', 'Yoshlik Sports Complex', 'pools', 'Sports complex', 41.31711, 69.25789, null, null, null),
  ('volna-uz', 'Volna.uz', 'pools', 'Sports club', 41.31988, 69.29869, null, null, null),
  ('olympic-reserve-aquatics-school', 'Olympic Reserve Aquatics School', 'pools', 'Swimming school', 41.29869, 69.25744, null, null, null),
  ('more-water-park', 'More water park', 'pools', 'Water park', 41.31123, 69.30026, 'Daily 09:00–22:00', null, null)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Onboarding answers Felix uses: goal, experience level and sports. Free
-- text from the onboarding chat (quick-reply value or what the user typed).
-- ---------------------------------------------------------------------------
alter table public.profiles
  add column goal text check (char_length(goal) <= 120),
  add column experience text check (char_length(experience) <= 120),
  add column sports text[] not null default '{}'
    check (coalesce(array_length(sports, 1), 0) <= 6);
