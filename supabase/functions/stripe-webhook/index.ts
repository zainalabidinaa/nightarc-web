// supabase/functions/stripe-webhook/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import Stripe from 'https://esm.sh/stripe@14?target=deno';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, { apiVersion: '2024-06-20' });
const supabase = createClient(Deno.env.get('SUPABASE_URL')!, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);

serve(async (req) => {
  const body = await req.text();
  const sig = req.headers.get('stripe-signature')!;

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(body, sig, Deno.env.get('STRIPE_WEBHOOK_SECRET')!);
  } catch {
    return new Response('Invalid signature', { status: 400 });
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object as Stripe.Checkout.Session;
    const plan = session.metadata?.plan as 'premium' | 'premium_plus';
    const email = session.customer_details?.email;
    if (!email || !plan) return new Response('Missing data', { status: 400 });

    // Create auth user
    const { data: authData, error } = await supabase.auth.admin.createUser({
      email,
      email_confirm: true,
      user_metadata: { stripe_customer_id: session.customer },
    });
    if (error || !authData.user) return new Response('User creation failed', { status: 500 });

    // Insert profile
    await supabase.from('profiles').insert({
      user_id: authData.user.id,
      name: email.split('@')[0],
      role: plan,
      uses_primary_addons: false,
      profile_index: 0,
    });

    // Send magic link for password setup
    await supabase.auth.admin.generateLink({ type: 'magiclink', email });
  }

  if (event.type === 'customer.subscription.deleted') {
    const sub = event.data.object as Stripe.Subscription;
    const customerId = sub.customer as string;
    // Look up user by stripe_customer_id in user_metadata and downgrade
    const { data: users } = await supabase.auth.admin.listUsers();
    const user = users.users.find(u => u.user_metadata?.stripe_customer_id === customerId);
    if (user) {
      await supabase.from('profiles').update({ role: 'user' }).eq('user_id', user.id);
    }
  }

  return new Response(JSON.stringify({ received: true }), { headers: { 'Content-Type': 'application/json' } });
});
