-- 005_seed_best_collections.sql
-- Full B.E.S.T collection pack (Better Enhanced Simple TV)
-- Source: public_id = b-e-s-t-better-enhanced-simple-tv
-- Replaces 003_seed_collections.sql data with the authoritative export

TRUNCATE collections CASCADE;

DO $$
DECLARE
  c1 UUID; c2 UUID; c3 UUID; c4 UUID; c5 UUID; c6 UUID; c7 UUID;
  f  UUID;
BEGIN

-- ============================================
-- COLLECTION 1: Discover
-- ============================================
INSERT INTO collections (name, sort_order, show_all_tab, focus_glow_enabled)
VALUES ('Discover', 0, true, true) RETURNING id INTO c1;

-- Trending Shows
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_backdrop, focus_gif_enabled)
VALUES (c1, 'Trending Shows', 0,
  'https://btttr.cc/dVHLbsIwEPyVaM8gOQ8njq-VekOqSqUeqh7W9hqikjiKDQgh_r2CBkJSOM5oZmdn9wgaA27cyoP8gtDhT5iHjhpTNSuYPSNa12432D3CtVHz4AweRmDu127vr5R2dT9tQGNFcO1t-B6DXm8qH27MGUiLO7ftqkAevmdQU0CQx-nC8ggN1gQSPnoqWlJX0SUIJHg4TTsMlrc_5pFjaHmX4Noo4dHC7QZ1PVb3Jf95niT0dxrkLxciWjrXPMsZXfOx82mfdrLZOwYyo4TJQwb54hB93v9p7Jg-bPC9DuTNdbWdZag1eQ8SSsoMlgqxSFOyBmNmE82sZtySFiLNKCNknBvBsri0nHJjmNKp5iRszguYQUe2I78GCYTEdZHl2qIlEipTQpdFmiXCljFLFGVpyQQZludM8TxOYqsKZQthTJGLsoDT6Rc/cover/series/trakt-trending.png?name=Trending%20Shows',
  'https://i.postimg.cc/Wbf23VDp/Playlists.jpg', true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.3882', 'series', 'None'),
  (f, 'tmdb.discover.series.latest.mpcugvcy', 'series', 'None');

-- Trending Movies
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_backdrop, focus_gif_enabled)
VALUES (c1, 'Trending Movies', 1,
  'https://btttr.cc/dVHLbsIwEPyVaM8gOQ8njq-VekOqSqUeqh7W9hqikjiKDQgh_r2CBkJSOM5oZmdn9wgaA27cyoP8gtDhT5iHjhpTNSuYPSNa12432D3CtVHz4AweRmDu127vr5R2dT9tQGNFcO1t-B6DXm8qH27MGUiLO7ftqkAevmdQU0CQx-nC8ggN1gQSPnoqWlJX0SUIJHg4TTsMlrc_5pFjaHmX4Noo4dHC7QZ1PVb3Jf95niT0dxrkLxciWjrXPMsZXfOx82mfdrLZOwYyo4TJQwb54hB93v9p7Jg-bPC9DuTNdbWdZag1eQ8SSsoMlgqxSFOyBmNmE82sZtySFiLNKCNknBvBsri0nHJjmNKp5iRszguYQUe2I78GCYTEdZHl2qIlEipTQpdFmiXCljFLFGVpyQQZludM8TxOYqsKZQthTJGLsoDT6Rc/cover/movie/trakt-trending.png?name=Trending%20Movies',
  'https://i.postimg.cc/Wbf23VDp/Playlists.jpg', true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.88306', 'movie', 'None'),
  (f, 'tmdb.trending_movie', 'movie', 'Day');

-- Popular Shows
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_backdrop, focus_gif_enabled)
VALUES (c1, 'Popular Shows', 2,
  'https://btttr.cc/dVHLbsIwEPyVaM8gOQ8njq-VekOqSqUeqh7W9hqikjiKDQgh_r2CBkJSOM5oZmdn9wgaA27cyoP8gtDhT5iHjhpTNSuYPSNa12432D3CtVHz4AweRmDu127vr5R2dT9tQGNFcO1t-B6DXm8qH27MGUiLO7ftqkAevmdQU0CQx-nC8ggN1gQSPnoqWlJX0SUIJHg4TTsMlrc_5pFjaHmX4Noo4dHC7QZ1PVb3Jf95niT0dxrkLxciWjrXPMsZXfOx82mfdrLZOwYyo4TJQwb54hB93v9p7Jg-bPC9DuTNdbWdZag1eQ8SSsoMlgqxSFOyBmNmE82sZtySFiLNKCNknBvBsri0nHJjmNKp5iRszguYQUe2I78GCYTEdZHl2qIlEipTQpdFmiXCljFLFGVpyQQZludM8TxOYqsKZQthTJGLsoDT6Rc/cover/series/trakt-popular.png?name=Popular%20Shows',
  'https://i.postimg.cc/Wbf23VDp/Playlists.jpg', true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.top_series', 'series', 'None');

-- Popular Movies
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_backdrop, focus_gif_enabled)
VALUES (c1, 'Popular Movies', 3,
  'https://btttr.cc/dVHLbsIwEPyVaM8gOQ8njq-VekOqSqUeqh7W9hqikjiKDQgh_r2CBkJSOM5oZmdn9wgaA27cyoP8gtDhT5iHjhpTNSuYPSNa12432D3CtVHz4AweRmDu127vr5R2dT9tQGNFcO1t-B6DXm8qH27MGUiLO7ftqkAevmdQU0CQx-nC8ggN1gQSPnoqWlJX0SUIJHg4TTsMlrc_5pFjaHmX4Noo4dHC7QZ1PVb3Jf95niT0dxrkLxciWjrXPMsZXfOx82mfdrLZOwYyo4TJQwb54hB93v9p7Jg-bPC9DuTNdbWdZag1eQ8SSsoMlgqxSFOyBmNmE82sZtySFiLNKCNknBvBsri0nHJjmNKp5iRszguYQUe2I78GCYTEdZHl2qIlEipTQpdFmiXCljFLFGVpyQQZludM8TxOYqsKZQthTJGLsoDT6Rc/cover/movie/trakt-popular.png?name=Popular%20Movies',
  'https://i.postimg.cc/Wbf23VDp/Playlists.jpg', true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.top_movie', 'movie', 'None');

-- Top Rated
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_backdrop, focus_gif_enabled)
VALUES (c1, 'Top Rated', 4,
  'https://btttr.cc/dVHLbsIwEPyVaM8gOQ8njq-VekOqSqUeqh7W9hqikjiKDQgh_r2CBkJSOM5oZmdn9wgaA27cyoP8gtDhT5iHjhpTNSuYPSNa12432D3CtVHz4AweRmDu127vr5R2dT9tQGNFcO1t-B6DXm8qH27MGUiLO7ftqkAevmdQU0CQx-nC8ggN1gQSPnoqWlJX0SUIJHg4TTsMlrc_5pFjaHmX4Noo4dHC7QZ1PVb3Jf95niT0dxrkLxciWjrXPMsZXfOx82mfdrLZOwYyo4TJQwb54hB93v9p7Jg-bPC9DuTNdbWdZag1eQ8SSsoMlgqxSFOyBmNmE82sZtySFiLNKCNknBvBsri0nHJjmNKp5iRszguYQUe2I78GCYTEdZHl2qIlEipTQpdFmiXCljFLFGVpyQQZludM8TxOYqsKZQthTJGLsoDT6Rc/cover/movie/tmdb-top.png?name=Top%20Rated',
  'https://i.postimg.cc/Wbf23VDp/Playlists.jpg', true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.top_rated_series', 'series', 'None'),
  (f, 'trakt.list.2143363',    'series', 'None'),
  (f, 'tmdb.top_rated_movie',  'movie',  'None'),
  (f, 'trakt.list.2142753',    'movie',  'None'),
  (f, 'trakt.list.1282987',    'movie',  'None');

-- Coming Soon Shows
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_backdrop, focus_gif_enabled)
VALUES (c1, 'Coming Soon Shows', 5,
  'https://btttr.cc/bYwxCoAwEAS_IlubD1xrbZVSLKIGDXg58IIWIX8XbVSw3GFnMkaX3CqzgjokngYzCoc4o34vo4scir4G--RA-XOljOjYg9DcoLIisWplD16vDgiM8hf8N63fHlNRSjkB/cover/series/tmdb-coming-shows.png?name=Coming%20Soon%20Shows',
  'https://i.postimg.cc/Wbf23VDp/Playlists.jpg', false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.20340',          'series', 'None'),
  (f, 'trakt.anticipated.shows','series', 'None');

-- Coming Soon Movies
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_backdrop, focus_gif_enabled)
VALUES (c1, 'Coming Soon Movies', 6,
  'https://btttr.cc/dVHLbsIwEPyVaM8gOQ8njq-VekOqSqUeqh7W9hqikjiKDQgh_r2CBkJSOM5oZmdn9wgaA27cyoP8gtDhT5iHjhpTNSuYPSNa12432D3CtVHz4AweRmDu127vr5R2dT9tQGNFcO1t-B6DXm8qH27MGUiLO7ftqkAevmdQU0CQx-nC8ggN1gQSPnoqWlJX0SUIJHg4TTsMlrc_5pFjaHmX4Noo4dHC7QZ1PVb3Jf95niT0dxrkLxciWjrXPMsZXfOx82mfdrLZOwYyo4TJQwb54hB93v9p7Jg-bPC9DuTNdbWdZag1eQ8SSsoMlgqxSFOyBmNmE82sZtySFiLNKCNknBvBsri0nHJjmNKp5iRszguYQUe2I78GCYTEdZHl2qIlEipTQpdFmiXCljFLFGVpyQQZludM8TxOYqsKZQthTJGLsoDT6Rc/cover/movie/tmdb-coming.png?name=Coming%20Soon%20Movies',
  'https://i.postimg.cc/Wbf23VDp/Playlists.jpg', true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.26816',           'movie', 'None'),
  (f, 'trakt.anticipated.movies','movie', 'None');


-- ============================================
-- COLLECTION 2: Franchises
-- ============================================
INSERT INTO collections (name, sort_order, show_all_tab, focus_glow_enabled)
VALUES ('Franchises', 1, false, true) RETURNING id INTO c2;

-- Star Wars
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hide_title, focus_gif_enabled)
VALUES (c2, 'Star Wars', 0,
  'https://i.postimg.cc/vHK1D7bP/Star-Wars.jpg',
  'https://i.postimg.cc/L6r64vPj/Star-Wars-Logo.png',
  'https://i.postimg.cc/sDtDfKWJ/Star-Wars-BG.jpg', true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.22202556', 'movie',  'None'),
  (f, 'trakt.list.22757470', 'series', 'None');

-- Middle Earth
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hide_title, focus_gif_enabled)
VALUES (c2, 'Middle Earth', 1,
  'https://i.postimg.cc/qvn2MrXq/Lo-TR-Tile.png',
  'https://i.postimg.cc/XYF97WcJ/Lo-TRLogo.png',
  'https://i.postimg.cc/BQRx0bFM/Lo-TR-BG.jpg', true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.1642688', 'movie', 'None');

-- The Wizarding World
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hide_title, focus_gif_enabled)
VALUES (c2, 'The Wizarding World', 2,
  'https://i.postimg.cc/xj44xqMB/Wizarding-World-of-Harry-Potter-Tile.png',
  'https://i.postimg.cc/pXgkWq8W/Wizarding-World-of-Harry-Potter-logo.png',
  'https://i.postimg.cc/sg7mv79C/Harry-Potter-BG.jpg', true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.21869828', 'movie', 'None');

-- Pixar
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hide_title, focus_gif_enabled)
VALUES (c2, 'Pixar', 3,
  'https://i.postimg.cc/5yrL2sh2/5440db5f-be91-4941-b1ba-4b4ea07b0f25.jpg',
  'https://i.postimg.cc/J0Y4Lsdk/Pixar-Logo.png',
  'https://i.postimg.cc/hj6yHJJv/Pixar-BG.jpg', true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.801240', 'movie', 'None'),
  (f, 'trakt.list.2749609', 'movie', 'None');

-- Dreamworks
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hide_title, focus_gif_enabled)
VALUES (c2, 'Dreamworks', 4,
  'https://i.postimg.cc/JnVNH8M5/882cf7a8-9aa6-4673-81c1-d3ed7a859e95.jpg',
  'https://i.postimg.cc/J4QCZCzG/Dream-Works-Logo.png',
  'https://i.postimg.cc/qqVzFhSX/Dream-Works-BG.jpg', true, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.801242', 'movie', 'None');

-- Pirates Of The Caribbean
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hide_title, focus_gif_enabled)
VALUES (c2, 'Pirates Of The Caribbean', 5,
  'https://i.postimg.cc/4xbkvk41/Piratesof-The-Caribbean-Tile.jpg',
  'https://i.postimg.cc/2SFRdRjw/Piratesof-The-Caribbean-Logo.png',
  'https://i.postimg.cc/y8X4h46y/Piratesof-The-Caribbean-BG.jpg', true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.162329', 'movie', 'None');

-- Back to the Future
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hide_title, focus_gif_enabled)
VALUES (c2, 'Back to the Future', 6,
  'https://i.postimg.cc/63FmJY5K/Backto-The-Future-Tile.png',
  'https://i.postimg.cc/nzNPb0cb/Backto-The-Future-Logo.png',
  'https://i.postimg.cc/C19QTmMW/Backto-The-Future-BG.jpg', true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.162330', 'movie', 'None');

-- Indiana Jones
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hide_title, focus_gif_enabled)
VALUES (c2, 'Indiana Jones', 7,
  'https://i.postimg.cc/k5zCjN89/Indiana-Jones-Tile.png',
  'https://i.postimg.cc/vmWxMmzF/Indiana-Jones-Logo.png',
  'https://i.postimg.cc/jjmT86NV/Indiana-Jones-BG.jpg', true, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.11723506', 'movie', 'None');

-- The Matrix
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hide_title, focus_gif_enabled)
VALUES (c2, 'The Matrix', 8,
  'https://i.postimg.cc/k43Gpd3c/The-Matrix-Tile.png',
  'https://i.postimg.cc/Kjwfgzgg/The-Matrix-Logo.webp',
  'https://i.postimg.cc/N0rLDjVL/The-Matrix-BG.jpg', true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.11723357', 'movie', 'None');

-- The Hunger Games
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hide_title, focus_gif_enabled)
VALUES (c2, 'The Hunger Games', 9,
  'https://i.postimg.cc/T1DT4WLq/0d7e0b16-0ad8-454e-8de1-31e42781a305.jpg',
  'https://i.postimg.cc/tTPPRBCc/The-Hunger-Games-Logo.png',
  'https://i.postimg.cc/JhSZWfmN/The-Hunger-Games-BG.jpg', true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.21226800', 'movie', 'None');

-- The Planet of the Apes
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hide_title, focus_gif_enabled)
VALUES (c2, 'The Planet of the Apes', 10,
  'https://i.postimg.cc/9FvGHPkB/a453ea55-5840-4dea-a6b8-bc2ba0a1e481.webp',
  'https://i.postimg.cc/9My83FdH/Planetof-The-Apes-Logo.png',
  'https://i.postimg.cc/1tKtYwYj/Planetof-The-Apes-BG.jpg', true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.11723368', 'movie', 'None');

-- Jurassic World
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hide_title, focus_gif_enabled)
VALUES (c2, 'Jurassic World', 11,
  'https://i.postimg.cc/xCpJgLZJ/Jurassic-World-Tile.png',
  'https://i.postimg.cc/1zP9F4vn/vle-Ub-BFl-EGdxaazvz-BMo-Z5d-HDo-Y.webp',
  'https://i.postimg.cc/W31qM55p/Jurassic-World-BG.jpg', true, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.11214030', 'movie', 'None');

-- Men In Black
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hide_title, focus_gif_enabled)
VALUES (c2, 'Men In Black', 12,
  'https://i.postimg.cc/X7HNTVNC/Men-In-Black-Tile.png',
  'https://i.postimg.cc/rFFFndT1/Men-In-Black-Logo.png',
  'https://i.postimg.cc/kXXX1VCK/Men-In-Black-BG.jpg', true, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.21273394', 'movie', 'None');

-- Ghostbusters
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hide_title, focus_gif_enabled)
VALUES (c2, 'Ghostbusters', 13,
  'https://i.postimg.cc/j5vJGHJb/Ghostbusters-Tile.png',
  'https://i.postimg.cc/7htHck4W/e3ed004b-4969-4109-9c9d-aef29189c433-(1)-(1).png',
  'https://i.postimg.cc/x8CbYXK9/Ghostbusters-BG.png', true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.162311', 'movie', 'None');

-- Battlestar Galactica
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hide_title, focus_gif_enabled)
VALUES (c2, 'Battlestar Galactica', 14,
  'https://i.postimg.cc/JzLh2h56/Battle-Star-Tile.png',
  'https://i.postimg.cc/pdjnnSkx/Battlestar-Logo.png',
  'https://i.postimg.cc/T27BpNsM/Battlestar-BG.png', true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.173508', 'all', 'None');

-- DC Universe
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hide_title, focus_gif_enabled)
VALUES (c2, 'DC Universe', 15,
  'https://i.postimg.cc/9fxVdSC1/DC-Universe.jpg',
  'https://i.postimg.cc/3WQ8YQ4b/960px-DC-Comics-logo-svg-png-utm-source-commons-wikimedia.png',
  'https://i.postimg.cc/4N45MSg7/ef215e66-54da-4b03-a946-34727ba52766.jpg', true, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.9429560', 'movie', 'None');

-- Marvel
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hide_title, focus_gif_enabled)
VALUES (c2, 'Marvel', 16,
  'https://i.postimg.cc/TYKW4WdV/Marvel-Tile.png',
  'https://i.postimg.cc/XNHCLgb4/Marvel-Logo.png',
  'https://i.postimg.cc/v8qVhvsn/Marvel-BG.png', true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.22881797', 'movie', 'None'),
  (f, 'trakt.list.828103',   'all',   'None');

-- Rocky
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hide_title, focus_gif_enabled)
VALUES (c2, 'Rocky', 17,
  'https://i.postimg.cc/V6GryckF/Rocky-Tile.png',
  'https://i.postimg.cc/Tw7L8X3V/Rocky-Logo.png',
  'https://i.postimg.cc/cH9gqNLM/Rocky-BG.jpg', true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.11723321', 'movie', 'None');

-- James Bond
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hide_title, focus_gif_enabled)
VALUES (c2, 'James Bond', 18,
  'https://i.postimg.cc/PJRvqd4D/James-Bond-Tile.png',
  'https://i.postimg.cc/RFGnj7nx/007-Logo.png',
  'https://i.postimg.cc/SRszqnWz/James-Bond-BG.png', true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.11754060', 'movie', 'None'),
  (f, 'trakt.list.11754031', 'movie', 'None'),
  (f, 'trakt.list.11754010', 'movie', 'None'),
  (f, 'trakt.list.11753990', 'movie', 'None'),
  (f, 'trakt.list.11753899', 'movie', 'None');

-- Monty Python
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hide_title, focus_gif_enabled)
VALUES (c2, 'Monty Python', 19,
  'https://i.postimg.cc/4NRMpgW1/Monty-Python-Button.png',
  'https://i.postimg.cc/Kv0WqWNq/Python-Logo.png',
  'https://i.postimg.cc/fTQFYN8x/Monty-Python-BG.png', false, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.22236190', 'all', 'None');

-- It's Aliens
INSERT INTO folders (collection_id, name, sort_order, cover_image, hide_title, focus_gif_enabled)
VALUES (c2, 'It''s Aliens', 20,
  'https://i.postimg.cc/d33f6Ng3/Aliens.png', true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.33753562', 'movie', 'None');


-- ============================================
-- COLLECTION 3: Streaming
-- ============================================
INSERT INTO collections (name, sort_order, show_all_tab, focus_glow_enabled)
VALUES ('Streaming', 2, false, true) RETURNING id INTO c3;

-- Netflix
INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, title_logo, hero_backdrop, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c3, 'Netflix', 0,
  'https://i.postimg.cc/FHrH9pYN/469fb054-cbec-46ca-bc91-6ed73a6d647b.png',
  'https://i.postimg.cc/mgm2h99c/bb74046420c4c992b8cabc6e667abe40.gif',
  'https://i.postimg.cc/903dVycz/Netflix-Logo.png',
  'https://i.postimg.cc/wTb6vztg/Netflix.jpg',
  'https://drive.google.com/uc?export=download&id=1yViFBWoiyPi6cuVdjUoABaEnZUbnnCxc',
  true, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.86620',     'series', 'None'),
  (f, 'streaming.nfx_series', 'series', 'None'),
  (f, 'mdblist.86628',     'movie',  'None'),
  (f, 'streaming.nfx_movie',  'movie',  'None');

-- Prime Video
INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, title_logo, hero_backdrop, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c3, 'Prime Video', 1,
  'https://i.postimg.cc/jSMdCffB/d0476b73-c21d-4c1d-946f-7ce3fef17ccd.png',
  'https://media1.tenor.com/m/T7L_NCdPIvAAAAAC/prime-video.gif',
  'https://i.postimg.cc/5ycB18f6/prime-video-landscape-logo.png',
  'https://i.postimg.cc/9FNWM24r/Prime.jpg',
  'https://drive.google.com/uc?export=download&id=1tilj8ekPSeDQCco00WMYPIEEkPN-lrb_',
  true, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.86624',     'series', 'None'),
  (f, 'streaming.amp_series', 'series', 'None'),
  (f, 'mdblist.86623',     'movie',  'None'),
  (f, 'streaming.amp_movie',  'movie',  'None');

-- Paramount+
INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, title_logo, hero_backdrop, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c3, 'Paramount+', 2,
  'https://i.postimg.cc/TPSdJXC1/12db31b7-ca2e-4980-9c92-c83e58a22949.png',
  'https://i.postimg.cc/zBgJdPcF/Paramount.gif',
  'https://i.postimg.cc/yYtfx3nP/Paramount-logo-svg.png',
  'https://i.postimg.cc/Z5GvWp9q/Paramount.jpg',
  'https://drive.google.com/uc?export=download&id=1O4iduIsp-tJhIurJiegbPESnHEKYElpw',
  true, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.89374',     'series', 'None'),
  (f, 'streaming.pmp_series', 'series', 'None'),
  (f, 'mdblist.89366',     'movie',  'None'),
  (f, 'streaming.pmp_movie',  'movie',  'None');

-- Disney+
INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, title_logo, hero_backdrop, hide_title, focus_gif_enabled)
VALUES (c3, 'Disney+', 3,
  'https://i.postimg.cc/D037RPV2/e2155ff8-4939-40d1-8dc2-7d28df3ecaa0.png',
  'https://i.postimg.cc/Y0Nt7Lk0/1775910668473-8e07b96b-4739-43d4-9475-f2aaeac8e259.gif',
  'https://i.postimg.cc/yd3mwLC3/Disney-Plus-logo-svg.png',
  'https://i.postimg.cc/X7DVJWZW/Disney.jpg',
  true, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'streaming.dnp_series', 'series', 'None'),
  (f, 'mdblist.86946',     'series', 'None'),
  (f, 'streaming.dnp_movie',  'movie',  'None'),
  (f, 'mdblist.86945',     'movie',  'None');

-- Apple TV
INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, title_logo, hero_backdrop, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c3, 'Apple TV', 4,
  'https://i.postimg.cc/yWq3QZjQ/d2b77dfd-c14a-4258-ab0f-b610519c96ef.png',
  'https://64.media.tumblr.com/d717319220a7d26bdaa88e72f6f76889/d9a7a808f588d8f4-63/s500x750/959b0ca57f53153b2ca9adaf414859e45e3734e6.gifv',
  'https://i.postimg.cc/B6PTdmfK/apple-tv-logo.png',
  'https://i.postimg.cc/m2rLBkrf/Apple-TV.jpg',
  'https://drive.google.com/uc?export=download&id=1SBpzMhx5jqVoQpqhK42CsNFiW8pCV3TD',
  true, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.86625',     'series', 'None'),
  (f, 'streaming.atp_series', 'series', 'None'),
  (f, 'mdblist.86626',     'movie',  'None'),
  (f, 'streaming.atp_movie',  'movie',  'None');

-- HBO MAX
INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, title_logo, hero_backdrop, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c3, 'HBO MAX', 5,
  'https://i.postimg.cc/1RbWh7Yp/af3c0122-cbd1-49ae-94f1-6da0f9f665a8.png',
  'https://i.postimg.cc/Hs0t4sLJ/4cb9b614191d17d02c946b4ca59548cd333c06fd.gif',
  'https://i.postimg.cc/JnmrXqYH/HBO-Max-logo-(May-2025).png',
  'https://i.postimg.cc/j2kCyF1D/HBOMax.png',
  'https://drive.google.com/uc?export=download&id=1TeeMKLynx5v4WE2cC03dw3fFIltlzKJ0',
  true, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.series.top_hbo_shows.mpe9izy7', 'series', 'None'),
  (f, 'streaming.hbm_series',                        'series', 'None'),
  (f, 'tmdb.discover.movie.top_hbo_movies.mpe9kdzj', 'movie',  'None'),
  (f, 'streaming.hbm_movie',                         'movie',  'None');

-- Starz
INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, title_logo, hero_backdrop, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c3, 'Starz', 6,
  'https://i.postimg.cc/W3Ff8LDH/c7688767-401f-45ad-998a-076ded525df7.png',
  'https://i.postimg.cc/sxJP9wJm/1000390458-(1).gif',
  'https://i.postimg.cc/m20PmKdG/Starz-logo.png',
  'https://i.postimg.cc/fygkYrP3/Starz.png',
  'https://drive.google.com/uc?export=download&id=1siM6tqtCtHzE306lVtH0uuSCmjdN5Mtd',
  true, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.series.top_starz_shows.mpe9ln7v', 'series', 'None'),
  (f, 'streaming.sta_series',                          'series', 'None'),
  (f, 'tmdb.discover.movie.top_starz_movies.mpe9mvs2', 'movie',  'None'),
  (f, 'streaming.sta_movie',                           'movie',  'None');


-- ============================================
-- COLLECTION 4: UK TV
-- ============================================
INSERT INTO collections (name, sort_order, show_all_tab, focus_glow_enabled)
VALUES ('UK TV', 3, false, true) RETURNING id INTO c4;

-- iPlayer
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c4, 'iPlayer', 0,
  'https://i.postimg.cc/W3TbWH10/3c471a49-13c3-40e2-8583-b1e9549b1768.jpg',
  'https://i.postimg.cc/6QLvvTx7/BBC-i-Player-Logo.png',
  'https://i.postimg.cc/zXfz8vfr/BBC.jpg',
  'https://drive.google.com/uc?export=download&id=1URan1tMAm_y1SnhIXoRWGVEN3ZyX3SIl',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.series.bbc_shows.mo3f2pnm', 'series', 'None');

-- itvX
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c4, 'itvX', 1,
  'https://i.postimg.cc/85NPK0zK/itv-xwefbrjsf.jpg',
  'https://i.postimg.cc/d0CHC242/ITVX-logo-svg.png',
  'https://i.postimg.cc/xTF0CQk2/ITVX.jpg',
  'https://drive.google.com/uc?export=download&id=11644rcEdmJINZ7NR8-IQaHyk0LCinDWR',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.series.itv_shows.mo3f4hdw', 'series', 'None');

-- Channel 4
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c4, 'Channel 4', 2,
  'https://i.postimg.cc/3R1rPFkS/63a2922f-2d1a-42ce-845e-de7e56aaf92f.jpg',
  'https://i.postimg.cc/fbd2dcBf/Channel-4.png',
  'https://i.postimg.cc/qM7J4q7H/Channel4.jpg',
  'https://drive.google.com/uc?export=download&id=11dQSrys5e_QoukwkOaqx-jfPFhuv7CJ2',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.series.channel_4_shows.mo3f7rpz', 'series', 'None');

-- Channel 5
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c4, 'Channel 5', 3,
  'https://i.postimg.cc/ZRHY1x9h/5logo.png',
  'https://i.postimg.cc/VNtGtqD4/Channel-5-2025-svg.png',
  'https://i.postimg.cc/xTdfn8dS/Channel5.jpg',
  'https://drive.google.com/uc?export=download&id=1weIEpwOt_g4ZIGauNnaXUtExljnMjCxs',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.series.channel_4_shows.mo3f5vt2', 'series', 'None');

-- U (UKTV Play)
INSERT INTO folders (collection_id, name, sort_order, cover_image, title_logo, hero_backdrop, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c4, 'U', 4,
  'https://i.postimg.cc/nr9yZw2w/UPlayer.png',
  'https://i.postimg.cc/g0hShVNK/UKTV-2024-svg.png',
  'https://i.postimg.cc/tCmXTb1s/UKTV.jpg',
  'https://drive.google.com/uc?export=download&id=11yixC0AXh76VR8du-VbiStz4U__GAMcx',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.series.uk_tv.mo8ai6c3',        'series', 'None'),
  (f, 'tmdb.discover.series.best_of_the_bbc.mo6vmso3', 'series', 'None');


-- ============================================
-- COLLECTION 5: Genres
-- ============================================
INSERT INTO collections (name, sort_order, show_all_tab, focus_glow_enabled)
VALUES ('Genres', 4, false, true) RETURNING id INTO c5;

-- Action
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c5, 'Action', 0,
  'https://i.postimg.cc/85TB12zQ/Action.png',
  'https://drive.google.com/uc?export=download&id=1dxNvmeUI7SAm9n1CJu0D8uSo3p5nyXg8',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.series.series.mo7biroh',  'series', 'Action & Adventure'),
  (f, 'tmdb.discover.movie.movies.mo7bd2ar',   'movie',  'Action'),
  (f, 'trakt.list.4973644',                    'movie',  'None');

-- Animation
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c5, 'Animation', 1,
  'https://i.postimg.cc/QtjkX2d3/Animation.png',
  'https://drive.google.com/uc?export=download&id=1FTuhYIirwkpVYcTHfWcw73sUpIf2ihIP',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.series.series.mo7biroh', 'series', 'Animation'),
  (f, 'tmdb.discover.movie.movies.mo7bd2ar',  'movie',  'Animation'),
  (f, 'trakt.list.21779826',                  'series', 'None'),
  (f, 'trakt.list.24484523',                  'movie',  'None'),
  (f, 'trakt.list.22847039',                  'movie',  'None');

-- Anime
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c5, 'Anime', 2,
  'https://i.postimg.cc/bvdxc0Fk/Anime.png',
  'https://drive.google.com/uc?export=download&id=10NI2ty9yrC-e41SJ8ZGAiE2KqXSjsNb_',
  true, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.5707382',                       'series', 'None'),
  (f, 'trakt.list.23438792',                      'movie',  'None'),
  (f, 'tmdb.discover.movie.studio_ghibli.mpcpum1k','movie', 'None'),
  (f, 'tmdb.discover.movie.mappa.mpcq8hnf',       'movie',  'None');

-- Comedy
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c5, 'Comedy', 3,
  'https://i.postimg.cc/tTDd7BYc/Comedy.png',
  'https://drive.google.com/uc?export=download&id=1QZ1IDK9asCqKpN5PS8m_WxR_BakHcIrI',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.series.series.mo7biroh', 'series', 'Comedy'),
  (f, 'tmdb.discover.movie.movies.mo7bd2ar',  'movie',  'Comedy'),
  (f, 'trakt.list.9659389',                   'movie',  'None'),
  (f, 'trakt.list.5040627',                   'movie',  'None');

-- Documentaries
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c5, 'Documentaries', 4,
  'https://i.postimg.cc/8cfxbkvz/Documentaries.png',
  'https://drive.google.com/uc?export=download&id=1QJPm1w5qpYaqf1JEnYeJi7Zo_rNW888x',
  true, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.series.latest_documentary_shows.mpcqbasr', 'series', 'None'),
  (f, 'trakt.list.801580',   'movie',  'None'),
  (f, 'trakt.list.10235726', 'movie',  'None'),
  (f, 'trakt.list.33762909', 'series', 'None');

-- Drama
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c5, 'Drama', 5,
  'https://i.postimg.cc/W3s62B1j/Drama.png',
  'https://drive.google.com/uc?export=download&id=1OeG4x4YZ9lYRmiZw4SzBjccOqScXS2zE',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.series.series.mo7biroh',  'series', 'Drama'),
  (f, 'tmdb.discover.movie.movies.mo7bd2ar',   'movie',  'Drama'),
  (f, 'tmdb.discover.series.uk_drama.mo2wdbu8','series', 'None'),
  (f, 'trakt.list.1076151',                    'movie',  'None'),
  (f, 'trakt.list.21715794',                   'movie',  'None'),
  (f, 'trakt.list.22957181',                   'movie',  'None');

-- Family
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c5, 'Family', 6,
  'https://i.postimg.cc/rmgGzfDR/Family.png',
  'https://drive.google.com/uc?export=download&id=1mpq4T8jg1kQxMgiBy7XJrr4sWsJkV_qO',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.series.series.mo7biroh', 'series', 'Family'),
  (f, 'tmdb.discover.movie.movies.mo7bd2ar',  'movie',  'Family'),
  (f, 'mdblist.2415',                         'movie',  'None'),
  (f, 'trakt.list.20580022',                  'movie',  'None');

-- Fantasy
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c5, 'Fantasy', 7,
  'https://i.postimg.cc/0jQYS7SQ/Fantasy.png',
  'https://drive.google.com/uc?export=download&id=1Ci69c42Ow16ezvoBnzySd5Wtt5u8ZPMq',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tvdb.discover.series.fantasy_shows.mo9s284k', 'series', 'None'),
  (f, 'tmdb.discover.movie.movies.mo7bd2ar',         'movie',  'Fantasy'),
  (f, 'trakt.list.22847198',                         'movie',  'None');

-- Food
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c5, 'Food', 8,
  'https://i.postimg.cc/vTBrn5nf/Food.png',
  'https://drive.google.com/uc?export=download&id=186FvtD1DfGQ9BtIOuEZLQXnNFq6QEjQH',
  true, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tvdb.discover.series.food.mo7esx5s', 'series', 'None');

-- Horror
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c5, 'Horror', 9,
  'https://i.postimg.cc/KjzPTtTf/Horror.png',
  'https://drive.google.com/uc?export=download&id=165bBSkdDWBjncGBHr3SE0zwX91hcfC51',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.movie.movies.mo7bd2ar', 'movie', 'Horror'),
  (f, 'trakt.list.21193458',                 'movie', 'None'),
  (f, 'trakt.list.4203408',                  'movie', 'None');

-- Martial Arts
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c5, 'Martial Arts', 10,
  'https://i.postimg.cc/B695gqsn/Martial-Arts.png',
  'https://drive.google.com/uc?export=download&id=1SYuGXNXoTX-gdwDta9xHBKfEJprvXDv3',
  true, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.21840363', 'movie', 'None'),
  (f, 'trakt.list.6674425',  'movie', 'None'),
  (f, 'trakt.list.4467615',  'movie', 'None'),
  (f, 'trakt.list.11632332', 'movie', 'None');

-- Musicals
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c5, 'Musicals', 11,
  'https://i.postimg.cc/KYhBHKgH/Musicals.png',
  'https://drive.google.com/uc?export=download&id=1BsYk7xKGLGjuVCNwOW_8FcQ9ChwREM_A',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.2619099', 'movie', 'None'),
  (f, 'trakt.list.4974101', 'movie', 'None');

-- Mystery
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c5, 'Mystery', 12,
  'https://i.postimg.cc/wMGhQ35P/Mystery.png',
  'https://drive.google.com/uc?export=download&id=1ZtGIuVxSe3-iZhv1t_otJKCQuGSy1qVS',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.series.series.mo7biroh', 'series', 'Mystery'),
  (f, 'tmdb.discover.movie.movies.mo7bd2ar',  'movie',  'Mystery'),
  (f, 'trakt.list.19594387',                  'movie',  'None'),
  (f, 'trakt.list.5221223',                   'movie',  'None');

-- Nature
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c5, 'Nature', 13,
  'https://i.postimg.cc/7Lm3z775/Nature.png',
  'https://drive.google.com/uc?export=download&id=1x-EZhP_IszLINr2tBEISVcVDMarIPy81',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.6652017',  'series', 'None'),
  (f, 'trakt.list.23440324', 'series', 'None'),
  (f, 'trakt.list.26957348', 'series', 'None'),
  (f, 'mdblist.84487',       'series', 'None');

-- Reality TV
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c5, 'Reality TV', 14,
  'https://i.postimg.cc/Kjx14KdH/Reality.png',
  'https://drive.google.com/uc?export=download&id=1H4IVJlICYCAO94FgnH-cluwJuTaWkr-4',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.series.latest.mpcugvcy',   'series', 'None'),
  (f, 'tmdb.discover.series.top_rated.mpcuiqyl', 'series', 'None');

-- Romance
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c5, 'Romance', 15,
  'https://i.postimg.cc/KjHnD4rZ/Romance.png',
  'https://drive.google.com/uc?export=download&id=1dDVyiwZ_UhX2lyvoU8HT3zX-nEkRwxo7',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tvdb.discover.series.romantic_shows.mo7eaudn', 'series', 'None'),
  (f, 'tmdb.discover.movie.movies.mo7bd2ar',          'movie',  'Romance'),
  (f, 'trakt.list.21033097',                          'movie',  'None'),
  (f, 'trakt.list.20701912',                          'movie',  'None');

-- Sci-Fi
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c5, 'Sci-Fi', 16,
  'https://i.postimg.cc/NGJ7cPhX/Sci-Fi.png',
  'https://drive.google.com/uc?export=download&id=1gSl6JHJY--Z0HX-6-EWhMWwZWYCSnPO0',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tvdb.discover.series.sci_fi_shows.mo9s3i10', 'series', 'None'),
  (f, 'trakt.list.797798',                          'movie',  'None'),
  (f, 'tmdb.discover.movie.movies.mo7bd2ar',        'movie',  'Science Fiction');

-- Space
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c5, 'Space', 17,
  'https://i.postimg.cc/Xv17qYKk/Space.png',
  'https://drive.google.com/uc?export=download&id=1-KiLdDJId4j29QgpSxvXn6RfCPToKrDs',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.3813071', 'series', 'None');

-- Thriller
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c5, 'Thriller', 18,
  'https://i.postimg.cc/v8qLsSRj/Thriller.png',
  'https://drive.google.com/uc?export=download&id=1MPHKBR2QIwrCWU9Ir_sLRbz_T7ZrjCjO',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tvdb.discover.series.thriller_shows.mo7ecu45', 'series', 'None'),
  (f, 'tmdb.discover.movie.movies.mo7bd2ar',          'movie',  'Thriller'),
  (f, 'trakt.list.22803128',                          'movie',  'None'),
  (f, 'trakt.list.22096238',                          'movie',  'None');

-- War
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c5, 'War', 19,
  'https://i.postimg.cc/tRStjm08/War.png',
  'https://drive.google.com/uc?export=download&id=1khcIurI9a_gPoz4lmJXCziKuFLeyFOTM',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.movie.movies.mo7bd2ar', 'movie', 'War'),
  (f, 'trakt.list.4433767',                  'movie', 'None');

-- Western
INSERT INTO folders (collection_id, name, sort_order, cover_image, hero_video_url, hide_title, focus_gif_enabled)
VALUES (c5, 'Western', 20,
  'https://i.postimg.cc/y6QXHr44/Western.png',
  'https://drive.google.com/uc?export=download&id=1_Ey9wT7I98-sVF_e2rx2zKC4k2xM51TU',
  true, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.movie.movies.mo7bd2ar',  'movie',  'Western'),
  (f, 'tmdb.discover.series.series.mo7biroh', 'series', 'Western'),
  (f, 'trakt.list.22847467',                  'movie',  'None'),
  (f, 'trakt.list.21899611',                  'movie',  'None');


-- ============================================
-- COLLECTION 6: Decades
-- ============================================
INSERT INTO collections (name, sort_order, show_all_tab, focus_glow_enabled)
VALUES ('Decades', 5, true, true) RETURNING id INTO c6;

-- 1980s
INSERT INTO folders (collection_id, name, sort_order, cover_image, hide_title, focus_gif_enabled)
VALUES (c6, '1980s', 0, 'https://i.postimg.cc/CxP1mxKd/80s.png', true, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.91301',                       'movie', 'None'),
  (f, 'tmdb.discover.movie.decades.1980s',   'movie', 'None');

-- 1990s
INSERT INTO folders (collection_id, name, sort_order, cover_image, hide_title, focus_gif_enabled)
VALUES (c6, '1990s', 1, 'https://i.postimg.cc/x1xCt1dy/90s.png', true, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.91300',                       'movie', 'None'),
  (f, 'tmdb.discover.movie.decades.1990s',   'movie', 'None');

-- 2000s
INSERT INTO folders (collection_id, name, sort_order, cover_image, hide_title, focus_gif_enabled)
VALUES (c6, '2000s', 2, 'https://i.postimg.cc/y8YxmZ70/00s.png', true, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.91302',                       'movie', 'None'),
  (f, 'tmdb.discover.movie.decades.2000s',   'movie', 'None');

-- 2010s
INSERT INTO folders (collection_id, name, sort_order, cover_image, hide_title, focus_gif_enabled)
VALUES (c6, '2010s', 3, 'https://i.postimg.cc/mg2kYHTF/10s.png', true, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.91303',                       'movie', 'None'),
  (f, 'tmdb.discover.movie.decades.2010s',   'movie', 'None');

-- 2020s
INSERT INTO folders (collection_id, name, sort_order, cover_image, hide_title, focus_gif_enabled)
VALUES (c6, '2020s', 4, 'https://i.postimg.cc/0y2jYw9p/20s.png', true, true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.91304',                       'movie', 'None'),
  (f, 'tmdb.discover.movie.decades.2020s',   'movie', 'None');


-- ============================================
-- COLLECTION 7: Directors
-- ============================================
INSERT INTO collections (name, sort_order, show_all_tab, focus_glow_enabled, backdrop_image)
VALUES ('Directors', 6, false, true, 'https://i.postimg.cc/2S8X7RGv/Directors.png')
RETURNING id INTO c7;

-- Wes Anderson
INSERT INTO folders (collection_id, name, sort_order, cover_image, hide_title, focus_gif_enabled)
VALUES (c7, 'Wes Anderson', 0, 'https://i.postimg.cc/P55n5nHZ/Wes-Anderson.png', false, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.6252074', 'movie', 'None');

-- Danny Boyle
INSERT INTO folders (collection_id, name, sort_order, cover_image, hide_title, focus_gif_enabled)
VALUES (c7, 'Danny Boyle', 1, 'https://i.postimg.cc/MKD8wKhs/Danny-Boyle.png', false, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.6241345', 'movie', 'None');

-- Tim Burton
INSERT INTO folders (collection_id, name, sort_order, cover_image, hide_title, focus_gif_enabled)
VALUES (c7, 'Tim Burton', 2, 'https://i.postimg.cc/RZZxZxmW/Tim-Burton.png', false, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.6241270', 'movie', 'None');

-- James Cameron
INSERT INTO folders (collection_id, name, sort_order, cover_image, hide_title, focus_gif_enabled)
VALUES (c7, 'James Cameron', 3, 'https://i.postimg.cc/hPrqnPHN/James-Cameron.png', false, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.6252088', 'movie', 'None');

-- Coen Brothers
INSERT INTO folders (collection_id, name, sort_order, cover_image, hide_title, focus_gif_enabled)
VALUES (c7, 'Coen Brothers', 4, 'https://i.postimg.cc/02fqv2LZ/Coen-Brothers.png', false, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.6241522', 'movie', 'None');

-- Ron Howard
INSERT INTO folders (collection_id, name, sort_order, cover_image, hide_title, focus_gif_enabled)
VALUES (c7, 'Ron Howard', 5, 'https://i.postimg.cc/TY9XxYz1/Ron-Howard.png', false, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.6241276', 'movie', 'None');

-- Stanley Kubrick
INSERT INTO folders (collection_id, name, sort_order, cover_image, hide_title, focus_gif_enabled)
VALUES (c7, 'Stanley Kubrick', 6, 'https://i.postimg.cc/JzzCzC8z/Stanley-Kubrick.png', false, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.6241405', 'movie', 'None');

-- Christopher Nolan
INSERT INTO folders (collection_id, name, sort_order, cover_image, hide_title, focus_gif_enabled)
VALUES (c7, 'Christopher Nolan', 7, 'https://i.postimg.cc/m2RGKF6X/Christopher-Nolan.png', false, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.6242091', 'movie', 'None');

-- Martin Scorsese
INSERT INTO folders (collection_id, name, sort_order, cover_image, hide_title, focus_gif_enabled)
VALUES (c7, 'Martin Scorsese', 8, 'https://i.postimg.cc/RCDwJskZ/Martin-Scorsese.png', false, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.24183553', 'movie', 'None');

-- Ridley Scott
INSERT INTO folders (collection_id, name, sort_order, cover_image, hide_title, focus_gif_enabled)
VALUES (c7, 'Ridley Scott', 9, 'https://i.postimg.cc/X780W7RJ/Ridley-Scott.png', false, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.6241250', 'movie', 'None');

-- M. Night Shyamalan
INSERT INTO folders (collection_id, name, sort_order, cover_image, hide_title, focus_gif_enabled)
VALUES (c7, 'M. Night Shyamalan', 10, 'https://i.postimg.cc/X780W7R3/M-Night-Shyamalan.png', false, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.6241387', 'movie', 'None');

-- Steven Spielberg
INSERT INTO folders (collection_id, name, sort_order, cover_image, hide_title, focus_gif_enabled)
VALUES (c7, 'Steven Spielberg', 11, 'https://i.postimg.cc/Z55z5zmq/Steven-Spielberg.png', false, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.6241187', 'movie', 'None');

-- Oliver Stone
INSERT INTO folders (collection_id, name, sort_order, cover_image, hide_title, focus_gif_enabled)
VALUES (c7, 'Oliver Stone', 12, 'https://i.postimg.cc/L6TMS6cH/Oliver-Stone.png', false, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.6241367', 'movie', 'None');

-- Quentin Tarantino
INSERT INTO folders (collection_id, name, sort_order, cover_image, hide_title, focus_gif_enabled)
VALUES (c7, 'Quentin Tarantino', 13, 'https://i.postimg.cc/CLNV0L3L/Quentin-Tarantino.png', false, false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.6241445', 'movie', 'None');

END $$;
