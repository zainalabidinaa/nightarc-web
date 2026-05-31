'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '../AuthProvider';
import { useRouter } from 'next/navigation';
import { Sidebar } from '@/components/Sidebar';
import { LibraryItem } from '@/lib/types';
import { getLibrary, toggleLibrary as toggleLib } from '@/lib/services/api';
import Link from 'next/link';

const FilmIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="w-8 h-8 text-luna-muted">
    <path fillRule="evenodd" d="M1.5 5.625c0-1.036.84-1.875 1.875-1.875h17.25c1.035 0 1.875.84 1.875 1.875v12.75c0 1.035-.84 1.875-1.875 1.875H3.375A1.875 1.875 0 011.5 18.375V5.625z" clipRule="evenodd" />
  </svg>
);

const XIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-3 h-3">
    <path d="M6.28 5.22a.75.75 0 00-1.06 1.06L8.94 10l-3.72 3.72a.75.75 0 101.06 1.06L10 11.06l3.72 3.72a.75.75 0 101.06-1.06L11.06 10l3.72-3.72a.75.75 0 00-1.06-1.06L10 8.94 6.28 5.22z" />
  </svg>
);

export default function LibraryPage() {
  const { currentProfile, user, isLoading } = useAuth();
  const router = useRouter();
  const [items, setItems] = useState<LibraryItem[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (isLoading) return;
    if (!user) { router.replace('/auth'); return; }
    if (!currentProfile) { router.replace('/profiles'); return; }
    loadLibrary();
  }, [currentProfile]);

  async function loadLibrary() {
    if (!currentProfile) return;
    setLoading(true);
    const lib = await getLibrary(currentProfile.id);
    setItems(lib);
    setLoading(false);
  }

  async function handleRemove(mediaId: string, mediaType: string, name?: string) {
    if (!currentProfile) return;
    await toggleLib(currentProfile.id, mediaId, mediaType, name);
    setItems(prev => prev.filter(i => i.media_id !== mediaId));
  }

  return (
    <Sidebar>
      <div className="px-6 pt-24 pb-12">
        <h1 className="text-xl font-semibold mb-6">Library</h1>

        {loading ? (
          <div className="flex items-center justify-center py-20">
            <div className="animate-spin rounded-full h-6 w-6 border-2 border-luna-accent border-t-transparent" />
          </div>
        ) : items.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-32 text-luna-muted">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="w-10 h-10 mb-4 opacity-40">
              <path d="M11.584 2.376a.75.75 0 01.832 0l9 6a.75.75 0 11-.832 1.248L12 3.901 3.416 9.624a.75.75 0 01-.832-1.248l9-6z" />
              <path fillRule="evenodd" d="M20.25 10.332v9.918H21a.75.75 0 010 1.5H3a.75.75 0 010-1.5h.75v-9.918a.75.75 0 01.634-.74A49.109 49.109 0 0112 9c2.59 0 5.134.202 7.616.592a.75.75 0 01.634.74zm-7.5 2.418a.75.75 0 00-1.5 0v6.75a.75.75 0 001.5 0v-6.75zm3-.75a.75.75 0 01.75.75v6.75a.75.75 0 01-1.5 0v-6.75a.75.75 0 01.75-.75zM9 12.75a.75.75 0 00-1.5 0v6.75a.75.75 0 001.5 0v-6.75z" clipRule="evenodd" />
            </svg>
            <p className="text-sm">Your library is empty</p>
            <p className="text-xs mt-1 text-luna-muted/60">Save movies and shows to watch later</p>
          </div>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3">
            {items.map(item => (
              <div key={item.id} className="media-card group">
                <Link href={`/browse/${item.media_type}/${item.media_id}`}>
                  <div className="media-card-inner aspect-[2/3] mb-2">
                    {item.poster ? (
                      <img
                        src={item.poster}
                        alt={item.name || item.media_id}
                        className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
                        loading="lazy"
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center">
                        <FilmIcon />
                      </div>
                    )}
                    <div className="media-card-overlay group-hover:opacity-100" />
                  </div>
                  <p className="text-xs text-luna-muted truncate group-hover:text-white transition-colors duration-200">{item.name || item.media_id}</p>
                </Link>
                <button
                  onClick={() => handleRemove(item.media_id, item.media_type, item.name)}
                  className="absolute top-2 right-2 w-6 h-6 bg-black/60 hover:bg-red-500/80 backdrop-blur-sm rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all duration-200 cursor-pointer"
                  aria-label="Remove from library"
                >
                  <XIcon />
                </button>
              </div>
            ))}
          </div>
        )}
      </div>
    </Sidebar>
  );
}
