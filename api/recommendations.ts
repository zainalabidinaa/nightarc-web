// api/recommendations.ts
export const config = { runtime: 'edge' };

import { generateRecommendations, getRecommendations } from './recommendation-engine';

export default async function handler(req: Request) {
  const url = new URL(req.url);
  const path = url.pathname.replace(/\/$/, '');

  if (req.method === 'OPTIONS') {
    return new Response(null, {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      },
    });
  }

  const corsHeaders = { 'Access-Control-Allow-Origin': '*' };

  try {
    if (req.method === 'GET') {
      const profileId = url.searchParams.get('profile_id');
      if (!profileId) {
        return new Response(JSON.stringify({ error: 'Missing profile_id' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      const data = await getRecommendations(profileId);
      return new Response(JSON.stringify(data), {
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
          'Cache-Control': 'public, max-age=3600, stale-while-revalidate=7200',
        },
      });
    }

    if (req.method === 'POST' && path.endsWith('/generate')) {
      let profileId: string;
      try {
        const body = await req.json();
        profileId = body.profile_id;
      } catch {
        profileId = url.searchParams.get('profile_id') || '';
      }

      if (!profileId) {
        return new Response(JSON.stringify({ error: 'Missing profile_id' }), {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        });
      }

      const result = await generateRecommendations(profileId);
      return new Response(JSON.stringify(result), {
        status: result.success ? 200 : 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ error: 'Not found' }), {
      status: 404,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
}
