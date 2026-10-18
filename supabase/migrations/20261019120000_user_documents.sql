-- Cloud copy of the app's local data (check-ins, food log, water, weight,
-- plans, ...). One row per document; the app decides what a document is.
-- Deletions are rows with deleted = true (no delete policy), so other
-- devices learn about them. updated_at is server-set (last-write-wins sync).
create table public.user_documents (
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null,
  doc_id text not null,
  data jsonb,
  deleted boolean not null default false,
  updated_at timestamptz not null default now(),
  primary key (user_id, kind, doc_id),
  constraint user_documents_kind_check check (kind in (
    'checkin', 'food', 'water', 'weight', 'week_plan', 'program',
    'performance', 'nutrition_settings', 'felix_plans')),
  constraint user_documents_doc_id_length check (char_length(doc_id) <= 100),
  constraint user_documents_data_size check (pg_column_size(data) <= 65536)
);

create index user_documents_user_updated_idx
  on public.user_documents (user_id, updated_at);

create trigger user_documents_set_updated_at
before insert or update on public.user_documents
for each row execute function public.set_updated_at();

alter table public.user_documents enable row level security;

create policy "Own documents: read" on public.user_documents
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "Own documents: create" on public.user_documents
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "Own documents: update" on public.user_documents
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
