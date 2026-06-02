ALTER TABLE watch_progress
  ADD COLUMN IF NOT EXISTS parent_meta_id text,
  ADD COLUMN IF NOT EXISTS season integer,
  ADD COLUMN IF NOT EXISTS episode integer;
