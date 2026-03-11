'use client';

import { useState } from 'react';
import Link from 'next/link';

type User = {
  id: string;
  email: string;
  createdAt: string;
  banned: boolean;
  name?: string;
  city?: string;
  verificationStatus?: string;
};

export default function UsersTable({ users }: { users: User[] }) {
  const [list, setList] = useState(users);
  const [banning, setBanning] = useState<string | null>(null);
  const [reason, setReason] = useState('');
  const [showBanModal, setShowBanModal] = useState<{ userId: string; email: string } | null>(null);

  async function handleBan(userId: string) {
    setBanning(userId);
    try {
      const res = await fetch('/api/banned', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId, reason }),
      });
      if (!res.ok) {
        const d = await res.json();
        alert(d.error || 'فشل الحظر');
        return;
      }
      setList((prev) => prev.map((u) => (u.id === userId ? { ...u, banned: true } : u)));
      setShowBanModal(null);
      setReason('');
    } finally {
      setBanning(null);
    }
  }

  async function handleUnban(userId: string) {
    setBanning(userId);
    try {
      const res = await fetch(`/api/banned?userId=${userId}`, { method: 'DELETE' });
      if (!res.ok) {
        const d = await res.json();
        alert(d.error || 'فشل إلغاء الحظر');
        return;
      }
      setList((prev) => prev.map((u) => (u.id === userId ? { ...u, banned: false } : u)));
    } finally {
      setBanning(null);
    }
  }

  return (
    <>
      <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white">
        <table className="w-full">
          <thead>
            <tr className="border-b border-slate-200 bg-slate-50">
              <th className="px-4 py-3 text-right text-sm font-medium text-slate-700">البريد</th>
              <th className="px-4 py-3 text-right text-sm font-medium text-slate-700">الاسم</th>
              <th className="px-4 py-3 text-right text-sm font-medium text-slate-700">المدينة</th>
              <th className="px-4 py-3 text-right text-sm font-medium text-slate-700">التوثيق</th>
              <th className="px-4 py-3 text-right text-sm font-medium text-slate-700">التاريخ</th>
              <th className="px-4 py-3 text-right text-sm font-medium text-slate-700">الحساب</th>
              <th className="px-4 py-3 text-right text-sm font-medium text-slate-700">الإجراءات</th>
            </tr>
          </thead>
          <tbody>
            {list.map((u) => (
              <tr key={u.id} className="border-b border-slate-100">
                <td className="px-4 py-3 text-sm font-medium text-slate-800" dir="ltr">{u.email}</td>
                <td className="px-4 py-3 text-sm text-slate-800">{u.name || '-'}</td>
                <td className="px-4 py-3 text-sm text-slate-800">{u.city || '-'}</td>
                <td className="px-4 py-3">
                  <span className={`inline-flex rounded px-2 py-0.5 text-xs font-medium ${
                    u.verificationStatus === 'verified' ? 'bg-emerald-100 text-emerald-800' :
                    u.verificationStatus === 'submitted' ? 'bg-amber-100 text-amber-800' :
                    'bg-slate-100 text-slate-700'
                  }`}>
                    {u.verificationStatus === 'verified' ? 'موثق' : u.verificationStatus === 'submitted' ? 'معلق' : '-'}
                  </span>
                </td>
                <td className="px-4 py-3 text-sm text-slate-700">
                  {new Date(u.createdAt).toLocaleDateString('ar')}
                </td>
                <td className="px-4 py-3">
                  <Link
                    href={`/dashboard/users/${u.id}`}
                    className="rounded bg-emerald-100 px-3 py-1 text-sm font-medium text-emerald-800 hover:bg-emerald-200"
                  >
                    عرض الحساب
                  </Link>
                </td>
                <td className="px-4 py-3">
                  {u.banned ? (
                    <button
                      onClick={() => handleUnban(u.id)}
                      disabled={!!banning}
                      className="rounded bg-amber-100 px-3 py-1 text-sm text-amber-800 hover:bg-amber-200 disabled:opacity-50"
                    >
                      إلغاء الحظر
                    </button>
                  ) : (
                    <button
                      onClick={() => setShowBanModal({ userId: u.id, email: u.email })}
                      disabled={!!banning}
                      className="rounded bg-red-100 px-3 py-1 text-sm text-red-800 hover:bg-red-200 disabled:opacity-50"
                    >
                      حظر
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {showBanModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="w-full max-w-md rounded-xl bg-white p-6">
            <h3 className="mb-4 font-bold">حظر المستخدم</h3>
            <p className="mb-2 text-sm text-slate-600">{showBanModal.email}</p>
            <input
              type="text"
              placeholder="سبب الحظر (اختياري)"
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              className="mb-4 w-full rounded border px-3 py-2"
            />
            <div className="flex gap-2">
              <button
                onClick={() => handleBan(showBanModal.userId)}
                disabled={!!banning}
                className="rounded bg-red-600 px-4 py-2 text-white hover:bg-red-700 disabled:opacity-50"
              >
                تأكيد الحظر
              </button>
              <button
                onClick={() => { setShowBanModal(null); setReason(''); }}
                className="rounded bg-slate-200 px-4 py-2 hover:bg-slate-300"
              >
                إلغاء
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
