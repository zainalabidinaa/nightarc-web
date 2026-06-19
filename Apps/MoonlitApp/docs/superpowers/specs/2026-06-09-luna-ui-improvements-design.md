# Moonlit UI Improvements — Design Spec
**Date:** 2026-06-09  
**Status:** Approved for implementation planning  
**Subsystems:** Player · Detail Screen · Library · Settings + Roles

---

## 1. Player Enhancements

### 1.1 Liquid Glass Audio Slider
- A frosted pill-shaped volume slider appears in the **top-right** corner of the player, visible only while controls are shown.
- Uses iOS 26 `.glassEffect` / `UIVisualEffectView` for the blur + refraction look.
- Drag left/right to adjust system volume. Thumb snaps to position.
- Animates in/out with controls visibility (same hide timer as other controls).

### 1.2 Skip Intro — IntroDB / PublicMetaDB
- On episode load, fetch intro timestamps from **PublicMetaDB** using `imdbId + season + episode`.
- No API key required. Result cached locally per episode — no repeat network calls.
- **Behaviour:** When playback position enters the intro window, a **"Skip Intro ⏭"** pill button animates in at **bottom-right above the scrubber**. Tapping jumps to intro end.
- **Auto-skip setting:** A toggle in Video Player settings ("Auto-skip intros when detected") skips silently without showing the button.
- Falls back gracefully — no button shown if PublicMetaDB returns no data.

### 1.3 Timeline Highlights
- Small **amber dots** on the scrubber at chapter/highlight positions, sourced from PublicMetaDB alongside intro timestamps.
- Toggled by **"Show highlights on timeline"** in Video Player settings.

### 1.4 Autoplay Next Episode
- Toggle in Video Player settings: **"Autoplay next episode"**.
- Secondary setting: **"Show Next Episode when"** → picker (e.g. 30 seconds remaining).
- Uses same source and quality as current episode.

### 1.5 Media Type Player Selection
- Default: **auto-detect** by stream URL — `.m3u8` / HLS → AVPlayer; `.mkv` / `.avi` / complex formats → KSPlayer.
- Video Player settings shows a **"Use different players per media type"** toggle (Fusion-style).
- When enabled, reveals per-type pickers: Movies / Series / Live — each can be set to AVPlayer or KSPlayer.
- When disabled, auto-detection applies globally.

### 1.6 Source Cache Mode
- Video Player settings section: **"Cache Mode"** with a picker — Memory / Disk / Off.
- Memory: buffers stream in RAM for smooth playback.
- Disk: caches segments to disk for resume capability.
- Off: no caching, stream live.

### 1.7 Long-Press Context Menu on Continue Watching Cards
- Long-pressing a Continue Watching card on the Home screen presents a context menu:
  - **Mark as Watched** — marks the current episode/movie as complete and removes from Continue Watching.
  - **Revert to previous episode** — steps back one episode in watch progress.
  - **Remove** — removes the item from Continue Watching entirely.
- Uses SwiftUI `.contextMenu` with SF Symbol icons.

---

## 2. Detail Screen Enhancements

### 2.1 Description Bottom Sheet
- The synopsis is displayed **truncated to 3 lines** with a "Read more →" tappable hint below.
- Tapping opens a **bottom sheet** (`.sheet` or `UIPresentationController` with detents) showing the full synopsis.
- Sheet has a drag handle, frosted glass background, show title as sheet header.
- **Episode descriptions** use the same pattern — tapping an episode description in the episodes list opens the sheet with that episode's full description.

### 2.2 Larger Clickable Cast Cards
- Cast section uses **portrait cards (72×90pt)** instead of small circles.
- Each card: actor photo (TMDB image), name below, character role in smaller text.
- Horizontally scrollable row.
- Tapping navigates to the **Actor Bio Page**.

### 2.3 Actor Bio Page
**Layout (top to bottom, scrollable):**
1. Nav bar with back button ("‹ [Show Name]") + centered actor name.
2. Single actor photo (90×120pt, rounded) + name + role in show + short bio (4 lines, expandable) — side by side.
3. Info table (stacked label → value rows): Also Known As, Born, Birthplace, IMDb link.
4. **Known For** section — large horizontal landscape backdrop cards (~140×80pt, 2 visible), horizontally scrollable. Shows title below each card.
5. **Credits** section — year-grouped list with filter chips (All / Acting / Directing). Each credit: small poster thumbnail + title + type (Acting/Voice/Movie/Series) + episode count if series + TMDB score + vote count + character name.

**Data source:** TMDB Person API.
- Person ID: taken from cast data if available; otherwise resolved via `GET /search/person?query={name}` (first result). ID cached locally.
- Single request: `GET /person/{id}?append_to_response=combined_credits` returns bio + filmography.
- Profile photo: `https://image.tmdb.org/t/p/w185{profile_path}`.
- Known For backdrops: top 5 credits by `popularity` from `combined_credits.cast`. Backdrop images fetched on demand via `GET /movie/{id}` or `GET /tv/{id}` for each. Falls back to `poster_path` if no backdrop available.
- Fetched on demand (tap cast card), cached in memory for the session.
- Uses existing TMDB API key from Metadata Integration settings — no new key needed.

---

## 3. Library Redesign

### 3.1 Layout
- **Single scrollable page** with three inline sections stacked vertically — no tabs.
- Section headers show name + item count.

### 3.2 Watchlist Section (🔖)
- Items added via the bookmark button on the detail screen (existing behaviour).
- **Grid layout** (3 columns, adaptive).
- Each poster: rating badges (IMDb, RT) at bottom-left, **purple progress bar** at poster bottom for in-progress titles (sourced from `WatchProgressRepository`).
- Long-press: Mark as Watched · Remove.

