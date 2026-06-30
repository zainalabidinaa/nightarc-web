# Personalized "For You" Recommendations — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a dedicated "For You" section to the home screen per profile with 5 personalized recommendation folders (Movie Night, Your Next Binge, Because You Watched X, We Made You a List, Worth the Risk), powered by a server-side recommendation engine.

**Architecture:** A Vercel Edge Function generates per-profile recommendations from watch history + TMDB + Stremio catalogs, stored in a new Supabase table. Both iOS and web consume the same `GET /api/recommendations` endpoint. Results appear as folder tiles in a "For You" section after Continue Watching.

**Tech Stack:** SwiftUI (iOS) + React/TypeScript (Web) + Vercel Edge Functions + Supabase + TMDB API + Stremio protocol

---

### Task 1: Create `profile_recommendations` Table in Supabase

**Files:**
- Create: `supabase/migrations/20260630_profile_recommendations.sql`

- [ ] **Step 1: Write the SQL migration**

```sql
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
```

- [ ] **Step 2: Run the migration** — Via Supabase dashboard SQL Editor.

- [ ] **Step 3: Verify** — Check `profile_recommendations` appears in Table Editor.

---

### Task 2: Create the Recommendation Engine Module

**Files:**
- Create: `api/recommendation-engine.ts`

- [ ] **Step 1: Create the engine file**

```typescript
// api/recommendation-engine.ts
import { createClient } from '@supabase/supabase-js';

const TMDB_API_KEY = process.env.TMDB_API_KEY || '1e818317d3086727eceecf0571621527';
const SUPABASE_URL = process.env.SUPABASE_URL || 'https://hvfsntdyowapjxobtyli.supabase.co';
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY);

interface MetaPreview {
  id: string;
  type: string;
  name: string;
  poster?: string;
  banner?: string;
  logo?: string;
  posterShape?: string;
  description?: string;
  releaseInfo?: string;
  imdbRating?: string;
  genres?: string[];
  popularity?: number;
}

interface WatchEntry {
  profile_id: string;
  media_id: string;
  media_type: string;
  position_seconds: number;
  duration_seconds: number;
  completed: boolean;
}

interface GenreProfile {
  genre: string;
  weight: number;
}

const COVER_IMAGES: Record<string, string> = {
  latest_movies: 'https://raw.githubusercontent.com/zainalabidinaa/luna-covers/main/movie-night.png',
  latest_series: 'https://raw.githubusercontent.com/zainalabidinaa/luna-covers/main/your-next-binge.png',
  because_you_watched: 'https://raw.githubusercontent.com/zainalabidinaa/luna-covers/main/because-you-watched.png',
  list_for_you: 'https://raw.githubusercontent.com/zainalabidinaa/luna-covers/main/we-made-you-a-list.png',
  ai_recommendations: 'https://raw.githubusercontent.com/zainalabidinaa/luna-covers/main/worth-the-risk.png',
};

const ROW_ORDER: Record<string, number> = {
  latest_movies: 1,
  latest_series: 2,
  because_you_watched: 3,
  list_for_you: 8,
  ai_recommendations: 9,
};

const ROW_TITLES: Record<string, string> = {
  latest_movies: 'Movie Night',
  latest_series: 'Your Next Binge',
  list_for_you: 'We Made You a List',
  ai_recommendations: 'Worth the Risk',
};

// ── Watch History ───────────────────────────────────────────────────

async function getWatchHistory(profileId: string): Promise<WatchEntry[]> {
  const { data } = await supabase
    .from('watch_progress')
    .select('profile_id,media_id,media_type,position_seconds,duration_seconds,completed')
    .eq('profile_id', profileId);
  return (data || []) as WatchEntry[];
}

// ── TMDB Integration ────────────────────────────────────────────────

async function resolveTmdbId(imdbId: string, type: string): Promise<number | null> {
  const tmdbType = type === 'series' ? 'tv' : 'movie';
  const res = await fetch(
    `https://api.themoviedb.org/3/find/${imdbId}?api_key=${TMDB_API_KEY}&external_source=imdb_id`
  );
  if (!res.ok) return null;
  const data = await res.json();
  const hit = tmdbType === 'tv' ? data.tv_results?.[0] : data.movie_results?.[0];
  return hit?.id ?? null;
}

