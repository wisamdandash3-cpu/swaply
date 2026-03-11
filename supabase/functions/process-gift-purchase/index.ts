/**
 * Supabase Edge Function: معالجة شراء الهدايا (ورود، خواتم، قهوة) وإضافة الرصيد للمحفظة.
 * يُستدعى بعد التحقق من الإيصال مع Apple/Google. الاستدعاء من السيرفر أو من التطبيق مع receipt.
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

/** خريطة منتجات الهدايا: معرف المنتج → الزيادة في الرصيد */
const GIFT_PRODUCTS: Record<string, { roses: number; rings: number; coffee: number }> = {
  roses_1: { roses: 1, rings: 0, coffee: 0 },
  roses_10: { roses: 10, rings: 0, coffee: 0 },
  roses_25: { roses: 25, rings: 0, coffee: 0 },
  roses_50: { roses: 50, rings: 0, coffee: 0 },
  roses_100: { roses: 100, rings: 0, coffee: 0 },
  rings_1: { roses: 0, rings: 1, coffee: 0 },
  rings_5: { roses: 0, rings: 5, coffee: 0 },
  rings_10: { roses: 0, rings: 10, coffee: 0 },
  coffee_1: { roses: 0, rings: 0, coffee: 1 },
  coffee_5: { roses: 0, rings: 0, coffee: 5 },
  coffee_10: { roses: 0, rings: 0, coffee: 10 },
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
    const body = (await req.json()) as { user_id: string; product_sku: string; quantity?: number };
    const { user_id, product_sku, quantity = 1 } = body;

    if (!user_id || !product_sku) {
      return new Response(
        JSON.stringify({ error: 'Missing user_id or product_sku' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 },
      );
    }

    const delta = GIFT_PRODUCTS[product_sku];
    if (!delta) {
      return new Response(
        JSON.stringify({ error: 'Unknown product_sku' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 },
      );
    }

    const q = Math.max(1, Math.floor(quantity));
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey, { auth: { persistSession: false } });

    const { data, error } = await supabase.rpc('add_wallet_balance', {
      p_user_id: user_id,
      p_roses_delta: delta.roses * q,
      p_rings_delta: delta.rings * q,
      p_coffee_delta: delta.coffee * q,
    });

    if (error) {
      throw error;
    }

    return new Response(
      JSON.stringify({ ok: true, added: data }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 500 },
    );
  }
});