### 3.3 Liked Section (❤️)
- Items added via a **new heart button** on the detail screen (next to the bookmark button).
- Same grid layout as Watchlist.
- Shows only titles that are **currently available** (released and/or currently airing).
- Long-press: Remove from Liked.

### 3.4 Upcoming Section (🗓)
- Liked items that are **not yet available** — auto-sorted here on save and refreshed daily.
- Uses **horizontal list rows** (not grid) to show release info.
- Each row: small poster + title + type + release badge.

**Detection logic:**
- **Movies:** `release_date > today` from TMDB → Upcoming. Badge shows exact date.
- **TV Series:** `next_episode_to_air != null` from TMDB series object → Upcoming. Badge shows "Season N · [date]" or "No air date yet" if date is null. Series with `status == "Ended"` are never placed in Upcoming.
- TMDB data for Liked items is re-fetched **once per day** in the background. No manual refresh required.

### 3.5 New "Like" Data Model
- `LikedRepository` mirrors the existing `LibraryRepository` pattern.
- Stores: `mediaId`, `mediaType`, `name`, `poster`, `tmdbId`, `likedAt`.
- Server-synced via the same backend as Library.

---

## 4. Settings Redesign + Role System

### 4.1 Modern Settings Rows
- Each settings row has a **tinted icon chip** (28×28pt, rounded rect) on the left, matching iOS Settings aesthetic.
- Row structure: icon chip · title · optional subtitle · optional value label · chevron.
- Rows are grouped into sections with uppercase section labels.
- `AppearanceSettingsScreen` is **removed entirely** — the accent colour picker is unused.

### 4.2 Settings Screen Structure

| Section | Rows | Visibility |
|---|---|---|
| **General** | iCloud, Accounts, Metadata (TMDB/TVDB) | All roles |
| **Content Management** | Addons, Catalog Management, Hero Management | Admin only (hidden for all other roles) |
| **Playback** | Video Player, Subtitles, Stream Auto-Play | All roles |
| **App** | Icon Packs, About | All roles |
| *(Sign Out)* | Sign Out | All roles |

> Note: Admin still sees `ADMIN` badge next to their name in the profile card. All other roles see name only — no tier label, no "using admin's addons" text.

### 4.3 Video Player Settings Screen
Replaces the current flat layout with grouped sections:

- **Playback:** Autoplay next episode (toggle) · Show Next Episode when (picker)
- **Skip Intro:** Show 'Skip Intro' when detected (toggle) · Auto-skip intros (toggle) · Use IntroDB for TV episodes (toggle) · Show highlights on timeline (toggle)
- **Format Compatibility:** Show only compatible formats (toggle)
- **Media Type Players:** Use different players per media type (toggle) → when on: Movie / Series / Live pickers (AVPlayer / KSPlayer)
- **Cache Mode:** Cache mode (Memory / Disk / Off picker)
- **Previews:** Autoplay previews in Home (toggle) · Play preview sound (toggle)
- **Default Audio & Subtitles:** Preferred audio language (picker) · Preferred subtitle language (picker)

### 4.4 Subtitle Appearance Settings Screen
Full redesign of the subtitles settings:

**Preview panel (top):**  
A static screenshot of the player as the background, with a live-rendered subtitle text overlay that reflects current settings. Updates in real-time as sliders/pickers change.

**Quick Presets:** Standard · Boxed · Classic · Minimal (with description of each)

**Font section:** Font size (slider) · Scale (slider) · Bold (toggle) · Italic (toggle)

**Colors section:** Text Color · Outline Color · Background Color (each opens a color picker)

**Position section:** Vertical position (slider) · Horizontal alignment (Left / Center / Right segmented) · Horizontal Margin (slider)

**Advanced section:** Text Blur (slider) · Scale with Window Size (toggle) · ASS Style Override (picker)

**Reset to Defaults** button at bottom.

### 4.5 Role System

**Four roles:**

| Role | Admin Tab | Addons | Catalog/Hero/Meta | Source |
|---|---|---|---|---|
| **Admin** | ✅ | ✅ Full control | ✅ | Hardcoded to account |
| **Friends & Family** | ❌ | Uses admin's (read-only) | ❌ | Assigned by admin |
| **Premium Full** | ❌ | Uses admin's (read-only) | ❌ | Assigned by admin via website |
| **Premium Self-Manage** | ❌ | ✅ Own addon list | ❌ | Assigned by admin via website |

**Implementation:**
- Role is stored on `MoonlitProfile` as a `ProfileRole` enum: `.admin`, `.friendsAndFamily`, `.premiumFull`, `.premiumSelfManage`.
- Role is synced from the admin's website (not set in-app). The app reads it from the profile object.
- No in-app payment. Apple App Store compliant — role assignment is a server-side operation, not a purchase.
- `ProfileRole` drives conditional rendering throughout the app via a `ProfileRoleManager` or extension on `ProfileManager`.
- Settings rows check `profileManager.currentProfile?.role` to decide visibility. Hidden rows emit no view at all (not disabled, not locked).

---

## 5. Out of Scope (This Spec)

- Push notifications for Upcoming releases
- Social features (sharing liked items)
- Trailer playback from detail screen (existing streailer integration unchanged)
- Admin website / role assignment backend (separate project)

---

## 6. Open Questions (Resolved)

| Question | Decision |
|---|---|
| Skip Intro behaviour | Show button + auto-skip toggle in settings |
| Player selection | Auto-detect by URL format; toggle in settings to override per type |
| Premium role assignment | Admin grants via website (no IAP) |
| Role-gating UI | Hidden rows — restricted rows simply don't render |
| Library layout | Single scrollable page, inline sections (no tabs) |
| F&F profile card | Name only — no tier badge, no "using admin's addons" text |
