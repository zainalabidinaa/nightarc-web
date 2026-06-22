import { MetaPreview } from '@/lib/types';
import { Link } from '@tanstack/react-router';
import { useState } from 'react';

function MediaCard({ item }: { item: MetaPreview }) {
  const [imgError, setImgError] = useState(false);

  return (
    <Link
      to="/browse/$type/$id"
      params={{ type: item.type, id: item.id }}
      className="flex-shrink-0 group cursor-pointer"
    >
      <div className="relative w-[154px] md:w-[168px] aspect-[2/3] overflow-hidden rounded-xl bg-moonlit-elevated mb-2 transition-shadow duration-300 group-hover:shadow-lg group-hover:shadow-black/30 group-hover:ring-1 group-hover:ring-white/10">
        {item.poster && !imgError ? (
          <img
            src={item.poster}
            alt={item.name}
            loading="lazy"
            className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-[1.025]"
            onError={() => setImgError(true)}
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center bg-moonlit-elevated">
            <span className="text-xs text-white/20 text-center px-3 line-clamp-3">{item.name}</span>
          </div>
        )}

        {item.imdbRating && (
          <span className="absolute top-1.5 right-1.5 bg-black/70 backdrop-blur-sm text-[10px] font-medium px-1.5 py-0.5 rounded text-white/90">
            ★ {item.imdbRating}
          </span>
        )}
      </div>

      <p className="text-[13px] font-medium text-white/80 truncate group-hover:text-white transition-colors leading-tight">
        {item.name}
      </p>
      {item.releaseInfo && (
        <p className="text-[11px] text-white/30 mt-0.5 leading-tight">{item.releaseInfo}</p>
      )}
    </Link>
  );
}

interface MediaRowProps {
  title: string;
  items: MetaPreview[];
  viewAllHref?: string;
  titleLogo?: string;
}

export function MediaRow({ title, items, viewAllHref, titleLogo }: MediaRowProps) {
  if (!items || items.length === 0) return null;

  return (
    <section className="mb-10">
      <div className="flex items-baseline justify-between mb-4 pr-1">
        {titleLogo ? (
          <img src={titleLogo} alt={title} className="h-6 object-contain object-left" />
        ) : (
          <h2 className="text-[17px] font-bold tracking-tight text-white">{title}</h2>
        )}
        {viewAllHref && (
          <Link
            to={viewAllHref as any}
            className="text-[12px] font-semibold text-white/40 hover:text-white/70 transition-colors flex-shrink-0"
          >
            View all →
          </Link>
        )}
      </div>
      <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-hide -mx-1 px-1">
        {items.map(item => (
          <MediaCard key={`${item.type}-${item.id}`} item={item} />
        ))}
      </div>
    </section>
  );
}
