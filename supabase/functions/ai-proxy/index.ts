// Voicelingo — Gemini 2.5 Flash proxy Edge Function
// Exposes six sub-paths under /functions/v1/ai-proxy:
//   POST /turn              multipart  file=<audio>, history?, system?      -> { transcript, reply, evaluation }
//   POST /chat              JSON  { messages, system? }                     -> { content }
//   POST /evaluate          JSON  { text }                                  -> JSON evaluation object
//   POST /transcribe        multipart  file=<audio>, language?              -> { text }
//   POST /enrich            JSON  { word, target_language? }                -> { ipa, example, ... }
//   POST /generate-scenario JSON  { description, category, difficulty, ... } -> structured JSON
//
// Authenticates the caller via the Supabase user JWT.
// Atomic per-user/per-day rate limits via the public.incr_api_usage RPC.
//
// Required Supabase function secrets:
//   GEMINI_API_KEY                 (set with: supabase secrets set GEMINI_API_KEY=...)
// Auto-injected by Supabase:
//   SUPABASE_URL
//   SUPABASE_SERVICE_ROLE_KEY

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

const GEMINI_API_KEY = Deno.env.get("GEMINI_API_KEY") ?? "";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const GEMINI_BASE = "https://generativelanguage.googleapis.com/v1beta";
const MODEL = "gemini-2.5-flash";

// Per-user / per-UTC-day soft caps. Free tier is 250 RPD globally — these are
// per-user budgets; the limits scale as billing tier upgrades.
const LIMITS = {
  turn: 300,
  chat: 200,
  evaluate: 200,
  transcribe: 100,
  enrich: 100,
  "generate-scenario": 30,
} as const;

type Action = keyof typeof LIMITS;

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

  if (!GEMINI_API_KEY || !SUPABASE_URL || !SERVICE_ROLE_KEY) {
    console.error("ai-proxy: missing required env vars");
    return jsonError(500, "Server misconfigured");
  }

  // --- Auth -----------------------------------------------------------------
  const authHeader = req.headers.get("Authorization") ?? "";
  if (!authHeader.toLowerCase().startsWith("bearer ")) {
    return jsonError(401, "Missing bearer token");
  }
  const jwt = authHeader.slice(7).trim();

  const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const { data: userData, error: userErr } = await supabase.auth.getUser(jwt);
  if (userErr || !userData.user) {
    return jsonError(401, "Invalid or expired session");
  }
  const userId = userData.user.id;

  // --- Routing --------------------------------------------------------------
  const url = new URL(req.url);
  const segments = url.pathname.split("/").filter((s) => s.length > 0);
  const action = segments[segments.length - 1] as Action | string;

  if (!Object.prototype.hasOwnProperty.call(LIMITS, action)) {
    return jsonError(404, `Unknown action: ${action}`);
  }

  // --- Rate limit ------------------------------------------------------------
  const { data: countAfter, error: rpcErr } = await supabase.rpc(
    "incr_api_usage",
    { p_user_id: userId, p_action: action },
  );
  if (rpcErr) {
    console.error("incr_api_usage failed:", rpcErr);
    return jsonError(500, "Rate limit ledger unavailable");
  }
  const used = (countAfter as number | null) ?? 0;
  const limit = LIMITS[action as Action];
  if (used > limit) {
    return new Response(
      JSON.stringify({
        error: `Günlük ${
          labelFor(action as Action)
        } limitine ulaştın (${limit}/gün). Yarın UTC 00:00'da sıfırlanır.`,
        limit,
        used,
      }),
      { status: 429, headers: JSON_HEADERS },
    );
  }

  // --- Dispatch -------------------------------------------------------------
  try {
    if (action === "turn") return await handleTurn(req);
    if (action === "chat") return await handleChat(req);
    if (action === "evaluate") return await handleEvaluate(req);
    if (action === "transcribe") return await handleTranscribe(req);
    if (action === "generate-scenario") return await handleGenerateScenario(req);
    return await handleEnrich(req);
  } catch (e) {
    console.error(`ai-proxy[${action}] threw:`, e);
    return jsonError(500, "Internal error");
  }
});

function labelFor(a: Action): string {
  switch (a) {
    case "turn":
      return "konuşma turu";
    case "chat":
      return "sohbet";
    case "evaluate":
      return "değerlendirme";
    case "transcribe":
      return "ses tanıma";
    case "enrich":
      return "kelime zenginleştirme";
    case "generate-scenario":
      return "senaryo üretimi";
  }
}

// ---------------------------------------------------------------------------
// Gemini API helpers
// ---------------------------------------------------------------------------

