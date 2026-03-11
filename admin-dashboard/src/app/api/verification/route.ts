import { createAdminClient } from '@/lib/supabase';
import { NextResponse } from 'next/server';

export async function GET() {
  try {
    const admin = createAdminClient();
    const { data, error } = await admin
      .from('user_profile_fields')
      .select('user_id, value, updated_at')
      .eq('field_key', 'selfie_verification_status')
      .in('value', ['submitted', 'verified']);

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    const list = (data || []).map((r) => ({
      userId: r.user_id,
      status: r.value,
      updatedAt: r.updated_at,
    }));

    return NextResponse.json({ verifications: list });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}

export async function PATCH(request: Request) {
  try {
    const body = await request.json();
    const { userId, status } = body as { userId: string; status: 'verified' | 'rejected' };

    if (!userId || !status) {
      return NextResponse.json({ error: 'userId and status required' }, { status: 400 });
    }

    const admin = createAdminClient();
    const { error } = await admin
      .from('user_profile_fields')
      .upsert(
        {
          user_id: userId,
          field_key: 'selfie_verification_status',
          value: status,
          visibility: 'hidden',
          updated_at: new Date().toISOString(),
        },
        { onConflict: 'user_id,field_key' }
      );

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ success: true });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}
