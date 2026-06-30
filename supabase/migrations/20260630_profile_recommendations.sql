CREATE TABLE IF NOT EXISTS profile_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  row_type TEXT NOT NULL,
  row_title TEXT NOT NULL,
  cover_image TEXT,
  items JSONB NOT NULL DEFAULT '[]',
  sort_order INTEGER NOT NULL DEFAULT 0,
  generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_profile_recs_unique
  ON profile_recommendations(profile_id, row_type, row_title);
