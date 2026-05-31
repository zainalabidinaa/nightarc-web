'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Folder } from '@/lib/types';

interface FolderTileProps {
  folder: Folder;
}

export function FolderTile({ folder }: FolderTileProps) {
  const [imgSrc, setImgSrc] = useState(folder.cover_image || '');

  return (
    <Link
      href={`/collections/${folder.id}`}
      className="flex-shrink-0 group cursor-pointer"
      style={{ width: '130px' }}
    >
      <div
        className="relative overflow-hidden rounded-lg"
        style={{ height: '75px', background: '#1a1a2e' }}
        onMouseEnter={() => folder.focus_gif && setImgSrc(folder.focus_gif)}
        onMouseLeave={() => setImgSrc(folder.cover_image || '')}
      >
        {imgSrc ? (
          <img
            src={imgSrc}
            alt={folder.name}
            className="w-full h-full object-cover transition-transform duration-300 group-hover:scale-105"
          />
        ) : (
          <div className="w-full h-full flex items-center justify-center">
            <span className="text-xs font-bold text-white/60 text-center px-2">{folder.name}</span>
          </div>
        )}
        <div className="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors duration-200" />
      </div>
      <p className="text-xs text-luna-muted mt-1.5 truncate group-hover:text-white transition-colors duration-200">
        {folder.name}
      </p>
    </Link>
  );
}
