'use client';

import { useEffect, useState } from 'react';
import { useAuth } from '../AuthProvider';
import { useRouter } from 'next/navigation';
import { Sidebar } from '@/components/Sidebar';
import { getInviteCodes, generateInviteCode, revokeInviteCode } from '@/lib/services/api';
import { InviteCode } from '@/lib/types';

export default function AdminPage() {
  const { currentProfile, user } = useAuth();
  const router = useRouter();
  const [codes, setCodes] = useState<InviteCode[]>([]);
  const [maxUses, setMaxUses] = useState(1);
  const [loading, setLoading] = useState(true);
  const [section, setSection] = useState<'codes' | 'stats'>('codes');

  useEffect(() => {
    if (!user) { router.replace('/auth'); return; }
    if (!currentProfile) { router.replace('/profiles'); return; }
    if (currentProfile.role !== 'admin') { router.replace('/home'); return; }
    loadData();
  }, [currentProfile]);

  async function loadData() {
    setLoading(true);
    const c = await getInviteCodes();
    setCodes(c);
    setLoading(false);
  }

  async function handleGenerate() {
    if (!user) return;
    await generateInviteCode(user.id, maxUses);
    await loadData();
  }

  async function handleRevoke(code: string) {
    await revokeInviteCode(code);
    await loadData();
  }

  return (
    <Sidebar>
      <div className="p-6">
        <h1 className="text-2xl font-bold mb-6">Admin Panel</h1>

        <div className="flex gap-2 mb-6">
          <button
            onClick={() => setSection('codes')}
            className={`px-4 py-2 rounded-xl text-sm ${section === 'codes' ? 'bg-luna-accent' : 'bg-luna-elevated'}`}
          >
            Invite Codes
          </button>
          <button
            onClick={() => setSection('stats')}
            className={`px-4 py-2 rounded-xl text-sm ${section === 'stats' ? 'bg-luna-accent' : 'bg-luna-elevated'}`}
          >
            Stats
          </button>
        </div>

        {section === 'codes' && (
          <div>
            <div className="flex gap-2 mb-4 items-center">
              <input
                type="number"
                value={maxUses}
                onChange={e => setMaxUses(Number(e.target.value))}
                min={1}
                max={100}
                className="w-20 px-3 py-2 bg-luna-elevated rounded-xl text-white focus:outline-none focus:ring-2 focus:ring-luna-accent text-sm"
              />
              <span className="text-sm text-luna-muted">uses per code</span>
              <button
                onClick={handleGenerate}
                className="ml-auto px-4 py-2 bg-luna-accent rounded-xl text-sm"
              >
                Generate Code
              </button>
            </div>

            <div className="space-y-2">
              <p className="text-sm text-luna-muted mb-2">
                Active: {codes.filter(c => c.is_active && !c.used_by).length} | Total: {codes.length}
              </p>
              {codes.map(code => (
                <div key={code.code} className="p-3 bg-luna-surface rounded-xl flex items-center justify-between">
                  <div>
                    <p className="font-mono font-bold">{code.code}</p>
                    <p className="text-xs text-luna-muted">
                      Created: {new Date(code.created_at).toLocaleDateString()}
                      {code.used_by && ' • Used'}
                      {!code.is_active && ' • Revoked'}
                    </p>
                  </div>
                  <div className="flex gap-2 items-center">
                    <span className={`w-2 h-2 rounded-full ${
                      code.is_active && !code.used_by ? 'bg-green-500' :
                      code.used_by ? 'bg-red-500' : 'bg-gray-500'
                    }`} />
                    {code.is_active && !code.used_by && (
                      <button
                        onClick={() => handleRevoke(code.code)}
                        className="text-xs text-red-400 hover:text-red-300"
                      >
                        Revoke
                      </button>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {section === 'stats' && (
          <div className="grid grid-cols-2 gap-4">
            {[
              { label: 'Total Invite Codes', value: codes.length },
              { label: 'Active Codes', value: codes.filter(c => c.is_active && !c.used_by).length },
              { label: 'Used Codes', value: codes.filter(c => c.used_by).length },
              { label: 'Revoked Codes', value: codes.filter(c => !c.is_active).length },
            ].map(stat => (
              <div key={stat.label} className="p-4 bg-luna-surface rounded-xl text-center">
                <p className="text-2xl font-bold">{stat.value}</p>
                <p className="text-xs text-luna-muted">{stat.label}</p>
              </div>
            ))}
          </div>
        )}
      </div>
    </Sidebar>
  );
}
