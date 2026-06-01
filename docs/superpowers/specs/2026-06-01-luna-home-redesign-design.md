# Luna — Home Redesign, Detail Page, Web Player Design Spec

**Date:** 2026-06-01  
**Status:** Approved  
**Scope:** LunaWeb (Next.js) + LunaApp (SwiftUI iOS/macOS)

---

## 1. Home Screen Redesign

### 1.1 Layout Order (top → bottom)

1. **Cinematic Hero** — auto-rotating featured item
2. **Continue Watching** — horizontal scroll, real artwork, progress bar
3. **Popular Movies** — horizontal poster row
4. **Popular TV Shows** — horizontal poster row
5. **Trending Movies** — horizontal poster row
6. **Trending TV Shows** — horizontal poster row
7. **Folder Grid Sections** — one per collection (Genres, Decades, Streaming, Franchises, UK TV, Directors, etc.) displayed as 4-column poster grids

### 1.2 Cinematic Hero

- **Source pool:** Top 5 items ranked by `popularity` score merged across all 4 main rows (Popular Movies, Popular TV Shows, Trending Movies, Trending TV Shows)
- **Background:** `meta.background` (wide TMDB backdrop image), with a `linear-gradient` overlay (left-to-right: `black/90 → black/50 → transparent`)
- **Bottom fade:** `linear-gradient` from `transparent → background-color` to blend into the row section below
- **Content (bottom-left):**
  - Source label (e.g. "Popular Movies") in accent color, uppercase, small tracking
  - Title — large, bold, tight letter-spacing
  - Metadata line: `Type · Genres · Year · ★ Rating`
  - Description — max 2 lines, clipped
  - Buttons: **Watch Now** (solid white/black) + **+ My List** (frosted)
- **Rotation:** Auto-advances every 6 seconds. Pauses on hover (web) / tap (iOS). Dot indicators bottom-right.
- **Meta fetch:** For each of the 5 items, fetch `meta` to get `background`, `description`, `genres`, `releaseInfo`, `imdbRating`. Cache results for the session.

### 1.3 Continue Watching

- Fetch `watchProgress` as today, but also call `fetchMeta` for each item to retrieve `poster` + `name`
- Card size: `192×108px` (16:9 landscape)
- Show: poster/backdrop image, play icon overlay on hover, progress bar at bottom, title below, `X% watched` sub-label
- Clicking navigates to `/browse/{type}/{id}` (web) or `DetailScreen` (iOS)

### 1.4 The 4 Main Rows

- These are always horizontal scroll rows, never collapsed or hidden
- Identified by **exact folder name match** against: `"Popular Movies"`, `"Popular TV Shows"`, `"Trending Movies"`, `"Trending TV Shows"`
- Card size: `120×180px` portrait poster
- No expand/collapse toggle — always visible

### 1.5 Folder Grid Sections

- All other folders/collections render as **4-column poster grids** inline on the home screen
- Each collection gets a section heading (collection name)
- Each folder = one cell: `aspect-ratio: 2/3`, shows `cover_image` from DB or a placeholder gradient
- Folder name shown at bottom of cell
- Tapping a folder navigates to `/collections/{folderId}` (already exists in LunaWeb) showing all content in that folder as a scrollable grid
- **No collapse/expand buttons** — all sections are always fully expanded and visible

---

## 2. Series & Movie Detail Page

### 2.1 Layout

1. **Full-width backdrop** — `meta.background` image, full bleed, `height: 50vh min 360px`, gradient fade to background at bottom
2. **Info panel** below backdrop:
   - Title (large, bold)
   - Metadata: `Type · Genres · Year · ★ Rating · Age Rating · Runtime`
   - Genre chips (pill badges)
   - Description (3 lines, expandable)
   - Action buttons: **Watch** (solid), **+ My List**, **▷ Trailer**
3. **Tab bar:** Episodes | Cast | Details (More Like This)
4. **Episodes tab:**
   - Season selector (dropdown/tabs for each season)
   - Horizontal scroll of episode cards: `180×101px` thumbnail + episode number + title + 2-line description
5. **Cast tab:**
   - Horizontal scroll of cast members: circular avatar + name + character
6. **Details tab:**
   - Network logos, Production company logos, More Like This grid

### 2.2 Data Sources

- `MetaDetail.background` → backdrop
- `MetaDetail.cast` → cast section
- `MetaDetail.links` → filter `category === "network"` and `category === "production"` for those panels
- `MetaDetail.seasons` / `MetaDetail.videos` → episode list
- `MetaDetail.moreLikeThis` → More Like This grid

---

## 3. Web Player Redesign & Fix

### 3.1 Visual Design (Apple-native style)

- **Background:** full-screen video, black letterbox
- **Controls overlay:** gradient top bar + gradient bottom bar, transparent middle
- **Top bar:**
  - Left: `← Back` text button
  - Center: `Title · Year` label
  - Right: AirPlay icon, Picture-in-Picture icon
