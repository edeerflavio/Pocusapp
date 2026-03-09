import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type, x-signature, x-request-id",
};

function json(data: unknown, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

async function verifyMpSignature(
  req: Request,
  rawBody: string,
  secret: string,
): Promise<boolean> {
  const xSignature = req.headers.get("x-signature") ?? "";
  const xRequestId = req.headers.get("x-request-id") ?? "";
  const url = new URL(req.url);
  const dataId = url.searchParams.get("id") ?? "";

  // x-signature format: "ts=<timestamp>,v1=<hmac>"
  const ts = xSignature.match(/ts=([^,]+)/)?.[1] ?? "";
  const v1 = xSignature.match(/v1=([^,]+)/)?.[1] ?? "";
  if (!ts || !v1) return false;

  const manifest = `id:${dataId};request-id:${xRequestId};ts:${ts}`;

  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(manifest));
  const computed = Array.from(new Uint8Array(sig))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");

  return computed === v1;
}

// Map MP preapproval status → our subscription status
function mapStatus(mpStatus: string): string {
  switch (mpStatus) {
    case "authorized": return "active";
    case "cancelled": return "cancelled";
    case "paused": return "paused";
    default: return mpStatus;
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: CORS_HEADERS });
  }
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const rawBody = await req.text();

  const webhookSecret = Deno.env.get("MP_WEBHOOK_SECRET");
  if (webhookSecret) {
    const valid = await verifyMpSignature(req, rawBody, webhookSecret).catch(() => false);
    if (!valid) {
      console.warn("mp webhook signature mismatch");
      return json({ error: "Forbidden" }, 403);
    }
  }

  let notification: { type?: string; action?: string; data?: { id?: string }; id?: string };
  try {
    notification = JSON.parse(rawBody);
  } catch {
    return json({ error: "Invalid JSON" }, 400);
  }

  if (notification.type !== "subscription_preapproval") {
    return json({ ok: true, ignored: true });
  }

  const resourceId = notification.data?.id;
  if (!resourceId) return json({ error: "Missing data.id" }, 400);

  // Idempotency key: combine MP notification id + resource id
  const eventId = `${notification.id ?? "noId"}_${resourceId}`;

  const supabase = createClient(
    Deno.env.get("SB_URL")!,
    Deno.env.get("SB_SERVICE_ROLE_KEY")!,
  );

  // Idempotency check
  const { data: existing } = await supabase
    .from("mp_events")
    .select("event_id")
    .eq("event_id", eventId)
    .maybeSingle();

  if (existing) return json({ ok: true, duplicate: true });

  // Fetch preapproval details from MP
  const mpToken = Deno.env.get("MP_ACCESS_TOKEN")!;
  let preapproval: Record<string, unknown>;
  try {
    const ctrl = new AbortController();
    const timeout = setTimeout(() => ctrl.abort(), 10_000);
    const mpRes = await fetch(`https://api.mercadopago.com/preapproval/${resourceId}`, {
      headers: { Authorization: `Bearer ${mpToken}` },
      signal: ctrl.signal,
    });
    clearTimeout(timeout);
    if (!mpRes.ok) {
      console.error("mp fetch preapproval", mpRes.status);
      return json({ error: "Payment provider error" }, 502);
    }
    preapproval = await mpRes.json();
  } catch (e) {
    console.error("mp fetch", e instanceof Error ? e.message : String(e));
    return json({ error: "Payment provider unreachable" }, 502);
  }

  const mpStatus = String(preapproval.status ?? "");
  const status = mapStatus(mpStatus);
  const nextPaymentDate = preapproval.next_payment_date
    ? new Date(preapproval.next_payment_date as string)
    : null;

  // Find subscription by provider_ref
  const { data: sub, error: subErr } = await supabase
    .from("subscriptions")
    .select("id, user_id")
    .eq("provider_ref", resourceId)
    .maybeSingle();

  if (subErr) {
    console.error("sub lookup", subErr.message);
    return json({ error: "DB error" }, 500);
  }
  if (!sub) {
    console.warn("mp webhook: no subscription for provider_ref", resourceId);
    // Record event anyway to prevent re-processing
    await supabase.from("mp_events").insert({ event_id: eventId, action: notification.action, resource_id: resourceId });
    return json({ ok: true, warning: "subscription not found" });
  }

  const isPremiumActive = status === "active";

  // Update subscription
  const { error: updateErr } = await supabase
    .from("subscriptions")
    .update({
      status,
      current_period_end: nextPaymentDate?.toISOString() ?? null,
    })
    .eq("id", sub.id);

  if (updateErr) {
    console.error("sub update", updateErr.message);
    return json({ error: "DB error" }, 500);
  }

  // Upsert entitlement
  const { error: entErr } = await supabase.from("entitlements").upsert(
    {
      user_id: sub.user_id,
      plan_code: "premium",
      active: isPremiumActive,
      ends_at: nextPaymentDate?.toISOString() ?? null,
    },
    { onConflict: "user_id,plan_code" },
  );

  if (entErr) {
    console.error("entitlement upsert", entErr.message);
    return json({ error: "DB error" }, 500);
  }

  // Record processed event
  await supabase.from("mp_events").insert({
    event_id: eventId,
    action: notification.action,
    resource_id: resourceId,
  });

  console.log("mp webhook processed", { eventId, status, user_id: sub.user_id });

  return json({ ok: true });
});
