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
  latest_movies: 'https://raw.githubusercontent.com/zainalabidinaa/moonlit-covers/main/movie-night.png',
  latest_series: 'https://raw.githubusercontent.com/zainalabidinaa/moonlit-covers/main/your-next-binge.png',
  because_you_watched: 'https://raw.githubusercontent.com/zainalabidinaa/moonlit-covers/main/because-you-watched.png',
  list_for_you: 'https://raw.githubusercontent.com/zainalabidinaa/moonlit-covers/main/we-made-you-a-list.png',
  ai_recommendations: 'https://raw.githubusercontent.com/zainalabidinaa/moonlit-covers/main/worth-the-risk.png',
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

function getProxyBase(): string {
  if (process.env.VERCEL_URL) return `https://${process.env.VERCEL_URL}`;
  if (process.env.VERCEL_BRANCH_URL) return `https://${process.env.VERCEL_BRANCH_URL}`;
  return 'http://localhost:3000';
}

async function getWatchHistory(profileId: string): Promise<WatchEntry[]> {
  const { data } = await supabase
    .from('watch_progress')
    .select('profile_id,media_id,media_type,position_seconds,duration_seconds,completed')
    .eq('profile_id', profileId);
  return (data || []) as WatchEntry[];
}

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

async function fetchStremioCatalog(
  baseUrl: string,
  type: string,
  catalogId: string,
  extras?: Record<string, string>
): Promise<MetaPreview[]> {
  const params = new URLSearchParams({ url: baseUrl, type, id: catalogId });
  if (extras) params.set('extras', JSON.stringify(extras));
  const proxyBase = getProxyBase();
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

async function buildGenreProfileFromWatchHistory(
  entries: WatchEntry[],
  transportUrl: string
): Promise<GenreProfile[]> {
  const genreCounts = new Map<string, number>();
  const proxyBase = getProxyBase();

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

function scoreByGenreProfile(item: MetaPreview, genreProfile: GenreProfile[]): number {
  if (!item.genres || item.genres.length === 0) return 0.1;
  let score = 0;
  for (const gp of genreProfile) {
    if (item.genres.includes(gp.genre)) score += gp.weight;
  }
  return score;
}

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
  const proxyBase = getProxyBase();

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
