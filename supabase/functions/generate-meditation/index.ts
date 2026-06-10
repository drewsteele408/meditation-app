import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { status: 200, headers: corsHeaders });
  }

  // SEC-01 — JWT Verification
  const authHeader = req.headers.get('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return new Response('Unauthorized', { status: 401, headers: corsHeaders });
  }
  const token = authHeader.slice(7);

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const supabase = createClient(supabaseUrl, serviceRoleKey);

  const { data: { user }, error: authError } = await supabase.auth.getUser(token);
  if (authError || !user) {
    return new Response('Unauthorized', { status: 401, headers: corsHeaders });
  }
  const userId = user.id;

  // SEC-02 — Request Body Validation
  let prompt: string;
  let durationMinutes: number = 10;

  try {
    const body = await req.json();
    prompt = body.prompt;
    if (typeof body.durationMinutes === 'number') {
      durationMinutes = body.durationMinutes;
    }
  } catch {
    return new Response(
      'prompt is required and must be a non-empty string under 1000 characters',
      { status: 400, headers: corsHeaders },
    );
  }

  if (!prompt || typeof prompt !== 'string' || prompt.trim().length === 0 || prompt.length > 1000) {
    return new Response(
      'prompt is required and must be a non-empty string under 1000 characters',
      { status: 400, headers: corsHeaders },
    );
  }

  // SEC-03 — Rate Limiting
  const { data: counter, error: fetchError } = await supabase
    .from('usage_counters')
    .select('id, request_count, window_start')
    .eq('user_id', userId)
    .maybeSingle();

  if (fetchError) {
    return new Response('Service unavailable', { status: 503, headers: corsHeaders });
  }

  const now = new Date();
  const windowDurationMs = 24 * 60 * 60 * 1000;

  if (!counter) {
    const { error: insertError } = await supabase
      .from('usage_counters')
      .insert({ user_id: userId, request_count: 1, window_start: now.toISOString() });

    if (insertError) {
      return new Response('Service unavailable', { status: 503, headers: corsHeaders });
    }
  } else {
    const windowStart = new Date(counter.window_start);
    const isWindowExpired = now.getTime() - windowStart.getTime() > windowDurationMs;

    if (isWindowExpired) {
      const { error: resetError } = await supabase
        .from('usage_counters')
        .update({ request_count: 1, window_start: now.toISOString() })
        .eq('id', counter.id);

      if (resetError) {
        return new Response('Service unavailable', { status: 503, headers: corsHeaders });
      }
    } else {
      if (counter.request_count >= 20) {
        return new Response('Rate limit exceeded. Try again later.', {
          status: 429,
          headers: corsHeaders,
        });
      }

      const { error: incrementError } = await supabase
        .from('usage_counters')
        .update({ request_count: counter.request_count + 1 })
        .eq('id', counter.id);

      if (incrementError) {
        return new Response('Service unavailable', { status: 503, headers: corsHeaders });
      }
    }
  }

  // SEC-04 — Gemini 1.5 Flash
  const geminiApiKey = Deno.env.get('GEMINI_API_KEY');
  const geminiUrl =
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${geminiApiKey}`;

  const systemInstruction = `You are a calm and experienced meditation guide. Write a guided meditation script in plain prose — no headings, no bullet points, no markdown. The script should be soothing, present-tense, and spoken directly to the listener. Duration: approximately ${durationMinutes} minutes.`;

  const geminiPayload = {
    system_instruction: {
      parts: [{ text: systemInstruction }],
    },
    contents: [
      {
        role: 'user',
        parts: [{ text: prompt }],
      },
    ],
  };

  const geminiRes = await fetch(geminiUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(geminiPayload),
  });

  if (!geminiRes.ok) {
    return new Response('Meditation script generation failed. Please try again later.', {
      status: geminiRes.status >= 500 ? 502 : geminiRes.status,
      headers: corsHeaders,
    });
  }

  const geminiData = await geminiRes.json();
  const script: string = geminiData?.candidates?.[0]?.content?.parts?.[0]?.text;

  if (!script) {
    return new Response('Meditation script generation failed. Please try again later.', {
      status: 502,
      headers: corsHeaders,
    });
  }

  // SEC-05 — ElevenLabs TTS
  const elevenLabsApiKey = Deno.env.get('ELEVENLABS_API_KEY');
  const voiceId = Deno.env.get('ELEVENLABS_VOICE_ID');
  const ttsUrl = `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`;

  const ttsRes = await fetch(ttsUrl, {
    method: 'POST',
    headers: {
      'xi-api-key': elevenLabsApiKey!,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      text: script,
      model_id: 'eleven_monolingual_v1',
    }),
  });

  if (!ttsRes.ok) {
    return new Response('Audio generation failed. Please try again later.', {
      status: ttsRes.status >= 500 ? 502 : ttsRes.status,
      headers: corsHeaders,
    });
  }

  const audioBuffer = await ttsRes.arrayBuffer();
  const audioBase64 = btoa(String.fromCharCode(...new Uint8Array(audioBuffer)));

  return new Response(
    JSON.stringify({ script, audioBase64 }),
    {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    },
  );
});
