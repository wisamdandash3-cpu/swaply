import { createAdminClient } from '@/lib/supabase';
import Link from 'next/link';

export default async function WalletPage() {
  const admin = createAdminClient();
  const { data: wallets } = await admin
    .from('user_wallet')
    .select('user_id, roses_balance, rings_balance, coffee_balance, created_at, updated_at')
    .order('roses_balance', { ascending: false });

  const list = wallets || [];
  const totalRoses = list.reduce((s, w) => s + (w.roses_balance ?? 0), 0);
  const totalRings = list.reduce((s, w) => s + (w.rings_balance ?? 0), 0);
  const totalCoffee = list.reduce((s, w) => s + (w.coffee_balance ?? 0), 0);

  return (
    <div>
      <h1 className="mb-6 text-2xl font-bold text-slate-800">الرصيد</h1>
      <div className="mb-8 grid gap-4 sm:grid-cols-3">
        <div className="rounded-xl border border-pink-200 bg-pink-50 p-4">
          <p className="text-sm text-pink-700">إجمالي الورود</p>
          <p className="mt-2 text-2xl font-bold text-pink-800">{totalRoses}</p>
        </div>
        <div className="rounded-xl border border-amber-200 bg-amber-50 p-4">
          <p className="text-sm text-amber-700">إجمالي الخواتم</p>
          <p className="mt-2 text-2xl font-bold text-amber-800">{totalRings}</p>
        </div>
        <div className="rounded-xl border border-orange-200 bg-orange-50 p-4">
          <p className="text-sm text-orange-700">إجمالي القهوة</p>
          <p className="mt-2 text-2xl font-bold text-orange-800">{totalCoffee}</p>
        </div>
      </div>
      <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table className="w-full">
          <thead>
            <tr className="border-b border-slate-200 bg-slate-50">
              <th className="px-4 py-3 text-right text-sm font-medium text-slate-700">المستخدم</th>
              <th className="px-4 py-3 text-right text-sm font-medium text-slate-700">ورود</th>
              <th className="px-4 py-3 text-right text-sm font-medium text-slate-700">خواتم</th>
              <th className="px-4 py-3 text-right text-sm font-medium text-slate-700">قهوة</th>
            </tr>
          </thead>
          <tbody>
            {list.map((w) => (
              <tr key={w.user_id} className="border-b border-slate-100">
                <td className="px-4 py-3">
                  <Link
                    href={`/dashboard/users/${w.user_id}`}
                    className="text-sm font-medium text-emerald-700 hover:underline"
                  >
                    {w.user_id.slice(0, 8)}...
                  </Link>
                </td>
                <td className="px-4 py-3 text-sm font-medium text-slate-800">{w.roses_balance ?? 0}</td>
                <td className="px-4 py-3 text-sm font-medium text-slate-800">{w.rings_balance ?? 0}</td>
                <td className="px-4 py-3 text-sm font-medium text-slate-800">{w.coffee_balance ?? 0}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {list.length === 0 && (
          <div className="p-8 text-center text-slate-500">لا توجد حسابات رصيد</div>
        )}
      </div>
    </div>
  );
}
