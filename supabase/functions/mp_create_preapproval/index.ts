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
