'use client';

import { useEffect, useState, use } from 'react';
import { useAuth } from '../../../AuthProvider';
import { useRouter, useSearchParams } from 'next/navigation';
import { Sidebar } from '@/components/Sidebar';
import { updateWatchProgress } from '@/lib/services/api';
import Script from 'next/script';

export default function WatchPage({ params }: { params: Promise<{ type: string; id: string }> }) {
  const resolved = use(params);
  const searchParams = useSearchParams();
  const { currentProfile, user } = useAuth();
  const router = useRouter();
  const streamUrl = searchParams.get('url');
  const headersStr = searchParams.get('headers');

  const [position, setPosition] = useState(0);
  const [duration, setDuration] = useState(0);
  const [playing, setPlaying] = useState(false);

  useEffect(() => {
    if (!user) { router.replace('/auth'); return; }
    if (!currentProfile) { router.replace('/profiles'); return; }
    if (!streamUrl) { router.back(); return; }
  }, [user, currentProfile, streamUrl]);

  useEffect(() => {
    if (!streamUrl || !currentProfile) return;
    const interval = setInterval(async () => {
      const video = document.querySelector('video');
      if (video && video.currentTime > 0) {
        setPosition(video.currentTime);
        setDuration(video.duration || 0);
        await updateWatchProgress(
          currentProfile.id,
          resolved.id,
          resolved.type,
          video.currentTime,
          video.duration || 0,
          false
        );
      }
    }, 10000);

    return () => clearInterval(interval);
  }, [streamUrl, currentProfile]);

  if (!streamUrl) return null;

  const decodedUrl = decodeURIComponent(streamUrl);
  let headers: Record<string, string> | undefined;
  try {
    if (headersStr) headers = JSON.parse(decodeURIComponent(headersStr));
  } catch {}

  return (
    <div className="h-screen bg-black flex flex-col">
      <div className="flex items-center gap-4 p-4 bg-black/80">
        <button
          onClick={() => router.back()}
          className="text-white hover:text-luna-accent"
        >
          ← Back
        </button>
        <span className="text-sm text-luna-muted truncate">{resolved.id}</span>
      </div>

      <div className="flex-1 flex items-center justify-center">
        <video
          id="luna-player"
          className="max-w-full max-h-full"
          controls
          autoPlay
          crossOrigin="anonymous"
          onPlay={() => setPlaying(true)}
          onPause={() => setPlaying(false)}
        >
          <source src={decodedUrl} />
        </video>
      </div>
    </div>
  );
}
