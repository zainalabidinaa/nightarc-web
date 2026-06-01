import { AddonManifest, MetaPreview, MetaDetail, StreamItem } from './types';

export async function fetchManifest(url: string): Promise<AddonManifest> {
  const res = await fetch(url);
  const json = await res.json();

  const baseURL = json.transportUrl || url.replace(/\/manifest\.json$/, '');

  return {
    id: json.id || new URL(url).hostname,
    name: json.name || 'Unknown',
    version: json.version || '0.0.0',
    description: json.description,
    types: json.types,
    resources: json.resources,
    catalogs: json.catalogs,
    transportUrl: baseURL.endsWith('/') ? baseURL.slice(0, -1) : baseURL,
    logo: json.logo
  };
}

export async function fetchCatalog(
  baseURL: string,
  type: string,
  id: string,
  extras?: Record<string, string>
): Promise<MetaPreview[]> {
  const params = new URLSearchParams(extras);
  const qs = params.toString();
  const url = `${baseURL}/catalog/${type}/${id}.json${qs ? '?' + qs : ''}`;

  const res = await fetch(url);
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
    popularity: m.popularity
  }));
}

export async function fetchMeta(
  baseURL: string,
  type: string,
  id: string
): Promise<MetaDetail | null> {
  try {
    const url = `${baseURL}/meta/${type}/${id}.json`;
    const res = await fetch(url);
    const json = await res.json();
    const m = json.meta;

    if (!m) return null;

    const videos = (m.videos || []).map((v: any) => ({
      id: v.id,
      title: v.name || v.title || `Episode ${v.episode}`,
      season: v.season,
      episode: v.episode || v.number,
      thumbnail: v.thumbnail,
      overview: v.overview || v.description,
    }));

    // Build seasons from videos if seasons not provided
    let seasons = m.seasons || null;
    if ((!seasons || seasons.length === 0) && videos.length > 0) {
      const seasonMap = new Map<number, typeof videos>();
      for (const v of videos) {
        if (!v.season) continue;
        if (!seasonMap.has(v.season)) seasonMap.set(v.season, []);
        seasonMap.get(v.season)!.push(v);
      }
      seasons = Array.from(seasonMap.entries())
        .sort(([a], [b]) => a - b)
        .map(([num, eps]) => ({
          id: `${id}:${num}`,
          number: num,
          name: `Season ${num}`,
          episodes: eps.sort((a: any, b: any) => (a.episode || 0) - (b.episode || 0)),
        }));
    }

    return {
      id: m.id || id,
      type: m.type || type,
      name: m.name || 'Unknown',
      poster: m.poster,
      background: m.background,
      logo: m.logo,
      description: m.description,
      releaseInfo: m.releaseInfo,
      status: m.status,
      imdbRating: m.imdbRating,
      runtime: m.runtime,
      genres: m.genres,
      director: m.director,
      cast: (m.cast || []).map((c: any) => ({ id: c.id, name: c.name, photo: c.photo })),
      trailers: m.trailers,
      links: m.links,
      videos,
      seasons,
    };
  } catch {
    return null;
  }
}

export async function fetchStreams(
  baseURL: string,
  type: string,
  id: string
): Promise<StreamItem[]> {
  try {
    const url = `${baseURL}/stream/${type}/${id}.json`;
    const res = await fetch(url);
    const json = await res.json();
    return json.streams || [];
  } catch {
    return [];
  }
}

function hasResource(addon: AddonManifest, name: string): boolean {
  return !!addon.resources?.some(r => (typeof r === 'string' ? r : r.name) === name);
}

export async function fetchStreamsFromAll(
  type: string,
  id: string,
  addons: AddonManifest[]
): Promise<StreamItem[]> {
  const results = await Promise.allSettled(
    addons
      .filter(a => a.transportUrl && hasResource(a, 'stream') && a.types?.includes(type))
      .map(async addon => {
        const streams = await fetchStreams(addon.transportUrl!, type, id);
        return streams.map(s => ({ ...s, addonName: addon.name, addonId: addon.id }));
      })
  );

  return results
    .filter((r): r is PromiseFulfilledResult<any[]> => r.status === 'fulfilled')
    .flatMap(r => r.value) as StreamItem[];
}

export async function fetchAllCatalogs(
  addons: AddonManifest[]
): Promise<{ id: string; title: string; items: MetaPreview[] }[]> {
  const results = await Promise.allSettled(
    addons
      .filter(a => a.transportUrl && a.catalogs && hasResource(a, 'catalog'))
      .flatMap(addon =>
        (addon.catalogs || []).map(async catalog => {
          const items = await fetchCatalog(addon.transportUrl!, catalog.type, catalog.id);
          return {
            id: `${addon.id}_${catalog.id}`,
            title: catalog.name || catalog.id,
            items
          };
        })
      )
  );

  return results
    .filter((r): r is PromiseFulfilledResult<any> => r.status === 'fulfilled')
    .map(r => r.value)
    .filter(row => row.items.length > 0);
}
