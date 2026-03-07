import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

/**
 * Returns a Supabase client authenticated with the service role key.
 * Use only in Edge Functions that run server-side without a user JWT
 * (e.g. webhooks). Never expose this client to browser code.
 */
export function makeAdminClient(): SupabaseClient {
  return createClient(
    Deno.env.get("SB_URL")!,
    Deno.env.get("SB_SERVICE_ROLE_KEY")!,
  );
}
