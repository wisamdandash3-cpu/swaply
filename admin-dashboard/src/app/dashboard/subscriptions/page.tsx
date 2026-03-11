import { createAdminClient } from '@/lib/supabase';
import Link from 'next/link';

export default async function SubscriptionsPage() {
  const admin = createAdminClient();
  const { data: subs } = await admin
    .from('subscriptions')
    .select('id, user_id, is_active, product_id, platform, expires_at, created_at')
    .order('created_at', { ascending: false });

  const list = subs || [];

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold text-slate-800">الاشتراكات</h1>
      <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table className="w-full">
          <thead>
            <tr className="border-b border-slate-200 bg-slate-50">
              <th className="px-4 py-3 text-right text-sm font-medium text-slate-700">المستخدم</th>
              <th className="px-4 py-3 text-right text-sm font-medium text-slate-700">المنتج</th>
              <th className="px-4 py-3 text-right text-sm font-medium text-slate-700">المنصة</th>
              <th className="px-4 py-3 text-right text-sm font-medium text-slate-700">نشط</th>
              <th className="px-4 py-3 text-right text-sm font-medium text-slate-700">انتهاء</th>
              <th className="px-4 py-3 text-right text-sm font-medium text-slate-700">التاريخ</th>
            </tr>
          </thead>
          <tbody>
            {list.map((s) => (
              <tr key={s.id} className="border-b border-slate-100">
                <td className="px-4 py-3">
                  <Link
                    href={`/dashboard/users/${s.user_id}`}
                    className="text-sm font-medium text-emerald-700 hover:underline"
                  >
                    {s.user_id.slice(0, 8)}...
                  </Link>
                </td>
                <td className="px-4 py-3 text-sm text-slate-800">{s.product_id || '-'}</td>
                <td className="px-4 py-3 text-sm text-slate-800">{s.platform || '-'}</td>
                <td className="px-4 py-3">
                  <span className={`inline-flex rounded px-2 py-0.5 text-xs font-medium ${
                    s.is_active ? 'bg-emerald-100 text-emerald-800' : 'bg-slate-100 text-slate-600'
                  }`}>
                    {s.is_active ? 'نشط' : 'منتهي'}
                  </span>
                </td>
                <td className="px-4 py-3 text-sm text-slate-700">
                  {s.expires_at ? new Date(s.expires_at).toLocaleDateString('ar') : '-'}
                </td>
                <td className="px-4 py-3 text-sm text-slate-500">
                  {new Date(s.created_at).toLocaleDateString('ar')}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {list.length === 0 && (
          <div className="p-8 text-center text-slate-500">لا توجد اشتراكات</div>
        )}
      </div>
    </div>
  );
}
