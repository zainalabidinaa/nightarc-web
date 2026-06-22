import { Collection } from '@/lib/types';
import { FolderTile } from './FolderTile';

interface CollectionRowProps {
  collection: Collection;
  titleLogo?: string;
}

export function CollectionRow({ collection, titleLogo }: CollectionRowProps) {
  if (!collection.folders || collection.folders.length === 0) return null;

  const showGlow = collection.focus_glow_enabled ?? true;

  return (
    <section className="mb-10">
      {titleLogo ? (
        <img src={titleLogo} alt={collection.name} className="h-6 object-contain object-left mb-4" />
      ) : (
        <h2 className="text-[17px] font-bold tracking-tight text-white mb-4">{collection.name}</h2>
      )}
      <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-hide">
        {[...collection.folders]
          .sort((a, b) => a.sort_order - b.sort_order)
          .map(folder => (
            <FolderTile key={folder.id} folder={folder} showGlow={showGlow} />
          ))}
      </div>
    </section>
  );
}