- **Center area:** `±15s skip` arc buttons + frosted glass play/pause button (`backdrop-blur`, white border, semi-transparent fill)
- **Bottom scrubber:** current time left, track (buffered layer + filled layer + draggable thumb), remaining time right
- **Bottom controls row:**
  - Left: Volume icon + expandable slider
  - Right: Sources (three-dot), Subtitles & Audio, Playback Speed, Fullscreen
- Controls auto-hide after 3.5s of inactivity, show on mouse move / tap

### 3.2 HLS Audio Fix

- Set `hls.startLevel = 0` on init
- Listen for `AUDIO_TRACKS_UPDATED` before setting default track (not `MANIFEST_PARSED` alone)
- Add `audioTrackController` config to HLS options
- When switching audio: `hls.audioTrack = id` + verify the track actually changed via `AUDIO_TRACK_SWITCHED` event before updating UI state

### 3.3 HLS Subtitle Fix

- Set `renderTextTracksNatively: false` in HLS config — this prevents the browser from rendering WebVTT as hidden native tracks
- Implement a custom subtitle cue overlay: listen to `hls.on(Hls.Events.CUES_UPDATED)` and render cue text in a positioned `<div>` above the video, styled for readability (white text, dark semi-transparent background pill)
- Subtitle off = no cues rendered
- Subtitle on = render active cues in the overlay div

### 3.4 Remove Fake Data

- Remove the hardcoded fake chapters panel entirely (it served no real purpose)
- Quality panel: derive actual quality levels from `hls.levels` (the HLS manifest levels array), not a hardcoded list
- If `hls.levels` is empty (non-HLS stream), hide the quality button

### 3.5 Sources Panel

- Keep existing sources panel (it works correctly)
- Move sources trigger to the three-dot button in the bottom-right controls

---

## 4. Technical Notes

### 4.1 Framework

Stay on **Next.js 14** — no migration. All issues are configuration/implementation, not framework-level.

### 4.2 Row Identification

In `CatalogRepository.loadFromCollections`, tag each `CatalogRow` with a `isMainRow: Bool` flag when `folder.name` matches one of the 4 main row names (case-insensitive). The home screen uses this flag to decide render mode (horizontal row vs. folder grid).

Alternatively (simpler): check `row.title` in the view layer — if it matches the 4 main names, render as a horizontal row; otherwise render as a folder grid cell within its collection section.

### 4.3 Hero Rotation (Web)

- In `home/page.tsx`, after rows are built: collect item[0] from each of the 4 main rows → rank by `popularity` → take top 5 → store as `featuredItems: FeaturedHomeItem[]`
- `useEffect` with a `setInterval(6000)` increments `featuredIndex` mod 5
- Pause on `mouseenter`, resume on `mouseleave`
- Prefetch meta for all 5 items on load (parallel)

### 4.4 Hero Rotation (iOS)

- In `HomeScreen.swift`, after catalog loads: collect top 5 items by `popularity` across the 4 main rows
- Use `@State private var featuredIndex = 0` + `Timer.scheduledTimer(withTimeInterval: 6, repeats: true)`
- Invalidate timer on `onDisappear`

### 4.5 Continue Watching Poster (Web)

- `home/page.tsx` already calls `fetchMeta` per continue-watching item for the name. Extend this to also extract `poster` and `background` and pass through to the card component.

### 4.6 Continue Watching (iOS)

- `ContinueWatchingCard` in `HomeScreen.swift` currently shows a placeholder `RoundedRectangle`. Fix: fetch `MetaPreview` for each item using `MetaRepository` and display `AsyncImage` with the poster URL.
- Tapping a card should push to `DetailScreen(mediaId:type:name:)` then immediately trigger stream selection.

---

## 5. Out of Scope

- Admin panel changes
- Auth flow changes
- Supabase schema changes (folder_sources, collections already have all needed fields)
- iOS watchlist / library syncing

---

## 6. File Map

| File | Change |
|------|--------|
| `LunaWeb/src/app/home/page.tsx` | Hero rotation, CW poster fetch, row split |
| `LunaWeb/src/app/home/home-data.ts` | `pickFeaturedItems` (plural, top-5) |
| `LunaWeb/src/components/HomeHero.tsx` | Cinematic backdrop design, rotation dots |
| `LunaWeb/src/components/MediaRow.tsx` | Unchanged (still used for 4 main rows) |
| `LunaWeb/src/components/FolderGrid.tsx` | **New** — 4-col poster grid for folders |
| `LunaWeb/src/components/Player.tsx` | Full redesign + HLS fixes |
| `LunaWeb/src/app/browse/[type]/[id]/page.tsx` | Detail page redesign (existing route) |
| `LunaWeb/src/app/collections/[folderId]/page.tsx` | Folder browse page (existing route, verify grid layout) |
| `Apps/LunaApp/Sources/Screens/HomeScreen.swift` | Hero rotation, CW fix, folder grid |
| `Apps/LunaApp/Sources/Components/ContentCard.swift` | No change needed |
| `Apps/LunaApp/Sources/Screens/DetailScreen.swift` | Nuveia-style layout |
