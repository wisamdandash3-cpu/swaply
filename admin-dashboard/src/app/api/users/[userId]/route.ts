import { createAdminClient } from '@/lib/supabase';
import { NextResponse } from 'next/server';

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ userId: string }> }
) {
  try {
    const { userId } = await params;
    const admin = createAdminClient();

    const [authRes, profileRes, fieldsRes, answersRes, bannedRes] = await Promise.all([
      admin.auth.admin.getUserById(userId),
      admin.from('profiles').select('*').eq('user_id', userId).maybeSingle(),
      admin.from('user_profile_fields').select('field_key, value').eq('user_id', userId),
      admin.from('profile_answers').select('id, item_type, content, sort_order, created_at').eq('profile_id', userId).order('sort_order'),
      admin.from('admin_banned_users').select('reason, created_at').eq('user_id', userId).maybeSingle(),
    ]);

    const authUser = authRes.data?.user;
    if (!authUser) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    const fields: Record<string, string> = {};
    for (const f of fieldsRes.data || []) {
      fields[f.field_key] = f.value ?? '';
    }

    return NextResponse.json({
      user: {
        id: authUser.id,
        email: authUser.email,
        createdAt: authUser.created_at,
      },
      profile: profileRes.data || null,
      fields,
      answers: answersRes.data || [],
      banned: bannedRes.data || null,
    });
  } catch (e) {
    return NextResponse.json({ error: String(e) }, { status: 500 });
  }
}
