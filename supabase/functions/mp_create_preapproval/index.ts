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
  if (!authHeader.startsWith("Bearer ")) return json({ error: "Unauthorized" }, 401);
  const token = authHeader.slice(7);

  const authClient = createClient(
    Deno.env.get("SB_URL")!,
    Deno.env.get("SB_ANON_KEY")!,
  );

  const { data: { user }, error: authErr } = await authClient.auth.getUser(token);
  if (authErr || !user) return json({ error: "invalid_token" }, 401);

  const dbClient = createClient(
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
    const { error: dbErr } = await dbClient.from("subscriptions").upsert(
      { user_id: user.id, provider: "mercadopago", status: "active", provider_ref: null, current_period_end: null },
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
    payer_email: user.email,
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

  const { error: dbErr } = await dbClient.from("subscriptions").upsert(
    {
      user_id: user.id,
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
