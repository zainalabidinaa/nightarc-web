import { useState } from 'react';
import { MoonlitProfile } from '@/lib/types';
import { avatarUrlForId } from '@/lib/avatars';

// Deterministic pastel gradient from a string seed (fallback when no avatar set)
function avatarGradient(seed: string): string {
  let h = 0;
  for (let i = 0; i < seed.length; i++) h = (h * 31 + seed.charCodeAt(i)) & 0xffffffff;
  const hue = Math.abs(h) % 360;
  return `linear-gradient(135deg, hsl(${hue},65%,52%), hsl(${(hue + 40) % 360},70%,42%))`;
}

interface ProfileAvatarProps {
  profile: Pick<MoonlitProfile, 'name' | 'avatar_color' | 'avatar_id'>;
  size?: number;
  className?: string;
}

/**
 * Renders a profile's avatar image (resolved from avatar_id, GIFs animate
 * natively in <img>). Falls back to a colored circle with the name's first
 * letter when no avatar_id is set or the image fails to load.
 */
export function ProfileAvatar({ profile, size = 32, className = '' }: ProfileAvatarProps) {
  const url = avatarUrlForId(profile.avatar_id);
  const [failed, setFailed] = useState(false);

  if (url && !failed) {
    return (
      <img
        src={url}
        alt={profile.name}
        loading="lazy"
        onError={() => setFailed(true)}
        className={`rounded-full object-cover select-none ${className}`}
        style={{ width: size, height: size }}
      />
    );
  }

  return (
    <div
      className={`rounded-full flex items-center justify-center font-black text-white select-none ${className}`}
      style={{
        width: size,
        height: size,
        fontSize: Math.round(size * 0.41),
        background: profile.avatar_color || avatarGradient(profile.name),
      }}
    >
      {profile.name?.[0]?.toUpperCase()}
    </div>
  );
}