type GeminiPart =
  | { text: string }
  | { inline_data: { mime_type: string; data: string } };

type GeminiContent = { role: "user" | "model"; parts: GeminiPart[] };

interface GeminiRequest {
  contents: GeminiContent[];
  systemInstruction?: { parts: { text: string }[] };
  generationConfig?: {
    temperature?: number;
    responseMimeType?: string;
    responseSchema?: unknown;
    maxOutputTokens?: number;
  };
}

const GEMINI_TIMEOUT_MS = 20000;
const GEMINI_MAX_ATTEMPTS = 3;

const sleep = (ms: number) => new Promise<void>((r) => setTimeout(r, ms));

async function geminiCall(
  body: GeminiRequest,
): Promise<
  { ok: true; text: string } | { ok: false; status: number; err: string }
> {
  let lastErr = "Max attempts reached";
  let lastStatus = 500;

  for (let attempt = 1; attempt <= GEMINI_MAX_ATTEMPTS; attempt++) {
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), GEMINI_TIMEOUT_MS);

    try {
      const res = await fetch(
        `${GEMINI_BASE}/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify(body),
          signal: controller.signal,
        },
      );

      if (!res.ok) {
        // Drain the body so the connection is freed even when we retry.
        const txt = await res.text().catch(() => "");
        // Retry only transient upstream failures; 4xx (except 429) are terminal.
        if ((res.status === 429 || res.status >= 500) &&
          attempt < GEMINI_MAX_ATTEMPTS) {
          lastErr = txt;
          lastStatus = res.status;
          await sleep(1000 * attempt); // linear backoff: 1s, 2s
          continue;
        }
        return { ok: false, status: res.status, err: txt };
      }

      const data = await res.json();
      const text = (data?.candidates?.[0]?.content?.parts ?? [])
        .map((p: { text?: string }) => p.text ?? "")
        .join("")
        .trim();

      return { ok: true, text };
    } catch (e) {
      // AbortError (timeout) vs. network failure — both retryable.
      const aborted = e instanceof DOMException && e.name === "AbortError";
      lastStatus = aborted ? 504 : 502;
      lastErr = aborted
        ? "Upstream timeout"
        : (e instanceof Error ? e.message : "Network error");
      if (attempt < GEMINI_MAX_ATTEMPTS) {
        await sleep(1000 * attempt);
        continue;
      }
    } finally {
      clearTimeout(timeoutId);
    }
  }
  return { ok: false, status: lastStatus, err: lastErr };
}

/// Convert an OpenAI-style messages array (used by legacy callers) into
/// Gemini's contents format. `assistant` → `model`.
function toGeminiContents(
  messages: { role: string; content: string }[],
): GeminiContent[] {
  return messages.map((m) => ({
    role: m.role === "assistant" ? "model" : "user",
    parts: [{ text: m.content }],
  }));
}

async function fileToBase64(file: File): Promise<string> {
  const buf = new Uint8Array(await file.arrayBuffer());
  let bin = "";
  const chunk = 0x8000;
  for (let i = 0; i < buf.length; i += chunk) {
    bin += String.fromCharCode.apply(
      null,
      buf.subarray(i, i + chunk) as unknown as number[],
    );
  }
  return btoa(bin);
}

function mimeFor(file: File): string {
  if (file.type && file.type !== "application/octet-stream") return file.type;
  const name = (file.name || "").toLowerCase();
  if (name.endsWith(".opus") || name.endsWith(".ogg")) return "audio/ogg";
  if (name.endsWith(".wav")) return "audio/wav";
  if (name.endsWith(".mp3")) return "audio/mpeg";
  if (name.endsWith(".m4a") || name.endsWith(".mp4")) return "audio/mp4";
  return "audio/ogg";
}

// ---------------------------------------------------------------------------
// /turn — multimodal one-shot: audio in, {transcript, reply, evaluation} out.
// Replaces the previous transcribe → chat → evaluate sequential chain.
// ---------------------------------------------------------------------------
async function handleTurn(req: Request): Promise<Response> {
  let form: FormData;
  try {
    form = await req.formData();
  } catch {
    return jsonError(400, "Expected multipart/form-data");
  }

  const file = form.get("file");
  if (!(file instanceof File)) {
    return jsonError(400, "`file` field is required");
  }
  if (file.size === 0) return jsonError(400, "Empty audio file");
  if (file.size > 18 * 1024 * 1024) {
    return jsonError(413, "Audio file too large (max 18MB inline)");
  }

  const historyRaw = form.get("history");
  let history: { role: string; content: string }[] = [];
  if (typeof historyRaw === "string" && historyRaw.length > 0) {
    try {
      const parsed = JSON.parse(historyRaw);
      if (Array.isArray(parsed)) {
        history = parsed
          .filter(
            (m): m is { role: string; content: string } =>
              m && typeof m === "object" &&
              typeof m.role === "string" &&
              typeof m.content === "string" &&
              (m.role === "user" || m.role === "assistant") &&
              m.content.length > 0 && m.content.length < 4000,
          )
          .slice(-20);
      }
    } catch {
      // Ignore malformed history; treat as fresh turn.
    }
  }

  const systemOverride = form.get("system");
  const cefr = (form.get("cefr") ?? "A2").toString();

  const defaultSystem =
    `You are a friendly English tutor speaking with a Turkish learner at CEFR ${cefr} level. ` +
    "The user just spoke an audio message in English (possibly broken). " +
    "Respond with ONLY a JSON object matching this exact schema:\n" +
    `{
  "transcript": "exact English transcription of what the user said",
  "reply": "your spoken-style English reply (1-3 short sentences, conversational, continues the dialogue)",
  "evaluation": {
    "correct": "corrected English version of the user's sentence",
    "score": 0-100,
    "explanation": "kısa Türkçe açıklama (1-2 cümle)",
    "grammar_errors": ["specific mistake 1", "specific mistake 2"],
    "cefr_band": "A1|A2|B1|B2|C1|C2",
    "next_focus": "one short suggestion for the learner's next focus area, Türkçe"
  }
}\n` +
    "Rules:\n" +
    "- `correct` must be in English, never Turkish.\n" +
    "- If the user's English is already perfect, `correct` equals `transcript` and score is 90-100.\n" +
    "- `reply` must continue the conversation naturally and be appropriate for CEFR " +
    cefr + ".\n" +
    "- `grammar_errors` is [] when none.\n" +
    "- Return ONLY the JSON object, no markdown fences, no commentary.";

  // When the caller supplies a persona/system override we still need the
  // JSON-schema contract appended, otherwise the model returns free-form prose
  // and the client's ConversationTurn.fromJson parse silently yields blanks.
  // Splitting on the "Respond with ONLY" marker preserves the schema half.
  const schemaPart = defaultSystem.includes("Respond with ONLY")
    ? "Respond with ONLY" + defaultSystem.split("Respond with ONLY")[1]
    : defaultSystem;
  const systemPrompt =
    typeof systemOverride === "string" && systemOverride.length > 0 &&
      systemOverride.length < 4000
      ? systemOverride + "\n\n" + schemaPart
      : defaultSystem;

  const audioBase64 = await fileToBase64(file);
  const mime = mimeFor(file);

  const historyContents = toGeminiContents(history);
  const turnContent: GeminiContent = {
    role: "user",
    parts: [
      { inline_data: { mime_type: mime, data: audioBase64 } },
      { text: "Transcribe my audio, then reply, then evaluate." },
    ],
  };

  const result = await geminiCall({
    contents: [...historyContents, turnContent],
    systemInstruction: { parts: [{ text: systemPrompt }] },
    generationConfig: {
      temperature: 0.5,
      responseMimeType: "application/json",
      maxOutputTokens: 1024,
    },
  });

  if (!result.ok) {
    console.error("gemini /turn failed", result.status, result.err);
    return jsonError(502, "AI servisi şu an cevap vermiyor.");
  }

  // Pass through the model's JSON directly — callers parse the structured fields.
  return new Response(result.text || "{}", {
    status: 200,
    headers: JSON_HEADERS,
  });
}

// ---------------------------------------------------------------------------
// /chat
// ---------------------------------------------------------------------------
async function handleChat(req: Request): Promise<Response> {
  let payload: unknown;
  try {
    payload = await req.json();
  } catch {
    return jsonError(400, "Invalid JSON body");
  }

  const messages = (payload as { messages?: unknown }).messages;
  const overrideSystem = (payload as { system?: unknown }).system;
  if (!Array.isArray(messages)) {
    return jsonError(400, "`messages` must be an array");
  }

  const safeMessages = messages
    .slice(-30)
    .filter((m): m is { role: string; content: string } =>
      m !== null &&
      typeof m === "object" &&
      typeof (m as { role?: unknown }).role === "string" &&
      typeof (m as { content?: unknown }).content === "string" &&
      ((m as { role: string }).role === "user" ||
        (m as { role: string }).role === "assistant") &&
      (m as { content: string }).content.length > 0 &&
      (m as { content: string }).content.length < 4000
    );

  const defaultSystem =
    "Sen Türkçe konuşan, çok arkadaş canlısı harika bir İngilizce öğretmenisin. " +
    "Kullanıcıyla sadece İngilizce pratiği yap. " +
    "Kullanıcıya İngilizce cevap ver, gerekirse çok kısa Türkçe destek ver. " +
    "Cevapların kısa (1-3 cümle) ve sohbeti devam ettiren nitelikte olsun.";

  const systemPrompt =
    typeof overrideSystem === "string" &&
      overrideSystem.length > 0 &&
      overrideSystem.length < 4000
      ? overrideSystem
      : defaultSystem;

  const result = await geminiCall({
    contents: toGeminiContents(safeMessages),
    systemInstruction: { parts: [{ text: systemPrompt }] },
    generationConfig: { temperature: 0.7, maxOutputTokens: 512 },
  });

  if (!result.ok) {
    console.error("gemini /chat failed", result.status, result.err);
    return jsonError(502, "AI servisi şu an cevap vermiyor.");
  }

  return jsonOk({ content: result.text });
}

// ---------------------------------------------------------------------------
// /evaluate
// ---------------------------------------------------------------------------
async function handleEvaluate(req: Request): Promise<Response> {
  let payload: unknown;
  try {
    payload = await req.json();
  } catch {
    return jsonError(400, "Invalid JSON body");
  }

  const text = (payload as { text?: unknown }).text;
  if (typeof text !== "string" || text.length === 0 || text.length > 1000) {
    return jsonError(400, "`text` must be a non-empty string under 1000 chars");
  }

  const systemPrompt =
    "You are an English language teacher evaluating a Turkish speaker's English sentence. " +
    "Return ONLY a JSON object with this schema:\n" +
    `{
  "correct": "corrected English sentence (NEVER Turkish; same as input if already perfect)",
  "score": 0-100,
  "explanation": "kısa Türkçe açıklama (1-2 cümle)",
  "grammar_errors": ["specific English mistake 1", "..."],
  "cefr_band": "A1|A2|B1|B2|C1|C2",
  "next_focus": "one short suggestion for the learner's next focus area, Türkçe"
}\n` +
    "If the sentence is already correct, `correct` equals input and score is 85-100. " +
    "`grammar_errors` is [] when none. JSON only, no markdown.";

  const result = await geminiCall({
    contents: [{ role: "user", parts: [{ text }] }],
    systemInstruction: { parts: [{ text: systemPrompt }] },
    generationConfig: {
      temperature: 0.3,
      responseMimeType: "application/json",
      maxOutputTokens: 512,
    },
  });

  if (!result.ok) {
    console.error("gemini /evaluate failed", result.status, result.err);
    return jsonError(502, "AI servisi şu an cevap vermiyor.");
  }

  return new Response(result.text || "{}", {
    status: 200,
    headers: JSON_HEADERS,
  });
}

// ---------------------------------------------------------------------------
// /transcribe — Gemini multimodal STT. Returns { text }.
// Kept for callers that want STT without a full turn cycle.
// ---------------------------------------------------------------------------
async function handleTranscribe(req: Request): Promise<Response> {
  let form: FormData;
  try {
    form = await req.formData();
  } catch {
    return jsonError(400, "Expected multipart/form-data");
  }

  const file = form.get("file");
  if (!(file instanceof File)) {
    return jsonError(400, "`file` field is required");
  }
  if (file.size === 0) return jsonError(400, "Empty audio file");
  if (file.size > 18 * 1024 * 1024) {
    return jsonError(413, "Audio file too large (max 18MB inline)");
  }

  const lang = form.get("language");
  const safeLang = (typeof lang === "string" &&
      /^[a-z]{2}(-[A-Z]{2})?$/.test(lang))
    ? lang.slice(0, 2)
    : "en";

  const prompt =
    `Transcribe the audio. The speaker is using ${safeLang}. ` +
    "Return ONLY the transcription text, no quotes, no markdown, no commentary.";

  const audioBase64 = await fileToBase64(file);
  const mime = mimeFor(file);

  const result = await geminiCall({
    contents: [
      {
        role: "user",
        parts: [
          { inline_data: { mime_type: mime, data: audioBase64 } },
          { text: prompt },
        ],
      },
    ],
    generationConfig: { temperature: 0.0, maxOutputTokens: 512 },
  });

  if (!result.ok) {
    console.error("gemini /transcribe failed", result.status, result.err);
    return jsonError(502, "Ses tanıma başarısız.");
  }

  return jsonOk({ text: result.text });
}

// ---------------------------------------------------------------------------
// /enrich — IPA + example for a single word.
// ---------------------------------------------------------------------------
async function handleEnrich(req: Request): Promise<Response> {
  let payload: unknown;
  try {
    payload = await req.json();
  } catch {
    return jsonError(400, "Invalid JSON body");
  }

  const word = (payload as { word?: unknown }).word;
  const lang = (payload as { target_language?: unknown }).target_language;
  if (typeof word !== "string" || word.length === 0 || word.length > 60) {
    return jsonError(400, "`word` must be 1–60 chars");
  }
  const safeLang =
    typeof lang === "string" && lang.length > 0 && lang.length < 6
      ? lang
      : "en";

  const systemPrompt =
    "You enrich vocabulary cards for language learners. " +
    `Return JSON ONLY: {"ipa": string, "example": string} for the given ${safeLang} word. ` +
    "IPA must be standard International Phonetic Alphabet, slashes optional. " +
    "Example must be a single short natural sentence using the word, suitable for an A2/B1 learner. " +
    "No extra text, no markdown.";

  const result = await geminiCall({
    contents: [{ role: "user", parts: [{ text: word }] }],
    systemInstruction: { parts: [{ text: systemPrompt }] },
    generationConfig: {
      temperature: 0.2,
      responseMimeType: "application/json",
      maxOutputTokens: 256,
    },
  });

  if (!result.ok) {
    console.error("gemini /enrich failed", result.status, result.err);
    return jsonError(502, "Zenginleştirme servisi şu an cevap vermiyor.");
  }

  return new Response(result.text || "{}", {
    status: 200,
    headers: JSON_HEADERS,
  });
}

// ---------------------------------------------------------------------------
// /generate-scenario — produce a structured role-play scenario from a
// free-form user description.
// ---------------------------------------------------------------------------
async function handleGenerateScenario(req: Request): Promise<Response> {
  let payload: unknown;
  try {
    payload = await req.json();
  } catch {
    return jsonError(400, "Invalid JSON body");
  }

  const body = payload as Record<string, unknown>;
  const description = (body.description ?? "").toString().trim();
  const category = (body.category ?? "other").toString();
  const difficulty = (body.difficulty ?? "medium").toString();
  const userLevel = (body.user_level ?? "A2").toString();
  const targetLanguage = (body.target_language ?? "en").toString();

  if (description.length === 0 || description.length > 300) {
    return jsonError(400, "`description` must be 1–300 chars");
  }
  const validDifficulties = ["easy", "medium", "hard"];
  if (!validDifficulties.includes(difficulty)) {
    return jsonError(400, "`difficulty` must be easy|medium|hard");
  }

  const systemPrompt =
    "You design realistic role-play scenarios for language learners. " +
    `The learner is studying ${targetLanguage} at CEFR ${userLevel} level. ` +
    "Output JSON ONLY with this exact schema:\n" +
    `{
  "title": "short English title (max 40 chars)",
  "title_tr": "short Turkish title (max 40 chars)",
  "setting": "1-2 sentence English description of the scene",
  "ai_role": "the AI character's role and personality",
  "user_role": "the learner's role in the scenario",
  "starter_line": "the AI's opening line (1-2 sentences, in target language)",
  "key_phrases": ["3-6 useful phrases the learner may use"],
  "objectives": ["2-4 short conversational goals for the learner"],
  "estimated_turns": 6,
  "icon_code": "one of: local_cafe_outlined, work_outline, medical_services_outlined, people_alt_outlined, flight_takeoff_outlined, restaurant_outlined, school_outlined, directions_car_outlined, hotel_outlined, shopping_cart_outlined, phone_outlined",
  "system_prompt": "instructions an LLM should follow to play the ai_role for this scenario; 3-6 sentences"
}\n` +
    `Difficulty is ${difficulty}: easy=simple vocabulary, hard=advanced idiomatic. ` +
    "Match the difficulty in the system_prompt. No markdown, no commentary, JSON only.";

  const userMsg = `Category: ${category}\nDescription: ${description}`;

  const result = await geminiCall({
    contents: [{ role: "user", parts: [{ text: userMsg }] }],
    systemInstruction: { parts: [{ text: systemPrompt }] },
    generationConfig: {
      temperature: 0.6,
      responseMimeType: "application/json",
      maxOutputTokens: 1024,
    },
  });

  if (!result.ok) {
    console.error("gemini /generate-scenario failed", result.status, result.err);
    return jsonError(502, "Senaryo üretim servisi şu an cevap vermiyor.");
  }

  return new Response(result.text || "{}", {
    status: 200,
    headers: JSON_HEADERS,
  });
}
