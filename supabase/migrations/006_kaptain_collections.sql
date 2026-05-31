-- 006_kaptain_collections.sql
-- Kaptain's community collection packs (ImKaptain/nuvio-assets on GitHub)
-- Appends to existing B.E.S.T data — does NOT truncate

DO $$
DECLARE
  c UUID; f UUID;
BEGIN

-- ============================================
-- COLLECTION: Actors
-- ============================================
INSERT INTO collections (name, sort_order, show_all_tab, focus_glow_enabled)
VALUES ('Actors', 7, false, true) RETURNING id INTO c;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Adam Sandler', 0, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Adam_Sandler/Adam_Sandler_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Adam_Sandler/Adam_Sandler_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Adam_Sandler_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Angelina Jolie', 1, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Angelina_Jolie/Angelina_Jolie_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Angelina_Jolie/Angelina_Jolie_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Angelina_Jolie_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Anne Hathaway', 2, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Anne_Hathaway/Anne_Hathaway_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Anne_Hathaway/Anne_Hathaway_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Anne_Hathaway_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Arnold Schwarzenegger', 3, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Arnold_Schwarzenegger/Arnold_Schwarzenegger_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Arnold_Schwarzenegger/Arnold_Schwarzenegger_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Arnold_Schwarzenegger_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Ben Stiller', 4, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Ben_Stiller/Ben_Stiller_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Ben_Stiller/Ben_Stiller_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Ben_Stiller_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Benedict Cumberbatch', 5, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Benedict_Cumberbatch/Benedict_Cumberbatch_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Benedict_Cumberbatch/Benedict_Cumberbatch_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Benedict_Cumberbatch_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Bill Murray', 6, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Bill_Murray/Bill_Murray_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Bill_Murray/Bill_Murray_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Bill_Murray_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Brad Pitt', 7, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Brad_Pitt/Brad_Pitt_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Brad_Pitt/Brad_Pitt_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Brad_Pitt_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Channing Tatum', 8, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Channing_Tatum/Channing_Tatum_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Channing_Tatum/Channing_Tatum_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Channing_Tatum_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Christian Bale', 9, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Christian_Bale/Christian_Bale_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Christian_Bale/Christian_Bale_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Christian_Bale_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Chuck Norris', 10, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Chuck_Norris/Chuck_Norris_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Chuck_Norris/Chuck_Norris_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Chuck_Norris_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Clint Eastwood', 11, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Clint_Eastwood/Clint_Eastwood_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Clint_Eastwood/Clint_Eastwood_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Clint_Eastwood_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Daniel Craig', 12, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Daniel_Craig/Daniel_Craig_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Daniel_Craig/Daniel_Craig_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Daniel_Craig_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Denzel Washington', 13, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Denzel_Washington/Denzel_Washington_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Denzel_Washington/Denzel_Washington_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Denzel_Washington_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Dwayne Johnson', 14, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Dwayne_Johnson/Dwayne_Johnson_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Dwayne_Johnson/Dwayne_Johnson_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Dwayne_Johnson_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Emma Stone', 15, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Emma_Stone/Emma_Stone_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Emma_Stone/Emma_Stone_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Emma_Stone_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Florence Pugh', 16, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Florence_Pugh/Florence_Pugh_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Florence_Pugh/Florence_Pugh_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Florence_Pugh_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'George Clooney', 17, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/George_Clooney/George_Clooney_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/George_Clooney/George_Clooney_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/George_Clooney_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Harrison Ford', 18, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Harrison_Ford/Harrison_Ford_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Harrison_Ford/Harrison_Ford_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Harrison_Ford_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Jack Black', 19, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Jack_Black/Jack_Black_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Jack_Black/Jack_Black_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Jack_Black_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Jackie Chan', 20, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Jackie_Chan/Jackie_Chan_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Jackie_Chan/Jackie_Chan_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Jackie_Chan_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Jake Gyllenhaal', 21, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Jake_Gyllenhaal/Jake_Gyllenhaal_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Jake_Gyllenhaal/Jake_Gyllenhaal_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Jake_Gyllenhaal_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Jason Statham', 22, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Jason_Statham/Jason_Statham_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Jason_Statham/Jason_Statham_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Jason_Statham_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Jenna Ortega', 23, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Jenna_Ortega/Jenna_Ortega_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Jenna_Ortega/Jenna_Ortega_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Jenna_Ortega_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Jennifer Aniston', 24, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Jennifer_Aniston/Jennifer_Aniston_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Jennifer_Aniston/Jennifer_Aniston_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Jennifer_Aniston_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Jennifer Lawrence', 25, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Jennifer_Lawrence/Jennifer_Lawrence_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Jennifer_Lawrence/Jennifer_Lawrence_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Jennifer_Lawrence_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Jim Carrey', 26, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Jim_Carrey/Jim_Carrey_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Jim_Carrey/Jim_Carrey_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Jim_Carrey_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Johnny Depp', 27, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Johnny_Depp/Johnny_Depp_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Johnny_Depp/Johnny_Depp_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Johnny_Depp_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Jonah Hill', 28, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Jonah_Hill/Jonah_Hill_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Jonah_Hill/Jonah_Hill_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Jonah_Hill_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Julia Roberts', 29, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Julia_Roberts/Julia_Roberts_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Julia_Roberts/Julia_Roberts_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Julia_Roberts_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Katherine Heigl', 30, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Katherine_Heigl/Katherine_Heigl_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Katherine_Heigl/Katherine_Heigl_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Katherine_Heigl_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Leonardo DiCaprio', 31, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Leonardo_DiCaprio/Leonardo_DiCaprio_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Leonardo_DiCaprio/Leonardo_DiCaprio_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Leonardo_DiCaprio_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Lily Collins', 32, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Lily_Collins/Lily_Collins_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Lily_Collins/Lily_Collins_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Lily_Collins_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Margot Robbie', 33, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Margot_Robbie/Margot_Robbie_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Margot_Robbie/Margot_Robbie_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Margot_Robbie_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Matt Damon', 34, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Matt_Damon/Matt_Damon_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Matt_Damon/Matt_Damon_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Matt_Damon_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Matthew McConaughey', 35, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Matthew_McConaughey/Matthew_McConaughey_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Matthew_McConaughey/Matthew_McConaughey_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Matthew_McConaughey_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Melissa McCarthy', 36, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Melissa_McCarthy/Melissa_McCarthy_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Melissa_McCarthy/Melissa_McCarthy_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Melissa_McCarthy_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Meryl Streep', 37, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Meryl_Streep/Meryl_Streep_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Meryl_Streep/Meryl_Streep_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Meryl_Streep_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Michael Herbig', 38, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Michael_Herbig/Michael_Herbig_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Michael_Herbig/Michael_Herbig_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Michael_Herbig_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Mila Kunis', 39, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Mila_Kunis/Mila_Kunis_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Mila_Kunis/Mila_Kunis_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Mila_Kunis_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Millie Bobby Brown', 40, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Millie_Bobby_Brown/Millie_Bobby_Brown_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Millie_Bobby_Brown/Millie_Bobby_Brown_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Millie_Bobby_Brown_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Morgan Freeman', 41, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Morgan_Freeman/Morgan_Freeman_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Morgan_Freeman/Morgan_Freeman_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Morgan_Freeman_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Nicolas Cage', 42, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Nicolas_Cage/Nicolas_Cage_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Nicolas_Cage/Nicolas_Cage_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Nicolas_Cage_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Nicole Kidman', 43, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Nicole_Kidman/Nicole_Kidman_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Nicole_Kidman/Nicole_Kidman_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Nicole_Kidman_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Owen Wilson', 44, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Owen_Wilson/Owen_Wilson_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Owen_Wilson/Owen_Wilson_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Owen_Wilson_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Reese Witherspoon', 45, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Reese_Witherspoon/Reese_Witherspoon_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Reese_Witherspoon/Reese_Witherspoon_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Reese_Witherspoon_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Robert Downey Jr.', 46, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Robert_Downey_Jr/Robert_Downey_Jr._Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Robert_Downey_Jr/Robert_Downey_Jr._Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Robert_Downey_Jr_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Robin Williams', 47, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Robin_Williams/Robin_Williams_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Robin_Williams/Robin_Williams_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Robin_Williams_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Ryan Reynolds', 48, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Ryan_Reynolds/Ryan_Reynolds_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Ryan_Reynolds/Ryan_Reynolds_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Ryan_Reynolds_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Samuel L. Jackson', 49, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Samuel_L._Jackson/Samuel_L._Jackson_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Samuel_L._Jackson/Samuel_L._Jackson_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Samuel_L_Jackson_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Sandra Bullock', 50, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Sandra_Bullock/Sandra_Bullock_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Sandra_Bullock/Sandra_Bullock_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Sandra_Bullock_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Steve Carell', 51, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Steve_Carell/Steve_Carell_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Steve_Carell/Steve_Carell_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Steve_Carell_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Sydney Sweeney', 52, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Sydney_Sweeney/Sydney_Sweeney_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Sydney_Sweeney/Sydney_Sweeney_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Sydney_Sweeney_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Sylvester Stallone', 53, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Sylvester_Stallone/Sylvester_Stallone_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Sylvester_Stallone/Sylvester_Stallone_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Sylvester_Stallone_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Timothée Chalamet', 54, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Timoth_e_Chalamet/Timoth_e_Chalamet_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Timoth_e_Chalamet/Timoth_e_Chalamet_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Timothée_Chalamet_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Tom Cruise', 55, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Tom_Cruise/Tom_Cruise_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Tom_Cruise/Tom_Cruise_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Tom_Cruise_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Tom Holland', 56, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Tom_Holland/Tom_Holland_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Tom_Holland/Tom_Holland_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Tom_Holland_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Zendaya', 57, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Zendaya/Zendaya_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Actors/Zendaya/Zendaya_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Zendaya_TitleLogo.png')
RETURNING id INTO f;

