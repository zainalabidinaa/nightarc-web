'use client';

import { useState, useEffect } from 'react';
import { useAuth } from '../AuthProvider';
import { useRouter } from 'next/navigation';
import { Sidebar } from '@/components/Sidebar';
import { MetaPreview } from '@/lib/types';
import { fetchCatalog } from '@/lib/stremio';
import Link from 'next/link';

const FilmIcon = () => (
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="w-6 h-6 text-luna-muted">
    <path fillRule="evenodd" d="M1.5 5.625c0-1.036.84-1.875 1.875-1.875h17.25c1.035 0 1.875.84 1.875 1.875v12.75c0 1.035-.84 1.875-1.875 1.875H3.375A1.875 1.875 0 011.5 18.375V5.625zM9 5.625a.375.375 0 00-.375.375v1.5c0 .207.168.375.375.375h1.5A.375.375 0 0010.875 7.5v-1.5A.375.375 0 0010.5 5.625H9zm0 3.75a.375.375 0 00-.375.375v1.5c0 .207.168.375.375.375h1.5A.375.375 0 0010.875 10.875v-1.5A.375.375 0 0010.5 9.375H9zm0 3.75a.375.375 0 00-.375.375v1.5c0 .207.168.375.375.375h1.5a.375.375 0 00.375-.375v-1.5a.375.375 0 00-.375-.375H9z" clipRule="evenodd" />
  </svg>
);

export default function SearchPage() {
  const { addons, user, currentProfile, isLoading } = useAuth();
  const router = useRouter();
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<MetaPreview[]>([]);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (isLoading) return;
    if (!user) { router.replace('/auth'); return; }
    if (!currentProfile) { router.replace('/profiles'); return; }
  }, [isLoading, user, currentProfile]);

  async function handleSearch(e: React.FormEvent) {
    e.preventDefault();
    if (!query.trim()) return;
    setLoading(true);
    const allResults: MetaPreview[] = [];
    for (const addon of addons) {
      if (!addon.transportUrl || !addon.resources?.some(r => (typeof r === 'string' ? r : r.name) === 'catalog')) continue;
      try {
        const items = await fetchCatalog(addon.transportUrl, 'movie', 'top', { search: query });
        allResults.push(...items);
      } catch {
        try {
          const items = await fetchCatalog(addon.transportUrl!, 'movie', 'search', { search: query });
          allResults.push(...items);
        } catch {}
      }
    }
    const unique = Array.from(new Map(allResults.map(item => [item.id, item])).values());
    unique.sort((a, b) => (b.popularity || 0) - (a.popularity || 0));
    setResults(unique);
    setLoading(false);
  }

  return (
    <Sidebar>
      <div className="px-6 pt-24 pb-12">
        {/* Search bar */}
        <form onSubmit={handleSearch} className="mb-8 max-w-lg">
          <div className="relative">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="absolute left-4 top-1/2 -translate-y-1/2 w-4 h-4 text-luna-muted pointer-events-none">
              <path fillRule="evenodd" d="M9 3.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM2 9a7 7 0 1112.452 4.391l3.328 3.329a.75.75 0 11-1.06 1.06l-3.329-3.328A7 7 0 012 9z" clipRule="evenodd" />
            </svg>
            <input
              type="text"
              value={query}
              onChange={e => setQuery(e.target.value)}
              placeholder="Search movies & shows..."
              className="w-full pl-11 pr-4 py-3 bg-white/5 border border-white/10 rounded-xl text-white placeholder-luna-muted focus:outline-none focus:border-purple-400/60 transition-all text-sm"
            />
          </div>
        </form>

        {loading && (
          <div className="flex items-center justify-center py-20">
            <div className="animate-spin rounded-full h-6 w-6 border-2 border-luna-accent border-t-transparent" />
          </div>
        )}

        {!loading && results.length > 0 && (
          <>
            <p className="text-xs text-luna-muted mb-4">{results.length} results for &ldquo;{query}&rdquo;</p>
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3">
              {results.map(item => (
                <Link key={item.id} href={`/browse/${item.type}/${item.id}`} className="media-card group">
                  <div className="media-card-inner aspect-[2/3] mb-2">
                    {item.poster ? (
                      <img
                        src={item.poster}
                        alt={item.name}
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
                  <p className="text-xs text-luna-muted truncate group-hover:text-white transition-colors duration-200">{item.name}</p>
                </Link>
              ))}
            </div>
          </>
        )}

        {!loading && query && results.length === 0 && (
          <p className="text-center py-20 text-luna-muted text-sm">No results for &ldquo;{query}&rdquo;</p>
        )}
      </div>
    </Sidebar>
  );
}
