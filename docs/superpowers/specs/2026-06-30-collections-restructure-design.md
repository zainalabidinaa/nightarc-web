# Collections Restructure + Refresh Fix + Image Fix

**Date**: 2026-06-30
**Status**: Draft

---

## Overview

Four changes to the iOS app:

1. **Fix Supabase collection refresh** — surface errors, expire stale disk cache, delete cache on failure
2. **Hide horror theme collections from home** — 5 horror collections should only appear inside Genre → Horror
3. **Genre Collections as top-level** — promote 11 genre-grouping folders from "Film Collections" to top-level collections; display only inside GenreHubScreen
4. **Images fill tiles** — remove dark gray background gap on folder tiles

---

## 1. Supabase Refresh Fix

### Current behavior
- `CollectionOrganizerStore.cachedOrBundledLayout()` prefers disk cache (`MoonlitHomeLayout/home-organizer.json`) over bundled JSON
- Background `refresh(remoteURL:)` fetches from Supabase edge function, writes to disk, applies to UI
- On fetch failure → returns `nil` → stale disk cache persists forever; no error surfaced

### Changes
**File: `Packages/MoonlitCore/Sources/MoonlitCore/Services/CollectionOrganizerStore.swift`**

- `cachedOrBundledLayout()`: check file modification date. If older than 24 hours, skip cache and fall back to bundled JSON.
- `refresh(remoteURL:)`:
  - On non-200 status or network error: log error via `os_log(.error, ...)`
  - On failure: delete the disk cache file so stale copy doesn't win next launch
  - Return `nil` as before (caller already handles nil gracefully)

**File: `Apps/MoonlitApp/Sources/Screens/HomeScreen.swift`**

- `loadGlobalOrganizer()`: in the background `Task`, log when refresh succeeds or fails to aid debugging

No API contract changes. No new dependencies.

---

## 2. Hide Horror Theme Collections from Home

### Current behavior
Five top-level collections appear as rows on the home screen:
- Horror genre
- Horror Decades
- Horror Franchises
- International Horror
- Horror Mood & Vibe

They are also found by `GenreCatalog.sections(for: "horror")` (keyword match on collection name) and displayed inside GenreHubScreen. This is the correct behavior for the genre view.

### Changes
**File: `Packages/MoonlitCore/Sources/MoonlitCore/Services/CatalogRepository.swift`**

Add a static set of collection names to exclude from home screen display:

```swift
private static let genreThemeCollections: Set<String> = [
    "horror genre", "horror decades", "horror franchises",
    "international horror", "horror mood & vibe"
]
```

In `displayRows()` (or the method that builds the home screen row list), filter out any `CatalogRow` whose associated collection name (lowercased, trimmed) matches this set.

Collections remain in `collectionRepo.collections` so `GenreCatalog.sections(for:)` continues to find them via its keyword-matching logic.

---

## 3. Genre Collections as Top-Level + Genre-Only Display

### Current behavior
11 genre-grouping folders live as sub-folders of the "Film Collections" top-level collection:
- Action Collections, Comedy Collections, Crime Collections, Drama Collections
- Family & Animation Collections, Fantasy Collections, Horror Collections
- Mystery Collections, Sci-Fi Collections, Thriller Collections, War Collections

Each contains TMDB franchise source entries (e.g., Action Collections has Bad Boys, John Wick, etc.).

### Changes

#### 3a. Data: `home-organizer.json`
Promote each of the 11 genre-grouping folders from "Film Collections" to its own top-level collection. Remove them from "Film Collections".

Each new top-level collection:
```json
{
    "id": "<uuid>",
    "title": "Action Collections",
    "folders": [ /* each franchise as a folder with 1 TMDB source */ ],
    "pinToTop": false,
    "viewMode": "FOLLOW_LAYOUT",
    "showAllTab": false,
    "backdropImageUrl": null,
    "focusGlowEnabled": false
}
```

Preserve the existing 164 individual franchise folders inside "Film Collections" (e.g., Die Hard, John Wick — they were already individual folders alongside the genre-grouping folders). Only the 11 genre-grouping folders are moved out.

#### 3b. Code: `CatalogRepository.swift`
Add the 11 names to the `genreThemeCollections` exclusion set alongside the horror collections, so they are filtered from home screen rows.

#### 3c. `GenreCatalog.swift`
No changes needed. `GenreCatalog.sections(for:)` already keys off collection names containing the genre keyword. "Action Collections" matches "action", so it's auto-discovered and rendered as a section row in GenreHubScreen.

#### 3d. `FolderScreen.swift`
No changes needed. Folder tiles (with `id: "folder_..."`) inside these new collections navigate to `FolderScreen` which loads the franchise's content via the folder's TMDB sources.

---

## 4. Images Fill Tiles

### Current behavior
`ContentCard.swift`:
- Line 23-25: `RoundedRectangle` background with `.fill(MoonlitTheme.surfaceElevated)` (#242424 dark gray) sits behind every tile image
- Line 42: Folder items use `.aspectRatio(contentMode: .fit)`, leaving visible gray bars when image aspect ratio doesn't match the tile frame

### Changes
**File: `Apps/MoonlitApp/Sources/Components/ContentCard.swift`**

- Line 42: Change `.fit` to `.fill` for folder items so images always cover the frame
- Lines 23-25: Remove the `RoundedRectangle` background (no longer needed since `.fill` covers the frame)

The `clipShape(RoundedRectangle(cornerRadius: 12))` already handles rounded corners, so removing the background rectangle has no visual downside.

---

## Files Changed Summary

| File | Change |
|------|--------|
| `Packages/MoonlitCore/Sources/MoonlitCore/Services/CollectionOrganizerStore.swift` | TTL on disk cache, error logging, cache deletion on failure |
| `Apps/MoonlitApp/Sources/Screens/HomeScreen.swift` | Logging in `loadGlobalOrganizer()` background Task |
| `Packages/MoonlitCore/Sources/MoonlitCore/Services/CatalogRepository.swift` | `genreThemeCollections` set, filter in `displayRows()` |
| `Apps/MoonlitApp/Resources/home-organizer.json` | Promote 11 genre Collections to top-level, remove from "Film Collections" |
| `Apps/MoonlitApp/Sources/Components/ContentCard.swift` | `.fill` instead of `.fit` for folders, remove background rect |
| `moonlit-portal/supabase/functions/home-organizer/index.ts` | No changes (edge function queries live DB) |

---

## Verification

- **Refresh fix**: Simulate network failure → verify disk cache is deleted, error logged to Console
- **Horror hidden**: Launch app → home screen has no "Horror genre", "Horror Decades", etc. rows. Open Genres → Horror → all 5 Horror sections appear
- **Genre Collections**: Launch app → home screen has no "Action Collections", "Comedy Collections" rows. Open Genres → Action → "Action Collections" section row visible with Bad Boys, John Wick, etc. tiles. Tap a tile → opens FolderScreen with franchise content
- **Film Collections integrity**: Home screen → "Film Collections" still shows its 164 individual franchise folders (Die Hard, James Bond, etc.) but no longer has the 11 genre-grouping folders
- **Image fill**: Folder tiles have no dark gray borders, images fill the entire tile frame
