// src/lib/recommendations.ts
import type { MetaPreview } from './types';

export interface RecommendationRow {
  row_type: string;
  row_title: string;
  cover_image: string | null;
  sort_order: number;
  items: MetaPreview[];
}

export interface RecommendationsResponse {
  generated_at: string;
  rows: RecommendationRow[];
}

const API_BASE = '/api/recommendations';

export async function fetchRecommendations(profileId: string): Promise<RecommendationsResponse> {
  const res = await fetch(`${API_BASE}?profile_id=${encodeURIComponent(profileId)}`);
  if (!res.ok) return { generated_at: new Date().toISOString(), rows: [] };
  return res.json();
}

export async function triggerRegeneration(profileId: string): Promise<{ success: boolean }> {
  const res = await fetch(`${API_BASE}/generate`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ profile_id: profileId }),
  });
  if (!res.ok) return { success: false };
  return res.json();
}
