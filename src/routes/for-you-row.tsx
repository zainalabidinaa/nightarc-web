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
