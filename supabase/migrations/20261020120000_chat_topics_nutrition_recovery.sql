-- Felix chats grow from app + 6 sports to 9 topics: add nutrition and recovery.
-- The check was created inline in the initial schema (Postgres named it
-- chat_messages_topic_check); drop it and add it back with the new list.
alter table public.chat_messages
  drop constraint chat_messages_topic_check;

alter table public.chat_messages
  add constraint chat_messages_topic_check check (
    topic in (
      'app', 'gym', 'fitness', 'cycling', 'running', 'football',
      'winterSports', 'nutrition', 'recovery'
    )
  );
