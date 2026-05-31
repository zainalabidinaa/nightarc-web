'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '../AuthProvider';
import { useRouter } from 'next/navigation';
import { Sidebar } from '@/components/Sidebar';
import { CollectionRow } from '@/components/CollectionRow';
import { Collection } from '@/lib/types';
import { getCollections, getWatchProgress } from '@/lib/services/api';
import Link from 'next/link';

export default function HomePage() {
  const { currentProfile, user, isLoading } = useAuth();
  const router = useRouter();
  const [collections, setCollections] = useState<Collection[]>([]);
  const [continueWatching, setContinueWatching] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (isLoading) return;
    if (!user) { router.replace('/auth'); return; }
    if (!currentProfile) { router.replace('/profiles'); return; }
    loadData();
  }, [currentProfile, isLoading]);

  async function loadData() {
    setLoading(true);
    try {
      const [cols, progress] = await Promise.all([
        getCollections(),
        getWatchProgress(currentProfile!.id)
      ]);
      setCollections(cols);
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
                      <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-white/10">
                        <div className="h-full bg-luna-accent transition-all" style={{ width: `${pct}%` }} />
                      </div>
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

        {/* Collection rows */}
        {collections.map(collection => (
          <CollectionRow key={collection.id} collection={collection} />
        ))}

        {/* Empty state */}
        {collections.length === 0 && (
          <div className="flex flex-col items-center justify-center py-32 text-luna-muted">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="w-8 h-8 mb-4 opacity-40">
              <path d="M19.5 21a3 3 0 003-3v-4.5a3 3 0 00-3-3h-15a3 3 0 00-3 3V18a3 3 0 003 3h15zM1.5 10.146V6a3 3 0 013-3h5.379a2.25 2.25 0 011.59.659l2.122 2.121c.14.141.331.22.53.22H19.5a3 3 0 013 3v1.146A4.483 4.483 0 0019.5 9h-15a4.483 4.483 0 00-3 1.146z" />
            </svg>
            <p className="text-sm">No collections yet.</p>
            <p className="text-xs mt-1 text-luna-muted/60">Ask your admin to set up collections.</p>
          </div>
        )}
      </div>
    </Sidebar>
  );
}
