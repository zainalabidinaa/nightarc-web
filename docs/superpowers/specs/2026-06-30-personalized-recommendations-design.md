# Personalized "For You" Recommendations — Design Spec

**Date**: 2026-06-30
**Status**: Approved
**Platforms**: iOS (SwiftUI), Web (React), Shared (Vercel Edge + Supabase)

---

## 1. Overview

Moonlit currently has zero personalization on the home screen beyond "Continue Watching." All catalog content is statically curated. This feature adds a dedicated **"For You"** section to the home screen for every profile, with personalized recommendation folders driven by watch history, genre preferences, and TMDB enrichment.

---

## 2. Folder Names & Cover Images

Each recommendation category appears as a folder tile in the "For You" section:

| Row Type | Folder Title | Cover Image URL |
|----------|-------------|-----------------|
| `latest_movies` | **Movie Night** | `https://raw.githubusercontent.com/zainalabidinaa/luna-covers/main/movie-night.png` |
| `latest_series` | **Your Next Binge** | `https://raw.githubusercontent.com/zainalabidinaa/luna-covers/main/your-next-binge.png` |
| `because_you_watched` | **Because You Watched {title}** (dynamic, up to 3) | `https://raw.githubusercontent.com/zainalabidinaa/luna-covers/main/because-you-watched.png` |
| `list_for_you` | **We Made You a List** | `https://raw.githubusercontent.com/zainalabidinaa/luna-covers/main/we-made-you-a-list.png` |
| `ai_recommendations` | **Worth the Risk** | `https://raw.githubusercontent.com/zainalabidinaa/luna-covers/main/worth-the-risk.png` |

---

## 3. Architecture

### 3.1 Component Diagram

```
Nightly Cron / On-Demand Trigger
         |
         v
Vercel Edge Function: generate-recommendations
  - Reads watch_progress per profile (Supabase)
  - Fetches MetaDetail for watched items (Stremio addons)
  - Queries TMDB /similar endpoints
  - Scores items against profile preferences
  - Writes results to profile_recommendations (Supabase)
         |
         v
GET /api/recommendations?profile_id=X
  (reads pre-computed rows, returns JSON)
         |
    +----+----+
    v         v
 iOS App    Web App
(SwiftUI)   (React)
```

### 3.2 Vercel Edge Function

**File**: `api/recommendations.ts`

**Endpoints**:
- `GET  /api/recommendations?profile_id={uuid}` — read pre-computed rows for a profile
- `POST /api/recommendations/generate` — trigger regeneration

### 3.3 Supabase Table

```sql
CREATE TABLE profile_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  row_type TEXT NOT NULL,
  row_title TEXT NOT NULL,
  cover_image TEXT,
  items JSONB NOT NULL DEFAULT '[]',
  sort_order INTEGER NOT NULL DEFAULT 0,
  generated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

---

## 4. Recommendation Engine Algorithms

### Data Sources
- `watch_progress` table: media_id, media_type, position_seconds, duration_seconds, completed, updated_at
- Stremio MetaDetail API: genres, moviedb_id (TMDB ID)
- TMDB API: /movie/{id}/similar, /tv/{id}/similar, /find/{imdb_id}
- Stremio catalog endpoints: sorted lists of movies/series

### Row Generation

**Movie Night** (`latest_movies`):
1. Build genre profile from watch history
2. Query top Stremio movie catalogs
3. Filter unwatched, score by genre overlap, take top 20

**Your Next Binge** (`latest_series`):
1. Same as above for series type, top 20

**Because You Watched {title}** (`because_you_watched`):
1. Pick 2-3 most recently watched items
2. Resolve TMDB ID, call /similar endpoint
3. Filter unwatched, take top 10 per source

**We Made You a List** (`list_for_you`):
1. Aggregate across catalogs, filter unwatched, score by genre match, top 20

**Worth the Risk** (`ai_recommendations`):
1. Phase 1: Same as List For You but genre-score only, zero popularity bias
2. Phase 2 (future): LLM-powered analysis

---

## 5. UI Integration

### iOS
- "For You" section after Continue Watching, before static catalog rows
- Horizontal scroll of FolderCell tiles, reusing existing component
- Tapping navigates to FolderScreen with items

### Web
- Same insertion point in home.tsx
- Folder tile grid reusing existing styling
- Tapping navigates to `/for-you/$rowType` route with items in search params

### Folder Detail
- iOS: FolderScreen displays items in grid
- Web: ForYouRowPage renders items in poster grid

---

## 6. Caching & Refresh

| Layer | Strategy |
|-------|----------|
| Supabase | `profile_recommendations` is source of truth |
| API | `Cache-Control: max-age=3600` |
| Web | React Query `staleTime: 30min` |
| iOS | On-demand fetch, clear on profile switch |
| Regeneration | Pull-to-refresh, nightly cron (future) |

---

## 7. Edge Cases

- **New profile**: No rows, section hidden
- **Profile switch**: Clear and re-fetch recommendations
- **Free/restricted role**: Engine uses only system addon catalogs (role filtering already applied upstream)
- **TMDB rate limited**: Fall back to genre-matching from catalogs only
- **No system addon**: Section hidden

---

## 8. Implementation Order

1. Supabase table + migration
2. Recommendation engine module (`api/recommendation-engine.ts`)
3. Vercel Edge Function (`api/recommendations.ts`)
4. Upload cover images to luna-covers
5. Web client module + home integration + route
6. iOS service + HomeScreen integration
7. Pull-to-refresh triggers
