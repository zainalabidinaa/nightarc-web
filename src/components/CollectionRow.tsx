import { Collection } from '@/lib/types';
import { FolderTile } from './FolderTile';

interface CollectionRowProps {
  collection: Collection;
}

export function CollectionRow({ collection }: CollectionRowProps) {
  if (!collection.folders || collection.folders.length === 0) return null;

  return (
    <section className="mb-10">
      <div className="flex items-center justify-between mb-4">
        <h2 className="text-base font-semibold text-white">{collection.name}</h2>
      </div>
      <div className="flex gap-3 overflow-x-auto pb-2 scrollbar-hide">
        {collection.folders
          .sort((a, b) => a.sort_order - b.sort_order)
          .map(folder => (
            <FolderTile key={folder.id} folder={folder} />
          ))}
      </div>
    </section>
  );
}
