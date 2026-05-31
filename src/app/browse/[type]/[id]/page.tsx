'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '../../../AuthProvider';
import { useRouter } from 'next/navigation';
import { Sidebar } from '@/components/Sidebar';
import { MetaDetail, StreamItem } from '@/lib/types';
import { fetchMeta, fetchStreamsFromAll } from '@/lib/stremio';
import { isInLibrary, toggleLibrary } from '@/lib/services/api';

const PlayIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="w-5 h-5 ml-0.5">
    <path fillRule="evenodd" d="M4.5 5.653c0-1.426 1.529-2.33 2.779-1.643l11.54 6.348c1.295.712 1.295 2.573 0 3.285L7.28 19.991c-1.25.687-2.779-.217-2.779-1.643V5.653z" clipRule="evenodd" />
  </svg>
);

const BookmarkIcon = ({ filled }: { filled: boolean }) => (
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill={filled ? 'currentColor' : 'none'} stroke="currentColor" strokeWidth={1.5} className="w-5 h-5">
    <path strokeLinecap="round" strokeLinejoin="round" d="M17.593 3.322c1.1.128 1.907 1.077 1.907 2.185V21L12 17.25 4.5 21V5.507c0-1.108.806-2.057 1.907-2.185a48.507 48.507 0 0111.186 0z" />
  </svg>
);

