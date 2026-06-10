// supabase/functions/create-checkout-session/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import Stripe from 'https://esm.sh/stripe@14?target=deno';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, { apiVersion: '2024-06-20' });
const cors = { 'Access-Control-Allow-Origin': '*', 'Access-Control-Allow-Headers': 'authorization, content-type' };

const PRICE_IDS: Record<string, string> = {
  premium: Deno.env.get('STRIPE_PREMIUM_PRICE_ID')!,
  premium_plus: Deno.env.get('STRIPE_PREMIUM_PLUS_PRICE_ID')!,
};

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors });

  const { plan, customerId } = await req.json();
  const priceId = PRICE_IDS[plan];
  if (!priceId) return new Response(JSON.stringify({ error: 'Invalid plan' }), { status: 400, headers: cors });

  // Portal session (for existing customers)
  if (req.url.endsWith('/create-portal-session') && customerId) {
    const session = await stripe.billingPortal.sessions.create({
      customer: customerId,
      return_url: Deno.env.get('PORTAL_RETURN_URL')!,
    });
    return new Response(JSON.stringify({ url: session.url }), { headers: { ...cors, 'Content-Type': 'application/json' } });
  }

  // Checkout session (new subscriber)
  const session = await stripe.checkout.sessions.create({
    mode: 'subscription',
    line_items: [{ price: priceId, quantity: 1 }],
    success_url: Deno.env.get('SUCCESS_URL')! + `?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${Deno.env.get('PORTAL_RETURN_URL')!.replace('/billing', '/pricing')}`,
    metadata: { plan },
  });

  return new Response(JSON.stringify({ url: session.url }), { headers: { ...cors, 'Content-Type': 'application/json' } });
});