async function fetchTmdbSimilar(tmdbId: number, type: string, limit = 20): Promise<any[]> {
  const tmdbType = type === 'series' ? 'tv' : 'movie';
  const res = await fetch(
    `https://api.themoviedb.org/3/${tmdbType}/${tmdbId}/similar?api_key=${TMDB_API_KEY}&language=en-US&page=1`
  );
  if (!res.ok) return [];
  const data = await res.json();
  return (data.results || []).slice(0, limit);
}

// ── Stremio Catalog Queries ─────────────────────────────────────────

async function fetchStremioCatalog(
  baseUrl: string,
  type: string,
  catalogId: string,
  extras?: Record<string, string>
): Promise<MetaPreview[]> {
  const params = new URLSearchParams({ url: baseUrl, type, id: catalogId });
  if (extras) params.set('extras', JSON.stringify(extras));
  const proxyBase = process.env.VERCEL_URL
    ? `https://${process.env.VERCEL_URL}`
    : process.env.VERCEL_BRANCH_URL
      ? `https://${process.env.VERCEL_BRANCH_URL}`
      : 'http://localhost:3000';
  const res = await fetch(`${proxyBase}/api/stremio/catalog?${params}`);
  if (!res.ok) return [];
  const json = await res.json();
  return (json.metas || []).map((m: any) => ({
    id: m.id,
    type: m.type || type,
    name: m.name || 'Unknown',
    poster: m.poster,
    banner: m.banner,
    logo: m.logo,
    posterShape: m.posterShape,
    description: m.description,
    releaseInfo: m.releaseInfo,
    imdbRating: m.imdbRating,
    genres: m.genres,
    popularity: m.popularity,
  }));
}

async function getSystemAddon(): Promise<{ manifest_url: string } | null> {
  const { data } = await supabase
    .from('system_addon')
    .select('manifest_url')
    .order('updated_at', { ascending: false })
    .limit(1)
    .maybeSingle();
  return data as any;
}

async function fetchStremioManifest(url: string): Promise<{
  transportUrl?: string;
  catalogs?: any[];
}> {
  const res = await fetch(url);
  if (!res.ok) return {};
  const json = await res.json();
  return {
    transportUrl: json.transportUrl || url.replace(/\/manifest\.json(\?.*)?$/, ''),
    catalogs: json.catalogs || [],
  };
}

// ── Genre Profile from Watch History ─────────────────────────────────

async function buildGenreProfileFromWatchHistory(
  entries: WatchEntry[],
  transportUrl: string
): Promise<GenreProfile[]> {
  const genreCounts = new Map<string, number>();
  const proxyBase = process.env.VERCEL_URL
    ? `https://${process.env.VERCEL_URL}`
    : process.env.VERCEL_BRANCH_URL
      ? `https://${process.env.VERCEL_BRANCH_URL}`
      : 'http://localhost:3000';

  for (const entry of entries) {
    const [baseId] = entry.media_id.split(':');
    try {
      const params = new URLSearchParams({ url: transportUrl, type: entry.media_type, id: baseId });
      const res = await fetch(`${proxyBase}/api/stremio/meta?${params}`);
      if (res.ok) {
        const json = await res.json();
        const genres: string[] = json.meta?.genres || [];
        const completionWeight = entry.completed
          ? 1.0
          : Math.max(0.2, entry.position_seconds / Math.max(1, entry.duration_seconds));
        for (const g of genres) {
          genreCounts.set(g, (genreCounts.get(g) || 0) + completionWeight);
        }
      }
    } catch {}
  }

  const total = Array.from(genreCounts.values()).reduce((a, b) => a + b, 0) || 1;
  return Array.from(genreCounts.entries())
    .map(([genre, count]) => ({ genre, weight: count / total }))
    .sort((a, b) => b.weight - a.weight);
}

