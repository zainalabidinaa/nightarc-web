'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '../AuthProvider';
import { useRouter } from 'next/navigation';
import { Sidebar } from '@/components/Sidebar';
import { MetaPreview } from '@/lib/types';
import { fetchAllCatalogs } from '@/lib/stremio';
import { getWatchProgress } from '@/lib/services/api';
import Link from 'next/link';

interface CatalogRow {
  id: string;
  title: string;
  items: MetaPreview[];
}

const FilmIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="w-8 h-8 text-luna-muted">
    <path fillRule="evenodd" d="M1.5 5.625c0-1.036.84-1.875 1.875-1.875h17.25c1.035 0 1.875.84 1.875 1.875v12.75c0 1.035-.84 1.875-1.875 1.875H3.375A1.875 1.875 0 011.5 18.375V5.625zm1.5 0v1.5c0 .207.168.375.375.375h1.5a.375.375 0 00.375-.375v-1.5a.375.375 0 00-.375-.375h-1.5A.375.375 0 003 5.625zm16.125-.375a.375.375 0 00-.375.375v1.5c0 .207.168.375.375.375h1.5A.375.375 0 0021 7.125v-1.5a.375.375 0 00-.375-.375h-1.5zM21 9.375A.375.375 0 0020.625 9h-1.5a.375.375 0 00-.375.375v1.5c0 .207.168.375.375.375h1.5A.375.375 0 0021 10.875v-1.5zm0 3.75a.375.375 0 00-.375-.375h-1.5a.375.375 0 00-.375.375v1.5c0 .207.168.375.375.375h1.5A.375.375 0 0021 14.625v-1.5zm0 3.75a.375.375 0 00-.375-.375h-1.5a.375.375 0 00-.375.375v1.5c0 .207.168.375.375.375h1.5A.375.375 0 0021 18.375v-1.5zM3.375 9a.375.375 0 00-.375.375v1.5c0 .207.168.375.375.375h1.5A.375.375 0 004.875 10.875v-1.5A.375.375 0 004.5 9H3.375zm0 3.75a.375.375 0 00-.375.375v1.5c0 .207.168.375.375.375h1.5a.375.375 0 00.375-.375v-1.5a.375.375 0 00-.375-.375H3.375zm0 3.75a.375.375 0 00-.375.375v1.5c0 .207.168.375.375.375h1.5a.375.375 0 00.375-.375v-1.5a.375.375 0 00-.375-.375H3.375zM9 5.625a.375.375 0 00-.375.375v1.5c0 .207.168.375.375.375h1.5A.375.375 0 0010.875 7.5v-1.5A.375.375 0 0010.5 5.625H9zm0 3.75a.375.375 0 00-.375.375v1.5c0 .207.168.375.375.375h1.5A.375.375 0 0010.875 10.875v-1.5A.375.375 0 0010.5 9.375H9zm0 3.75a.375.375 0 00-.375.375v1.5c0 .207.168.375.375.375h1.5a.375.375 0 00.375-.375v-1.5a.375.375 0 00-.375-.375H9zm0 3.75a.375.375 0 00-.375.375v1.5c0 .207.168.375.375.375h1.5a.375.375 0 00.375-.375v-1.5a.375.375 0 00-.375-.375H9zm3.75-11.25a.375.375 0 00-.375.375v1.5c0 .207.168.375.375.375h1.5A.375.375 0 0014.625 7.5v-1.5a.375.375 0 00-.375-.375h-1.5zm0 3.75a.375.375 0 00-.375.375v1.5c0 .207.168.375.375.375h1.5a.375.375 0 00.375-.375v-1.5a.375.375 0 00-.375-.375h-1.5zm0 3.75a.375.375 0 00-.375.375v1.5c0 .207.168.375.375.375h1.5a.375.375 0 00.375-.375v-1.5a.375.375 0 00-.375-.375h-1.5zm0 3.75a.375.375 0 00-.375.375v1.5c0 .207.168.375.375.375h1.5a.375.375 0 00.375-.375v-1.5a.375.375 0 00-.375-.375h-1.5z" clipRule="evenodd" />
  </svg>
);

const TvIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="w-8 h-8 text-luna-muted">
    <path d="M19.5 6h-15v9h15V6z" />
    <path fillRule="evenodd" d="M3.375 3C2.339 3 1.5 3.84 1.5 4.875v11.25C1.5 17.16 2.34 18 3.375 18H9.75v1.5H6A.75.75 0 006 21h12a.75.75 0 000-1.5h-3.75V18h6.375c1.035 0 1.875-.84 1.875-1.875V4.875C22.5 3.839 21.66 3 20.625 3H3.375zm0 13.5h17.25a.375.375 0 00.375-.375V4.875a.375.375 0 00-.375-.375H3.375A.375.375 0 003 4.875v11.25c0 .207.168.375.375.375z" clipRule="evenodd" />
  </svg>
);

