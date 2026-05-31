'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '../AuthProvider';
import { useRouter } from 'next/navigation';
import { Sidebar } from '@/components/Sidebar';
import { getInstalledAddons, saveInstalledAddons } from '@/lib/services/api';
import { fetchManifest } from '@/lib/stremio';
import { DEFAULT_ADDONS } from '@/lib/supabase';
import { AddonManifest } from '@/lib/types';

export default function SettingsPage() {
  const { currentProfile, user, signOut } = useAuth();
  const router = useRouter();
  const [addonUrls, setAddonUrls] = useState<string[]>([]);
  const [manifestCache, setManifestCache] = useState<Record<string, AddonManifest>>({});
  const [newUrl, setNewUrl] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) { router.replace('/auth'); return; }
    if (!currentProfile) { router.replace('/profiles'); return; }
    loadAddons();
  }, [currentProfile]);

  async function loadAddons() {
    if (!currentProfile) return;
    setLoading(true);
    const urls = await getInstalledAddons(currentProfile.id);
    const targetUrls = urls.length > 0 ? urls : DEFAULT_ADDONS;
    setAddonUrls(targetUrls);

    const cache: Record<string, AddonManifest> = {};
    await Promise.allSettled(
      targetUrls.map(async url => {
        try { cache[url] = await fetchManifest(url); } catch {}
      })
    );
    setManifestCache(cache);
    setLoading(false);
  }

  async function handleInstall() {
    if (!newUrl.trim() || !currentProfile) return;
    const url = newUrl.trim();
    const updated = [...addonUrls.filter(u => u !== url), url];
    setAddonUrls(updated);
    await saveInstalledAddons(currentProfile.id, updated);
    try {
      const manifest = await fetchManifest(url);
      setManifestCache(prev => ({ ...prev, [url]: manifest }));
    } catch {}
    setNewUrl('');
  }

  async function handleRemove(url: string) {
    if (!currentProfile) return;
    const updated = addonUrls.filter(u => u !== url);
    setAddonUrls(updated);
    await saveInstalledAddons(currentProfile.id, updated);
  }

  return (
    <Sidebar>
      <div className="p-6 max-w-2xl">
        <h1 className="text-2xl font-bold mb-6">Settings</h1>

        <div className="mb-8">
          <h2 className="text-lg font-semibold mb-2">Profile</h2>
          <div className="p-4 bg-luna-surface rounded-xl">
            <p className="font-medium">{currentProfile?.name}</p>
            <p className="text-sm text-luna-muted">{currentProfile?.role === 'admin' ? 'Admin' : 'User'}</p>
            <button
              onClick={() => router.push('/profiles')}
              className="mt-2 text-sm text-luna-accent hover:underline"
            >
              Switch Profile
            </button>
          </div>
        </div>

        <div className="mb-8">
          <h2 className="text-lg font-semibold mb-2">Addons ({addonUrls.length})</h2>
          <div className="space-y-2 mb-3">
            {addonUrls.map(url => (
              <div key={url} className="p-3 bg-luna-surface rounded-xl flex items-center justify-between">
                <div className="truncate flex-1">
                  <p className="text-sm font-medium truncate">
                    {manifestCache[url]?.name || url.split('/')[2] || url}
                  </p>
                  <p className="text-xs text-luna-muted truncate">{url}</p>
                </div>
                <button
                  onClick={() => handleRemove(url)}
                  className="ml-2 text-red-400 hover:text-red-300 text-sm"
                >
                  Remove
                </button>
              </div>
            ))}
          </div>
          <div className="flex gap-2">
            <input
              value={newUrl}
              onChange={e => setNewUrl(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && handleInstall()}
              placeholder="https://.../manifest.json"
              className="flex-1 px-4 py-2 bg-luna-elevated rounded-xl text-white placeholder-luna-muted focus:outline-none focus:ring-2 focus:ring-luna-accent text-sm"
            />
            <button
              onClick={handleInstall}
              disabled={!newUrl.trim()}
              className="px-4 py-2 bg-luna-accent rounded-xl text-sm disabled:opacity-50"
            >
              Install
            </button>
          </div>
        </div>

        <div>
          <h2 className="text-lg font-semibold mb-2">Account</h2>
          <button
            onClick={signOut}
            className="px-4 py-2 bg-red-500/20 text-red-400 rounded-xl text-sm hover:bg-red-500/30"
          >
            Sign Out
          </button>
        </div>

        <p className="mt-8 text-xs text-luna-muted">Luna v1.0.0 • Powered by Stremio addon ecosystem</p>
      </div>
    </Sidebar>
  );
}
