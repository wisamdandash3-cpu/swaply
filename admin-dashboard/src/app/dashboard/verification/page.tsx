import { createAdminClient } from '@/lib/supabase';
import VerificationTable from './VerificationTable';

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const BUCKET = 'profile-photos';

export default async function VerificationPage() {
  const admin = createAdminClient();
  const { data } = await admin
    .from('user_profile_fields')
    .select('user_id, value, updated_at')
    .eq('field_key', 'selfie_verification_status')
    .in('value', ['submitted', 'verified']);

  const userIds = (data || []).map((r) => r.user_id);
  const profilePhotosByUser = new Map<string, string[]>();

  if (userIds.length > 0) {
    const { data: answers } = await admin
      .from('profile_answers')
      .select('profile_id, content')
      .in('profile_id', userIds)
      .eq('item_type', 'image')
      .not('content', 'is', null)
      .order('sort_order', { ascending: true });

    if (answers) {
      for (const row of answers) {
        const url = row.content?.trim();
        if (!url) continue;
        const arr = profilePhotosByUser.get(row.profile_id) ?? [];
        if (arr.length < 6) arr.push(url);
        profilePhotosByUser.set(row.profile_id, arr);
      }
    }
  }

  const list = (data || []).map((r) => ({
    userId: r.user_id,
    status: r.value,
    updatedAt: r.updated_at,
    selfieUrl: `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${r.user_id}/verification_selfie.jpg`,
    videoUrl: `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${r.user_id}/verification_video.mp4`,
    profilePhotoUrls: profilePhotosByUser.get(r.user_id) ?? [],
  }));

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold text-slate-800">موافقات التوثيق</h1>
      <VerificationTable verifications={list} />
    </div>
  );
}
