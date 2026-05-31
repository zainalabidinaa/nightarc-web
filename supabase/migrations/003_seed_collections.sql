-- 003_seed_collections.sql
-- Seed collections from AIOMetadata B.E.S.T catalog export
-- Run AFTER 002_collections.sql
-- NOTE: Set your AIOMetadata manifest URL in the admin panel (/admin → Collections → System Addon)

DO $$
DECLARE
  -- Collection IDs
  c1 UUID; c2 UUID; c3 UUID; c4 UUID;
  c5 UUID; c6 UUID; c7 UUID; c8 UUID; c9 UUID;

  -- Folder IDs
  f UUID;
BEGIN

-- ============================================
-- COLLECTION 1: Trending & Popular
-- ============================================
INSERT INTO collections (name, sort_order) VALUES ('Trending & Popular', 0) RETURNING id INTO c1;

INSERT INTO folders (collection_id, name, sort_order) VALUES (c1, 'Popular Movies', 0) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tmdb.top', 'movie');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c1, 'Popular TV Shows', 1) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tmdb.top', 'series');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c1, 'Trending Movies', 2) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tmdb.trending', 'movie');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c1, 'Trending TV Shows', 3) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tmdb.trending', 'series');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c1, 'Top Rated Movies', 4) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tmdb.top_rated', 'movie');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c1, 'Top Rated TV Shows', 5) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tmdb.top_rated', 'series');

-- ============================================
-- COLLECTION 2: New Releases
-- ============================================
INSERT INTO collections (name, sort_order) VALUES ('New Releases', 1) RETURNING id INTO c2;

INSERT INTO folders (collection_id, name, sort_order) VALUES (c2, 'New Movies', 0) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tmdb.discover.movie.movies.mo7bd2ar', 'movie');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c2, 'New Series', 1) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tmdb.discover.series.series.mo7biroh', 'series');

-- ============================================
-- COLLECTION 3: By Decade
-- ============================================
INSERT INTO collections (name, sort_order) VALUES ('By Decade', 2) RETURNING id INTO c3;

INSERT INTO folders (collection_id, name, sort_order) VALUES (c3, '2020s', 0) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tmdb.discover.movie.decades.2020s', 'movie');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c3, '2010s', 1) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tmdb.discover.movie.decades.2010s', 'movie');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c3, '2000s', 2) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tmdb.discover.movie.decades.2000s', 'movie');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c3, '1990s', 3) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tmdb.discover.movie.decades.1990s', 'movie');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c3, '1980s', 4) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tmdb.discover.movie.decades.1980s', 'movie');

-- ============================================
-- COLLECTION 4: Genres
-- ============================================
INSERT INTO collections (name, sort_order) VALUES ('Genres', 3) RETURNING id INTO c4;

INSERT INTO folders (collection_id, name, sort_order) VALUES (c4, 'Sci-Fi Movies', 0) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tmdb.discover.movie.genres.popular.science-fiction', 'movie');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c4, 'Sci-Fi Shows', 1) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES
  (f, 'tmdb.discover.series.genres.popular.sci-fi-fantasy', 'series'),
  (f, 'tvdb.discover.series.sci_fi_shows.mo9s3i10', 'series');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c4, 'Fantasy Shows', 2) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tvdb.discover.series.fantasy_shows.mo9s284k', 'series');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c4, 'Thriller Shows', 3) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tvdb.discover.series.thriller_shows.mo7ecu45', 'series');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c4, 'Romance Shows', 4) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tvdb.discover.series.romantic_shows.mo7eaudn', 'series');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c4, 'UK Drama', 5) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tmdb.discover.series.uk_drama.mo2wdbu8', 'series');

-- ============================================
-- COLLECTION 5: British TV
-- ============================================
INSERT INTO collections (name, sort_order) VALUES ('British TV', 4) RETURNING id INTO c5;