// ── Scoring ─────────────────────────────────────────────────────────

function scoreByGenreProfile(item: MetaPreview, genreProfile: GenreProfile[]): number {
  if (!item.genres || item.genres.length === 0) return 0.1;
  let score = 0;
  for (const gp of genreProfile) {
    if (item.genres.includes(gp.genre)) score += gp.weight;
  }
  return score;
}

// ── Row Generators ──────────────────────────────────────────────────

async function generateLatestRow(
  type: 'movie' | 'series',
  transportUrl: string,
  catalogs: any[],
  genreProfile: GenreProfile[],
  watchedIds: Set<string>
): Promise<MetaPreview[]> {
  const candidates: MetaPreview[] = [];
  const seen = new Set<string>();

  const relevantCatalogs = (catalogs || [])
    .filter((c: any) => c.type === type)
    .slice(0, 4);

  for (const catalog of relevantCatalogs) {
    const items = await fetchStremioCatalog(transportUrl, type, catalog.id);
    for (const item of items) {
      if (!seen.has(item.id) && !watchedIds.has(item.id)) {
        seen.add(item.id);
        item.popularity = item.popularity ?? 0;
        candidates.push(item);
      }
    }
  }

  return candidates
    .map(item => ({
      item,
      score: scoreByGenreProfile(item, genreProfile) * 0.7 + ((item.popularity ?? 0) / 1000) * 0.3,
    }))
    .sort((a, b) => b.score - a.score)
    .slice(0, 20)
    .map(({ item }) => item);
}

async function generateBecauseYouWatchedRows(
  entries: WatchEntry[],
  transportUrl: string,
  watchedIds: Set<string>
): Promise<Array<{ rowTitle: string; items: MetaPreview[] }>> {
  const candidates = entries
    .sort(
      (a, b) =>
        b.position_seconds / Math.max(1, b.duration_seconds) -
        a.position_seconds / Math.max(1, a.duration_seconds)
    )
    .slice(0, 3);

  const rows: Array<{ rowTitle: string; items: MetaPreview[] }> = [];
  const proxyBase = process.env.VERCEL_URL
    ? `https://${process.env.VERCEL_URL}`
    : process.env.VERCEL_BRANCH_URL
      ? `https://${process.env.VERCEL_BRANCH_URL}`
      : 'http://localhost:3000';

  for (const entry of candidates) {
    const [baseId] = entry.media_id.split(':');
    if (!baseId.startsWith('tt')) continue;

    let sourceName = baseId;
    let tmdbId: number | null = null;
    try {
      const params = new URLSearchParams({ url: transportUrl, type: entry.media_type, id: baseId });
      const res = await fetch(`${proxyBase}/api/stremio/meta?${params}`);
      if (res.ok) {
        const json = await res.json();
        sourceName = json.meta?.name || baseId;
        if (json.meta?.moviedb_id) tmdbId = Number(json.meta.moviedb_id);
      }
    } catch {}

    if (!tmdbId) tmdbId = await resolveTmdbId(baseId, entry.media_type);
    if (!tmdbId) continue;

    const similar = await fetchTmdbSimilar(tmdbId, entry.media_type, 10);
    const items: MetaPreview[] = similar
      .filter((r: any) => !watchedIds.has(r.id))
      .slice(0, 10)
      .map((r: any) => ({
        id: r.imdb_id || String(r.id),
        type: entry.media_type,
        name: r.title || r.name || 'Unknown',
        poster: r.poster_path ? `https://image.tmdb.org/t/p/w500${r.poster_path}` : undefined,
        releaseInfo: r.release_date || r.first_air_date,
        genres: undefined,
        popularity: r.popularity ?? 0,
      }));

    if (items.length > 0) {
      rows.push({ rowTitle: `Because You Watched ${sourceName}`, items });
    }
  }
  return rows;
}

