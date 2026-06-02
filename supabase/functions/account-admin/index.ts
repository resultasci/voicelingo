// Voicelingo — account-admin Edge Function
// Two POST sub-paths under /functions/v1/account-admin:
//   POST /export   -> returns the caller's full data dump as JSON
//   POST /delete   -> deletes the caller's user row (cascades to all data)
//
// Authenticates via the Supabase user JWT (Authorization: Bearer ...).
// Uses the service-role client only for the admin delete; data export uses
// the caller's JWT so RLS is enforced top-to-bottom.
//
// Auto-injected by Supabase:
//   SUPABASE_URL
//   SUPABASE_ANON_KEY
//   SUPABASE_SERVICE_ROLE_KEY

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const JSON_HEADERS = {
  ...CORS_HEADERS,
  "content-type": "application/json; charset=utf-8",
};

function jsonError(status: number, message: string): Response {
  return new Response(JSON.stringify({ error: message }), {
    status,
    headers: JSON_HEADERS,
  });
}

function jsonOk(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status, headers: JSON_HEADERS });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return jsonError(405, "Method not allowed");
  }

  if (!SUPABASE_URL || !ANON_KEY || !SERVICE_ROLE_KEY) {
    console.error("account-admin: missing required env vars");
    return jsonError(500, "Server misconfigured");
  }

  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.toLowerCase().startsWith("bearer ")) {
    return jsonError(401, "Missing bearer token");
  }
  const jwt = authHeader.slice(7).trim();

  // Service-role client: used to verify the JWT and to perform admin deletes.
  const adminClient = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: userData, error: userErr } = await adminClient.auth.getUser(jwt);
  if (userErr || !userData.user) {
    return jsonError(401, "Invalid or expired session");
  }
  const userId = userData.user.id;

  const url = new URL(req.url);
  const segments = url.pathname.split("/").filter((s) => s.length > 0);
  const action = segments[segments.length - 1];

  try {
    if (action === "export") return await handleExport(jwt);
    if (action === "delete") return await handleDelete(adminClient, userId);
    return jsonError(404, `Unknown action: ${action}`);
  } catch (e) {
    console.error(`account-admin[${action}] threw:`, e);
    return jsonError(500, "Internal error");
  }
});

// ---------------------------------------------------------------------------
// /export — runs export_user_data() under the caller's JWT (RLS enforced).
// ---------------------------------------------------------------------------
async function handleExport(jwt: string): Promise<Response> {
  const userClient = createClient(SUPABASE_URL, ANON_KEY, {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data, error } = await userClient.rpc("export_user_data");
  if (error) {
    console.error("export_user_data RPC failed:", error);
    return jsonError(500, "Veriler dışa aktarılamadı.");
  }
  return jsonOk(data);
}

// ---------------------------------------------------------------------------
// /delete — wipes user payload then deletes the auth.users row.
// ---------------------------------------------------------------------------
async function handleDelete(
  adminClient: ReturnType<typeof createClient>,
  userId: string,
): Promise<Response> {
  // NOTE: We do not call the delete_user_payload() RPC here. It relies on
  // auth.uid(), which is null when invoked through the service-role client, so
  // it would always fail. We delete each table directly by user_id instead;
  // the final auth.users delete also CASCADEs as a backstop.

  // Direct row deletes via service_role (RLS bypassed).
  const tables: { name: string; column: string }[] = [
    { name: "messages", column: "" }, // handled via session join below
    { name: "practice_sessions", column: "user_id" },
    { name: "words", column: "user_id" },
    { name: "api_usage", column: "user_id" },
    { name: "profiles", column: "id" },
  ];

  // messages: delete via session_id IN (sessions of user)
  const { data: sessionRows, error: sessionFetchErr } = await adminClient
    .from("practice_sessions")
    .select("id")
    .eq("user_id", userId);
  if (sessionFetchErr) {
    console.error("fetch sessions for cleanup failed:", sessionFetchErr);
  } else if (sessionRows && sessionRows.length > 0) {
    const ids = sessionRows.map((r: { id: string }) => r.id);
    const { error: msgErr } = await adminClient
      .from("messages")
      .delete()
      .in("session_id", ids);
    if (msgErr) console.error("messages cleanup failed:", msgErr);
  }

  for (const t of tables) {
    if (t.name === "messages") continue;
    const { error: delErr } = await adminClient
      .from(t.name)
      .delete()
      .eq(t.column, userId);
    if (delErr) {
      console.error(`${t.name} cleanup failed:`, delErr);
    }
  }

  // Final step: delete the auth.users row itself.
  const { error: adminErr } = await adminClient.auth.admin.deleteUser(userId);
  if (adminErr) {
    console.error("auth.admin.deleteUser failed:", adminErr);
    return jsonError(500, "Hesap silinemedi. Lütfen daha sonra tekrar dene.");
  }

  return jsonOk({ deleted: true });
}
