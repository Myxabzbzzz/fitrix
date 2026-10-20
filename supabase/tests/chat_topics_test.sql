-- pgTAP tests for the Felix chat topic check.
begin;
create extension if not exists pgtap with schema extensions;
select plan(5);

insert into auth.users (id, aud, role) values
  ('aaaaaaaa-0000-0000-0000-00000000000a', 'authenticated', 'authenticated');

set local role authenticated;
set local request.jwt.claims = '{"sub":"aaaaaaaa-0000-0000-0000-00000000000a","role":"authenticated"}';

select lives_ok($$insert into public.chat_messages (id, user_id, topic, role, content, sent_at)
  values ('11111111-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-00000000000a', 'nutrition', 'user', 'macros?', now())$$,
  'owner can insert a nutrition message');
select lives_ok($$insert into public.chat_messages (id, user_id, topic, role, content, sent_at)
  values ('11111111-0000-0000-0000-000000000002', 'aaaaaaaa-0000-0000-0000-00000000000a', 'recovery', 'user', 'sleep?', now())$$,
  'owner can insert a recovery message');
select lives_ok($$insert into public.chat_messages (id, user_id, topic, role, content, sent_at)
  values ('11111111-0000-0000-0000-000000000003', 'aaaaaaaa-0000-0000-0000-00000000000a', 'winterSports', 'user', 'skis?', now())$$,
  'existing topics still work');
select throws_ok($$insert into public.chat_messages (id, user_id, topic, role, content, sent_at)
  values ('11111111-0000-0000-0000-000000000004', 'aaaaaaaa-0000-0000-0000-00000000000a', 'chess', 'user', 'e4', now())$$,
  '23514', null, 'an unknown topic is rejected');
select is((select count(*)::int from public.chat_messages), 3, 'only the valid messages were stored');

select * from finish();
rollback;
