import { createAdminClient } from '@/lib/supabase';
import { NextResponse } from 'next/server';

export async function POST(request: Request) {
  try {
    const body = await request.json();
    const userId = typeof body.userId === 'string' ? body.userId.trim() : '';
    const content = typeof body.content === 'string' ? body.content.trim() : '';
    const complaintId = typeof body.complaintId === 'string' ? body.complaintId.trim() || null : null;

    if (!userId || !content) {
      return NextResponse.json(
        { error: 'معرّف المستخدم ونص الرد مطلوبان' },
        { status: 400 }
      );
    }

    const admin = createAdminClient();
    const { data, error } = await admin
      .from('admin_replies')
      .insert({ user_id: userId, complaint_id: complaintId || null, content })
      .select('id, created_at')
      .single();

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 500 });
    }

    return NextResponse.json({ ok: true, id: data?.id, created_at: data?.created_at });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}
