// supabase/functions/admin-users/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const ANON_KEY = Deno.env.get('SUPABASE_ANON_KEY')!;

const cors = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, content-type' };

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  const authHeader = req.headers.get('Authorization') ?? '';
  const callerClient = createClient(SUPABASE_URL, ANON_KEY, { global: { headers: { Authorization: authHeader } } });
  const { data: { user } } = await callerClient.auth.getUser();
  if (!user) return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401, headers: cors });

  const serviceClient = createClient(SUPABASE_URL, SERVICE_KEY);
  const { data: callerProfile } = await serviceClient.from('profiles').select('role').eq('user_id', user.id).single();
  if (callerProfile?.role !== 'admin') return new Response(JSON.stringify({ error: 'Forbidden' }), { status: 403, headers: cors });

  if (req.method === 'GET') {
    const { data: profiles } = await serviceClient.from('profiles').select('*').order('created_at');
    const { data: authUsers } = await serviceClient.auth.admin.listUsers();
    const emailMap = new Map(authUsers.users.map(u => [u.id, u.email]));
    const users = (profiles ?? []).map(p => ({ ...p, email: emailMap.get(p.user_id) }));
    return new Response(JSON.stringify({ users }), { headers: { ...cors, 'Content-Type': 'application/json' } });
  }

  if (req.method === 'PATCH') {
    const { userId, role } = await req.json();
    await serviceClient.from('profiles').update({ role }).eq('user_id', userId);
    return new Response(JSON.stringify({ ok: true }), { headers: { ...cors, 'Content-Type': 'application/json' } });
  }

  return new Response('Method Not Allowed', { status: 405, headers: cors });
});
