// Supabase Edge Function: Validate invite code during signup
// Deploy with: supabase functions deploy invite-validation

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { code } = await req.json();

    if (!code || typeof code !== "string" || code.length < 4) {
      return new Response(
        JSON.stringify({ valid: false, error: "Invalid invite code" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }

    const supabaseAdmin = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    const { data: codes, error } = await supabaseAdmin
      .from("invite_codes")
      .select("code, is_active, used_by, max_uses")
      .eq("code", code.toUpperCase())
      .limit(1);

    if (error || !codes || codes.length === 0) {
      return new Response(
        JSON.stringify({ valid: false, error: "Invalid invite code" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }

    const invite = codes[0];

    if (!invite.is_active) {
      return new Response(
        JSON.stringify({ valid: false, error: "Invite code has been revoked" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }

    if (invite.used_by) {
      return new Response(
        JSON.stringify({ valid: false, error: "Invite code has already been used" }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 400 }
      );
    }

    return new Response(
      JSON.stringify({ valid: true }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ valid: false, error: "Internal server error" }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" }, status: 500 }
    );
  }
});
