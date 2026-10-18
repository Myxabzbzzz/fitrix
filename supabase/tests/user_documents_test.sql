-- pgTAP tests for public.user_documents.
begin;
create extension if not exists pgtap with schema extensions;
select plan(15);

-- Fixtures (as the table owner) ---------------------------------------------
insert into auth.users (id, aud, role) values
  ('aaaaaaaa-0000-0000-0000-00000000000a', 'authenticated', 'authenticated'),
  ('bbbbbbbb-0000-0000-0000-00000000000b', 'authenticated', 'authenticated');

insert into public.user_documents (user_id, kind, doc_id, data)
values ('bbbbbbbb-0000-0000-0000-00000000000b', 'water', '2026-10-19', '{"ml":500}');

-- Structure -----------------------------------------------------------------
select has_table('public', 'user_documents', 'user_documents exists');
select is(
  (select relrowsecurity from pg_class where oid = 'public.user_documents'::regclass),
  true, 'row level security is enabled');
select is(
  (select count(*)::int from pg_trigger
    where tgrelid = 'public.user_documents'::regclass and tgname = 'user_documents_set_updated_at'),
  1, 'updated_at trigger exists');

-- User A --------------------------------------------------------------------
set local role authenticated;
set local request.jwt.claims = '{"sub":"aaaaaaaa-0000-0000-0000-00000000000a","role":"authenticated"}';

select lives_ok(
  $$insert into public.user_documents (user_id, kind, doc_id, data, updated_at)
    values ('aaaaaaaa-0000-0000-0000-00000000000a', 'checkin', '2026-10-19', '{"mood":3}', '2020-01-01')$$,
  'A inserts own row');
select is((select data->>'mood' from public.user_documents where kind = 'checkin'),
  '3', 'A reads own row');
select is((select count(*)::int from public.user_documents), 1, 'A sees only own rows');
select lives_ok(
  $$update public.user_documents set data = '{"mood":4}' where kind = 'checkin'$$,
  'A updates own row');
select cmp_ok(
  (select updated_at from public.user_documents where kind = 'checkin'),
  '>', '2020-01-01'::timestamptz, 'updated_at advances on update');
select is((select data->>'mood' from public.user_documents where kind = 'checkin'),
  '4', 'update is visible');

select is(
  (select count(*)::int from public.user_documents where user_id = 'bbbbbbbb-0000-0000-0000-00000000000b'),
  0, 'A cannot select B''s row');
update public.user_documents set data = '{"ml":1}' where user_id = 'bbbbbbbb-0000-0000-0000-00000000000b';
select throws_ok(
  $$insert into public.user_documents (user_id, kind, doc_id) values ('bbbbbbbb-0000-0000-0000-00000000000b', 'food', 'x')$$,
  '42501', null, 'A cannot insert a row for B');
select throws_ok(
  $$insert into public.user_documents (user_id, kind, doc_id) values ('aaaaaaaa-0000-0000-0000-00000000000a', 'bogus', 'x')$$,
  '23514', null, 'unknown kind is rejected');
select throws_ok(
  $$insert into public.user_documents (user_id, kind, doc_id) values ('aaaaaaaa-0000-0000-0000-00000000000a', 'food', repeat('x', 101))$$,
  '23514', null, 'doc_id over 100 chars is rejected');
reset role;

select is(
  (select data->>'ml' from public.user_documents where user_id = 'bbbbbbbb-0000-0000-0000-00000000000b'),
  '500', 'A''s update did not touch B''s row');

-- Cascade -------------------------------------------------------------------
delete from auth.users where id = 'aaaaaaaa-0000-0000-0000-00000000000a';
select is(
  (select count(*)::int from public.user_documents where user_id = 'aaaaaaaa-0000-0000-0000-00000000000a'),
  0, 'deleting the auth user cascades');

select * from finish();
rollback;
