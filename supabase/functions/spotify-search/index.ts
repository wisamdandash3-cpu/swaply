/**
 * Supabase Edge Function: Spotify Search
 * 
 * يبحث في Spotify عن الأغاني باستخدام Web API.
 * 
 * إعداد Secrets في Supabase Dashboard:
 * Project Settings → Edge Functions → Secrets
 * - SPOTIFY_CLIENT_ID
 * - SPOTIFY_CLIENT_SECRET
 */

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { query } = (await req.json()) as { query?: string };
    const q = typeof query === 'string' ? query.trim() : '';
    if (!q || q.length < 1) {
      return new Response(
        JSON.stringify({ tracks: [] }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 },
      );
    }

    const clientId = Deno.env.get('SPOTIFY_CLIENT_ID');
    const clientSecret = Deno.env.get('SPOTIFY_CLIENT_SECRET');
    if (!clientId || !clientSecret) {
      return new Response(
        JSON.stringify({ error: 'Spotify credentials not configured' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 },
      );
    }

    // Client Credentials: get access token
    const tokenRes = await fetch('https://accounts.spotify.com/api/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        Authorization: `Basic ${btoa(`${clientId}:${clientSecret}`)}`,
      },
      body: 'grant_type=client_credentials',
    });
    if (!tokenRes.ok) {
      const err = await tokenRes.text();
      console.error('Spotify token error:', err);
      return new Response(
        JSON.stringify({ error: 'Failed to get Spotify token', details: err }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 502 },
      );
    }
    const tokenData = await tokenRes.json();
    const accessToken = tokenData.access_token as string;
    if (!accessToken) {
      return new Response(
        JSON.stringify({ error: 'No access token from Spotify' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 502 },
      );
    }

    // Search tracks
    const searchRes = await fetch(
      `https://api.spotify.com/v1/search?q=${encodeURIComponent(q)}&type=track&limit=20`,
      {
        headers: { Authorization: `Bearer ${accessToken}` },
      },
    );
    if (!searchRes.ok) {
      const err = await searchRes.text();
      console.error('Spotify search error:', err);
      return new Response(
        JSON.stringify({ error: 'Spotify search failed', details: err }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 502 },
      );
    }
    const searchData = await searchRes.json();
    const items = (searchData.tracks?.items ?? []) as Array<{
      id: string;
      name: string;
      external_urls?: { spotify?: string };
      artists?: Array<{ name: string }>;
      album?: { images?: Array<{ url: string }> };
    }>;

    const tracks = items.map((t) => ({
      id: t.id,
      name: t.name,
      url: t.external_urls?.spotify ?? `https://open.spotify.com/track/${t.id}`,
      artist: t.artists?.map((a) => a.name).join(', ') ?? '',
      imageUrl: t.album?.images?.[0]?.url ?? null,
    }));

    return new Response(JSON.stringify({ tracks }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (e) {
    console.error('spotify-search error:', e);
    return new Response(
      JSON.stringify({ error: 'Internal server error', message: String(e) }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 },
    );
  }
});
