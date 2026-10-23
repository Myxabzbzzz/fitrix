-- pgTAP tests for the health_import document kind.
begin;
create extension if not exists pgtap with schema extensions;
select plan(3);

insert into auth.users (id, aud, role) values
  ('aaaaaaaa-0000-0000-0000-00000000000a', 'authenticated', 'authenticated');

set local role authenticated;
set local request.jwt.claims = '{"sub":"aaaaaaaa-0000-0000-0000-00000000000a","role":"authenticated"}';

select lives_ok(
  $$insert into public.user_documents (user_id, kind, doc_id, data)
    values ('aaaaaaaa-0000-0000-0000-00000000000a', 'health_import', 'w1', '{"source":"Apple Watch"}')$$,
  'owner inserts a health_import document');
select throws_ok(
  $$insert into public.user_documents (user_id, kind, doc_id)
    values ('aaaaaaaa-0000-0000-0000-00000000000a', 'chess', 'x')$$,
  '23514', null, 'unknown kind is still rejected');
select lives_ok(
  $$insert into public.user_documents (user_id, kind, doc_id)
    values ('aaaaaaaa-0000-0000-0000-00000000000a', 'run', 'x')$$,
  'a previous kind still works');

reset role;
select * from finish();
rollback;