async function generateListForYou(
  genreProfile: GenreProfile[],
  transportUrl: string,
  catalogs: any[],
  watchedIds: Set<string>
): Promise<MetaPreview[]> {
  const candidates: MetaPreview[] = [];
  const seen = new Set<string>();
  const topCatalogs = (catalogs || []).slice(0, 6);

  for (const catalog of topCatalogs) {
    const items = await fetchStremioCatalog(transportUrl, catalog.type, catalog.id);
    for (const item of items) {
      if (!seen.has(item.id) && !watchedIds.has(item.id)) {
        seen.add(item.id);
        candidates.push(item);
      }
    }
  }

  return candidates
    .map(item => ({ item, score: scoreByGenreProfile(item, genreProfile) }))
    .sort((a, b) => b.score - a.score)
    .slice(0, 20)
    .map(({ item }) => item);
}

async function generateAiRecommendations(
  genreProfile: GenreProfile[],
  transportUrl: string,
  catalogs: any[],
  watchedIds: Set<string>
): Promise<MetaPreview[]> {
  const candidates: MetaPreview[] = [];
  const seen = new Set<string>();
  const topCatalogs = (catalogs || []).slice(0, 8);

  for (const catalog of topCatalogs) {
    const items = await fetchStremioCatalog(transportUrl, catalog.type, catalog.id);
    for (const item of items) {
      if (!seen.has(item.id) && !watchedIds.has(item.id)) {
        seen.add(item.id);
        candidates.push(item);
      }
    }
  }

  return candidates
    .map(item => ({ item, score: scoreByGenreProfile(item, genreProfile) }))
    .sort((a, b) => b.score - a.score)
    .slice(0, 20)
    .map(({ item }) => item);
}

// ── Main Generate ───────────────────────────────────────────────────

export async function generateRecommendations(profileId: string): Promise<{
  success: boolean;
  rowsGenerated: number;
  error?: string;
}> {
  try {
    const history = await getWatchHistory(profileId);
    const watchedIds = new Set(history.map(e => e.media_id));

    const systemAddon = await getSystemAddon();
    if (!systemAddon?.manifest_url) {
      return { success: false, rowsGenerated: 0, error: 'No system addon configured' };
    }

    const manifest = await fetchStremioManifest(systemAddon.manifest_url);
    const transportUrl = manifest.transportUrl || '';
    const catalogs = manifest.catalogs || [];

    if (!transportUrl || catalogs.length === 0) {
      return { success: false, rowsGenerated: 0, error: 'No catalogs available' };
    }

    const genreProfile = await buildGenreProfileFromWatchHistory(history, transportUrl);

    const rows: Array<{
      profile_id: string;
      row_type: string;
      row_title: string;
      cover_image: string;
      items: MetaPreview[];
      sort_order: number;
    }> = [];

    const movieItems = await generateLatestRow('movie', transportUrl, catalogs, genreProfile, watchedIds);
    if (movieItems.length > 0) {
      rows.push({
        profile_id: profileId,
        row_type: 'latest_movies',
        row_title: ROW_TITLES.latest_movies,
        cover_image: COVER_IMAGES.latest_movies,
        items: movieItems,
        sort_order: ROW_ORDER.latest_movies,
      });
    }

    const seriesItems = await generateLatestRow('series', transportUrl, catalogs, genreProfile, watchedIds);
    if (seriesItems.length > 0) {
      rows.push({
        profile_id: profileId,
        row_type: 'latest_series',
        row_title: ROW_TITLES.latest_series,
        cover_image: COVER_IMAGES.latest_series,
        items: seriesItems,
        sort_order: ROW_ORDER.latest_series,
      });
    }

    const becauseRows = await generateBecauseYouWatchedRows(history, transportUrl, watchedIds);
    let sortOrder = ROW_ORDER.because_you_watched;
    for (const br of becauseRows) {
      rows.push({
        profile_id: profileId,
        row_type: 'because_you_watched',
        row_title: br.rowTitle,
        cover_image: COVER_IMAGES.because_you_watched,
        items: br.items,
        sort_order: sortOrder++,
      });
    }

    const listItems = await generateListForYou(genreProfile, transportUrl, catalogs, watchedIds);
    if (listItems.length > 0) {
      rows.push({
        profile_id: profileId,
        row_type: 'list_for_you',
        row_title: ROW_TITLES.list_for_you,
        cover_image: COVER_IMAGES.list_for_you,
        items: listItems,
        sort_order: ROW_ORDER.list_for_you,
      });
    }

    const aiItems = await generateAiRecommendations(genreProfile, transportUrl, catalogs, watchedIds);
    if (aiItems.length > 0) {
      rows.push({
        profile_id: profileId,
        row_type: 'ai_recommendations',
        row_title: ROW_TITLES.ai_recommendations,
        cover_image: COVER_IMAGES.ai_recommendations,
        items: aiItems,
        sort_order: ROW_ORDER.ai_recommendations,
      });
    }

    if (rows.length > 0) {
      await supabase.from('profile_recommendations').delete().eq('profile_id', profileId);
      await supabase.from('profile_recommendations').insert(rows);
    }

    return { success: true, rowsGenerated: rows.length };
  } catch (err: any) {
    return { success: false, rowsGenerated: 0, error: err.message };
  }
}