-- ============================================
-- COLLECTION: Anime
-- ============================================
INSERT INTO collections (name, sort_order, show_all_tab, focus_glow_enabled)
VALUES ('Anime', 8, false, true) RETURNING id INTO c;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Latest Release', 0, 'https://i.postimg.cc/xd7RHS0J/DERNIERS-AJOUTS(4).png', NULL, 'LANDSCAPE', false, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/Latest%20Release/Latest%20Release_Logo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.2483', 'movie', 'None'),
  (f, 'mdblist.2472', 'series', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Popular', 1, 'https://i.postimg.cc/j5L10XjG/DERNIERS-AJOUTS(1).png', NULL, 'LANDSCAPE', false, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/Popular/Popular_Logo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.88469', 'series', 'None'),
  (f, 'mdblist.88468', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Most Watched', 2, 'https://i.postimg.cc/ydkG4PNG/DERNIERS-AJOUTS(2).png', NULL, 'LANDSCAPE', false)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.161995', 'series', 'None'),
  (f, 'mdblist.161994', 'movie', 'None'),
  (f, 'mdblist.13210', 'series', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Upcoming', 3, 'https://i.postimg.cc/k4BH3c5h/DERNIERS-AJOUTS(3).png', NULL, 'LANDSCAPE', false, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/Upcoming/Upcoming_Logo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.12244', 'series', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Dubbed Only', 4, 'https://i.postimg.cc/fLFtbwfH/DERNIERS-AJOUTS(6).png', NULL, 'LANDSCAPE', false, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/Dubbed%20Only/Dubbed%20Only_Logo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.50738', 'series', 'None');

-- ============================================
-- COLLECTION: Awards
-- ============================================
INSERT INTO collections (name, sort_order, show_all_tab, focus_glow_enabled)
VALUES ('Awards', 9, false, true) RETURNING id INTO c;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Academy Awards', 0, 'https://i.postimg.cc/KzdMvyMB/oscars.jpg', NULL, 'LANDSCAPE', false, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/Academy%20Awards/Academy%20Awards_Logo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.list.4325279', 'movie', 'None'),
  (f, 'trakt.list.20492427', 'movie', 'None'),
  (f, 'trakt.list.11505940', 'movie', 'None'),
  (f, 'trakt.list.34697078', 'movie', 'None'),
  (f, 'trakt.list.34698053', 'movie', 'None'),
  (f, 'trakt.list.34698737', 'movie', 'None'),
  (f, 'trakt.list.34698738', 'movie', 'None'),
  (f, 'trakt.list.34698739', 'movie', 'None'),
  (f, 'trakt.list.34698743', 'movie', 'None'),
  (f, 'trakt.list.34698744', 'movie', 'None'),
  (f, 'trakt.list.34698745', 'movie', 'None'),
  (f, 'trakt.list.34698746', 'movie', 'None'),
  (f, 'trakt.list.34698747', 'movie', 'None'),
  (f, 'trakt.list.34698749', 'movie', 'None'),
  (f, 'trakt.list.34698750', 'movie', 'None'),
  (f, 'trakt.list.34698751', 'movie', 'None'),
  (f, 'trakt.list.34698752', 'movie', 'None'),
  (f, 'trakt.list.34698753', 'movie', 'None'),
  (f, 'trakt.list.34698756', 'movie', 'None'),
  (f, 'trakt.list.34698757', 'movie', 'None'),
  (f, 'trakt.list.34698759', 'movie', 'None'),
  (f, 'trakt.list.34698760', 'movie', 'None'),
  (f, 'trakt.list.34698761', 'movie', 'None'),
  (f, 'trakt.list.34698762', 'movie', 'None'),
  (f, 'trakt.list.34698763', 'movie', 'None');

-- ============================================
-- COLLECTION: Genres
-- ============================================
INSERT INTO collections (name, sort_order, show_all_tab, focus_glow_enabled)
VALUES ('Genres', 10, false, true) RETURNING id INTO c;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Action', 0, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Action/Action_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Action/Action_Hover.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Adventure', 1, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Adventure/Adventure_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Adventure/Adventure_Hover.gif', 'LANDSCAPE', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/Adventure/Adventure_Logo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Animation', 2, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Animation/Animation_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Animation/Animation_Hover.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Anime', 3, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Anime/Anime_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Anime/Anime_Hover.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Comedy', 4, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Comedy/Comedy_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Comedy/Comedy_Hover.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Crime', 5, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Crime/Crime_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Crime/Crime_Hover.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Dark Fantasy   Thriller', 6, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Dark%20Fantasy%20_%20Thriller/Dark_Fantasy___Thriller_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Dark%20Fantasy%20_%20Thriller/Dark_Fantasy___Thriller_Hover.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Documentary', 7, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Documentary/Documentary_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Documentary/Documentary_Hover.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Drama', 8, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Drama/Drama_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Drama/Drama_Hover.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Dubbed Only', 9, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Dubbed%20Only/Dubbed_Only_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Dubbed%20Only/Dubbed_Only_Hover.gif', 'LANDSCAPE', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/Dubbed%20Only/Dubbed%20Only_Logo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Family', 10, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Family/Family_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Family/Family_Hover.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Fantasy', 11, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Fantasy/Fantasy_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Fantasy/Fantasy_Hover.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Fantasy   Isekai Worlds', 12, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Fantasy%20_%20Isekai%20Worlds/Fantasy___Isekai_Worlds_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Fantasy%20_%20Isekai%20Worlds/Fantasy___Isekai_Worlds_Hover.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'History', 13, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/History/History_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/History/History_Hover.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Horror', 14, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Horror/Horror_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Horror/Horror_Hover.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Latest Release', 15, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Latest%20Release/Latest_Release_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Latest%20Release/Latest_Release_Hover.gif', 'LANDSCAPE', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/Latest%20Release/Latest%20Release_Logo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Mystery', 16, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Mystery/Mystery_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Mystery/Mystery_Hover.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Popular', 17, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Popular/Popular_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Popular/Popular_Hover.gif', 'LANDSCAPE', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/Popular/Popular_Logo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Reality TV', 18, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Reality%20TV/Reality_TV_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Reality%20TV/Reality_TV_Hover.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Romance', 19, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Romance/Romance_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Romance/Romance_Hover.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Romantic Comedy', 20, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Romantic%20Comedy/Romantic_Comedy_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Romantic%20Comedy/Romantic_Comedy_Hover.gif', 'LANDSCAPE', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/Romantic%20Comedy/Romantic%20Comedy_Logo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Science Fiction', 21, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Science%20Fiction/Science_Fiction_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Science%20Fiction/Science_Fiction_Hover.gif', 'LANDSCAPE', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/Science%20Fiction/Science%20Fiction_Logo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Shonen   Action Hits', 22, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Shonen%20_%20Action%20Hits/Shonen___Action_Hits_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Shonen%20_%20Action%20Hits/Shonen___Action_Hits_Hover.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Stand-Up Comedy', 23, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Stand-Up%20Comedy/Stand_Up_Comedy_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Stand-Up%20Comedy/Stand_Up_Comedy_Hover.gif', 'LANDSCAPE', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/Stand-Up%20Comedy/Stand-Up%20Comedy_Logo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Studio Ghibli Masterpieces', 24, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Studio%20Ghibli%20Masterpieces/Studio_Ghibli_Masterpieces_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Studio%20Ghibli%20Masterpieces/Studio_Ghibli_Masterpieces_Hover.gif', 'LANDSCAPE', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/Studio%20Ghibli%20Masterpieces/Studio%20Ghibli%20Masterpieces_Logo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Studio Spotlight  MAPPA   ufotable ', 25, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Studio%20Spotlight%20_MAPPA%20_%20ufotable_/Studio_Spotlight__MAPPA___ufotable__Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Studio%20Spotlight%20_MAPPA%20_%20ufotable_/Studio_Spotlight__MAPPA___ufotable__Hover.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Thriller', 26, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Thriller/Thriller_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Thriller/Thriller_Hover.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Top Rated All-Time', 27, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Top%20Rated%20All-Time/Top_Rated_All_Time_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Top%20Rated%20All-Time/Top_Rated_All_Time_Hover.gif', 'LANDSCAPE', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/Top%20Rated%20All-Time/Top%20Rated%20All-Time_Logo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Upcoming', 28, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Upcoming/Upcoming_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Upcoming/Upcoming_Hover.gif', 'LANDSCAPE', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/Upcoming/Upcoming_Logo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'War', 29, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/War/War_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/War/War_Hover.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Western', 30, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Western/Western_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Genres/Western/Western_Hover.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

-- ============================================
-- COLLECTION: Legendary Directors
-- ============================================
INSERT INTO collections (name, sort_order, show_all_tab, focus_glow_enabled)
VALUES ('Legendary Directors', 11, false, true) RETURNING id INTO c;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Alfred Hitchcock', 0, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Alfred_Hitchcock/Alfred_Hitchcock_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Alfred_Hitchcock/Alfred_Hitchcock_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Alfred_Hitchcock_TitleLogo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.159462', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Brian De Palma', 1, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Brian_De_Palma/Brian_De_Palma_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Brian_De_Palma/Brian_De_Palma_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Brian_De_Palma_TitleLogo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.159449', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Christopher Nolan', 2, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Christopher_Nolan/Christopher_Nolan_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Christopher_Nolan/Christopher_Nolan_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Christopher_Nolan_TitleLogo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.159441', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'David Fincher', 3, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/David_Fincher/David_Fincher_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/David_Fincher/David_Fincher_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/David_Fincher_TitleLogo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.159463', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'David Lynch', 4, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/David_Lynch/David_Lynch_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/David_Lynch/David_Lynch_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/David_Lynch_TitleLogo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.159451', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Denis Villeneuve', 5, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Denis_Villeneuve/Denis_Villeneuve_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Denis_Villeneuve/Denis_Villeneuve_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Denis_Villeneuve_TitleLogo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.159458', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Francis Ford Coppola', 6, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Francis_Ford_Coppola/Francis_Ford_Coppola_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Francis_Ford_Coppola/Francis_Ford_Coppola_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Francis_Ford_Coppola_TitleLogo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.159465', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'George Lucas', 7, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/George_Lucas/George_Lucas_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/George_Lucas/George_Lucas_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/George_Lucas_TitleLogo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Greta Gerwig', 8, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Greta_Gerwig/Greta_Gerwig_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Greta_Gerwig/Greta_Gerwig_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Greta_Gerwig_TitleLogo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.159472', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Guillermo del Toro', 9, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Guillermo_del_Toro/Guillermo_del_Toro_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Guillermo_del_Toro/Guillermo_del_Toro_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Guillermo_del_Toro_TitleLogo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.159466', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'James Cameron', 10, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/James_Cameron/James_Cameron_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/James_Cameron/James_Cameron_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/James_Cameron_TitleLogo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.159456', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'John Carpenter', 11, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/John_Carpenter/John_Carpenter_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/John_Carpenter/John_Carpenter_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/John_Carpenter_TitleLogo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.159457', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Martin Scorsese', 12, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Martin_Scorsese/Martin_Scorsese_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Martin_Scorsese/Martin_Scorsese_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Martin_Scorsese_TitleLogo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.159467', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Paul Thomas Anderson', 13, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Paul_Thomas_Anderson/Paul_Thomas_Anderson_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Paul_Thomas_Anderson/Paul_Thomas_Anderson_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Paul_Thomas_Anderson_TitleLogo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.159464', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Peter Jackson', 14, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Peter_Jackson/Peter_Jackson_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Peter_Jackson/Peter_Jackson_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Peter_Jackson_TitleLogo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.159468', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Quentin Tarantino', 15, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Quentin_Tarantino/Quentin_Tarantino_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Quentin_Tarantino/Quentin_Tarantino_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Quentin_Tarantino_TitleLogo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.159453', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Ridley Scott', 16, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Ridley_Scott/Ridley_Scott_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Ridley_Scott/Ridley_Scott_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Ridley_Scott_TitleLogo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.159454', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Spike Lee', 17, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Spike_Lee/Spike_Lee_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Spike_Lee/Spike_Lee_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Spike_Lee_TitleLogo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.159452', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Stanley Kubrick', 18, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Stanley_Kubrick/Stanley_Kubrick_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Stanley_Kubrick/Stanley_Kubrick_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Stanley_Kubrick_TitleLogo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.159469', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Steven Spielberg', 19, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Steven_Spielberg/Steven_Spielberg_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Steven_Spielberg/Steven_Spielberg_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Steven_Spielberg_TitleLogo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.159455', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'Wes Anderson', 20, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Wes_Anderson/Wes_Anderson_Base.png', 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Directors/Wes_Anderson/Wes_Anderson_Hover.gif', 'POSTER', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/TitleLogos/Wes_Anderson_TitleLogo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.159471', 'movie', 'None');

-- ============================================
-- COLLECTION: By Decade
-- ============================================
INSERT INTO collections (name, sort_order, show_all_tab, focus_glow_enabled)
VALUES ('By Decade', 12, false, true) RETURNING id INTO c;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, '2020s Movies', 0, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/f07d1484.webp', 'https://github.com/luckynumb3rs/stremio-perfect-setup/blob/main/collections/decades/focused/2020s.gif?raw=true', 'LANDSCAPE', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/2020s%20Movies/2020s%20Movies_Logo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.movie.decades.2020s', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, '10s Movies', 1, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/9cb570e8.webp', 'https://github.com/luckynumb3rs/stremio-perfect-setup/blob/main/collections/decades/focused/2010s.gif?raw=true', 'LANDSCAPE', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/10s%20Movies/10s%20Movies_Logo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.movie.decades.2010s', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, '00s Movies', 2, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/4449e62a.webp', 'https://github.com/luckynumb3rs/stremio-perfect-setup/blob/main/collections/decades/focused/2000s.gif?raw=true', 'LANDSCAPE', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/00s%20Movies/00s%20Movies_Logo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.movie.decades.2000s', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, '90s Movies', 3, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/712f6a02.webp', 'https://github.com/luckynumb3rs/stremio-perfect-setup/blob/main/collections/decades/focused/1990s.gif?raw=true', 'LANDSCAPE', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/90s%20Movies/90s%20Movies_Logo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.movie.decades.1990s', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, '80s Movies', 4, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/3583b980.webp', 'https://github.com/luckynumb3rs/stremio-perfect-setup/blob/main/collections/decades/focused/1980s.gif?raw=true', 'LANDSCAPE', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/80s%20Movies/80s%20Movies_Logo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.movie.decades.1980s', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, '70s Movies', 5, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/7ab327a6.webp', 'https://github.com/luckynumb3rs/stremio-perfect-setup/blob/main/collections/decades/focused/1970s.gif?raw=true', 'LANDSCAPE', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/70s%20Movies/70s%20Movies_Logo.png')
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'tmdb.discover.movie.decades.1970s', 'movie', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, '60s Movies', 6, 'https://github.com/luckynumb3rs/stremio-perfect-setup/blob/main/collections/decades/focused/1960s.gif?raw=true', 'https://github.com/luckynumb3rs/stremio-perfect-setup/blob/main/collections/decades/focused/1960s.gif?raw=true', 'LANDSCAPE', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/60s%20Movies/60s%20Movies_Logo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, '50s Movies', 7, 'https://github.com/luckynumb3rs/stremio-perfect-setup/blob/main/collections/decades/cover/1950s.jpg?raw=true', 'https://github.com/luckynumb3rs/stremio-perfect-setup/blob/main/collections/decades/focused/1950s.gif?raw=true', 'LANDSCAPE', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/50s%20Movies/50s%20Movies_Logo.png')
RETURNING id INTO f;

-- ============================================
-- COLLECTION: Streaming Services
-- ============================================
INSERT INTO collections (name, sort_order, show_all_tab, focus_glow_enabled)
VALUES ('Streaming Services', 13, false, true) RETURNING id INTO c;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Netflix', 0, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/49571953.webp', 'https://64.media.tumblr.com/9f93a9fc2e02fb466eb02a7d2247cb6e/a5b604d3737fc559-49/s500x750/403804744183922f6091d48139021fc3da22f786.gifv', 'LANDSCAPE', true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.86752', 'movie', 'None'),
  (f, 'mdblist.86751', 'series', 'None'),
  (f, 'mdblist.86628', 'movie', 'None'),
  (f, 'mdblist.86620', 'series', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Prime Video', 1, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/5c86c888.webp', 'https://64.media.tumblr.com/5c5ed8bf948c5b3ca63a11544b94c720/55dbe5d6db4b66a5-bf/s500x750/d6686beaab57aa152f1b92a4562f757a1c522a2f.gifv', 'LANDSCAPE', true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.86755', 'movie', 'None'),
  (f, 'mdblist.86753', 'series', 'None'),
  (f, 'mdblist.86623', 'movie', 'None'),
  (f, 'mdblist.86624', 'series', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'HBO Max', 2, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/b59babf1.webp', 'https://64.media.tumblr.com/cca7a86d443a0bc88536a2ad6ce72aec/b495f88d5c1df470-a2/s640x960/4cb9b614191d17d02c946b4ca59548cd333c06fd.gifv', 'LANDSCAPE', true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'streaming.hbm_movie', 'movie', 'None'),
  (f, 'mdblist.89647', 'movie', 'None'),
  (f, 'mdblist.89649', 'series', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Disney+', 3, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/b8c0d25b.webp', 'https://64.media.tumblr.com/ca6dc6d4e8a260c0c5f40c47c7334e57/eb71329b4dc482d5-50/s500x750/e9e82c5bca839be289f3d87863141ebf6d7fca28.gifv', 'LANDSCAPE', true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.86759', 'movie', 'None'),
  (f, 'mdblist.86758', 'series', 'None'),
  (f, 'mdblist.86945', 'movie', 'None'),
  (f, 'mdblist.86946', 'series', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Apple TV+', 4, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/4d8f0a8f.webp', 'https://64.media.tumblr.com/d717319220a7d26bdaa88e72f6f76889/d9a7a808f588d8f4-63/s500x750/959b0ca57f53153b2ca9adaf414859e45e3734e6.gifv', 'LANDSCAPE', true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.86757', 'movie', 'None'),
  (f, 'mdblist.86756', 'series', 'None'),
  (f, 'mdblist.86626', 'movie', 'None'),
  (f, 'mdblist.86625', 'series', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Hulu', 5, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/3a4d1b46.webp', 'https://64.media.tumblr.com/3a7015de27b570e421a0182a66d0a69b/0ec3a7379449b39d-2d/s1280x1920/962f0dcfa0a2458bd6bf923ff47776f2404bf43a.gifv', 'LANDSCAPE', true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.127955', 'movie', 'None'),
  (f, 'mdblist.127954', 'series', 'None'),
  (f, 'mdblist.127956', 'movie', 'None'),
  (f, 'mdblist.127957', 'series', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Paramount+', 6, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/3b626b1a.webp', 'https://ingeniousguru.com/wp-content/uploads/2022/10/Paramount.gif', 'LANDSCAPE', true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.86762', 'movie', 'None'),
  (f, 'mdblist.86761', 'series', 'None'),
  (f, 'mdblist.89366', 'movie', 'None'),
  (f, 'mdblist.89374', 'series', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Peacock', 7, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/970b675f.webp', 'https://64.media.tumblr.com/a378bf124ed7d00c8d7430cb8a9ae0cc/9e0da9dbc32641f6-b2/s1280x1920/e8c0ba2f6aadae5b6f532a177926528e94b04d68.gifv', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Shudder', 8, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/99e24ce1.webp', 'https://nuvioapp.space/uploads/covers/1a03bb2e-9478-4ede-93f4-69a1a306837a.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'MGM+', 9, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/d490e713.webp', 'https://64.media.tumblr.com/9f43b185411e18d71444c9a5a5a79632/5d68ae94e9917470-70/s500x750/0871e87c17045759735ef64c26703c71b585bfb0.gifv', 'LANDSCAPE', true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'mdblist.48305', 'movie', 'None'),
  (f, 'mdblist.48306', 'series', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Starz', 10, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/9e92f9b6.webp', 'https://64.media.tumblr.com/81fe52878aad139bc7b4ff5db7efc766/1e7a62d9e4b13b7a-a2/s500x750/740d23b1e14a96d02282d62190ee61e2a30aed4d.gifv', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Discovery+', 11, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/dbed63f2.webp', 'https://max-streams.gleeze.com/images/Discovery.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Crunchyroll', 12, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/129a4038.webp', 'https://i.postimg.cc/Y2DYwj4f/Crunchyrroll-50FPS.gif', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Curiosity Stream', 13, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/7bec8cc8.webp', NULL, 'LANDSCAPE', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Criterion', 14, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/3bd59373.webp', NULL, 'LANDSCAPE', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Mubi', 15, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/7c4bd708.webp', NULL, 'LANDSCAPE', false)
RETURNING id INTO f;

-- ============================================
-- COLLECTION: Film Collections
-- ============================================
INSERT INTO collections (name, sort_order, show_all_tab, focus_glow_enabled)
VALUES ('Film Collections', 14, false, true) RETURNING id INTO c;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, '🎬 Action Collections', 0, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/dcb10a2e.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, '😂 Comedy Collections', 1, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/43b2d5ca.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, '🔫 Crime Collections', 2, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/b132769f.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, '🎭 Drama Collections', 3, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/3ac59efc.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, '👨‍👩‍👧‍👦 Family & Animation Collections', 4, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/d5ed3ea2.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, '🧙 Fantasy & Adventure Collections', 5, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/a096f796.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, '🔪 Horror Collections', 6, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/7781af3b.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, '🔍 Mystery Collections', 7, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/63c34493.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, '🚀 Sci-Fi Collections', 8, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/559ca341.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, '😰 Thriller Collections', 9, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/466e410a.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, '⚔️ War Collections', 10, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/3d6f5a2a.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'A Nightmare on Elm Street', 11, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/3689fda1.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'A Quiet Place', 12, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/d56c8626.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Ace Ventura', 13, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/38ad4f29.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Alien', 14, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/2c74418f.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Alvin and the Chipmunks', 15, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/4f63afe9.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'American Pie', 16, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/344b063b.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Anchorman', 17, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/14c1ab90.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Austin Powers', 18, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/26dc4800.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Back to the Future', 19, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/b2663518.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Bad Boys', 20, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/6ffc69f0.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Behind Enemy Lines', 21, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/d70047f6.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Beverly Hills Cop', 22, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/9ff1c712.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Big Momma''s House', 23, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/17bf57fc.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Blade', 24, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/790dff03.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Blade Runner', 25, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/eaef5071.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Bridget Jones', 26, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/b8be3443.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Bring It On', 27, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/46f10451.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Cars', 28, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/9c7fef1c.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Child''s Play', 29, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/ff20cbec.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Clerks', 30, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/b4cf0df9.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Creed', 31, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/00b20809.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Daddy''s Home', 32, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/dd4903d0.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Demon Slayer', 33, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/792bd6ca.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Despicable Me', 34, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/aa875555.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Detective Conan', 35, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/d109acb6.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Diary of a Wimpy Kid', 36, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/dc54a920.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Die Hard', 37, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/9e972baa.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Dirty Harry', 38, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/905f56ef.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Divergent', 39, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/ab324ad1.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Don''t Breathe', 40, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/c5d59c00.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Dragon Ball', 41, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/99abe534.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Dune', 42, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/526d7d80.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Enola Holmes', 43, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/c1b5bd49.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Escape Room', 44, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/7476342e.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Evangelion', 45, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/bb2ca404.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Evil Dead', 46, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/df6ec619.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Fantastic Beasts', 47, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/aa84780f.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Fifty Shades', 48, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/8cb13575.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Final Destination', 49, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/7b075ae1.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Finding Nemo', 50, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/fdaf249c.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Friday the 13th', 51, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/a9fd14b0.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Ghostbusters', 52, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/3fac65be.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Goal!', 53, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/d991629c.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Godzilla', 54, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/b7a013be.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Guardians of the Galaxy', 55, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/47eec346.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Halloween', 56, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/23069ebe.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Hannibal Lecter', 57, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/5fdc64d1.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Harry Potter', 58, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/7649ef92.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Hellraiser', 59, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/7b6a757c.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Home Alone', 60, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/741800f0.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Hotel Transylvania', 61, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/d12a44e3.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'How to Train Your Dragon', 62, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/f5d559ca.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Ice Age', 63, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/781fa072.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Indiana Jones', 64, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/a913f937.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Insidious', 65, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/3062357d.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'It', 66, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/1556754d.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'James Bond', 67, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/b44d3a28.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Jarhead', 68, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/81e22603.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Jaws', 69, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/2939d81b.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'John Wick', 70, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/a579c22b.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Jumanji', 71, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/d1bbf235.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Jump Street', 72, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/f6e8adb6.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Jurassic Park', 73, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/8f7531dd.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'King Kong (1976)', 74, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/f6b1cb78.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Kingsman', 75, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/4d59deea.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Knives Out', 76, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/0fa76102.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Kung Fu Panda', 77, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/af023ee1.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Legally Blonde', 78, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/00955ea1.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Lethal Weapon', 79, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/ea698ab8.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Mad Max', 80, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/ba07868f.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Madagascar', 81, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/687577b6.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Magic Mike', 82, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/d08d2fc0.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Major League', 83, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/605a022d.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Man of Steel', 84, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/9dabd5c7.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Meet the Parents', 85, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/d105299d.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Men in Black Collection', 86, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/ed15bf82.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Missing in Action', 87, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/18f9387e.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Mission: Impossible', 88, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/3f691530.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Monsters, Inc.', 89, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/3cd34e57.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'My Hero Academia', 90, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/8a2d5903.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Naruto', 91, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/17f18526.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'National Lampoon''s Vacation', 92, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/d8c849ca.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'National Treasure', 93, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/51432bbe.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Night at the Museum', 94, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/b7522cb4.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Now You See Me', 95, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/f7892a33.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Ocean''s', 96, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/794262fb.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'One Piece', 97, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/c94a0c30.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Pacific Rim', 98, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/c1e081d8.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Paddington', 99, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/1fb92b94.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Paranormal Activity', 100, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/295bd9af.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Percy Jackson', 101, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/c1a5f914.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Pirates of the Caribbean', 102, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/563825d1.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Pitch Perfect', 103, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/84ed6b50.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Planet of the Apes (Original)', 104, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/a4d9d3e6.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Pokémon', 105, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/b0c7b7eb.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Poltergeist', 106, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/93361710.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Predator', 107, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/bcf0d4e0.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Rambo', 108, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/300dea0f.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Resident Evil', 109, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/c81d6b06.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Robert Langdon', 110, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/bcc7e1cb.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'RoboCop', 111, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/fc7ef774.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Rocky', 112, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/2a82defa.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Rush Hour', 113, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/60eea627.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Saw', 114, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/6b958d6a.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Scary Movie', 115, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/df5fcf3a.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Scooby-Doo', 116, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/fec1439c.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Scream', 117, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/ccf7d4df.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Sherlock Holmes', 118, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/511c48c8.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Shrek', 119, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/5460f3a5.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Sicario', 120, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/8edc704b.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Sing', 121, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/c84a8b86.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Sniper', 122, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/0265d5f0.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Spider-Man', 123, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/657027ce.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Spider-Man: Spider-Verse', 124, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/3e68413a.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Star Trek: Alternate Reality', 125, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/c1568cd1.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Star Wars', 126, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/2f0dac1f.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Starship Troopers', 127, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/678a458a.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Step Up', 128, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/6fafb3ef.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Addams Family (Animated)', 129, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/0d1a0e02.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Boondock Saints', 130, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/f31ac656.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Boss Baby', 131, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/ab40d744.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Bourne', 132, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/f28b60be.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Chronicles of Narnia', 133, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/0f380e0e.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Conjuring', 134, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/1cb88558.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Dark Knight', 135, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/7948192d.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Dirty Dozen', 136, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/11713b5c.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Equalizer', 137, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/d91b26b5.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Exorcist', 138, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/36f9b405.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Expendables', 139, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/027dbd9e.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Fast and the Furious', 140, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/5e5db9d7.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Godfather', 141, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/a547f450.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Grudge', 142, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/f4806772.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Hangover', 143, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/6148088a.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Hannibal Lecter', 144, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/5fdc64d1.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Hobbit', 145, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/4f4fc8b4.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Hunger Games', 146, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/f1ada021.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Incredibles', 147, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/83f3a2da.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Karate Kid', 148, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/01958ba9.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Lego Movie', 149, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/e9158bb6.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Lord of the Rings', 150, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/a52436af.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Matrix', 151, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/6dcc40bb.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Maze Runner', 152, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/c6b1f8dc.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Mighty Ducks', 153, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/74358baf.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Mummy', 154, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/42fbdc73.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Omen', 155, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/c90d869d.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Purge', 156, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/ab5648ce.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Ring', 157, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/c998383a.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Secret Life of Pets', 158, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/7175f50b.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Terminator', 159, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/8bcbf4ec.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Transporter', 160, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/edca54de.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'The Twilight', 161, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/599a9d56.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Top Gun', 162, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/143f4860.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Toy Story', 163, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/fc258a59.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Transformers', 164, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/e46ec78e.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Tremors', 165, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/3cf415a8.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Trolls Holiday', 166, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/f9e1726a.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'TRON', 167, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/19742b41.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Underworld', 168, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/0d236814.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'V/H/S', 169, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/3b3f45f0.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Wayne''s World', 170, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/412f6c2f.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Wreck-It Ralph', 171, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/fd662458.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'X-Men', 172, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/726b165f.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'xXx', 173, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/c38a8e3a.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Zoolander', 174, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/assets/images/dfd7c503.webp', NULL, 'POSTER', false)
RETURNING id INTO f;

-- ============================================
-- COLLECTION: Trending & New
-- ============================================
INSERT INTO collections (name, sort_order, show_all_tab, focus_glow_enabled)
VALUES ('Trending & New', 15, false, true) RETURNING id INTO c;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'For You', 0, 'https://i.ibb.co/ccprGWNw/For-you-Base.png', 'https://i.ibb.co/Jw7mYdzT/For-you-Hover.png', 'LANDSCAPE', true)
RETURNING id INTO f;
INSERT INTO folder_catalogs (folder_id, catalog_id, media_type, genre) VALUES
  (f, 'trakt.upnext', 'series', 'None'),
  (f, 'trakt.unwatched', 'series', 'None'),
  (f, 'trakt.calendar', 'series', 'None'),
  (f, 'trakt.recommendations.movies', 'movie', 'None'),
  (f, 'trakt.recommendations.shows', 'series', 'None'),
  (f, 'trakt.watchlist', 'all', 'None');

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'New Movies', 1, 'https://i.ibb.co/RGWLbN1j/New-Movies-Base.png', 'https://i.ibb.co/0pDkBjh5/New-Movies-Hover.png', 'LANDSCAPE', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/New%20Movies/New%20Movies_Logo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled, title_logo)
VALUES (c, 'New Series', 2, 'https://i.ibb.co/fjPLCdm/New-Series-Base.png', 'https://i.ibb.co/4w5dBfyg/New-Series-Hover.png', 'LANDSCAPE', true, 'https://raw.githubusercontent.com/ImKaptain/nuvio-assets/main/Misc/New%20Series/New%20Series_Logo.png')
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Trending Movies', 3, 'https://i.ibb.co/bMXtwmrB/Trending-Movies-Base.png', 'https://i.ibb.co/VYKdQKRd/Trending-Movies-Hover.png', 'LANDSCAPE', true)
RETURNING id INTO f;

INSERT INTO folders (collection_id, name, sort_order, cover_image, focus_gif, tile_shape, focus_gif_enabled)
VALUES (c, 'Trending TV', 4, 'https://i.ibb.co/JFQ07xpm/Trending-Series-Base.png', 'https://i.ibb.co/cKMsL4gt/Trending-Series-Hover.png', 'LANDSCAPE', true)
RETURNING id INTO f;

END $$;
