import { createAdminClient } from '@/lib/supabase';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import SelfieImage from './SelfieImage';
import BanButton from './BanButton';

const SUPABASE_URL = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const BUCKET = 'profile-photos';

const fieldLabels: Record<string, string> = {
  name: 'الاسم',
  age: 'العمر',
  gender: 'الجنس',
  pronouns: 'الضمائر',
  work: 'العمل',
  job_title: 'المسمى الوظيفي',
  college_or_university: 'الجامعة',
  education_level: 'مستوى التعليم',
  languages_spoken: 'اللغات',
  height: 'الطول',
  location: 'الموقع',
  home_town: 'مسقط الرأس',
  children: 'الأطفال',
  family_plans: 'خطط العائلة',
  selfie_verification_status: 'حالة التوثيق',
  temporary_pause: 'الإيقاف المؤقت',
  last_active_at: 'آخر نشاط',
  match_note: 'ملاحظة المطابقة',
  dating_intentions: 'نية المواعدة',
  relationship_type: 'نوع العلاقة',
};

export default async function UserDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const admin = createAdminClient();

  const [authRes, profileRes, fieldsRes, answersRes, bannedRes] = await Promise.all([
    admin.auth.admin.getUserById(id),
    admin.from('profiles').select('*').eq('user_id', id).maybeSingle(),
    admin.from('user_profile_fields').select('field_key, value').eq('user_id', id),
    admin.from('profile_answers').select('id, item_type, content, sort_order, created_at').eq('profile_id', id).order('sort_order'),
    admin.from('admin_banned_users').select('reason, created_at').eq('user_id', id).maybeSingle(),
  ]);

  const authUser = authRes.data?.user;
  if (!authUser) notFound();

  const profile = profileRes.data;
  const fields = (fieldsRes.data || []).reduce((acc, f) => {
    acc[f.field_key] = f.value ?? '';
    return acc;
  }, {} as Record<string, string>);
  const answers = answersRes.data || [];
  const banned = bannedRes.data;

  const verificationStatus = fields.selfie_verification_status;
  const selfieUrl = `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${id}/verification_selfie.jpg`;
  const videoUrl = `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}/${id}/verification_video.mp4`;

  return (
    <div className="space-y-8">
      <div className="flex items-center gap-4">
        <Link
          href="/dashboard/users"
          className="rounded-lg border border-slate-200 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
        >
          ← المستخدمون
        </Link>
        <h1 className="text-2xl font-bold text-slate-800">حساب المستخدم</h1>
      </div>

      {banned && (
        <div className="rounded-xl border border-red-200 bg-red-50 p-4">
          <p className="font-bold text-red-800">محظور</p>
          <p className="text-sm text-red-700">السبب: {banned.reason || 'غير محدد'}</p>
          <p className="text-xs text-red-600">منذ: {new Date(banned.created_at).toLocaleDateString('ar')}</p>
        </div>
      )}

      <BanButton userId={id} isBanned={!!banned} />

      <div className="grid gap-6 lg:grid-cols-2">
        <section className="rounded-xl border border-slate-200 bg-white p-6">
          <h2 className="mb-4 text-lg font-bold text-slate-800">بيانات الحساب</h2>
          <dl className="space-y-2 text-sm">
            <div>
              <dt className="text-slate-500">البريد</dt>
              <dd className="font-medium text-slate-800" dir="ltr">{authUser.email ?? '-'}</dd>
            </div>
            <div>
              <dt className="text-slate-500">User ID</dt>
              <dd className="font-mono text-xs text-slate-700 break-all">{authUser.id}</dd>
            </div>
            <div>
              <dt className="text-slate-500">تاريخ التسجيل</dt>
              <dd className="text-slate-800">{new Date(authUser.created_at!).toLocaleString('ar')}</dd>
            </div>
          </dl>
        </section>

        {profile && (
          <section className="rounded-xl border border-slate-200 bg-white p-6">
            <h2 className="mb-4 text-lg font-bold text-slate-800">البروفايل (profiles)</h2>
            <dl className="space-y-2 text-sm">
              <div>
                <dt className="text-slate-500">المدينة</dt>
                <dd className="text-slate-800">{profile.city || '-'}</dd>
              </div>
              <div>
                <dt className="text-slate-500">الدولة</dt>
                <dd className="text-slate-800">{profile.country || '-'}</dd>
              </div>
              <div>
                <dt className="text-slate-500">اللغات</dt>
                <dd className="text-slate-800">{Array.isArray(profile.languages) ? profile.languages.join(', ') || '-' : '-'}</dd>
              </div>
              <div>
                <dt className="text-slate-500">الأطفال</dt>
                <dd className="text-slate-800">{profile.children_preference || '-'}</dd>
              </div>
            </dl>
          </section>
        )}

        <section className="rounded-xl border border-slate-200 bg-white p-6 lg:col-span-2">
          <h2 className="mb-4 text-lg font-bold text-slate-800">الحقول (user_profile_fields)</h2>
          <dl className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
            {Object.entries(fields).filter(([, v]) => v).map(([key, value]) => (
              <div key={key}>
                <dt className="text-slate-500">{fieldLabels[key] || key}</dt>
                <dd className="text-slate-800">{value}</dd>
              </div>
            ))}
          </dl>
          {Object.keys(fields).filter(k => fields[k]).length === 0 && (
            <p className="text-slate-500">لا توجد حقول</p>
          )}
        </section>

        {verificationStatus && (
          <section className="rounded-xl border border-slate-200 bg-white p-6">
            <h2 className="mb-4 text-lg font-bold text-slate-800">التوثيق</h2>
            <span className={`inline-flex rounded px-2 py-1 text-sm font-medium ${
              verificationStatus === 'verified' ? 'bg-emerald-100 text-emerald-800' :
              verificationStatus === 'submitted' ? 'bg-amber-100 text-amber-800' :
              'bg-slate-100 text-slate-700'
            }`}>
              {verificationStatus === 'verified' ? 'موثق' : verificationStatus === 'submitted' ? 'معلق' : verificationStatus}
            </span>
            {verificationStatus !== 'rejected' && (
              <div className="mt-3 space-y-3">
                <div>
                  <p className="mb-1 text-xs font-medium text-slate-600">فيديو التوثيق</p>
                  <video src={videoUrl} controls className="max-h-64 w-full rounded-lg border border-slate-200 bg-slate-900 object-contain" />
                </div>
                <div>
                  <p className="mb-1 text-xs font-medium text-slate-600">صورة التوثيق</p>
                  <SelfieImage src={selfieUrl} />
                </div>
              </div>
            )}
          </section>
        )}

        <section className="rounded-xl border border-slate-200 bg-white p-6 lg:col-span-2">
          <h2 className="mb-4 text-lg font-bold text-slate-800">إجابات البروفايل ({answers.length})</h2>
          <div className="space-y-4">
            {answers.map((a) => (
              <div key={a.id} className="rounded-lg border border-slate-100 p-4">
                <span className="text-xs text-slate-500">{a.item_type}</span>
                {a.item_type === 'image' || a.item_type === 'video' ? (
                  <a href={a.content} target="_blank" rel="noreferrer" className="block mt-2 text-sm text-emerald-600 hover:underline break-all">
                    {a.content}
                  </a>
                ) : (
                  <p className="mt-2 text-sm text-slate-800">{a.content}</p>
                )}
                <p className="mt-1 text-xs text-slate-500">ترتيب: {a.sort_order}</p>
              </div>
            ))}
          </div>
          {answers.length === 0 && <p className="text-slate-500">لا توجد إجابات</p>}
        </section>
      </div>
    </div>
  );
}
