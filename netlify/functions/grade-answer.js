const jsonHeaders = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "Content-Type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const clampScore = (value) => {
  const parsed = Number.parseInt(value, 10);
  if (Number.isNaN(parsed)) return 0;
  return Math.max(0, Math.min(100, parsed));
};

const parseModelJson = (content) => {
  const trimmed = String(content || "").trim();
  const unfenced = trimmed
    .replace(/^```(?:json)?/i, "")
    .replace(/```$/i, "")
    .trim();
  return JSON.parse(unfenced);
};

const fail = (message, status = 400) =>
  Response.json(
    { score: 0, feedback: message, improvedAnswer: "" },
    { status, headers: jsonHeaders },
  );

export default async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: jsonHeaders });
  }

  if (req.method !== "POST") {
    return fail("Method not allowed.", 405);
  }

  let payload;
  try {
    payload = await req.json();
  } catch {
    return fail("Request body must be valid JSON.");
  }

  const item = payload?.item || {};
  const userAnswer = String(payload?.userAnswer || "").trim();
  const title = String(item.title || "Practice prompt").slice(0, 160);
  const prompt = String(item.prompt || "").slice(0, 4000);
  const rubric = String(item.rubric || "").slice(0, 3000);

  if (!prompt || !rubric || !userAnswer) {
    return fail("Missing prompt, rubric, or user answer.");
  }

  const baseUrl = (
    Netlify.env.get("OPENAI_BASE_URL") || "https://api.openai.com/v1"
  ).replace(/\/+$/, "");
  const apiKey = Netlify.env.get("OPENAI_API_KEY");
  const model = Netlify.env.get("OPENAI_MODEL") || "gpt-4o-mini";

  const headers = { "Content-Type": "application/json" };
  if (apiKey) headers.Authorization = `Bearer ${apiKey}`;

  const system = [
    "You are a strict but supportive coach for learning AI prompting.",
    "Return only valid JSON with keys: score, feedback, improvedAnswer.",
    "score must be an integer from 0 to 100.",
    "feedback should be concise, specific, and actionable.",
  ].join(" ");

  const user = [
    `Practice title: ${title}`,
    "",
    "Task prompt:",
    prompt,
    "",
    "Rubric:",
    rubric,
    "",
    "Learner answer:",
    userAnswer.slice(0, 6000),
    "",
    "Grade the learner answer using the rubric and provide an improved answer.",
  ].join("\n");

  try {
    const upstream = await fetch(`${baseUrl}/chat/completions`, {
      method: "POST",
      headers,
      body: JSON.stringify({
        model,
        messages: [
          { role: "system", content: system },
          { role: "user", content: user },
        ],
        temperature: 0.2,
        max_tokens: 600,
      }),
    });

    const upstreamText = await upstream.text();
    if (!upstream.ok) {
      console.error("AI grading upstream error", upstream.status, upstreamText);
      return fail(`AI grading request failed (${upstream.status}).`, 502);
    }

    const data = JSON.parse(upstreamText);
    const content = data?.choices?.[0]?.message?.content || "{}";
    const parsed = parseModelJson(content);

    return Response.json(
      {
        score: clampScore(parsed.score),
        feedback: String(parsed.feedback || "").trim(),
        improvedAnswer: String(parsed.improvedAnswer || "").trim(),
      },
      { headers: jsonHeaders },
    );
  } catch (error) {
    return fail(`AI grading service error: ${error.message}`, 500);
  }
};

export const config = {
  path: "/api/grade-answer",
  method: ["POST", "OPTIONS"],
};