export default function DetailPage({ params }: { params: { type: string; id: string } }) {
  const resolved = params;
  const { currentProfile, addons, user, isLoading } = useAuth();
  const router = useRouter();
  const [detail, setDetail] = useState<MetaDetail | null>(null);
  const [streams, setStreams] = useState<StreamItem[]>([]);
  const [inLibrary, setInLibrary] = useState(false);
  const [loading, setLoading] = useState(true);
  const [showStreams, setShowStreams] = useState(false);
  const [loadingStreams, setLoadingStreams] = useState(false);

  useEffect(() => {
    if (isLoading) return;
    if (!user) { router.replace('/auth'); return; }
    if (!currentProfile) { router.replace('/profiles'); return; }
    loadAll();
  }, [currentProfile, resolved.type, resolved.id]);

  async function loadAll() {
    setLoading(true);
    try {
      const metaAddons = addons.filter(a => a.resources?.some(r => r.name === 'meta'));
      let found: MetaDetail | null = null;
      for (const addon of metaAddons) {
        if (!addon.transportUrl) continue;
        found = await fetchMeta(addon.transportUrl, resolved.type, resolved.id);
        if (found) break;
      }
      setDetail(found || { id: resolved.id, type: resolved.type, name: decodeURIComponent(resolved.id) });
      if (currentProfile) {
        const lib = await isInLibrary(currentProfile.id, resolved.id);
        setInLibrary(lib);
      }
    } catch {}
    setLoading(false);
  }

  async function handleToggleLibrary() {
    if (!currentProfile) return;
    await toggleLibrary(currentProfile.id, resolved.id, resolved.type, detail?.name, detail?.poster);
    setInLibrary(!inLibrary);
  }

  async function loadStreams() {
    setShowStreams(true);
    setLoadingStreams(true);
    const allStreams = await fetchStreamsFromAll(resolved.type, resolved.id, addons);
    setStreams(allStreams);
    setLoadingStreams(false);
  }

  function handlePlay(stream: StreamItem) {
    if (!stream.url) return;
    const encodedUrl = encodeURIComponent(stream.url);
    let playerUrl = `/watch/${resolved.type}/${resolved.id}?url=${encodedUrl}`;
    if (stream.behaviorHints?.proxyHeaders?.request) {
      playerUrl += '&headers=' + encodeURIComponent(JSON.stringify(stream.behaviorHints.proxyHeaders.request));
    }
    router.push(playerUrl);
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

  const backdropSrc = (detail as any)?.background || detail?.poster;
  const title = detail?.name || decodeURIComponent(resolved.id);

  return (
    <Sidebar>
      {/* Hero section */}
      <div className="relative min-h-[60vh] flex items-end">
        {/* Backdrop */}
        {backdropSrc && (
          <div className="absolute inset-0 overflow-hidden">
            <img
              src={backdropSrc}
              alt=""
              className="w-full h-full object-cover scale-105 blur-sm"
              aria-hidden="true"
            />
          </div>
        )}
        {/* Gradient overlays */}
        <div className="absolute inset-0 bg-gradient-to-t from-luna-bg via-luna-bg/60 to-transparent" />
        <div className="absolute inset-0 bg-gradient-to-r from-luna-bg/80 via-transparent to-transparent" />

        {/* Hero content */}
        <div className="relative z-10 px-6 pt-28 pb-8 flex gap-6 items-end w-full max-w-5xl">
          {/* Poster thumbnail */}
          {detail?.poster && (
            <div className="hidden sm:block flex-shrink-0 w-36 h-52 rounded-xl overflow-hidden shadow-2xl ring-1 ring-white/10">
              <img src={detail.poster} alt={title} className="w-full h-full object-cover" />
            </div>
          )}

          {/* Info */}
          <div className="flex-1 min-w-0">
            <h1 className="text-3xl sm:text-4xl font-bold tracking-tight mb-2 text-white">{title}</h1>

            {/* Meta row */}
            <div className="flex items-center gap-3 text-sm text-luna-muted mb-3 flex-wrap">
              {(detail as any)?.year && <span>{(detail as any).year}</span>}
              {(detail as any)?.runtime && <span>{(detail as any).runtime}</span>}
              {(detail as any)?.imdbRating && (
                <span className="flex items-center gap-1">
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="#f59e0b" className="w-3.5 h-3.5">
                    <path fillRule="evenodd" d="M10.868 2.884c-.321-.772-1.415-.772-1.736 0l-1.83 4.401-4.753.381c-.833.067-1.171 1.107-.536 1.651l3.62 3.102-1.106 4.637c-.194.813.691 1.456 1.405 1.02L10 15.591l4.069 2.485c.713.436 1.598-.207 1.404-1.02l-1.106-4.637 3.62-3.102c.635-.544.297-1.584-.536-1.65l-4.752-.382-1.831-4.401z" clipRule="evenodd" />
                  </svg>
                  {(detail as any).imdbRating}
                </span>
              )}
            </div>

            {/* Genres */}
            {detail?.genres && detail.genres.length > 0 && (
              <div className="flex gap-2 flex-wrap mb-4">
                {detail.genres.map(g => (
                  <span key={g} className="px-3 py-1 bg-white/10 border border-white/10 rounded-full text-xs text-white/80">{g}</span>
                ))}
              </div>
            )}

            {/* Description */}
            {detail?.description && (
              <p className="text-sm text-luna-muted leading-relaxed mb-5 max-w-xl line-clamp-3">{detail.description}</p>
            )}

            {/* Action buttons */}
            <div className="flex gap-3 flex-wrap">
              <button
                onClick={loadStreams}
                className="flex items-center gap-2 px-6 py-2.5 bg-white text-black font-semibold rounded-full hover:bg-white/90 transition-all duration-200 cursor-pointer text-sm"
              >
                <PlayIcon /> Play
              </button>
              <button
                onClick={handleToggleLibrary}
                className={`flex items-center gap-2 px-6 py-2.5 rounded-full font-semibold transition-all duration-200 cursor-pointer text-sm border ${
                  inLibrary
                    ? 'bg-luna-accent/20 border-luna-accent/40 text-luna-accent'
                    : 'bg-white/10 border-white/10 text-white hover:bg-white/15'
                }`}
              >
                <BookmarkIcon filled={inLibrary} />
                {inLibrary ? 'Saved' : 'Watchlist'}
              </button>
            </div>
          </div>
        </div>
      </div>

      {/* Below-the-fold content */}
      <div className="px-6 pb-12 max-w-5xl space-y-8">

        {/* Cast */}
        {detail?.cast && detail.cast.length > 0 && (
          <section>
            <h3 className="text-sm font-semibold text-white mb-3">Cast</h3>
            <div className="flex gap-4 overflow-x-auto pb-2">
              {detail.cast.slice(0, 20).map(p => (
                <div key={p.name} className="flex-shrink-0 text-center w-14">
                  <div className="w-12 h-12 rounded-full bg-luna-elevated mx-auto mb-1.5 flex items-center justify-center text-sm font-semibold text-white ring-1 ring-white/10">
                    {p.name[0]}
                  </div>
                  <p className="text-xs text-luna-muted truncate">{p.name}</p>
                </div>
              ))}
            </div>
          </section>
        )}

        {/* Seasons */}
        {detail?.seasons && detail.seasons.length > 0 && (
          <section>
            <h3 className="text-sm font-semibold text-white mb-3">Seasons</h3>
            <div className="flex gap-3 overflow-x-auto pb-2">
              {detail.seasons.map(s => (
                <div key={s.id} className="flex-shrink-0 w-24 group cursor-pointer">
                  <div className="h-32 bg-luna-elevated rounded-xl overflow-hidden mb-1.5 ring-1 ring-white/5 group-hover:ring-luna-accent/30 transition-all">
                    {s.poster ? (
                      <img src={s.poster} alt={`Season ${s.number}`} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300" loading="lazy" />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center text-luna-muted text-2xl font-bold">
                        {s.number}
                      </div>
                    )}
                  </div>
                  <p className="text-xs text-center text-luna-muted">Season {s.number}</p>
                </div>
              ))}
            </div>
          </section>
        )}

        {/* Streams */}
        {showStreams && (
          <section>
            <h3 className="text-sm font-semibold text-white mb-3">
              Sources {!loadingStreams && streams.length > 0 && <span className="text-luna-muted font-normal">({streams.length})</span>}
            </h3>
            {loadingStreams ? (
              <div className="flex items-center gap-2 text-luna-muted text-sm">
                <div className="animate-spin rounded-full h-4 w-4 border-2 border-luna-accent border-t-transparent" />
                Fetching streams...
              </div>
            ) : streams.length === 0 ? (
              <p className="text-luna-muted text-sm">No sources found</p>
            ) : (
              <div className="space-y-2">
                {streams.slice(0, 30).map((s, i) => (
                  <button
                    key={s.url || i}
                    onClick={() => handlePlay(s)}
                    className="w-full text-left p-3 bg-white/5 hover:bg-white/10 border border-white/5 hover:border-white/10 rounded-xl transition-all duration-200 flex items-center justify-between cursor-pointer group"
                  >
                    <div className="min-w-0">
                      <p className="text-sm font-medium text-white truncate">{s.title || s.name || s.description || 'Unknown'}</p>
                      <p className="text-xs text-luna-muted">{s.addonName}</p>
                    </div>
                    <div className="flex-shrink-0 w-7 h-7 rounded-full bg-white/10 group-hover:bg-luna-accent/20 flex items-center justify-center ml-3 transition-colors">
                      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-3 h-3 ml-0.5 text-white/70 group-hover:text-luna-accent">
                        <path fillRule="evenodd" d="M2 10a8 8 0 1116 0 8 8 0 01-16 0zm6.39-2.908a.75.75 0 01.766.027l3.5 2.25a.75.75 0 010 1.262l-3.5 2.25A.75.75 0 018 12.25v-4.5a.75.75 0 01.39-.658z" clipRule="evenodd" />
                      </svg>
                    </div>
                  </button>
                ))}
              </div>
            )}
          </section>
        )}
      </div>
    </Sidebar>
  );
}
