/**
 * Supabase Edge Function: استقبال webhook الاشتراكات (Apple/Google) وتحديث جدول subscriptions.
 * يُستدعى من App Store Server Notifications أو Google Real-time developer notifications.
 * التحقق من التوقيع يُضاف حسب وثائق كل منصة.
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 405 },
    );
  }

  try {
    const payload = await req.json() as Record<string, unknown>;

    // استخراج البيانات حسب شكل الـ webhook (Apple / Google / RevenueCat)
    const userId = (payload.user_id ?? payload.subscriber_id ?? payload.app_user_id) as string | undefined;
    const productId = (payload.product_id ?? payload.plan_id ?? payload.entitlement_id) as string | undefined;
    const expiresAtRaw = payload.expiration_at ?? payload.expires_date_ms ?? payload.expires_at;
    const expiresAt = expiresAtRaw
      ? typeof expiresAtRaw === 'number'
        ? new Date(expiresAtRaw).toISOString()
        : String(expiresAtRaw)
      : null;
    const platform = (payload.platform ?? (payload.package_name ? 'android' : 'ios')) as 'ios' | 'android';
    const isActive = expiresAt ? new Date(expiresAt) > new Date() : Boolean(payload.is_active ?? true);

    if (!userId) {
      return new Response(
        JSON.stringify({ error: 'Missing user_id' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 },
      );
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey, { auth: { persistSession: false } });

    const { error } = await supabase
      .from('subscriptions')
      .upsert(
        {
          user_id: userId,
          is_active: isActive,
          product_id: productId ?? null,
          platform,
          expires_at: expiresAt,
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'user_id' },
      );

    if (error) {
      throw error;
    }

    return new Response(
      JSON.stringify({ ok: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 },
    );
  }
});