export default function HomePage() {
  const { currentProfile, addons, user } = useAuth();
  const router = useRouter();
  const [rows, setRows] = useState<CatalogRow[]>([]);
  const [continueWatching, setContinueWatching] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) { router.replace('/auth'); return; }
    if (!currentProfile) { router.replace('/profiles'); return; }
    loadData();
  }, [currentProfile, addons]);

  async function loadData() {
    setLoading(true);
    try {
      const [catalogRows, progress] = await Promise.all([
        fetchAllCatalogs(addons),
        getWatchProgress(currentProfile!.id)
      ]);
      setRows(catalogRows);
      setContinueWatching(
        progress
          .filter((p: any) => !p.completed && p.position_seconds > 0)
          .sort((a: any, b: any) => new Date(b.updated_at).getTime() - new Date(a.updated_at).getTime())
      );
    } catch {}
    setLoading(false);
  }

  if (loading) {
    return (
      <Sidebar>
        <div className="flex items-center justify-center min-h-screen">
          <div className="animate-spin rounded-full h-6 w-6 border-2 border-luna-accent border-t-transparent" />
        </div>
      </Sidebar>
    );
  }

  return (
    <Sidebar>
      <div className="px-6 pt-24 pb-12">

        {/* Continue Watching */}
        {continueWatching.length > 0 && (
          <section className="mb-10">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-base font-semibold text-white">Continue Watching</h2>
            </div>
            <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-hide">
              {continueWatching.slice(0, 10).map((item: any) => {
                const pct = item.duration_seconds > 0
                  ? (item.position_seconds / item.duration_seconds) * 100
                  : 0;
                return (
                  <Link
                    key={item.media_id}
                    href={`/browse/${item.media_type}/${item.media_id}`}
                    className="flex-shrink-0 w-48 group cursor-pointer"
                  >
                    <div className="relative h-28 bg-luna-elevated rounded-xl overflow-hidden mb-2">
                      {/* progress bar */}
                      <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-white/10">
                        <div className="h-full bg-luna-accent transition-all" style={{ width: `${pct}%` }} />
                      </div>
                      {/* overlay on hover */}
                      <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity duration-200 flex items-center justify-center">
                        <div className="w-10 h-10 rounded-full bg-white/20 backdrop-blur-sm flex items-center justify-center">
                          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="w-5 h-5 ml-0.5">
                            <path fillRule="evenodd" d="M4.5 5.653c0-1.426 1.529-2.33 2.779-1.643l11.54 6.348c1.295.712 1.295 2.573 0 3.285L7.28 19.991c-1.25.687-2.779-.217-2.779-1.643V5.653z" clipRule="evenodd" />
                          </svg>
                        </div>
                      </div>
                    </div>
                    <p className="text-xs text-luna-muted truncate">{item.media_id}</p>
                    <p className="text-xs text-luna-muted/60 mt-0.5">{Math.round(pct)}% watched</p>
                  </Link>
                );
              })}
            </div>
          </section>
        )}

        {/* Catalog rows */}
        {rows.map(row => (
          <section key={row.id} className="mb-10">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-base font-semibold text-white">{row.title}</h2>
              <span className="text-xs text-luna-muted hover:text-white transition-colors cursor-pointer">View all →</span>
            </div>
            <div className="flex gap-3 overflow-x-auto pb-2">
              {row.items.slice(0, 20).map(item => (
                <Link
                  key={item.id}
                  href={`/browse/${item.type}/${item.id}`}
                  className="media-card group w-36"
                >
                  <div className="media-card-inner h-52 mb-2">
                    {item.poster ? (
                      <img
                        src={item.poster}
                        alt={item.name}
                        className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
                        loading="lazy"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center">
                        {item.type === 'movie' ? <FilmIcon /> : <TvIcon />}
                      </div>
                    )}
                    <div className="media-card-overlay group-hover:opacity-100" />
                    {item.imdbRating && (
                      <span className="absolute top-2 right-2 bg-black/70 backdrop-blur-sm text-xs font-medium px-1.5 py-0.5 rounded text-white/90">
                        ★ {item.imdbRating}
                      </span>
                    )}
                    <p className="absolute bottom-2 left-2 right-2 text-xs font-medium text-white opacity-0 group-hover:opacity-100 transition-opacity duration-300 truncate">
                      {item.name}
                    </p>
                  </div>
                  <p className="text-xs text-luna-muted truncate group-hover:text-white transition-colors duration-200">{item.name}</p>
                </Link>
              ))}
            </div>
          </section>
        ))}

        {rows.length === 0 && !loading && (
          <div className="flex flex-col items-center justify-center py-32 text-luna-muted">
            <FilmIcon />
            <p className="mt-4 text-sm">No content found.</p>
            <p className="text-xs mt-1 text-luna-muted/60">Try installing more addons in Settings.</p>
          </div>
        )}
      </div>
    </Sidebar>
  );
}
