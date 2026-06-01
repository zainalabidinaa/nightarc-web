-- Add poster and name columns to watch_progress so Continue Watching
-- items have their visuals pre-stored, eliminating fetchMeta calls on home load.
ALTER TABLE watch_progress
  ADD COLUMN IF NOT EXISTS poster text,
  ADD COLUMN IF NOT EXISTS name text;
