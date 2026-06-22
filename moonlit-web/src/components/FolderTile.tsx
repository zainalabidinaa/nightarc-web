import { useState } from 'react';
import { Link } from '@tanstack/react-router';
import { Folder } from '@/lib/types';

interface FolderTileProps {
  folder: Folder;
  showGlow?: boolean;
}

export function FolderTile({ folder, showGlow = false }: FolderTileProps) {
  const [imgSrc, setImgSrc] = useState(folder.cover_image || '');
  const [glowing, setGlowing] = useState(false);

  const isLandscape = (folder.tile_shape || '').toUpperCase() === 'LANDSCAPE';
  const width = isLandscape ? 220 : 140;
  const aspectRatio = isLandscape ? '16/9' : '2/3';

  const canSwapGif = folder.focus_gif_enabled && folder.focus_gif;

  function handleEnter() {
    if (canSwapGif) setImgSrc(folder.focus_gif!);
    if (showGlow) setGlowing(true);
  }

  function handleLeave() {
    if (canSwapGif) setImgSrc(folder.cover_image || '');
    if (showGlow) setGlowing(false);
  }

  return (
    <Link
      to="/collections/$folderId"
      params={{ folderId: folder.id }}
      className="flex-shrink-0 group cursor-pointer"
      style={{ width: `${width}px` }}
    >
      <div
        className="relative overflow-hidden rounded-xl mb-2 transition-all duration-300 group-hover:shadow-lg group-hover:shadow-black/30 group-hover:ring-1 group-hover:ring-white/10"
        style={{
          aspectRatio,
          boxShadow: glowing ? '0 0 28px 4px rgba(192,132,252,0.45)' : undefined,
        }}
        onMouseEnter={handleEnter}
        onMouseLeave={handleLeave}
      >
        {imgSrc ? (
          <img
            src={imgSrc}
            alt={folder.name}
            loading="lazy"
            className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-[1.025]"
          />
        ) : (
          <div className="w-full h-full bg-moonlit-elevated flex items-center justify-center">
            <span className="text-xs font-bold text-white/40 text-center px-2">{folder.name}</span>
          </div>
        )}
      </div>
      <p className="text-sm font-semibold text-white/80 truncate group-hover:text-white transition-colors duration-200">
        {folder.name}
      </p>
    </Link>
  );
}