INSERT INTO folders (collection_id, name, sort_order) VALUES (c5, 'BBC', 0) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tmdb.discover.series.bbc_shows.mo3f2pnm', 'series');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c5, 'ITV', 1) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tmdb.discover.series.itv_shows.mo3f4hdw', 'series');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c5, 'Channel 4', 2) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tmdb.discover.series.channel_4_shows.mo3f7rpz', 'series');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c5, 'Channel 5', 3) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tmdb.discover.series.channel_4_shows.mo3f5vt2', 'series');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c5, 'UK TV', 4) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tmdb.discover.series.uk_tv.mo8ai6c3', 'series');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c5, 'Best of British', 5) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'tmdb.discover.series.best_of_the_bbc.mo6vmso3', 'series');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c5, 'UK Shows', 6) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'mdblist.3091', 'series');

-- ============================================
-- COLLECTION 6: Franchises
-- ============================================
INSERT INTO collections (name, sort_order) VALUES ('Franchises', 5) RETURNING id INTO c6;

INSERT INTO folders (collection_id, name, sort_order) VALUES (c6, 'Marvel', 0) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES
  (f, 'trakt.list.828103', 'all'),
  (f, 'trakt.list.22881797', 'all');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c6, 'Star Wars', 1) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES
  (f, 'trakt.list.22202556', 'all'),
  (f, 'trakt.list.22757470', 'all');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c6, 'James Bond', 2) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'trakt.list.802940', 'all');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c6, 'Indiana Jones', 3) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'trakt.list.11723506', 'all');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c6, 'Jurassic Park', 4) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'trakt.list.11332030', 'all');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c6, 'The Matrix', 5) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'trakt.list.11723357', 'all');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c6, 'Rocky', 6) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'trakt.list.11723321', 'all');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c6, 'Hunger Games', 7) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'trakt.list.21226800', 'all');

-- ============================================
-- COLLECTION 7: Directors
-- ============================================
INSERT INTO collections (name, sort_order) VALUES ('Directors', 6) RETURNING id INTO c7;

INSERT INTO folders (collection_id, name, sort_order) VALUES (c7, 'Christopher Nolan', 0) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'trakt.list.6242091', 'all');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c7, 'Steven Spielberg', 1) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'trakt.list.6241187', 'all');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c7, 'Quentin Tarantino', 2) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'trakt.list.6241445', 'all');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c7, 'Stanley Kubrick', 3) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'trakt.list.6241405', 'all');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c7, 'Ridley Scott', 4) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'trakt.list.6241250', 'all');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c7, 'Wes Anderson', 5) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'trakt.list.6252074', 'all');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c7, 'James Cameron', 6) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'trakt.list.6252088', 'all');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c7, 'Tim Burton', 7) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'trakt.list.6241270', 'all');

-- ============================================
-- COLLECTION 8: Family & Animation
-- ============================================
INSERT INTO collections (name, sort_order) VALUES ('Family & Animation', 7) RETURNING id INTO c8;

INSERT INTO folders (collection_id, name, sort_order) VALUES (c8, 'Pixar', 0) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'trakt.list.33761345', 'all');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c8, 'Disney', 1) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'trakt.list.22888726', 'all');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c8, 'DreamWorks', 2) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'trakt.list.801242', 'all');

-- ============================================
-- COLLECTION 9: Top Lists
-- ============================================
INSERT INTO collections (name, sort_order) VALUES ('Top Lists', 8) RETURNING id INTO c9;

INSERT INTO folders (collection_id, name, sort_order) VALUES (c9, 'IMDB Top 250 Movies', 0) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'trakt.list.2142753', 'all');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c9, 'IMDB Top TV Shows', 1) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'trakt.list.2143363', 'all');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c9, '1001 Greatest Movies', 2) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'trakt.list.1282987', 'all');

INSERT INTO folders (collection_id, name, sort_order) VALUES (c9, 'Latest TV Shows', 3) RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type) VALUES (f, 'mdblist.3882', 'series');

END $$;