// ── Read Cached ─────────────────────────────────────────────────────

export async function getRecommendations(profileId: string) {
  const { data } = await supabase
    .from('profile_recommendations')
    .select('*')
    .eq('profile_id', profileId)
    .order('sort_order');

  return {
    generated_at: data?.[0]?.generated_at || new Date().toISOString(),
    rows: (data || []).map((row: any) => ({
      row_type: row.row_type,
      row_title: row.row_title,
      cover_image: row.cover_image,
      sort_order: row.sort_order,
      items: row.items || [],
    })),
  };
}
```

---

### Task 3: Create the Vercel Edge Function Endpoint

**Files:**
- Create: `api/recommendations.ts`

- [ ] **Step 1: Create the edge function**

```typescript
// api/recommendations.ts
export const config = { runtime: 'edge' };

import { generateRecommendations, getRecommendations } from './recommendation-engine';

export default async function handler(req: Request) {
  const url = new URL(req.url);
  const path = url.pathname.replace(/\/$/, '');

  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      },
    });
  }

  const corsHeaders = { 'Access-Control-Allow-Origin': '*' };

  try {
    if (req.method === 'GET') {
      const profileId = url.searchParams.get('profile_id');
      if (!profileId) {
        return new Response(JSON.stringify({ error: 'Missing profile_id' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      const data = await getRecommendations(profileId);
      return new Response(JSON.stringify(data), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
          'Cache-Control': 'public, max-age=3600, stale-while-revalidate=7200',
        },
      });
    }

    if (req.method === 'POST' && path.endsWith('/generate')) {
      let profileId: string;
      try {
        const body = await req.json();
        profileId = body.profile_id;
      } catch {
        profileId = url.searchParams.get('profile_id') || '';
      }

      if (!profileId) {
        return new Response(JSON.stringify({ error: 'Missing profile_id' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      const result = await generateRecommendations(profileId);
      return new Response(JSON.stringify(result), {
        status: result.success ? 200 : 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ error: 'Not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
}
```

---

### Task 4: Upload Cover Images

**Manual step.**

- [ ] **Step 1: Upload images to `zainalabidinaa/luna-covers` GitHub repo**

From `/Users/zain/Downloads/`:
- `movie night.png` → `movie-night.png`
- `your next binge.png` → `your-next-binge.png`
- `because you watched....png` → `because-you-watched.png`
- `we made u a list.png` → `we-made-you-a-list.png`
- `worth the risk.png` → `worth-the-risk.png`

- [ ] **Step 2: Verify URLs**

```
https://raw.githubusercontent.com/zainalabidinaa/luna-covers/main/movie-night.png
https://raw.githubusercontent.com/zainalabidinaa/luna-covers/main/your-next-binge.png
https://raw.githubusercontent.com/zainalabidinaa/luna-covers/main/because-you-watched.png
https://raw.githubusercontent.com/zainalabidinaa/luna-covers/main/we-made-you-a-list.png
https://raw.githubusercontent.com/zainalabidinaa/luna-covers/main/worth-the-risk.png
```

---

### Task 5: Create Web Client API Module

**Files:**
- Create: `src/lib/recommendations.ts`

- [ ] **Step 1: Create the client module**

```typescript
// src/lib/recommendations.ts
import type { MetaPreview } from './types';

export interface RecommendationRow {
  row_type: string;
  row_title: string;
  cover_image: string | null;
  sort_order: number;
  items: MetaPreview[];
}

export interface RecommendationsResponse {
  generated_at: string;
  rows: RecommendationRow[];
}

const API_BASE = '/api/recommendations';

export async function fetchRecommendations(profileId: string): Promise<RecommendationsResponse> {
  const res = await fetch(`${API_BASE}?profile_id=${encodeURIComponent(profileId)}`);
  if (!res.ok) return { generated_at: new Date().toISOString(), rows: [] };
  return res.json();
}

export async function triggerRegeneration(profileId: string): Promise<{ success: boolean }> {
  const res = await fetch(`${API_BASE}/generate`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ profile_id: profileId }),
  });
  if (!res.ok) return { success: false };
  return res.json();
}
```

---

### Task 6: Add "For You" Section to Web Home

**Files:**
- Modify: `src/routes/home.tsx`

- [ ] **Step 1: Add imports**

Add after existing imports in `home.tsx`:
```typescript
import { fetchRecommendations } from '@/lib/recommendations';
import { Link } from '@tanstack/react-router';
```

- [ ] **Step 2: Add recommendations query** (after `initialData` query, ~line 73)

```typescript
const { data: recommendations } = useQuery({
  queryKey: ['recommendations', currentProfile?.id],
  queryFn: () => fetchRecommendations(currentProfile!.id),
  enabled: !!currentProfile,
  staleTime: 30 * 60 * 1000,
});
```

- [ ] **Step 3: Add "For You" section JSX** (after Continue Watching section, before `{!hasSystemAddon ? ...}`)

```tsx
        {/* For You — Personalized Recommendations */}
        {recommendations && recommendations.rows.length > 0 && (
          <section className="mb-10">
            <h2 className="text-[17px] font-bold tracking-tight text-white mb-4">For You</h2>
            <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-hide">
              {recommendations.rows.map(row => (
                <Link
                  key={`${row.row_type}_${row.row_title}`}
                  to="/for-you/$rowType"
                  params={{ rowType: encodeURIComponent(row.row_title) }}
                  search={{ items: JSON.stringify(row.items), title: row.row_title }}
                  className="flex-shrink-0 group cursor-pointer"
                  style={{ width: '140px' }}
                >
                  <div className="relative overflow-hidden rounded-xl mb-2 aspect-[2/3]">
                    {row.cover_image ? (
                      <img src={row.cover_image} alt={row.row_title} loading="lazy"
                        className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105" />
                    ) : (
                      <div className="w-full h-full bg-nightarc-elevated flex items-center justify-center">
                        <span className="text-xs font-bold text-white/40 text-center px-2">{row.row_title}</span>
                      </div>
                    )}
                    <div className="absolute inset-0 bg-black/0 group-hover:bg-black/25 transition-colors duration-300 flex items-center justify-center">
                      <div className="w-10 h-10 rounded-full bg-white/20 backdrop-blur-sm opacity-0 group-hover:opacity-100 transition-opacity duration-300 flex items-center justify-center">
                        <svg viewBox="0 0 24 24" fill="white" className="w-4 h-4 ml-0.5">
                          <polygon points="6,4 20,12 6,20" />
                        </svg>
                      </div>
                    </div>
                  </div>
                  <p className="text-sm font-semibold text-white/80 truncate group-hover:text-white transition-colors duration-200">
                    {row.row_title}
                  </p>
                </Link>
              ))}
            </div>
          </section>
        )}
```

---

### Task 7: Create For You Item Grid Route (Web)

**Files:**
- Create: `src/routes/for-you-row.tsx`
- Modify: `src/router.tsx`

- [ ] **Step 1: Create the route component**

```typescript
// src/routes/for-you-row.tsx
import { useSearch } from '@tanstack/react-router';
import { Sidebar } from '@/components/Sidebar';
import { MetaPreview } from '@/lib/types';

export default function ForYouRowPage() {
  const search = useSearch({ from: '/for-you/$rowType' }) as any;
  const items: MetaPreview[] = (() => {
    try { return JSON.parse(search.items || '[]'); } catch { return []; }
  })();
  const title: string = search.title || 'Recommendations';

  return (
    <Sidebar>
      <div className="px-6 pb-12 pt-4">
        <h1 className="text-2xl font-bold tracking-tight text-white mb-6">{title}</h1>
        <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-4">
          {items.map(item => (
            <div key={item.id} className="group cursor-pointer">
              <div className="aspect-[2/3] bg-nightarc-elevated rounded-lg overflow-hidden mb-2">
                {item.poster ? (
                  <img src={item.poster} alt={item.name} loading="lazy"
                    className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105" />
                ) : (
                  <div className="w-full h-full flex items-center justify-center text-white/20 text-xs">{item.name}</div>
                )}
              </div>
              <p className="text-xs font-medium text-white/70 truncate">{item.name}</p>
              {item.releaseInfo && <p className="text-xs text-nightarc-muted mt-0.5">{item.releaseInfo}</p>}
            </div>
          ))}
        </div>
        {items.length === 0 && (
          <div className="flex flex-col items-center justify-center py-32 text-nightarc-muted">
            <p className="text-sm">No items found in this recommendation.</p>
          </div>
        )}
      </div>
    </Sidebar>
  );
}
```

- [ ] **Step 2: Add route to router.tsx** — Add import and route definition:

```typescript
import ForYouRowPage from './routes/for-you-row';

const forYouRowRoute = createRoute({
  getParentRoute: () => protectedLayoutRoute,
  path: '/for-you/$rowType',
  component: ForYouRowPage,
  validateSearch: (search: Record<string, unknown>) => ({
    items: (search.items as string) || '[]',
    title: (search.title as string) || '',
  }),
});

// Add forYouRowRoute to routeTree children array
```

---

### Task 8: Create iOS Recommendations Service

**Files:**
- Create: `Packages/MoonlitCore/Sources/MoonlitCore/Services/RecommendationsService.swift`

- [ ] **Step 1: Create the service**

```swift
import Foundation

public struct RecommendationRow: Codable, Identifiable, Sendable {
    public let rowType: String
    public let rowTitle: String
    public let coverImage: String?
    public let sortOrder: Int
    public let items: [MetaPreview]

    public var id: String { "\(rowType)_\(rowTitle)" }

    enum CodingKeys: String, CodingKey {
        case rowType = "row_type"
        case rowTitle = "row_title"
        case coverImage = "cover_image"
        case sortOrder = "sort_order"
        case items
    }
}

public struct RecommendationsResponse: Codable, Sendable {
    public let generatedAt: String
    public let rows: [RecommendationRow]

    enum CodingKeys: String, CodingKey {
        case generatedAt = "generated_at"
        case rows
    }
}

@MainActor
public final class RecommendationsService: ObservableObject {
    public static let shared = RecommendationsService()

    @Published public var rows: [RecommendationRow] = []
    @Published public var isLoading = false
    @Published public var generatedAt: String?

    private let apiBase = "https://nightarc-web.vercel.app/api/recommendations"

    private init() {}

    public func load(profileId: String) async {
        isLoading = true
        defer { isLoading = false }

        guard var components = URLComponents(string: apiBase) else { return }
        components.queryItems = [URLQueryItem(name: "profile_id", value: profileId)]

        guard let url = components.url else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(RecommendationsResponse.self, from: data)
            rows = response.rows
            generatedAt = response.generatedAt
        } catch {
            print("[RecommendationsService] load failed: \(error)")
        }
    }

    public func triggerRegeneration(profileId: String) async -> Bool {
        guard let components = URLComponents(string: "\(apiBase)/generate") else { return false }
        guard let url = components.url else { return false }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["profile_id": profileId])

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return json?["success"] as? Bool ?? false
        } catch {
            print("[RecommendationsService] generate failed: \(error)")
            return false
        }
    }

    public func clear() {
        rows = []
        generatedAt = nil
    }
}
```

---

### Task 9: Add "For You" Section to iOS HomeScreen

**Files:**
- Modify: `Apps/MoonlitApp/Sources/Screens/HomeScreen.swift`

- [ ] **Step 1: Add StateObject** (~line 17)

```swift
@StateObject private var recsService = RecommendationsService.shared
```

- [ ] **Step 2: Add navigation state** (~line 25)

```swift
@State private var selectedRecRow: CatalogRow? = nil
@State private var showRecFolder = false
```

- [ ] **Step 3: Load recommendations in .task** — after `homeRepo.loadContinueWatching`, add:

```swift
Task { await recsService.load(profileId: profile.id) }
```

- [ ] **Step 4: Add "For You" section in ScrollView** — after Continue Watching block, before catalog rows:

```swift
// For You — Personalized Recommendations
if !recsService.rows.isEmpty {
    VStack(alignment: .leading, spacing: 8) {
        Text("For You")
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal)

        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 10) {
                ForEach(recsService.rows) { row in
                    Button {
                        let catalogRow = CatalogRow(
                            id: row.id,
                            title: row.rowTitle,
                            items: row.items,
                            tileShape: "poster",
                            coverImage: row.coverImage
                        )
                        selectedRecRow = catalogRow
                        showRecFolder = true
                    } label: {
                        FolderCell(row: CatalogRow(
                            id: row.id,
                            title: row.rowTitle,
                            items: row.items,
                            tileShape: "poster",
                            coverImage: row.coverImage
                        ), onTap: { _ in })
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
    .padding(.top, 16)
}
```

- [ ] **Step 5: Add navigation destination** — after other `.navigationDestination` modifiers:

```swift
.navigationDestination(isPresented: $showRecFolder) {
    if let folder = selectedRecRow {
        FolderScreen(row: folder)
    }
}
```

- [ ] **Step 6: Add to pull-to-refresh** — in `.refreshable`, add:

```swift
await recsService.load(profileId: profile.id)
```

---

### Task 10: Pull-to-Refresh Regeneration (Web)

**Files:**
- Modify: `src/routes/home.tsx`

- [ ] **Step 1: Add import and mutation**

```typescript
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { triggerRegeneration } from '@/lib/recommendations';
```

- [ ] **Step 2: Add regeneration mutation**

In `HomePage` component:
```typescript
const queryClient = useQueryClient();
const recMutation = useMutation({
  mutationFn: () => triggerRegeneration(currentProfile!.id),
  onSuccess: () => {
    queryClient.invalidateQueries({ queryKey: ['recommendations', currentProfile?.id] });
  },
});
```

- [ ] **Step 3: Add refresh button next to For You header**

```tsx
<div className="flex items-baseline justify-between mb-4 pr-1">
  <h2 className="text-[17px] font-bold tracking-tight text-white">For You</h2>
  <button onClick={() => recMutation.mutate()} disabled={recMutation.isPending}
    className="text-xs text-nightarc-accent hover:text-white transition-colors">
    {recMutation.isPending ? '...' : 'Refresh'}
  </button>
</div>
```

---

### Task 11: Final Verification

- [ ] **Step 1: Run web dev server and test**

```bash
cd /Users/zain/projects/Moonlit && npm run dev
```

Navigate to home page with a profile that has watch history. Verify "For You" section renders with folder tiles.

- [ ] **Step 2: Test iOS build**

```bash
cd /Users/zain/projects/Moonlit/Apps/MoonlitApp && xcodegen generate && xcodebuild -project MoonlitApp.xcodeproj -scheme MoonlitApp -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -30
```

Verify no compilation errors.

- [ ] **Step 3: Commit**

```bash
git add -A
git commit -m "feat: add personalized 'For You' recommendations per profile"
```
