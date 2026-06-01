# Luna Web Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign LunaWeb home screen (cinematic hero, folder grids, CW artwork), detail page (episode horizontal scroll, network section), and web player (Liquid Glass Apple-style UI, HLS audio+subtitle fixes).

**Architecture:** Six targeted file changes in the existing Next.js 14 app. No new routes needed — `/collections/[folderId]` already exists for folder browsing. All HLS fixes are in `Player.tsx` config and event handling.

**Tech Stack:** Next.js 14, React 18, TypeScript, HLS.js 1.5, Tailwind CSS 3

---

## File Map

| File | Role |
|------|------|
| `LunaWeb/src/app/home/home-data.ts` | Add `pickFeaturedItems` (plural, top-5 by popularity) |
| `LunaWeb/src/components/HomeHero.tsx` | Cinematic hero with backdrop image, rotation dots, auto-advance |
| `LunaWeb/src/components/FolderGrid.tsx` | **New** — 4-col poster grid for a single collection's folders |
| `LunaWeb/src/app/home/page.tsx` | Wire hero rotation timer, CW poster fetch, main-row split, folder grids |
| `LunaWeb/src/app/browse/[type]/[id]/page.tsx` | Episode horizontal scroll cards + network/production chips |
| `LunaWeb/src/components/Player.tsx` | Apple-native UI redesign + HLS audio init fix + subtitle overlay |

---

## Task 1: home-data.ts — `pickFeaturedItems`

**Files:**
- Modify: `LunaWeb/src/app/home/home-data.ts`

- [ ] **Step 1: Add `MAIN_ROW_NAMES` constant and `pickFeaturedItems` function**

Replace the existing `pickFeaturedItem` function (keep it for now, add the new one alongside):

```typescript
// In home-data.ts, after the existing imports:

export const MAIN_ROW_NAMES = [
  'Popular Movies',
  'Popular TV Shows',
  'Trending Movies',
  'Trending TV Shows',
] as const;

export function pickFeaturedItems(rows: HomeCatalogRow[]): FeaturedHomeItem[] {
  const mainRows = rows.filter(r =>
    MAIN_ROW_NAMES.some(n => r.title.toLowerCase() === n.toLowerCase())
  );

  const seen = new Set<string>();
  const candidates: FeaturedHomeItem[] = [];

  for (const row of mainRows) {
    for (const item of row.items) {
      if (!seen.has(item.id)) {
        seen.add(item.id);
        candidates.push({ row, item });
      }
    }
  }

  return candidates
    .sort((a, b) => (b.item.popularity ?? 0) - (a.item.popularity ?? 0))
    .slice(0, 5);
}
```

