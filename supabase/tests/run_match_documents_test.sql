-- pgTAP tests for the run, match and workout_deleted document kinds.
begin;
create extension if not exists pgtap with schema extensions;
select plan(5);

insert into auth.users (id, aud, role) values
  ('aaaaaaaa-0000-0000-0000-00000000000a', 'authenticated', 'authenticated');

set local role authenticated;
set local request.jwt.claims = '{"sub":"aaaaaaaa-0000-0000-0000-00000000000a","role":"authenticated"}';

select lives_ok(
  $$insert into public.user_documents (user_id, kind, doc_id, data)
    values ('aaaaaaaa-0000-0000-0000-00000000000a', 'run', 'w1', '{"distanceKm":5}')$$,
  'owner inserts a run document');
select lives_ok(
  $$insert into public.user_documents (user_id, kind, doc_id, data)
    values ('aaaaaaaa-0000-0000-0000-00000000000a', 'match', 'w2', '{"type":"match"}')$$,
  'owner inserts a match document');
select lives_ok(
  $$insert into public.user_documents (user_id, kind, doc_id)
    values ('aaaaaaaa-0000-0000-0000-00000000000a', 'workout_deleted', 'w3')$$,
  'owner inserts a workout_deleted document');
select throws_ok(
  $$insert into public.user_documents (user_id, kind, doc_id)
    values ('aaaaaaaa-0000-0000-0000-00000000000a', 'chess', 'x')$$,
  '23514', null, 'unknown kind is still rejected');
select lives_ok(
  $$insert into public.user_documents (user_id, kind, doc_id)
    values ('aaaaaaaa-0000-0000-0000-00000000000a', 'felix_plans', 'x')$$,
  'an original kind still works');

reset role;
select * from finish();
rollback;
