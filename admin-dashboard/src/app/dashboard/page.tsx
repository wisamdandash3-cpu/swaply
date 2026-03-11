import { createAdminClient } from '@/lib/supabase';
import Link from 'next/link';
import { getCountryFlag } from '@/lib/country-flags';

export default async function DashboardPage() {
  const admin = createAdminClient();

  const today = new Date();
  today.setHours(0, 0, 0, 0);
  const todayIso = today.toISOString();

  const ROSE_CENTS = 99;
  const RING_CENTS = 199;
  const COFFEE_CENTS = 149;

  const [
    usersRes,
    verificationRes,
    bannedRes,
    lastActiveRes,
    giftsRes,
    subsRes,
    complaintsRes,
    profilesRes,
    locationFieldsRes,
  ] = await Promise.all([
    admin.auth.admin.listUsers({ perPage: 100 }),
    admin.from('user_profile_fields').select('user_id', { count: 'exact', head: true }).eq('field_key', 'selfie_verification_status').eq('value', 'submitted'),
    admin.from('admin_banned_users').select('id', { count: 'exact', head: true }),
    admin.from('user_profile_fields').select('user_id').eq('field_key', 'last_active_at').gte('value', todayIso),
    admin.from('profile_likes').select('gift_type').not('gift_type', 'is', null),
    admin.from('subscriptions').select('id', { count: 'exact', head: true }).eq('is_active', true),
    admin.from('user_complaints').select('id', { count: 'exact', head: true }),
    admin.from('profiles').select('user_id, country, city'),
    admin.from('user_profile_fields').select('user_id, value').eq('field_key', 'location').not('value', 'is', null),
  ]);

  const userCount = usersRes.data?.users?.length ?? 0;
  const dailyActive = new Set((lastActiveRes.data || []).map((r) => r.user_id)).size;
  const gifts = (giftsRes.data || []) as { gift_type: string }[];
  let giftRevenueCents = 0;
  for (const g of gifts) {
    const t = (g.gift_type || '').toLowerCase();
    if (t.includes('rose')) giftRevenueCents += ROSE_CENTS;
    else if (t.includes('ring')) giftRevenueCents += RING_CENTS;
    else if (t.includes('coffee')) giftRevenueCents += COFFEE_CENTS;
  }
  const giftRevenueEur = (giftRevenueCents / 100).toFixed(2);

  const stats = [
    { label: 'المستخدمون (آخر 100)', value: userCount, href: '/dashboard/users' },
    { label: 'نشطون اليوم', value: dailyActive, href: '/dashboard/stats' },
    { label: 'طلبات توثيق معلقة', value: verificationRes.count ?? 0, href: '/dashboard/verification' },
    { label: 'الهدايا المرسلة', value: gifts.length, href: '/dashboard/stats' },
    { label: 'رصيد الربح (من الهدايا)', value: `${giftRevenueEur} €`, href: '/dashboard/stats' },
    { label: 'الاشتراكات النشطة', value: subsRes.count ?? 0, href: '/dashboard/subscriptions' },
    { label: 'المحظورون', value: bannedRes.count ?? 0, href: '/dashboard/banned' },
    { label: 'الشكاوى', value: complaintsRes.count ?? 0, href: '/dashboard/complaints' },
  ];

  const users = usersRes.data?.users ?? [];
  const profiles = profilesRes.data || [];
  const locationFields = (locationFieldsRes.data || []) as { user_id: string; value: string | null }[];
  const profilesByUser = new Map<string, { country?: string | null; city?: string | null }>();
  for (const p of profiles) {
    profilesByUser.set(p.user_id, { country: p.country, city: p.city });
  }
  const locationByUser = new Map<string, string>();
  for (const row of locationFields) {
    const v = (row.value || '').trim();
    if (v) locationByUser.set(row.user_id, v);
  }
  function inferCountryFromLocation(text: string): string | null {
    const t = text.toLowerCase();
    if (/\busa\b|united states|\bca\b|california|san francisco|new york|texas|florida\b/.test(t)) return 'United States';
    if (/\bgermany\b|deutschland|\bde\b/.test(t)) return 'Germany';
    if (/\buk\b|united kingdom|britain|england\b/.test(t)) return 'United Kingdom';
    if (/\bsaudi|ksa|\bsa\b|السعودية|المملكة\b/.test(t)) return 'Saudi Arabia';
    if (/\buae\b|emirates|الإمارات\b/.test(t)) return 'United Arab Emirates';
    if (/\begypt|مصر\b/.test(t)) return 'Egypt';
    if (/\bjordan|الأردن\b/.test(t)) return 'Jordan';
    if (/\blebanon|لبنان\b/.test(t)) return 'Lebanon';
    if (/\bturkey|تركيا\b/.test(t)) return 'Turkey';
    if (/\bfrance\b|فرنسا\b/.test(t)) return 'France';
    if (/\bcanada\b|كندا\b/.test(t)) return 'Canada';
    return null;
  }
  const countryCounts = new Map<string, number>();
  const regionCounts = new Map<string, number>();
  for (const u of users) {
    const id = u.id;
    const prof = profilesByUser.get(id);
    const locationText = locationByUser.get(id);
    const country = (prof?.country || '').trim() || inferCountryFromLocation(locationText || '') || 'غير محدد';
    const region = (prof?.city || '').trim() || (locationText || '').trim() || 'غير محدد';
    countryCounts.set(country, (countryCounts.get(country) ?? 0) + 1);
    regionCounts.set(region, (regionCounts.get(region) ?? 0) + 1);
  }
  const countriesSorted = [...countryCounts.entries()].sort((a, b) => b[1] - a[1]);
  const regionsSorted = [...regionCounts.entries()].filter(([k]) => k !== 'غير محدد').sort((a, b) => b[1] - a[1]);

  return (
    <div>
      <h1 className="mb-8 text-2xl font-bold text-slate-800">نظرة عامة</h1>
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
        {stats.map((s) => (
          <Link
            key={s.label}
            href={s.href}
            className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm transition hover:shadow-md"
          >
            <p className="text-sm text-slate-500">{s.label}</p>
            <p className="mt-2 text-3xl font-bold text-emerald-600">{s.value}</p>
          </Link>
        ))}
      </div>

      <section className="mt-10">
        <h2 className="mb-4 text-xl font-bold text-slate-800">الدول والمناطق الجغرافية</h2>
        <div className="grid gap-6 md:grid-cols-2">
          <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
            <h3 className="mb-3 text-sm font-semibold uppercase tracking-wide text-slate-500">الدول (حسب البروفايلات)</h3>
            <ul className="space-y-2">
              {countriesSorted.length === 0 ? (
                <li className="text-slate-500">لا توجد بيانات دول</li>
              ) : (
                countriesSorted.map(([country, count]) => (
                  <li key={country} className="flex items-center justify-between rounded-lg border border-slate-100 px-3 py-2">
                    <span className="flex items-center gap-2">
                      <span className="text-2xl" title={country}>{getCountryFlag(country)}</span>
                      <span className="font-medium text-slate-800">{country}</span>
                    </span>
                    <span className="rounded-full bg-emerald-100 px-2 py-0.5 text-sm font-medium text-emerald-700">{count}</span>
                  </li>
                ))
              )}
            </ul>
          </div>
          <div className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
            <h3 className="mb-3 text-sm font-semibold uppercase tracking-wide text-slate-500">المدن / المناطق</h3>
            <ul className="space-y-2">
              {regionsSorted.length === 0 ? (
                <li className="text-slate-500">لا توجد بيانات مدن</li>
              ) : (
                regionsSorted.slice(0, 15).map(([region, count]) => (
                  <li key={region} className="flex items-center justify-between rounded-lg border border-slate-100 px-3 py-2">
                    <span className="font-medium text-slate-800">{region}</span>
                    <span className="rounded-full bg-slate-100 px-2 py-0.5 text-sm font-medium text-slate-700">{count}</span>
                  </li>
                ))
              )}
            </ul>
          </div>
        </div>
      </section>
    </div>
  );
}
