-- Wave 2C: GPS runs, football matches and workout deletions sync as documents.
alter table public.user_documents drop constraint user_documents_kind_check;
alter table public.user_documents add constraint user_documents_kind_check check (kind in (
  'checkin', 'food', 'water', 'weight', 'week_plan', 'program',
  'performance', 'nutrition_settings', 'felix_plans',
  'run', 'match', 'workout_deleted'));
