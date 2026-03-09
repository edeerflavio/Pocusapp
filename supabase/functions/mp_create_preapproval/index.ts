import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';
import { corsHeaders } from '../_shared/cors.ts';
import { createUserClient, createAdminClient } from '../_shared/supabase.ts';

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return jsonResponse({ error: 'Missing authorization header' }, 401);
    }

    const supabaseUser = createUserClient(authHeader);
    const { data: { user }, error: authError } = await supabaseUser.auth.getUser();

    if (authError || !user) {
      return jsonResponse({ error: 'Unauthorized' }, 401);
    }

    const { plan_code } = await req.json();
    if (!plan_code || typeof plan_code !== 'string') {
      return jsonResponse({ error: 'plan_code is required' }, 400);
    }

    const admin = createAdminClient();

    const { data: plan, error: planError } = await admin
      .from('plans')
      .select('id, code')
      .eq('code', plan_code)
      .eq('active', true)
      .single();

    if (planError || !plan) {
      return jsonResponse({ error: 'Invalid or inactive plan' }, 400);
    }

    const { data: existing } = await admin
      .from('subscriptions')
      .select('id, status')
      .eq('user_id', user.id)
      .in('status', ['pending', 'active'])
      .limit(1)
      .maybeSingle();

    if (existing) {
      return jsonResponse(
        { error: 'Subscription already exists', subscription_id: existing.id, status: existing.status },
        409,
      );
    }

    const mpAccessToken = Deno.env.get('MP_ACCESS_TOKEN');
    const mpBackUrl = Deno.env.get('MP_BACK_URL');
    const mpPlanAmount = Number(Deno.env.get('MP_PLAN_AMOUNT') || '0');

    if (!mpAccessToken || !mpBackUrl || !mpPlanAmount) {
      console.error('mp_create_preapproval: missing MP env vars');
      return jsonResponse({ error: 'Internal configuration error' }, 500);
    }

    const mpBody = {
      payer_email: user.email,
      reason: 'Pocusapp Premium',
      external_reference: user.id,
      back_url: mpBackUrl,
      auto_recurring: {
        frequency: 1,
        frequency_type: 'months',
        transaction_amount: mpPlanAmount,
        currency_id: 'BRL',
      },
    };

    const mpRes = await fetch('https://api.mercadopago.com/preapproval', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${mpAccessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(mpBody),
    });

    if (!mpRes.ok) {
      const mpStatus = mpRes.status;
      console.error(`mp_create_preapproval: MP API returned ${mpStatus}`);
      return jsonResponse({ error: 'Payment provider error' }, 502);
    }

    const mpData = await mpRes.json();

    const { data: subscription, error: insertError } = await admin
      .from('subscriptions')
      .insert({
        user_id: user.id,
        provider: 'mercadopago',
        provider_ref: String(mpData.id),
        status: 'pending',
      })
      .select('id')
      .single();

    if (insertError) {
      console.error(`mp_create_preapproval: insert failed for user ${user.id}`);
      return jsonResponse({ error: 'Failed to save subscription' }, 500);
    }

    return jsonResponse(
      { init_point: mpData.init_point, subscription_id: subscription.id },
      201,
    );
  } catch (err) {
    console.error('mp_create_preapproval: unhandled error', err.message);
    return jsonResponse({ error: 'Internal error' }, 500);
  }
});

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}
import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Authorization, Content-Type",
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization") ?? "";
  const hasAuthHeader = authHeader !== "";
  const hasXJwtClaimSub = req.headers.get("x-jwt-claim-sub") !== null;
  const hasXSupabaseAuthUser = req.headers.get("x-supabase-auth-user") !== null;

  const tokenMatch = authHeader.match(/^bearer\s+(.+)/i);
  if (!tokenMatch) {
    return json({
      error: "Unauthorized",
      reason: "missing_auth_header",
      debug: {
        has_auth_header: hasAuthHeader,
        has_x_jwt_claim_sub: hasXJwtClaimSub,
        has_x_supabase_auth_user: hasXSupabaseAuthUser,
      },
    }, 401);
  }
  const token = tokenMatch[1].trim();

  console.log(`[auth] token length=${token.length}, preview=${token.slice(0, 5)}...${token.slice(-5)}`);

  // Trust the edge runtime's JWT validation; extract claims from headers or JWT payload.
  let userId: string | null =
    req.headers.get("x-jwt-claim-sub") ??
    req.headers.get("x-supabase-auth-user") ??
    null;
  let userEmail: string | null = req.headers.get("x-jwt-claim-email") ?? null;

  let jwtDecodeFailed = false;
  if (!userId || !userEmail) {
    // Fallback: decode JWT payload (no signature verification — runtime already accepted it).
    try {
      const parts = token.split(".");
      if (parts.length === 3) {
        const payload = JSON.parse(atob(parts[1].replace(/-/g, "+").replace(/_/g, "/")));
        userId = userId ?? payload.sub ?? null;
        userEmail = userEmail ?? payload.email ?? null;
      }
    } catch (e) {
      jwtDecodeFailed = true;
      console.error("[auth] jwt decode failed", e instanceof Error ? e.message : String(e));
    }
  }

  console.log(`[auth] userId=${userId}, email=${userEmail}`);
  if (!userId) {
    return json({
      code: 401,
      message: "Invalid JWT",
      reason: jwtDecodeFailed ? "jwt_decode_failed" : "missing_user_claim",
      debug: {
        has_auth_header: hasAuthHeader,
        has_x_jwt_claim_sub: hasXJwtClaimSub,
        has_x_supabase_auth_user: hasXSupabaseAuthUser,
        token_parts: token.split(".").length,
        token_len: token.length,
      },
    }, 401);
  }

  const adminClient = createClient(
    Deno.env.get("SB_URL")!,
    Deno.env.get("SB_SERVICE_ROLE_KEY")!,
  );

  let body: { plan_code?: string };
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  const { plan_code } = body;
  if (plan_code !== "premium" && plan_code !== "free") {
    return json({ error: "Invalid plan_code" }, 400);
  }

  if (plan_code === "free") {
    const { error: dbErr } = await adminClient.from("subscriptions").upsert(
      { user_id: userId, provider: "mercadopago", status: "active", provider_ref: null, current_period_end: null },
      { onConflict: "user_id,provider" },
    );
    if (dbErr) {
      console.error("db upsert free", dbErr.message);
      return json({ error: "DB error" }, 500);
    }
    return json({ init_point: null, provider_ref: null });
  }

  // Premium: create MP preapproval
  const mpToken = Deno.env.get("MP_ACCESS_TOKEN")!;

  const mpPayload = {
    reason: "Pocusapp Premium",
    auto_recurring: {
      frequency: 1,
      frequency_type: "months",
      transaction_amount: Number(Deno.env.get("MP_PREMIUM_PRICE") ?? "29.90"),
      currency_id: Deno.env.get("MP_CURRENCY") ?? "BRL",
    },
    back_url: Deno.env.get("MP_BACK_URL") ?? "https://pocusapp.com/subscription",
    payer_email: userEmail,
    status: "pending",
  };

  let mpRes: Response;
  try {
    const ctrl = new AbortController();
    const timeout = setTimeout(() => ctrl.abort(), 10_000);
    mpRes = await fetch("https://api.mercadopago.com/preapproval", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${mpToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(mpPayload),
      signal: ctrl.signal,
    });
    clearTimeout(timeout);
  } catch (e) {
    console.error("mp fetch", e instanceof Error ? e.message : String(e));
    return json({ error: "Payment provider unreachable" }, 502);
  }

  if (!mpRes.ok) {
    const errText = await mpRes.text().catch(() => "");
    console.error("mp error", mpRes.status, errText.slice(0, 200));
    return json({ error: "Payment provider error", status: mpRes.status }, 502);
  }

  const mp = await mpRes.json();
  const provider_ref: string = mp.id;
  const init_point: string = mp.init_point;

  const { error: dbErr } = await adminClient.from("subscriptions").upsert(
    {
      user_id: userId,
      provider: "mercadopago",
      provider_ref,
      status: "pending",
      current_period_end: null,
    },
    { onConflict: "user_id,provider" },
  );
  if (dbErr) {
    console.error("db upsert premium", dbErr.message);
    return json({ error: "DB error" }, 500);
  }

  return json({ init_point, provider_ref });
});
