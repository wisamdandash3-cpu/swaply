'use client';

import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { createClient } from '@/lib/supabase-browser';

function LogoutButton() {
  const router = useRouter();

  async function handleLogout() {
    const supabase = createClient();
    await supabase.auth.signOut();
    router.push('/login');
    router.refresh();
  }

  return (
    <button
      onClick={handleLogout}
      className="mt-4 block w-full rounded-lg px-4 py-2 text-right text-sm text-slate-500 hover:bg-slate-100"
    >
      تسجيل الخروج
    </button>
  );
}

const navItems = [
  { href: '/dashboard', label: 'نظرة عامة' },
  { href: '/dashboard/stats', label: 'الإحصائيات' },
  { href: '/dashboard/users', label: 'المستخدمون' },
  { href: '/dashboard/subscriptions', label: 'الاشتراكات' },
  { href: '/dashboard/wallet', label: 'الرصيد' },
  { href: '/dashboard/verification', label: 'موافقات التوثيق' },
  { href: '/dashboard/banned', label: 'المحظورون' },
  { href: '/dashboard/complaints', label: 'الشكاوى' },
];

export default function DashboardNav() {
  const pathname = usePathname();

  return (
    <nav className="space-y-1">
      {navItems.map((item) => (
        <Link
          key={item.href}
          href={item.href}
          className={`block rounded-lg px-4 py-2 text-sm font-medium transition ${
            pathname === item.href
              ? 'bg-emerald-100 text-emerald-800'
              : 'text-slate-600 hover:bg-slate-100'
          }`}
        >
          {item.label}
        </Link>
      ))}
      <LogoutButton />
    </nav>
  );
}
