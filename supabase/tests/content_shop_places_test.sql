-- pgTAP tests for the shop / content / places schema.
begin;
create extension if not exists pgtap with schema extensions;
select plan(36);

-- Fixtures (as the table owner) ---------------------------------------------
insert into auth.users (id, aud, role) values
  ('aaaaaaaa-0000-0000-0000-00000000000a', 'authenticated', 'authenticated'),
  ('bbbbbbbb-0000-0000-0000-00000000000b', 'authenticated', 'authenticated');

insert into public.products (id, name, category, price_cents, active)
values ('test-inactive', 'Retired item', 'apparel', 100, false);

insert into public.orders (id, user_id, total_cents, currency)
values ('cccccccc-0000-0000-0000-00000000000c', 'bbbbbbbb-0000-0000-0000-00000000000b', 5900, 'USD');
insert into public.order_items (order_id, product_id, quantity, price_cents)
values ('cccccccc-0000-0000-0000-00000000000c', 'home-training-set', 1, 5900);
insert into public.challenge_participants (challenge_id, user_id)
values ('steps-7', 'bbbbbbbb-0000-0000-0000-00000000000b');

-- Structure -----------------------------------------------------------------
select is(
  (select count(*)::int from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public' and c.relkind = 'r' and c.relrowsecurity
      and c.relname in ('products','orders','order_items','programs','articles',
                        'challenges','challenge_participants','places')),
  8, 'row level security is enabled on all eight new tables');

-- Anonymous visitor ---------------------------------------------------------
set local role anon;
select is((select count(*)::int from public.products), 8, 'anon reads only active products');
select is((select count(*)::int from public.places), 22, 'anon reads places');
select is((select count(*)::int from public.programs), 3, 'anon reads programs');
select is((select count(*)::int from public.articles), 3, 'anon reads articles');
select is((select count(*)::int from public.challenges), 1, 'anon reads challenges');
select throws_ok($$select * from public.orders$$, '42501', null, 'anon cannot read orders');
select throws_ok($$select * from public.order_items$$, '42501', null, 'anon cannot read order items');
select throws_ok($$select * from public.challenge_participants$$, '42501', null, 'anon cannot read participants');
select throws_ok($$select public.place_order('[{"product_id":"home-training-set","quantity":1}]'::jsonb)$$,
  '42501', null, 'anon cannot call place_order');
select throws_ok($$update public.products set price_cents = 1$$, '42501', null, 'anon cannot change prices');
reset role;

-- User A --------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub":"aaaaaaaa-0000-0000-0000-00000000000a","role":"authenticated"}';

select is((select count(*)::int from public.orders), 0, 'A cannot see B''s orders');
select is((select count(*)::int from public.order_items), 0, 'A cannot see B''s order items');
select throws_ok(
  $$insert into public.orders (user_id, total_cents, currency) values ('aaaaaaaa-0000-0000-0000-00000000000a', 1, 'USD')$$,
  '42501', null, 'direct insert into orders fails');
select throws_ok(
  $$insert into public.order_items (order_id, product_id, quantity, price_cents) values ('cccccccc-0000-0000-0000-00000000000c', 'fitrix-tee', 1, 0)$$,
  '42501', null, 'direct insert into order_items fails');
select throws_ok($$update public.orders set total_cents = 0$$, '42501', null, 'direct update of orders fails');
select throws_ok($$update public.products set price_cents = 1$$, '42501', null, 'authenticated cannot change prices');

select throws_ok($$select public.place_order('[{"product_id":"home-training-set","quantity":0}]'::jsonb)$$,
  '23514', null, 'quantity 0 is rejected');
select throws_ok($$select public.place_order('[{"product_id":"home-training-set","quantity":21}]'::jsonb)$$,
  '23514', null, 'quantity 21 is rejected');
select throws_ok($$select public.place_order('[{"product_id":"no-such-thing","quantity":1}]'::jsonb)$$,
  '22023', null, 'unknown product is rejected');
select throws_ok($$select public.place_order('[{"product_id":"test-inactive","quantity":1}]'::jsonb)$$,
  '22023', null, 'inactive product is rejected');
select throws_ok($$select public.place_order('[]'::jsonb)$$, '22023', null, 'empty cart is rejected');
select throws_ok($$select public.place_order('{"product_id":"fitrix-tee","quantity":1}'::jsonb)$$,
  '22023', null, 'non-array payload is rejected');
select throws_ok($$select public.place_order('[{"product_id":"fitrix-tee","quantity":1},{"product_id":"fitrix-tee","quantity":1}]'::jsonb)$$,
  '23505', null, 'duplicate lines are rejected');
select is((select count(*)::int from public.orders), 0, 'failed attempts leave no order behind');

-- A valid order: prices come from the catalog even if the payload lies.
select lives_ok($$select public.place_order(
  '[{"product_id":"home-training-set","quantity":2,"price_cents":1},{"product_id":"resistance-bands","quantity":1,"price_cents":1}]'::jsonb)$$,
  'valid order is placed');
select is((select total_cents from public.orders), 5900 * 2 + 1600,
  'total is the catalog price x quantity, not the client price');
select is((select count(*)::int from public.order_items where price_cents = 1), 0,
  'client-supplied price_cents is ignored');

-- Challenges
select lives_ok($$insert into public.challenge_participants (challenge_id, user_id) values ('steps-7', 'aaaaaaaa-0000-0000-0000-00000000000a')$$,
  'A can join a challenge');
select throws_ok($$insert into public.challenge_participants (challenge_id, user_id) values ('steps-7', 'bbbbbbbb-0000-0000-0000-00000000000b')$$,
  '42501', null, 'A cannot join on behalf of B');

-- Signed out (no sub claim)
set local request.jwt.claims = '{}';
select throws_ok($$select public.place_order('[{"product_id":"home-training-set","quantity":1}]'::jsonb)$$,
  '28000', null, 'signed-out call raises');

-- Back to A: leave the challenge, and B's row is untouchable.
set local request.jwt.claims = '{"sub":"aaaaaaaa-0000-0000-0000-00000000000a","role":"authenticated"}';
select is((select count(*)::int from public.challenge_participants), 1, 'A sees only own participation');
delete from public.challenge_participants;
select is((select count(*)::int from public.challenge_participants), 0, 'A left the challenge');
reset role;
select is((select count(*)::int from public.challenge_participants where user_id = 'bbbbbbbb-0000-0000-0000-00000000000b'),
  1, 'B''s participation survived A''s delete');

-- Cascade -------------------------------------------------------------------
insert into public.challenge_participants (challenge_id, user_id)
values ('steps-7', 'aaaaaaaa-0000-0000-0000-00000000000a');
delete from auth.users where id = 'aaaaaaaa-0000-0000-0000-00000000000a';
select is((select count(*)::int from public.orders where user_id = 'aaaaaaaa-0000-0000-0000-00000000000a'), 0,
  'deleting the user deletes their orders');
select is((select count(*)::int from public.challenge_participants where user_id = 'aaaaaaaa-0000-0000-0000-00000000000a'), 0,
  'deleting the user deletes their participations');

select * from finish();
rollback;
