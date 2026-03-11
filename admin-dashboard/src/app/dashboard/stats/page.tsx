import { createAdminClient } from '@/lib/supabase';
import Link from 'next/link';

export default async function StatsPage() {
  const admin = createAdminClient();

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const todayIso = today.toISOString();

  const ROSE_CENTS = 99;
  const RING_CENTS = 199;
  const COFFEE_CENTS = 149;

  const [
    usersRes,
    lastActiveRes,
    giftsRes,
    subscriptionsRes,
    walletRes,
  ] = await Promise.all([
    admin.auth.admin.listUsers({ perPage: 100 }),
    admin.from('user_profile_fields').select('user_id').eq('field_key', 'last_active_at').gte('value', todayIso),
    admin.from('profile_likes').select('gift_type').not('gift_type', 'is', null),
    admin.from('subscriptions').select('user_id, is_active, expires_at').eq('is_active', true),
    admin.from('user_wallet').select('roses_balance, rings_balance, coffee_balance'),
  ]);

  const usersCount = usersRes.data?.users?.length ?? 0;
  const dailyActiveCount = new Set((lastActiveRes.data || []).map((r) => r.user_id)).size;
  const gifts = (giftsRes.data || []) as { gift_type: string }[];
  const giftsCount = gifts.length;

  let roseGifts = 0;
  let ringGifts = 0;
  let coffeeGifts = 0;
  for (const g of gifts) {
    const t = (g.gift_type || '').toLowerCase();
    if (t.includes('rose')) roseGifts++;
    else if (t.includes('ring')) ringGifts++;
    else if (t.includes('coffee')) coffeeGifts++;
  }

  const giftRevenueCents = roseGifts * ROSE_CENTS + ringGifts * RING_CENTS + coffeeGifts * COFFEE_CENTS;
  const giftRevenueEur = (giftRevenueCents / 100).toFixed(2);

  const activeSubs = (subscriptionsRes.data || []).length;
  const totalRoses = (walletRes.data || []).reduce((s, w) => s + (w.roses_balance ?? 0), 0);
  const totalRings = (walletRes.data || []).reduce((s, w) => s + (w.rings_balance ?? 0), 0);
  const totalCoffee = (walletRes.data || []).reduce((s, w) => s + (w.coffee_balance ?? 0), 0);

  return (
    <div>
      <h1 className="mb-8 text-2xl font-bold text-slate-800">الإحصائيات</h1>
      <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
        <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <p className="text-sm text-slate-500">المستخدمون (آخر 100)</p>
          <p className="mt-2 text-3xl font-bold text-emerald-600">{usersCount}</p>
        </div>
        <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <p className="text-sm text-slate-500">نشطون اليوم</p>
          <p className="mt-2 text-3xl font-bold text-blue-600">{dailyActiveCount}</p>
          <p className="mt-1 text-xs text-slate-500">مستخدم سجّل نشاطاً اليوم</p>
        </div>
        <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <p className="text-sm text-slate-500">إجمالي الهدايا المرسلة</p>
          <p className="mt-2 text-3xl font-bold text-rose-600">{giftsCount}</p>
        </div>
        <div className="rounded-xl border border-emerald-200 bg-emerald-50 p-6 shadow-sm">
          <p className="text-sm font-medium text-emerald-700">رصيد الربح (من الهدايا)</p>
          <p className="mt-2 text-3xl font-bold text-emerald-800">{giftRevenueEur} €</p>
          <p className="mt-1 text-xs text-emerald-600">إجمالي قيمة الهدايا المرسلة</p>
        </div>
        <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <p className="text-sm text-slate-500">أسعار الهدايا المرسلة</p>
          <p className="mt-2 text-sm font-medium text-slate-800">ورود: {(roseGifts * ROSE_CENTS / 100).toFixed(2)} € ({roseGifts}×{ROSE_CENTS / 100})</p>
          <p className="mt-1 text-sm font-medium text-slate-800">خواتم: {(ringGifts * RING_CENTS / 100).toFixed(2)} € ({ringGifts}×{RING_CENTS / 100})</p>
          <p className="mt-1 text-sm font-medium text-slate-800">قهوة: {(coffeeGifts * COFFEE_CENTS / 100).toFixed(2)} € ({coffeeGifts}×{COFFEE_CENTS / 100})</p>
        </div>
        <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <p className="text-sm text-slate-500">الاشتراكات النشطة</p>
          <p className="mt-2 text-3xl font-bold text-amber-600">{activeSubs}</p>
        </div>
        <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <p className="text-sm text-slate-500">إجمالي الرصيد (ورود)</p>
          <p className="mt-2 text-3xl font-bold text-pink-600">{totalRoses}</p>
        </div>
        <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <p className="text-sm text-slate-500">إجمالي الرصيد (خواتم + قهوة)</p>
          <p className="mt-2 text-lg font-bold text-slate-700">
            خواتم: {totalRings} | قهوة: {totalCoffee}
          </p>
        </div>
      </div>
    </div>
  );
}
