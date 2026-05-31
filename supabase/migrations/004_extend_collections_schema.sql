-- 004_extend_collections_schema.sql
-- Extend schema to support full B.E.S.T collection pack metadata

ALTER TABLE collections
  ADD COLUMN IF NOT EXISTS backdrop_image     TEXT,
  ADD COLUMN IF NOT EXISTS view_mode          TEXT    DEFAULT 'FOLLOW_LAYOUT',
  ADD COLUMN IF NOT EXISTS show_all_tab       BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS focus_glow_enabled BOOLEAN DEFAULT true,
  ADD COLUMN IF NOT EXISTS pin_to_top         BOOLEAN DEFAULT false;

ALTER TABLE folders
  ADD COLUMN IF NOT EXISTS title_logo        TEXT,
  ADD COLUMN IF NOT EXISTS hero_backdrop     TEXT,
  ADD COLUMN IF NOT EXISTS hero_video_url    TEXT,
  ADD COLUMN IF NOT EXISTS hide_title        BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS tile_shape        TEXT    DEFAULT 'LANDSCAPE',
  ADD COLUMN IF NOT EXISTS focus_gif_enabled BOOLEAN DEFAULT false;

ALTER TABLE folder_catalogs
  ADD COLUMN IF NOT EXISTS genre TEXT DEFAULT 'None';
