import { createAdminClient } from '@/lib/supabase';
import UsersTable from './UsersTable';

export default async function UsersPage() {
  const admin = createAdminClient();
  const [usersRes, bannedRes, profilesRes, fieldsRes] = await Promise.all([
    admin.auth.admin.listUsers({ perPage: 100 }),
    admin.from('admin_banned_users').select('user_id'),
    admin.from('profiles').select('user_id, city, country'),
    admin.from('user_profile_fields').select('user_id, field_key, value').in('field_key', ['name', 'selfie_verification_status']),
  ]);

  const users = usersRes.data?.users || [];
  const bannedIds = new Set((bannedRes.data || []).map((b) => b.user_id));
  const profilesByUser = new Map<string, { city?: string; country?: string }>();
  for (const p of profilesRes.data || []) {
    profilesByUser.set(p.user_id, { city: p.city ?? undefined, country: p.country ?? undefined });
  }
  const fieldsByUser = new Map<string, { name?: string; verification?: string }>();
  for (const f of fieldsRes.data || []) {
    const u = fieldsByUser.get(f.user_id) || {};
    if (f.field_key === 'name') u.name = f.value || undefined;
    if (f.field_key === 'selfie_verification_status') u.verification = f.value || undefined;
    fieldsByUser.set(f.user_id, u);
  }

  const list = users.map((u) => {
    const prof = profilesByUser.get(u.id);
    const fields = fieldsByUser.get(u.id);
    return {
      id: u.id,
      email: u.email ?? '-',
      createdAt: u.created_at,
      banned: bannedIds.has(u.id),
      name: fields?.name,
      city: prof?.city,
      verificationStatus: fields?.verification,
    };
  });

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold text-slate-800">المستخدمون</h1>
      <UsersTable users={list} />
    </div>
  );
}