- [ ] **Step 2: Verify the existing `pickFeaturedItem` is still exported (don't break anything yet)**

`home-data.ts` should now export both `pickFeaturedItem` (old) and `pickFeaturedItems` (new). Build to confirm:

```bash
cd LunaWeb && npx tsc --noEmit 2>&1 | head -20
```

Expected: no new errors.

- [ ] **Step 3: Commit**

```bash
git add LunaWeb/src/app/home/home-data.ts
git commit -m "feat(web): add pickFeaturedItems for top-5 hero rotation"
```

---

## Task 2: HomeHero.tsx — Cinematic Backdrop + Rotation Dots

**Files:**
- Modify: `LunaWeb/src/components/HomeHero.tsx`

- [ ] **Step 1: Rewrite `HomeHero.tsx` with new props and design**

Replace the entire file with:

```tsx
'use client';

import React from 'react';
import Link from 'next/link';
import { FeaturedHomeItem, MetaDetail } from '@/lib/types';

interface HomeHeroProps {
  featuredItems: FeaturedHomeItem[];
  activeIndex: number;
  metas: Record<string, MetaDetail | null>;
  onIndexChange: (i: number) => void;
}

export function HomeHero({ featuredItems, activeIndex, metas, onIndexChange }: HomeHeroProps) {
  if (featuredItems.length === 0) return null;

  const featured = featuredItems[activeIndex] ?? featuredItems[0];
  const meta = metas[featured.item.id] ?? null;

  const title = meta?.name || featured.item.name;
  const description = meta?.description || featured.item.description || '';
  const bgImage = meta?.background || featured.item.banner || featured.item.poster || null;

  const metaParts: string[] = [];
  if (featured.item.type) {
    metaParts.push(featured.item.type.charAt(0).toUpperCase() + featured.item.type.slice(1));
  }
  if (meta?.genres?.length) metaParts.push(meta.genres.slice(0, 2).join(', '));
  const year = meta?.releaseInfo || featured.item.releaseInfo;
  if (year) metaParts.push(year);
  if (meta?.imdbRating || featured.item.imdbRating) {
    metaParts.push(`★ ${meta?.imdbRating ?? featured.item.imdbRating}`);
  }

  return (
    <section className="relative w-full mb-10" style={{ height: 'clamp(420px, 60vh, 680px)' }}>
      {/* Backdrop */}
      {bgImage ? (
        <img
          src={bgImage}
          alt=""
          className="absolute inset-0 w-full h-full object-cover"
          aria-hidden="true"
        />
      ) : (
        <div className="absolute inset-0 bg-luna-elevated" />
      )}

      {/* Gradients */}
      <div className="absolute inset-0 bg-gradient-to-r from-black/90 via-black/50 to-transparent" />
      <div className="absolute inset-0 bg-gradient-to-t from-[#080808] via-transparent to-black/30" />

      {/* Content */}
      <div className="absolute bottom-0 left-0 right-0 p-8 md:p-12 pb-14">
        <p className="text-xs uppercase tracking-[0.18em] text-luna-accent font-bold mb-3">
          {featured.row.title}
        </p>

        {meta?.logo ? (
          <img
            src={meta.logo}
            alt={title}
            className="h-14 sm:h-20 object-contain object-left mb-4"
          />
        ) : (
          <h1 className="text-4xl md:text-5xl lg:text-6xl font-black text-white mb-3 max-w-2xl leading-[1.05] tracking-tight">
            {title}
          </h1>
        )}

        {metaParts.length > 0 && (
          <p className="text-sm text-white/60 mb-4">{metaParts.join(' · ')}</p>
        )}

        {description && (
          <p className="max-w-lg text-sm leading-relaxed text-white/60 mb-6 line-clamp-2">
            {description}
          </p>
        )}

        <div className="flex items-center gap-3">
          <Link
            href={`/browse/${featured.item.type}/${featured.item.id}`}
            className="inline-flex items-center gap-2 rounded-full bg-white px-6 py-3 text-sm font-bold text-black hover:bg-white/90 transition-colors"
          >
            <svg viewBox="0 0 24 24" fill="currentColor" className="w-4 h-4 ml-0.5">
              <polygon points="6,4 20,12 6,20" />
            </svg>
            Watch Now
          </Link>
          <Link
            href={`/browse/${featured.item.type}/${featured.item.id}`}
            className="inline-flex items-center gap-2 rounded-full bg-white/10 border border-white/15 backdrop-blur-sm px-5 py-3 text-sm font-semibold text-white hover:bg-white/15 transition-colors"
          >
            + My List
          </Link>
        </div>
      </div>

      {/* Rotation dots */}
      {featuredItems.length > 1 && (
        <div className="absolute bottom-5 right-8 flex items-center gap-1.5">
          {featuredItems.map((_, i) => (
            <button
              key={i}
              onClick={() => onIndexChange(i)}
              aria-label={`Go to featured item ${i + 1}`}
              className={`h-[3px] rounded-full transition-all duration-300 ${
                i === activeIndex ? 'w-6 bg-white' : 'w-1.5 bg-white/30 hover:bg-white/50'
              }`}
            />
          ))}
        </div>
      )}
    </section>
  );
}
```

- [ ] **Step 2: Type-check**

```bash
cd LunaWeb && npx tsc --noEmit 2>&1 | head -20
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add LunaWeb/src/components/HomeHero.tsx
git commit -m "feat(web): cinematic HomeHero with backdrop, rotation dots, logo support"
```

---

## Task 3: FolderGrid.tsx — New Component

**Files:**
- Create: `LunaWeb/src/components/FolderGrid.tsx`

- [ ] **Step 1: Create `FolderGrid.tsx`**

```tsx
'use client';

import Link from 'next/link';
import { CatalogRow } from '@/lib/types';

interface FolderGridProps {
  /** Collection name shown as section heading */
  collectionTitle: string;
  /** All non-main rows belonging to this collection */
  rows: CatalogRow[];
}

/** Renders a non-main collection as a 4-column poster grid. Each cell links to /collections/[folderId]. */
export function FolderGrid({ collectionTitle, rows }: FolderGridProps) {
  if (rows.length === 0) return null;

  return (
    <section className="mb-10">
      <h2 className="text-base font-bold text-white mb-4 px-0">{collectionTitle}</h2>
      <div className="grid grid-cols-4 sm:grid-cols-6 md:grid-cols-8 gap-2">
        {rows.map(row => (
          <FolderCell key={row.id} row={row} />
        ))}
      </div>
    </section>
  );
}

function FolderCell({ row }: { row: CatalogRow }) {
  // Use the first item's poster as the cell image, fall back to coverImage or gradient
  const coverUrl = row.coverImage || row.items[0]?.poster || null;
  // folderId is encoded in row.id as "folder_<uuid>"
  const folderId = row.id.startsWith('folder_') ? row.id.slice(7) : row.id;

  return (
    <Link
      href={`/collections/${folderId}`}
      className="group relative aspect-[2/3] rounded-lg overflow-hidden bg-luna-elevated cursor-pointer"
    >
      {coverUrl ? (
        <img
          src={coverUrl}
          alt={row.title}
          className="absolute inset-0 w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
          loading="lazy"
        />
      ) : (
        <div className="absolute inset-0 bg-gradient-to-br from-white/5 to-white/0" />
      )}
      {/* Bottom gradient + label */}
      <div className="absolute inset-0 bg-gradient-to-t from-black/80 via-black/10 to-transparent" />
      <div className="absolute bottom-0 left-0 right-0 p-2">
        <p className="text-[10px] font-bold text-white leading-tight line-clamp-2">{row.title}</p>
      </div>
    </Link>
  );
}
```

Note: `CatalogRow` in the web app's `HomeCatalogRow` type doesn't have `coverImage`. We need to add it. Open `LunaWeb/src/lib/types.ts` and extend `HomeCatalogRow`:

```typescript
// In types.ts, update HomeCatalogRow:
export interface HomeCatalogRow {
  id: string;
  title: string;
  type: string;
  catalogId: string;
  items: MetaPreview[];
  coverImage?: string;      // ADD THIS
  isMainRow?: boolean;      // ADD THIS — true for the 4 featured rows
}
```

Then update `FolderGrid.tsx` to use `HomeCatalogRow` (rename the import):

```tsx
import { HomeCatalogRow } from '@/lib/types';

interface FolderGridProps {
  collectionTitle: string;
  rows: HomeCatalogRow[];
}

function FolderCell({ row }: { row: HomeCatalogRow }) {
  const coverUrl = row.coverImage || row.items[0]?.poster || null;
  const folderId = row.id.startsWith('folder_') ? row.id.slice(7) : row.id;
  // ... rest same
}
```

- [ ] **Step 2: Type-check**

```bash
cd LunaWeb && npx tsc --noEmit 2>&1 | head -20
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add LunaWeb/src/components/FolderGrid.tsx LunaWeb/src/lib/types.ts
git commit -m "feat(web): add FolderGrid component and HomeCatalogRow.isMainRow/coverImage fields"
```

---

## Task 4: home-data.ts — Tag Main Rows + Pass coverImage

**Files:**
- Modify: `LunaWeb/src/app/home/home-data.ts`

- [ ] **Step 1: Update `buildHomeRows` to tag main rows and pass coverImage**

Replace the `buildHomeRows` function:

```typescript
export function buildHomeRows(
  manifest: AddonManifest,
  catalogItemsById: Record<string, MetaPreview[]>
): HomeCatalogRow[] {
  return (manifest.catalogs || [])
    .map((catalog) => {
      const items =
        catalogItemsById[`${catalog.type}:${catalog.id}`] ||
        catalogItemsById[catalog.id] ||
        [];

      if (items.length === 0) return null;

      const title = catalog.name || catalog.id;
      const isMainRow = MAIN_ROW_NAMES.some(
        n => title.toLowerCase() === n.toLowerCase()
      );

      return {
        id: `${manifest.id}_${catalog.type}_${catalog.id}`,
        title,
        type: catalog.type,
        catalogId: catalog.id,
        items,
        isMainRow,
      } satisfies HomeCatalogRow;
    })
    .filter((row): row is HomeCatalogRow => row !== null);
}
```

- [ ] **Step 2: Type-check**

```bash
cd LunaWeb && npx tsc --noEmit 2>&1 | head -20
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add LunaWeb/src/app/home/home-data.ts
git commit -m "feat(web): tag main rows and pass coverImage in buildHomeRows"
```

---

## Task 5: home/page.tsx — Wire Everything Together

**Files:**
- Modify: `LunaWeb/src/app/home/page.tsx`

- [ ] **Step 1: Replace `home/page.tsx` with the updated version**

```tsx
'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import { useAuth } from '../AuthProvider';
import { useRouter } from 'next/navigation';
import { Sidebar } from '@/components/Sidebar';
import { HomeHero } from '@/components/HomeHero';
import { MediaRow } from '@/components/MediaRow';
import { FolderGrid } from '@/components/FolderGrid';
import { FeaturedHomeItem, HomeCatalogRow, MetaDetail, WatchProgressEntry } from '@/lib/types';
import { getWatchProgress, getSystemAddon } from '@/lib/services/api';
import { fetchCatalog, fetchManifest, fetchMeta } from '@/lib/stremio';
import { buildHomeRows, pickFeaturedItems, selectInitialCatalogs, MAIN_ROW_NAMES } from './home-data';
import Link from 'next/link';

const HERO_INTERVAL_MS = 6000;

interface ContinueWatchingItem extends WatchProgressEntry {
  poster?: string;
  resolvedName?: string;
}

export default function HomePage() {
  const { currentProfile, user, isLoading } = useAuth();
  const router = useRouter();

  const [rows, setRows] = useState<HomeCatalogRow[]>([]);
  const [featuredItems, setFeaturedItems] = useState<FeaturedHomeItem[]>([]);
  const [featuredMetas, setFeaturedMetas] = useState<Record<string, MetaDetail | null>>({});
  const [featuredIndex, setFeaturedIndex] = useState(0);
  const [hasSystemAddon, setHasSystemAddon] = useState(true);
  const [continueWatching, setContinueWatching] = useState<ContinueWatchingItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const heroTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const heroPausedRef = useRef(false);

  // Auto-rotate hero
  useEffect(() => {
    if (featuredItems.length <= 1) return;
    heroTimerRef.current = setInterval(() => {
      if (!heroPausedRef.current) {
        setFeaturedIndex(i => (i + 1) % featuredItems.length);
      }
    }, HERO_INTERVAL_MS);
    return () => {
      if (heroTimerRef.current) clearInterval(heroTimerRef.current);
    };
  }, [featuredItems.length]);

  const loadData = useCallback(async () => {
    if (!currentProfile) return;
    setLoading(true);
    setError(null);
    try {
      const [progress, systemAddon] = await Promise.all([
        getWatchProgress(currentProfile.id),
        getSystemAddon(),
      ]);

      const filteredProgress = progress
        .filter(e => !e.completed && e.position_seconds > 0)
        .sort((a, b) => new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime())
        .slice(0, 10);

      if (!systemAddon?.manifest_url) {
        setHasSystemAddon(false);
        setContinueWatching(filteredProgress);
        setRows([]);
        setFeaturedItems([]);
        return;
      }

      setHasSystemAddon(true);
      const manifest = await fetchManifest(systemAddon.manifest_url);
      if (!manifest.transportUrl) {
        setContinueWatching(filteredProgress);
        setRows([]);
        setFeaturedItems([]);
        return;
      }

      // Fetch CW meta (name + poster) in parallel
      const cwWithMeta: ContinueWatchingItem[] = await Promise.all(
        filteredProgress.map(async entry => {
          try {
            const meta = await fetchMeta(manifest.transportUrl!, entry.media_type, entry.media_id);
            return { ...entry, resolvedName: meta?.name, poster: meta?.poster ?? meta?.background ?? undefined };
          } catch {
            return entry;
          }
        })
      );
      setContinueWatching(cwWithMeta);

      // Fetch catalog rows
      const initialCatalogs = selectInitialCatalogs(manifest);
      const catalogResults = await Promise.allSettled(
        initialCatalogs.map(async catalog => ({
          key: `${catalog.type}:${catalog.id}`,
          fallbackKey: catalog.id,
          items: await fetchCatalog(manifest.transportUrl!, catalog.type, catalog.id),
        }))
      );

      const catalogItemsById: Record<string, HomeCatalogRow['items']> = {};
      for (const result of catalogResults) {
        if (result.status !== 'fulfilled') continue;
        catalogItemsById[result.value.key] = result.value.items;
        if (!(result.value.fallbackKey in catalogItemsById)) {
          catalogItemsById[result.value.fallbackKey] = result.value.items;
        }
      }

      const nextRows = buildHomeRows(manifest, catalogItemsById);
      const nextFeaturedItems = pickFeaturedItems(nextRows);

      setRows(nextRows);
      setFeaturedItems(nextFeaturedItems);
      setFeaturedIndex(0);

      // Prefetch meta for all 5 hero items in parallel
      const canFetchMeta = manifest.resources?.some(r =>
        (typeof r === 'string' ? r : r.name) === 'meta'
      );

      if (canFetchMeta && nextFeaturedItems.length > 0) {
        const metaResults = await Promise.allSettled(
          nextFeaturedItems.map(fi =>
            fetchMeta(manifest.transportUrl!, fi.item.type, fi.item.id)
              .then(m => ({ id: fi.item.id, meta: m }))
          )
        );
        const metasById: Record<string, MetaDetail | null> = {};
        for (const r of metaResults) {
          if (r.status === 'fulfilled') metasById[r.value.id] = r.value.meta;
        }
        setFeaturedMetas(metasById);
      }
    } catch (e) {
      console.error('Failed to load home data:', e);
      setError('Failed to load content. Please try again later.');
      setRows([]);
      setFeaturedItems([]);
    } finally {
      setLoading(false);
    }
  }, [currentProfile]);

  useEffect(() => {
    if (isLoading) return;
    if (!user) { router.replace('/auth'); return; }
    if (!currentProfile) { router.replace('/profiles'); return; }
    loadData();
  }, [currentProfile, isLoading, user, loadData]);

  if (loading) {
    return (
      <Sidebar>
        <div className="flex items-center justify-center min-h-screen">
          <div className="animate-spin rounded-full h-6 w-6 border-2 border-luna-accent border-t-transparent" />
        </div>
      </Sidebar>
    );
  }

  // Split rows: main 4 rows vs folder rows
  const mainRows = rows.filter(r => r.isMainRow);
  const folderRows = rows.filter(r => !r.isMainRow);

  // Group folder rows by a pseudo-collection name derived from their title patterns
  // Since we don't have collection info in HomeCatalogRow for web, group all folder rows together
  // under a single "Browse" section. For richer grouping, the iOS app has full collection context.
  const hasFolderRows = folderRows.length > 0;

  return (
    <Sidebar>
      {/* Hero — full width, no horizontal padding */}
      {featuredItems.length > 0 && (
        <div
          onMouseEnter={() => { heroPausedRef.current = true; }}
          onMouseLeave={() => { heroPausedRef.current = false; }}
        >
          <HomeHero
            featuredItems={featuredItems}
            activeIndex={featuredIndex}
            metas={featuredMetas}
            onIndexChange={setFeaturedIndex}
          />
        </div>
      )}

      <div className="px-6 pb-12">
        {/* Continue Watching */}
        {continueWatching.length > 0 && (
          <section className="mb-10">
            <h2 className="text-base font-bold text-white mb-4">Continue Watching</h2>
            <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-hide">
              {continueWatching.map(item => {
                const pct = item.duration_seconds > 0
                  ? Math.round((item.position_seconds / item.duration_seconds) * 100)
                  : 0;
                return (
                  <Link
                    key={item.media_id}
                    href={`/browse/${item.media_type}/${item.media_id}`}
                    className="flex-shrink-0 w-48 group cursor-pointer"
                  >
                    <div className="relative h-[108px] bg-luna-elevated rounded-xl overflow-hidden mb-2">
                      {item.poster ? (
                        <img
                          src={item.poster}
                          alt={item.resolvedName || item.media_id}
                          className="absolute inset-0 w-full h-full object-cover"
                          loading="lazy"
                        />
                      ) : null}
                      <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                        <div className="w-10 h-10 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center">
                          <svg viewBox="0 0 24 24" fill="currentColor" className="w-5 h-5 ml-0.5">
                            <polygon points="6,4 20,12 6,20" />
                          </svg>
                        </div>
                      </div>
                      <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-white/10">
                        <div className="h-full bg-luna-accent" style={{ width: `${pct}%` }} />
                      </div>
                    </div>
                    <p className="text-xs text-white font-medium truncate">
                      {item.resolvedName || item.media_id}
                    </p>
                    <p className="text-xs text-luna-muted mt-0.5">{pct}% watched</p>
                  </Link>
                );
              })}
            </div>
          </section>
        )}

        {!hasSystemAddon ? (
          <div className="flex flex-col items-center justify-center py-32 text-luna-muted">
            <p className="text-sm">No system addon configured.</p>
          </div>
        ) : error ? (
          <div className="flex flex-col items-center justify-center py-32 text-luna-muted">
            <p className="text-sm">Something went wrong.</p>
            <p className="text-xs mt-1 opacity-60">{error}</p>
          </div>
        ) : (
          <>
            {/* 4 Main rows */}
            {mainRows.map(row => (
              <MediaRow key={row.id} title={row.title} items={row.items} />
            ))}

            {/* Folder grids */}
            {hasFolderRows && (
              <FolderGrid collectionTitle="Browse" rows={folderRows} />
            )}
          </>
        )}
      </div>
    </Sidebar>
  );
}
```

- [ ] **Step 2: Type-check**

```bash
cd LunaWeb && npx tsc --noEmit 2>&1 | head -30
```

Expected: no errors.

- [ ] **Step 3: Start dev server and verify the home page loads**

```bash
cd LunaWeb && npm run dev
```

Open `http://localhost:3000/home`. Verify:
- Cinematic hero shows with backdrop image (or dark fallback if no backdrop)
- Rotation dots appear at bottom-right
- Continue Watching shows poster thumbnails (not blank boxes)
- 4 main rows render as horizontal scroll
- Non-main rows appear as a 4-col folder grid

- [ ] **Step 4: Commit**

```bash
git add LunaWeb/src/app/home/page.tsx
git commit -m "feat(web): wire hero rotation, CW poster artwork, folder grid to home screen"
```

---

## Task 6: browse/[type]/[id]/page.tsx — Episode Horizontal Scroll + Network Section

**Files:**
- Modify: `LunaWeb/src/app/browse/[type]/[id]/page.tsx`

The page already has a solid hero, season selector, and episode list. Three targeted changes:
1. Change episodes from vertical list to **horizontal scroll cards** (thumbnail + episode number + title + 2-line description)
2. Add **genre pill chips** below the metadata line
3. Add a **network/production** section from `detail.links`

- [ ] **Step 1: Add `MetaDetail` `links` field to types if missing**

Check `LunaWeb/src/lib/types.ts` — if `MetaDetail` doesn't have `links`, add it:

```typescript
export interface MetaLink {
  name: string;
  category?: string;
  url: string;
}

// In MetaDetail interface, add:
links?: MetaLink[];
```

- [ ] **Step 2: Replace the Episodes section in `browse/[type]/[id]/page.tsx`**

Find the block starting with `{/* Seasons + Episodes */}` and replace the inner episode list (the `<div className="space-y-1">` block) with a horizontal scroll version:

```tsx
{/* Seasons + Episodes */}
{isSeries && detail?.seasons && detail.seasons.length > 0 && (
  <section>
    <h3 className="text-sm font-semibold text-white mb-4">Episodes</h3>
    {/* Season tabs */}
    <div className="flex gap-2 overflow-x-auto pb-2 mb-5 scrollbar-hide">
      {detail.seasons.map(s => (
        <button key={s.id}
          onClick={() => { setSelectedSeason(s); setShowStreams(false); setSelectedEpisodeId(null); }}
          className={`flex-shrink-0 px-4 py-2 rounded-full text-sm font-medium transition-all ${
            selectedSeason?.id === s.id
              ? 'bg-white text-black'
              : 'bg-white/8 text-white/60 hover:bg-white/12 hover:text-white'
          }`}>
          Season {s.number}
        </button>
      ))}
    </div>
    {/* Horizontal episode cards */}
    {selectedSeason?.episodes && (
      <div className="flex gap-4 overflow-x-auto pb-3 scrollbar-hide -mx-6 px-6">
        {selectedSeason.episodes.map(ep => (
          <button
            key={ep.id}
            onClick={() => handleEpisodeClick(ep.id)}
            className={`flex-shrink-0 w-52 text-left group rounded-xl overflow-hidden transition-all ${
              selectedEpisodeId === ep.id ? 'ring-2 ring-luna-accent' : ''
            }`}
          >
            {/* Thumbnail */}
            <div className="relative w-full aspect-video bg-luna-elevated rounded-xl overflow-hidden mb-2">
              {ep.thumbnail ? (
                <img
                  src={ep.thumbnail}
                  alt={ep.title}
                  className="absolute inset-0 w-full h-full object-cover"
                  loading="lazy"
                />
              ) : (
                <div className="absolute inset-0 flex items-center justify-center text-white/15 text-sm font-semibold">
                  E{ep.episode}
                </div>
              )}
              <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                <div className="w-10 h-10 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center">
                  <svg viewBox="0 0 24 24" fill="white" className="w-4 h-4 ml-0.5">
                    <polygon points="6,4 20,12 6,20" />
                  </svg>
                </div>
              </div>
            </div>
            {/* Labels */}
            <p className="text-[10px] text-white/40 mb-0.5">Episode {ep.episode}</p>
            <p className="text-sm font-semibold text-white truncate">{ep.title}</p>
            {ep.overview && (
              <p className="text-xs text-white/40 mt-1 line-clamp-2 leading-relaxed">{ep.overview}</p>
            )}
          </button>
        ))}
      </div>
    )}
  </section>
)}
```

- [ ] **Step 3: Add genre chips below the metadata line**

Find the line `{detail?.genres?.slice(0, 3).map(g => (` (inside the hero section) and replace it with pill chips:

```tsx
{/* Genre chips */}
{detail?.genres && detail.genres.length > 0 && (
  <div className="flex flex-wrap gap-2 mb-4">
    {detail.genres.slice(0, 5).map(g => (
      <span
        key={g}
        className="px-3 py-1 rounded-full bg-white/8 border border-white/10 text-xs text-white/70 font-medium"
      >
        {g}
      </span>
    ))}
  </div>
)}
```

Remove the old inline genre spans from the metadata row.

- [ ] **Step 4: Add network/production section below cast**

After the cast section closing `</section>`, add:

```tsx
{/* Network / Production */}
{detail?.links && detail.links.length > 0 && (() => {
  const networks = detail.links!.filter(l => l.category === 'network');
  const studios = detail.links!.filter(l => l.category === 'production');
  if (networks.length === 0 && studios.length === 0) return null;
  return (
    <section className="flex gap-8 flex-wrap">
      {networks.length > 0 && (
        <div>
          <h4 className="text-xs font-bold text-white/40 uppercase tracking-wider mb-3">Network</h4>
          <div className="flex gap-2 flex-wrap">
            {networks.map(l => (
              <span key={l.url} className="px-3 py-1.5 rounded-lg bg-white/6 border border-white/8 text-xs text-white/70 font-semibold">
                {l.name}
              </span>
            ))}
          </div>
        </div>
      )}
      {studios.length > 0 && (
        <div>
          <h4 className="text-xs font-bold text-white/40 uppercase tracking-wider mb-3">Production</h4>
          <div className="flex gap-2 flex-wrap">
            {studios.map(l => (
              <span key={l.url} className="px-3 py-1.5 rounded-lg bg-white/6 border border-white/8 text-xs text-white/70 font-semibold">
                {l.name}
              </span>
            ))}
          </div>
        </div>
      )}
    </section>
  );
})()}
```

- [ ] **Step 5: Type-check and verify**

```bash
cd LunaWeb && npx tsc --noEmit 2>&1 | head -20
```

Navigate to a series detail page (e.g. `/browse/series/tt15562852`) and verify:
- Episode cards are horizontal scroll with thumbnails
- Genre pill chips appear below meta row
- If the addon returns `links`, network/production chips appear

- [ ] **Step 6: Commit**

```bash
git add LunaWeb/src/app/browse/[type]/[id]/page.tsx LunaWeb/src/lib/types.ts
git commit -m "feat(web): horizontal episode cards, genre chips, network section on detail page"
```

---

## Task 7: Player.tsx — Apple-Native Redesign + HLS Fixes

**Files:**
- Modify: `LunaWeb/src/components/Player.tsx`

This is a full replacement. Key changes from the current version:
- **Liquid Glass visual style** — all controls use `backdrop-filter: blur()` + translucent borders. Back button and title are glass pills. Skip buttons are glass circles. Play button is a heavy glass disc with inner specular highlight. Bottom controls float as a dark glass shelf (`rgba(0,0,0,.45)` + `blur(40px)`). Popovers use dark glass (`blur(48px)`).
- Apple-native layout: top bar with back/title/AirPlay, center skip+play, bottom scrubber+controls
- HLS audio fix: ensure `AUDIO_TRACK_SWITCHED` event is handled; use `hls.recoverMediaError()` on fatal media errors
- Subtitle fix: set `renderTextTracksNatively: false` in HLS config, implement custom `<div>` cue overlay using the video element's `textTracks` API
- Quality panel: derive from `hls.levels` (real levels), not hardcoded list
- Remove fake hardcoded chapters panel

**CSS tokens for Liquid Glass** (use inline styles or extend Tailwind config — `backdrop-filter` isn't in Tailwind v3 by default, use the `[@supports]` variant or inline):
```css
/* Glass light — for back pill, skip buttons, top icons */
background: rgba(255,255,255,0.08);
backdrop-filter: blur(32px) saturate(180%);
border: 1px solid rgba(255,255,255,0.12);
box-shadow: 0 2px 16px rgba(0,0,0,0.35), inset 0 1px 0 rgba(255,255,255,0.15);

/* Glass dark — for bottom shelf, popovers */
background: rgba(0,0,0,0.45);
backdrop-filter: blur(40px) saturate(150%);
border: 1px solid rgba(255,255,255,0.08);
box-shadow: 0 8px 32px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.08);

/* Play button — stronger glass disc */
background: rgba(255,255,255,0.14);
backdrop-filter: blur(40px) saturate(200%);
border: 1.5px solid rgba(255,255,255,0.22);
box-shadow: 0 4px 24px rgba(0,0,0,0.4), inset 0 1.5px 0 rgba(255,255,255,0.3), inset 0 -1.5px 0 rgba(0,0,0,0.15);
```

- [ ] **Step 1: Replace `Player.tsx` entirely**

```tsx
'use client';

import { useEffect, useRef, useState, useCallback } from 'react';
import Hls from 'hls.js';
import { StreamItem } from '@/lib/types';
import { updateWatchProgress } from '@/lib/services/api';
import { useAuth } from '@/app/AuthProvider';

interface PlayerProps {
  streamUrl: string;
  streams: StreamItem[];
  currentStream: StreamItem;
  title: string;
  poster?: string;
  backdrop?: string;
  mediaId: string;
  mediaType: string;
  startPosition?: number;
  onSwitchStream: (stream: StreamItem) => void;
  onBack: () => void;
}

interface TrackItem { id: number; name: string; lang: string }
interface QualityLevel { height: number; bitrate: number }

function fmt(s: number): string {
  if (!isFinite(s) || s < 0) return '0:00';
  const sec = Math.floor(s), m = Math.floor(sec / 60), r = sec % 60;
  if (m >= 60) { const h = Math.floor(m / 60); return `${h}:${String(m % 60).padStart(2,'0')}:${String(r).padStart(2,'0')}`; }
  return `${m}:${String(r).padStart(2,'0')}`;
}

export default function Player({
  streamUrl, streams, currentStream, title, poster, backdrop,
  mediaId, mediaType, startPosition, onSwitchStream, onBack,
}: PlayerProps) {
  const videoRef = useRef<HTMLVideoElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const hlsRef = useRef<Hls | null>(null);
  const progressInterval = useRef<ReturnType<typeof setInterval> | null>(null);
  const hideTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const startPosRef = useRef<number | undefined>();
  const { currentProfile } = useAuth();

  const [state, setState] = useState<'loading' | 'playing' | 'paused' | 'ended' | 'error'>('loading');
  const [pos, setPos] = useState(0);
  const [dur, setDur] = useState(0);
  const [buf, setBuf] = useState(0);
  const [showControls, setShowControls] = useState(true);
  const [showSources, setShowSources] = useState(false);
  const [showSubPop, setShowSubPop] = useState(false);
  const [showQualPop, setShowQualPop] = useState(false);
  const [errMsg, setErrMsg] = useState('');
  const [volume, setVolume] = useState(1);
  const [muted, setMuted] = useState(false);
  const [audioTracks, setAudioTracks] = useState<TrackItem[]>([]);
  const [activeAudio, setActiveAudio] = useState(-1);
  const [subTracks, setSubTracks] = useState<TrackItem[]>([]);
  const [activeSub, setActiveSub] = useState(-1);
  const [isDragging, setIsDragging] = useState(false);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [qualityLevels, setQualityLevels] = useState<QualityLevel[]>([]);
  const [activeQuality, setActiveQuality] = useState(-1); // -1 = Auto
  // Subtitle cue overlay
  const [activeCueText, setActiveCueText] = useState('');

  useEffect(() => { startPosRef.current = startPosition; }, [startPosition]);

  // --- HLS init ---
  const initPlayer = useCallback(() => {
    const video = videoRef.current;
    if (!video) return;
    if (hlsRef.current) { hlsRef.current.destroy(); hlsRef.current = null; }
    video.src = '';
    setState('loading'); setErrMsg('');
    setAudioTracks([]); setActiveAudio(-1);
    setSubTracks([]); setActiveSub(-1);
    setQualityLevels([]); setActiveQuality(-1);
    setActiveCueText('');

    const proxyHeaders = currentStream.behaviorHints?.proxyHeaders?.request;
    const hasHeaders = proxyHeaders != null && Object.keys(proxyHeaders).length > 0;
    const isHls = streamUrl.includes('.m3u8') || streamUrl.includes('/manifest') || streamUrl.includes('/playlist');
    const tryHls = (isHls || hasHeaders) && Hls.isSupported();

    if (tryHls) {
      const hls = new Hls({
        renderTextTracksNatively: false,   // we render subs ourselves
        subtitleDisplay: false,            // disable native display
        startLevel: -1,                    // auto quality on start
        xhrSetup(xhr) {
          if (hasHeaders) {
            for (const [k, v] of Object.entries(proxyHeaders!)) xhr.setRequestHeader(k, v);
          }
        },
      });

      hls.on(Hls.Events.MANIFEST_PARSED, (_e, data) => {
        const at = hls.audioTracks.map((t, i) => ({ id: i, name: t.name || t.lang || 'Unknown', lang: t.lang || '?' }));
        const st = hls.subtitleTracks.map((t, i) => ({ id: i, name: t.name || t.lang || 'Unknown', lang: t.lang || '?' }));
        const ql: QualityLevel[] = data.levels.map(l => ({ height: l.height, bitrate: l.bitrate }));

        if (at.length > 0) { setAudioTracks(at); setActiveAudio(hls.audioTrack); }
        if (st.length > 0) { setSubTracks(st); }
        if (ql.length > 0) { setQualityLevels(ql); }

        video.play().catch(() => {});
      });

      hls.on(Hls.Events.AUDIO_TRACKS_UPDATED, () => {
        const at = hls.audioTracks.map((t, i) => ({ id: i, name: t.name || t.lang || 'Unknown', lang: t.lang || '?' }));
        setAudioTracks(at);
        setActiveAudio(hls.audioTrack);
      });

      hls.on(Hls.Events.SUBTITLE_TRACKS_UPDATED, () => {
        const st = hls.subtitleTracks.map((t, i) => ({ id: i, name: t.name || t.lang || 'Unknown', lang: t.lang || '?' }));
        setSubTracks(st);
      });

      hls.on(Hls.Events.AUDIO_TRACK_SWITCHED, (_e, d) => setActiveAudio(d.id));
      hls.on(Hls.Events.SUBTITLE_TRACK_SWITCH, (_e, d) => {
        setActiveSub(d.id);
        hls.subtitleDisplay = d.id >= 0;
      });

      hls.on(Hls.Events.ERROR, (_e, data) => {
        if (data.fatal) {
          if (data.type === Hls.ErrorTypes.MEDIA_ERROR) {
            hls.recoverMediaError();
          } else {
            setState('error');
            setErrMsg(data.type === Hls.ErrorTypes.NETWORK_ERROR ? 'Network error' : 'Playback error');
            hls.destroy(); hlsRef.current = null;
          }
        }
      });

      hls.loadSource(streamUrl);
      hls.attachMedia(video);
      hlsRef.current = hls;
    } else {
      video.src = streamUrl;
      video.play().catch(() => {});
    }
  }, [streamUrl, currentStream]);

  useEffect(() => {
    initPlayer();
    return () => { if (hlsRef.current) { hlsRef.current.destroy(); hlsRef.current = null; } };
  }, [initPlayer]);

  // --- Subtitle cue overlay using TextTrack API ---
  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;

    function updateCue() {
      if (!video) return;
      let text = '';
      for (let ti = 0; ti < video.textTracks.length; ti++) {
        const track = video.textTracks[ti];
        if (track.mode !== 'showing' && track.mode !== 'hidden') continue;
        if (!track.activeCues || track.activeCues.length === 0) continue;
        for (let ci = 0; ci < track.activeCues.length; ci++) {
          const cue = track.activeCues[ci] as VTTCue;
          if (cue.text) text += (text ? '\n' : '') + cue.text;
        }
        if (text) break;
      }
      setActiveCueText(text);
    }

    video.addEventListener('timeupdate', updateCue);
    return () => video.removeEventListener('timeupdate', updateCue);
  }, [streamUrl]);

  // Set TextTrack modes when activeSub changes
  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;
    for (let i = 0; i < video.textTracks.length; i++) {
      video.textTracks[i].mode = i === activeSub ? 'showing' : 'disabled';
    }
    if (activeSub < 0) setActiveCueText('');
  }, [activeSub]);

  // --- Video events ---
  useEffect(() => {
    const video = videoRef.current;
    if (!video) return;
    const onCanPlay = () => {
      setState('paused');
      if (startPosRef.current && startPosRef.current > 0) {
        video.currentTime = startPosRef.current;
        startPosRef.current = undefined;
      }
    };
    const onPlay = () => setState('playing');
    const onPause = () => { if (!video.ended) setState('paused'); };
    const onEnded = () => setState('ended');
    const onError = () => { setState('error'); setErrMsg('Failed to play'); };
    const onTimeUpdate = () => {
      if (isDragging) return;
      setPos(video.currentTime); setDur(video.duration || 0);
      if (video.buffered.length > 0) setBuf(video.buffered.end(video.buffered.length - 1));
    };
    video.addEventListener('canplay', onCanPlay);
    video.addEventListener('play', onPlay);
    video.addEventListener('pause', onPause);
    video.addEventListener('ended', onEnded);
    video.addEventListener('error', onError);
    video.addEventListener('timeupdate', onTimeUpdate);
    return () => {
      video.removeEventListener('canplay', onCanPlay);
      video.removeEventListener('play', onPlay);
      video.removeEventListener('pause', onPause);
      video.removeEventListener('ended', onEnded);
      video.removeEventListener('error', onError);
      video.removeEventListener('timeupdate', onTimeUpdate);
    };
  }, [streamUrl, isDragging]);

  // --- Progress reporting ---
  useEffect(() => {
    if (!currentProfile) return;
    progressInterval.current = setInterval(async () => {
      const video = videoRef.current;
      if (video && video.currentTime > 0) {
        await updateWatchProgress(currentProfile.id, mediaId, mediaType, video.currentTime, video.duration || 0, false);
      }
    }, 10000);
    return () => { if (progressInterval.current) clearInterval(progressInterval.current); };
  }, [currentProfile, mediaId, mediaType]);

  useEffect(() => {
    if (state === 'ended' && currentProfile) {
      updateWatchProgress(currentProfile.id, mediaId, mediaType, dur, dur, true);
    }
  }, [state, currentProfile, mediaId, mediaType, dur]);

  // --- Controls hide ---
  const resetHide = useCallback(() => {
    setShowControls(true);
    if (hideTimer.current) clearTimeout(hideTimer.current);
    hideTimer.current = setTimeout(() => setShowControls(false), 3500);
  }, []);

  useEffect(() => {
    const el = containerRef.current;
    if (!el) return;
    const mv = () => resetHide();
    const lv = () => { if (!showSubPop && !showQualPop && !showSources) setShowControls(false); };
    el.addEventListener('mousemove', mv);
    el.addEventListener('mouseleave', lv);
    resetHide();
    return () => {
      el.removeEventListener('mousemove', mv);
      el.removeEventListener('mouseleave', lv);
      if (hideTimer.current) clearTimeout(hideTimer.current);
    };
  }, [resetHide, showSubPop, showQualPop, showSources]);

  // --- Fullscreen ---
  useEffect(() => {
    const onChange = () => setIsFullscreen(!!document.fullscreenElement);
    document.addEventListener('fullscreenchange', onChange);
    return () => document.removeEventListener('fullscreenchange', onChange);
  }, []);

  // --- Volume sync ---
  useEffect(() => {
    const v = videoRef.current;
    if (v) { v.volume = volume; v.muted = muted; }
  }, [volume, muted]);

  // --- Playback controls ---
  const togglePlay = useCallback(() => {
    const v = videoRef.current;
    if (!v) return;
    if (v.paused) v.play().catch(() => {}); else v.pause();
  }, []);

  const seek = useCallback((s: number) => {
    const v = videoRef.current;
    if (!v) return;
    v.currentTime = s; setPos(s);
  }, []);

  const skip = useCallback((s: number) => {
    const v = videoRef.current;
    if (!v) return;
    seek(Math.max(0, Math.min(v.duration || 0, v.currentTime + s)));
  }, [seek]);

  const toggleFS = useCallback(() => {
    const el = containerRef.current;
    if (!el) return;
    if (document.fullscreenElement) document.exitFullscreen();
    else el.requestFullscreen().catch(() => {});
  }, []);

  const switchAudio = (id: number) => {
    if (hlsRef.current) { hlsRef.current.audioTrack = id; }
    setShowSubPop(false);
  };

  const switchSub = (id: number) => {
    if (hlsRef.current) {
      hlsRef.current.subtitleTrack = id;
      hlsRef.current.subtitleDisplay = id >= 0;
    }
    setActiveSub(id);
    setShowSubPop(false);
  };

  const switchQuality = (level: number) => {
    if (hlsRef.current) hlsRef.current.currentLevel = level;
    setActiveQuality(level);
    setShowQualPop(false);
  };

  // --- Keyboard ---
  useEffect(() => {
    const onK = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return;
      if (e.key === ' ' || e.key === 'k') { e.preventDefault(); togglePlay(); }
      if (e.key === 'ArrowLeft') skip(-15);
      if (e.key === 'ArrowRight') skip(15);
      if (e.key === 'ArrowUp') setVolume(v => Math.min(1, v + 0.1));
      if (e.key === 'ArrowDown') setVolume(v => Math.max(0, v - 0.1));
      if (e.key === 'f') toggleFS();
      if (e.key === 'm') { e.preventDefault(); setMuted(m => !m); }
    };
    window.addEventListener('keydown', onK);
    return () => window.removeEventListener('keydown', onK);
  }, [togglePlay, skip, toggleFS]);

  // --- Seek bar ---
  const seekBarRef = useRef<HTMLDivElement>(null);
  const seekFromX = useCallback((clientX: number) => {
    const el = seekBarRef.current;
    if (!el) return;
    const rect = el.getBoundingClientRect();
    const pct = Math.max(0, Math.min(1, (clientX - rect.left) / rect.width));
    seek(pct * (dur || 0));
  }, [dur, seek]);

  useEffect(() => {
    if (!isDragging) return;
    const onMove = (e: MouseEvent) => seekFromX(e.clientX);
    const onUp = () => setIsDragging(false);
    window.addEventListener('mousemove', onMove);
    window.addEventListener('mouseup', onUp);
    return () => { window.removeEventListener('mousemove', onMove); window.removeEventListener('mouseup', onUp); };
  }, [isDragging, seekFromX]);

  const pct = dur > 0 ? (pos / dur) * 100 : 0;
  const bufPct = dur > 0 ? (buf / dur) * 100 : 0;
  const bgSrc = backdrop || poster;

  const closePops = () => { setShowSubPop(false); setShowQualPop(false); };

  return (
    <div
      ref={containerRef}
      className="fixed inset-0 bg-black z-50 select-none"
      style={{ cursor: showControls ? 'default' : 'none' }}
    >
      <video
        ref={videoRef}
        className="absolute inset-0 w-full h-full"
        playsInline
        onClick={togglePlay}
      />

      {/* Subtitle overlay */}
      {activeCueText && (
        <div className="absolute bottom-28 left-0 right-0 flex justify-center pointer-events-none z-20 px-8">
          <div className="bg-black/75 text-white text-base font-medium px-4 py-2 rounded-lg text-center whitespace-pre-wrap max-w-2xl leading-relaxed">
            {activeCueText}
          </div>
        </div>
      )}

      {/* Loading */}
      {state === 'loading' && (
        <div className="absolute inset-0 flex flex-col items-center justify-center gap-5 bg-black/80 z-20">
          {bgSrc && <div className="absolute inset-0 bg-cover bg-center opacity-25 blur-lg" style={{ backgroundImage: `url(${bgSrc})` }} />}
          <div className="relative z-10 flex flex-col items-center gap-5">
            {poster && <img src={poster} alt="" className="w-24 sm:w-28 rounded-xl shadow-2xl" />}
            <h2 className="text-base font-semibold text-white text-center max-w-sm px-4">{title}</h2>
            <div className="w-7 h-7 rounded-full border-2 border-white border-t-transparent animate-spin" />
          </div>
        </div>
      )}

      {/* Error */}
      {state === 'error' && (
        <div className="absolute inset-0 flex flex-col items-center justify-center gap-4 bg-black/90 z-20">
          <p className="text-white text-base font-semibold">Playback Error</p>
          <p className="text-white/40 text-sm">{errMsg}</p>
          <div className="flex gap-3 mt-2">
            <button onClick={onBack} className="px-6 py-2.5 bg-white/10 border border-white/10 text-white rounded-full text-sm hover:bg-white/15">Back</button>
            <button onClick={initPlayer} className="px-6 py-2.5 bg-luna-accent text-white font-semibold rounded-full text-sm hover:opacity-90">Retry</button>
          </div>
        </div>
      )}

      {/* Ended */}
      {state === 'ended' && (
        <div className="absolute inset-0 flex flex-col items-center justify-center gap-4 bg-black/80 z-20">
          <p className="text-white text-base font-semibold">Finished</p>
          <button onClick={onBack} className="px-6 py-2.5 bg-luna-accent text-white font-semibold rounded-full text-sm hover:opacity-90">Back</button>
        </div>
      )}

      {/* Controls */}
      <div className={`absolute inset-0 z-10 transition-opacity duration-300 ${showControls ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}>
        {/* Gradient overlay */}
        <div className="absolute inset-0 bg-gradient-to-b from-black/60 via-transparent to-black/75 pointer-events-none" />

        {/* TOP BAR */}
        <div className="absolute top-0 left-0 right-0 flex items-center justify-between px-5 pt-5">
          {/* Back — glass pill */}
          <button
            onClick={onBack}
            className="flex items-center gap-1.5 text-sm font-semibold text-white/90 px-4 py-2 rounded-full transition-opacity hover:opacity-80"
            style={{
              background: 'rgba(255,255,255,0.08)',
              backdropFilter: 'blur(32px) saturate(180%)',
              WebkitBackdropFilter: 'blur(32px) saturate(180%)',
              border: '1px solid rgba(255,255,255,0.12)',
              boxShadow: '0 2px 16px rgba(0,0,0,0.35), inset 0 1px 0 rgba(255,255,255,0.15)',
            }}
            aria-label="Back"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" className="w-4 h-4 opacity-80">
              <path d="M15 18l-6-6 6-6" />
            </svg>
            Back
          </button>

          {/* Title — glass pill */}
          <p
            className="text-sm font-semibold text-white/85 px-4 py-2 rounded-full truncate max-w-[260px]"
            style={{
              background: 'rgba(255,255,255,0.08)',
              backdropFilter: 'blur(32px) saturate(180%)',
              WebkitBackdropFilter: 'blur(32px) saturate(180%)',
              border: '1px solid rgba(255,255,255,0.12)',
              boxShadow: '0 2px 16px rgba(0,0,0,0.35), inset 0 1px 0 rgba(255,255,255,0.15)',
            }}
          >
            {title}
          </p>

          <div className="flex items-center gap-2">
            {/* Sources toggle — glass circle */}
            <button
              onClick={() => { closePops(); setShowSources(s => !s); }}
              className="w-9 h-9 rounded-full flex items-center justify-center text-white/75 transition-opacity hover:opacity-80"
              style={{
                background: 'rgba(255,255,255,0.08)',
                backdropFilter: 'blur(32px) saturate(180%)',
                WebkitBackdropFilter: 'blur(32px) saturate(180%)',
                border: '1px solid rgba(255,255,255,0.12)',
                boxShadow: '0 2px 16px rgba(0,0,0,0.35), inset 0 1px 0 rgba(255,255,255,0.15)',
              }}
              aria-label="Sources"
            >
              <svg viewBox="0 0 24 24" fill="currentColor" className="w-4 h-4">
                <circle cx="12" cy="5" r="1.8" /><circle cx="12" cy="12" r="1.8" /><circle cx="12" cy="19" r="1.8" />
              </svg>
            </button>
            {/* AirPlay — glass circle */}
            <button
              className="w-9 h-9 rounded-full flex items-center justify-center text-white/75 transition-opacity hover:opacity-80"
              style={{
                background: 'rgba(255,255,255,0.08)',
                backdropFilter: 'blur(32px) saturate(180%)',
                WebkitBackdropFilter: 'blur(32px) saturate(180%)',
                border: '1px solid rgba(255,255,255,0.12)',
                boxShadow: '0 2px 16px rgba(0,0,0,0.35), inset 0 1px 0 rgba(255,255,255,0.15)',
              }}
              aria-label="AirPlay"
            >
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" className="w-4 h-4">
                <path d="M5 17H3a2 2 0 01-2-2V5a2 2 0 012-2h18a2 2 0 012 2v10a2 2 0 01-2 2h-2M12 15l-4 5h8l-4-5z" />
              </svg>
            </button>
          </div>
        </div>

        {/* CENTER: Skip + Play */}
        <div className="absolute inset-0 flex items-center justify-center gap-11 pointer-events-none">
          <button
            onClick={() => skip(-15)}
            className="pointer-events-auto flex flex-col items-center gap-1.5 text-white/80 transition-opacity hover:opacity-80"
            aria-label="Skip back 15s"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" className="w-9 h-9">
              <path d="M12 5C7.03 5 3 9.03 3 14s4.03 9 9 9 9-4.03 9-9" />
              <path d="M17 3l3 3-3 3" />
              <text x="50%" y="60%" textAnchor="middle" dominantBaseline="middle" fontSize="6.5" fontWeight="700" stroke="none" fill="currentColor">15</text>
            </svg>
            <span className="text-[10px] font-semibold tracking-wider opacity-60">BACK</span>
          </button>

          <button
            onClick={togglePlay}
            className="pointer-events-auto w-16 h-16 rounded-full flex items-center justify-center active:scale-95 transition-transform"
            style={{
              background: 'rgba(255,255,255,0.14)',
              backdropFilter: 'blur(40px) saturate(200%)',
              WebkitBackdropFilter: 'blur(40px) saturate(200%)',
              border: '1.5px solid rgba(255,255,255,0.22)',
              boxShadow: '0 4px 24px rgba(0,0,0,0.4), inset 0 1.5px 0 rgba(255,255,255,0.3), inset 0 -1.5px 0 rgba(0,0,0,0.15)',
            }}
            aria-label={state === 'playing' ? 'Pause' : 'Play'}
          >
            {state === 'playing' ? (
              <svg viewBox="0 0 24 24" fill="white" className="w-6 h-6">
                <path d="M6 5h3v14H6V5zm9 0h3v14h-3V5z" />
              </svg>
            ) : (
              <svg viewBox="0 0 24 24" fill="white" className="w-6 h-6 ml-1">
                <polygon points="6,4 20,12 6,20" />
              </svg>
            )}
          </button>

          <button
            onClick={() => skip(15)}
            className="pointer-events-auto flex flex-col items-center gap-1.5 text-white/80 transition-opacity hover:opacity-80"
            aria-label="Skip forward 15s"
          >
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" strokeLinecap="round" strokeLinejoin="round" className="w-9 h-9">
              <path d="M12 5c4.97 0 9 4.03 9 9s-4.03 9-9 9-9-4.03-9-9" />
              <path d="M7 3L4 6l3 3" />
              <text x="50%" y="60%" textAnchor="middle" dominantBaseline="middle" fontSize="6.5" fontWeight="700" stroke="none" fill="currentColor">15</text>
            </svg>
            <span className="text-[10px] font-semibold tracking-wider opacity-60">FWD</span>
          </button>
        </div>

        {/* BOTTOM — floating dark glass shelf */}
        <div
          className="absolute bottom-0 left-0 right-0 mx-4 mb-5 rounded-2xl px-5 py-4 space-y-3"
          style={{
            background: 'rgba(0,0,0,0.45)',
            backdropFilter: 'blur(40px) saturate(150%)',
            WebkitBackdropFilter: 'blur(40px) saturate(150%)',
            border: '1px solid rgba(255,255,255,0.08)',
            boxShadow: '0 8px 32px rgba(0,0,0,0.5), inset 0 1px 0 rgba(255,255,255,0.08)',
          }}
        >
          {/* Seek bar */}
          <div className="flex items-center gap-3">
            <span className="text-xs text-white/50 w-10 text-right tabular-nums shrink-0">{fmt(pos)}</span>
            <div
              ref={seekBarRef}
              className="relative flex-1 h-5 flex items-center cursor-pointer group"
              onMouseDown={e => { setIsDragging(true); seekFromX(e.clientX); e.preventDefault(); }}
            >
              <div className="w-full h-[3px] group-hover:h-[5px] bg-white/15 rounded-full relative transition-all duration-150">
                <div className="absolute left-0 top-0 h-full bg-white/20 rounded-full" style={{ width: `${bufPct}%` }} />
                <div className="absolute left-0 top-0 h-full bg-white rounded-full" style={{ width: `${pct}%` }} />
              </div>
              <div
                className="absolute top-1/2 -translate-y-1/2 w-3.5 h-3.5 bg-white rounded-full -translate-x-1/2 shadow-md pointer-events-none opacity-0 group-hover:opacity-100 transition-opacity"
                style={{ left: `${pct}%` }}
              />
            </div>
            <span className="text-xs text-white/50 w-10 tabular-nums shrink-0">
              {dur > 0 ? `-${fmt(dur - pos)}` : '0:00'}
            </span>
          </div>

          {/* Controls row */}
          <div className="flex items-center justify-between">
            {/* Left: Volume */}
            <div className="flex items-center gap-1 group/vol">
              <button
                onClick={() => setMuted(m => !m)}
                className="w-9 h-9 rounded-full flex items-center justify-center hover:bg-white/10 transition-colors text-white/65"
                aria-label={muted ? 'Unmute' : 'Mute'}
              >
                {muted || volume === 0 ? (
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" className="w-5 h-5">
                    <path d="M5 9H2a1 1 0 00-1 1v4a1 1 0 001 1h3l4 4V5L5 9z"/><path d="M23 9l-6 6M17 9l6 6" strokeLinecap="round"/>
                  </svg>
                ) : (
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" className="w-5 h-5">
                    <path d="M5 9H2a1 1 0 00-1 1v4a1 1 0 001 1h3l4 4V5L5 9z"/>
                    <path d="M15.5 8.5a5 5 0 010 7M19 5a9 9 0 010 14" strokeLinecap="round"/>
                  </svg>
                )}
              </button>
              <div className="w-0 overflow-hidden group-hover/vol:w-20 transition-all duration-200 flex items-center">
                <input
                  type="range" min={0} max={1} step={0.05}
                  value={muted ? 0 : volume}
                  onChange={e => { setVolume(+e.target.value); setMuted(false); }}
                  className="w-16 h-[3px] accent-white bg-white/20 rounded-full cursor-pointer"
                />
              </div>
            </div>

            {/* Right: Subs, Quality, Fullscreen */}
            <div className="flex items-center gap-1">
              {/* Subtitles & Audio */}
              <div className="relative">
                <button
                  onClick={() => { setShowQualPop(false); setShowSubPop(s => !s); }}
                  className={`w-9 h-9 rounded-full flex items-center justify-center hover:bg-white/10 transition-colors ${activeSub >= 0 ? 'text-white' : 'text-white/65'}`}
                  aria-label="Subtitles and audio"
                >
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" className="w-5 h-5">
                    <rect x="2" y="5" width="20" height="14" rx="2"/>
                    <path d="M7 10h4M7 14h10" strokeLinecap="round"/>
                  </svg>
                </button>

                {showSubPop && (
                  <div className="absolute bottom-full right-0 mb-2 rounded-2xl p-1.5 min-w-[240px] z-30" style={{ background:'rgba(18,18,22,0.7)', backdropFilter:'blur(48px) saturate(200%)', WebkitBackdropFilter:'blur(48px) saturate(200%)', border:'1px solid rgba(255,255,255,0.1)', boxShadow:'0 16px 48px rgba(0,0,0,0.7), inset 0 1px 0 rgba(255,255,255,0.1)' }}>
                    {audioTracks.length > 0 && (
                      <>
                        <p className="px-3 pt-2 pb-1 text-[10px] font-bold text-white/30 uppercase tracking-widest">Audio</p>
                        {audioTracks.map(t => (
                          <button key={t.id} onClick={() => switchAudio(t.id)}
                            className={`w-full text-left px-3 py-2 rounded-xl text-sm flex items-center justify-between gap-2 transition-colors ${t.id === activeAudio ? 'text-white' : 'text-white/60 hover:bg-white/5'}`}>
                            <span>{t.name}{t.lang !== '?' ? ` (${t.lang})` : ''}</span>
                            {t.id === activeAudio && <span className="w-1.5 h-1.5 rounded-full bg-luna-accent shrink-0" />}
                          </button>
                        ))}
                        <div className="mx-2 my-1 h-px bg-white/6" />
                      </>
                    )}
                    <p className="px-3 pt-1 pb-1 text-[10px] font-bold text-white/30 uppercase tracking-widest">Subtitles</p>
                    <button onClick={() => switchSub(-1)}
                      className={`w-full text-left px-3 py-2 rounded-xl text-sm flex items-center justify-between gap-2 transition-colors ${activeSub < 0 ? 'text-white' : 'text-white/60 hover:bg-white/5'}`}>
                      <span>Off</span>
                      {activeSub < 0 && <span className="w-1.5 h-1.5 rounded-full bg-luna-accent shrink-0" />}
                    </button>
                    {subTracks.map(t => (
                      <button key={t.id} onClick={() => switchSub(t.id)}
                        className={`w-full text-left px-3 py-2 rounded-xl text-sm flex items-center justify-between gap-2 transition-colors ${t.id === activeSub ? 'text-white' : 'text-white/60 hover:bg-white/5'}`}>
                        <span>{t.name}{t.lang !== '?' ? ` (${t.lang})` : ''}</span>
                        {t.id === activeSub && <span className="w-1.5 h-1.5 rounded-full bg-luna-accent shrink-0" />}
                      </button>
                    ))}
                    {subTracks.length === 0 && (
                      <p className="px-3 py-2 text-xs text-white/25">No subtitle tracks detected</p>
                    )}
                  </div>
                )}
              </div>

              {/* Quality */}
              {qualityLevels.length > 0 && (
                <div className="relative">
                  <button
                    onClick={() => { setShowSubPop(false); setShowQualPop(q => !q); }}
                    className="w-9 h-9 rounded-full flex items-center justify-center hover:bg-white/10 transition-colors text-white/65"
                    aria-label="Quality"
                  >
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" className="w-5 h-5">
                      <path d="M12 2a10 10 0 100 20A10 10 0 0012 2z"/><path d="M12 6v6l4 2" strokeLinecap="round"/>
                    </svg>
                  </button>
                  {showQualPop && (
                    <div className="absolute bottom-full right-0 mb-2 rounded-2xl p-1.5 min-w-[160px] z-30" style={{ background:'rgba(18,18,22,0.7)', backdropFilter:'blur(48px) saturate(200%)', WebkitBackdropFilter:'blur(48px) saturate(200%)', border:'1px solid rgba(255,255,255,0.1)', boxShadow:'0 16px 48px rgba(0,0,0,0.7), inset 0 1px 0 rgba(255,255,255,0.1)' }}>
                      <p className="px-3 pt-1 pb-1 text-[10px] font-bold text-white/30 uppercase tracking-widest">Quality</p>
                      <button onClick={() => switchQuality(-1)}
                        className={`w-full text-left px-3 py-2 rounded-xl text-sm flex items-center justify-between gap-2 transition-colors ${activeQuality === -1 ? 'text-white' : 'text-white/60 hover:bg-white/5'}`}>
                        <span>Auto</span>
                        {activeQuality === -1 && <span className="w-1.5 h-1.5 rounded-full bg-luna-accent shrink-0" />}
                      </button>
                      {qualityLevels.map((q, i) => (
                        <button key={i} onClick={() => switchQuality(i)}
                          className={`w-full text-left px-3 py-2 rounded-xl text-sm flex items-center justify-between gap-2 transition-colors ${activeQuality === i ? 'text-white' : 'text-white/60 hover:bg-white/5'}`}>
                          <span>{q.height ? `${q.height}p` : `${Math.round(q.bitrate / 1000)}k`}</span>
                          {activeQuality === i && <span className="w-1.5 h-1.5 rounded-full bg-luna-accent shrink-0" />}
                        </button>
                      ))}
                    </div>
                  )}
                </div>
              )}

              {/* Speed */}
              <div className="relative group/speed">
                <button className="w-9 h-9 rounded-full flex items-center justify-center hover:bg-white/10 transition-colors text-white/65" aria-label="Playback speed">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" className="w-5 h-5">
                    <circle cx="12" cy="12" r="10"/><path d="M10 8l6 4-6 4V8z" fill="currentColor" stroke="none"/>
                  </svg>
                </button>
                <div className="absolute bottom-full right-0 mb-2 rounded-2xl p-1.5 min-w-[140px] z-30 hidden group-hover/speed:block" style={{ background:'rgba(18,18,22,0.7)', backdropFilter:'blur(48px) saturate(200%)', WebkitBackdropFilter:'blur(48px) saturate(200%)', border:'1px solid rgba(255,255,255,0.1)', boxShadow:'0 16px 48px rgba(0,0,0,0.7), inset 0 1px 0 rgba(255,255,255,0.1)' }}>
                  {[0.5, 0.75, 1, 1.25, 1.5, 2].map(s => (
                    <button key={s}
                      onClick={() => { const v = videoRef.current; if (v) v.playbackRate = s; }}
                      className="w-full text-left px-3 py-2 rounded-xl text-sm text-white/60 hover:bg-white/5 hover:text-white transition-colors">
                      {s === 1 ? 'Normal' : `${s}×`}
                    </button>
                  ))}
                </div>
              </div>

              {/* Fullscreen */}
              <button
                onClick={toggleFS}
                className="w-9 h-9 rounded-full flex items-center justify-center hover:bg-white/10 transition-colors text-white/65"
                aria-label="Fullscreen"
              >
                {isFullscreen ? (
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" className="w-5 h-5">
                    <path d="M8 3v3a2 2 0 01-2 2H3M21 8h-3a2 2 0 01-2-2V3M3 16h3a2 2 0 012 2v3M16 21v-3a2 2 0 012-2h3" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                ) : (
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7" className="w-5 h-5">
                    <path d="M8 3H5a2 2 0 00-2 2v3M16 3h3a2 2 0 012 2v3M8 21H5a2 2 0 01-2-2v-3M16 21h3a2 2 0 002-2v-3" strokeLinecap="round" strokeLinejoin="round"/>
                  </svg>
                )}
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Tap to play when controls hidden */}
      {!showControls && state === 'paused' && (
        <button onClick={togglePlay} className="absolute inset-0 z-10 flex items-center justify-center">
          <div className="w-16 h-16 rounded-full bg-black/40 backdrop-blur-sm border border-white/15 flex items-center justify-center">
            <svg viewBox="0 0 24 24" fill="white" className="w-7 h-7 ml-1"><polygon points="6,4 20,12 6,20" /></svg>
          </div>
        </button>
      )}

      {/* Sources panel */}
      {showSources && (
        <div className="absolute inset-0 z-40 flex justify-end">
          <div className="absolute inset-0 bg-black/60" onClick={() => setShowSources(false)} />
          <div className="relative w-80 max-w-[85vw] h-full bg-neutral-950 border-l border-white/8 overflow-y-auto">
            <div className="p-4 border-b border-white/8 flex items-center justify-between">
              <h3 className="text-sm font-semibold text-white">Sources</h3>
              <button onClick={() => setShowSources(false)} className="w-7 h-7 rounded-full hover:bg-white/8 flex items-center justify-center">
                <svg viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2" className="w-4 h-4 opacity-50"><path d="M6 18L18 6M6 6l12 12" strokeLinecap="round"/></svg>
              </button>
            </div>
            {(() => {
              const grp: Record<string, StreamItem[]> = {};
              for (const s of streams) { const k = s.addonName || 'Unknown'; (grp[k] ??= []).push(s); }
              return Object.entries(grp).map(([name, items]) => (
                <div key={name} className="border-b border-white/4 last:border-b-0">
                  <p className="px-4 pt-3 pb-1 text-[10px] font-bold text-white/25 uppercase tracking-widest">{name}</p>
                  {items.map(s => (
                    <button key={s.url || Math.random().toString()} onClick={() => { setShowSources(false); onSwitchStream(s); }}
                      className={`w-full text-left px-4 py-3 hover:bg-white/4 flex items-center justify-between ${s.url === currentStream.url ? 'bg-luna-accent/10 border-l-2 border-luna-accent' : ''}`}>
                      <p className="text-sm text-white truncate">{s.title || s.name || s.description || 'Unknown'}</p>
                      {s.url === currentStream.url && <div className="w-1.5 h-1.5 rounded-full bg-luna-accent shrink-0 ml-2" />}
                    </button>
                  ))}
                </div>
              ));
            })()}
          </div>
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 2: Type-check**

```bash
cd LunaWeb && npx tsc --noEmit 2>&1 | head -30
```

Expected: no errors.

- [ ] **Step 3: Test player manually**

Start dev server and navigate to a watch page. Test:
- ✓ Play/pause works (center button + spacebar)
- ✓ ±15s skip works (buttons + arrow keys)
- ✓ Volume slider expands on hover
- ✓ Subtitles panel opens and "Off" option works
- ✓ If stream has HLS audio tracks, they appear in the panel
- ✓ Quality panel only appears when HLS levels are detected
- ✓ Fullscreen toggle works (F key + button)
- ✓ Controls auto-hide after 3.5s

- [ ] **Step 4: Commit**

```bash
git add LunaWeb/src/components/Player.tsx
git commit -m "feat(web): Apple-native player redesign with HLS audio/subtitle fixes"
```

---

## Self-Review Checklist

- [x] `pickFeaturedItems` — implemented in Task 1, wired in Task 5 ✓
- [x] Hero uses backdrop image — `HomeHero` uses `meta.background || banner || poster` ✓
- [x] Hero auto-rotates every 6s — `setInterval` in `home/page.tsx` ✓
- [x] Hero pauses on hover — `heroPausedRef` ✓
- [x] CW shows real artwork — `poster` fetched in `loadData` ✓
- [x] CW clicking navigates to detail page — `href=/browse/{type}/{id}` ✓
- [x] 4 main rows always shown as horizontal scroll — `isMainRow` flag ✓
- [x] Folder rows shown as 4-col grids — `FolderGrid` component ✓
- [x] No collapse/expand buttons — never existed in web, not added ✓
- [x] Episode horizontal scroll — Task 6 ✓
- [x] Genre chips — Task 6 ✓
- [x] Network/production section — Task 6, uses `detail.links` ✓
- [x] HLS audio fix — `AUDIO_TRACK_SWITCHED` event + `hls.recoverMediaError()` ✓
- [x] HLS subtitle fix — `renderTextTracksNatively: false` + TextTrack cue overlay ✓
- [x] Fake chapters removed — not in new `Player.tsx` ✓
- [x] Quality from real HLS levels — `hls.levels` in `MANIFEST_PARSED` ✓
