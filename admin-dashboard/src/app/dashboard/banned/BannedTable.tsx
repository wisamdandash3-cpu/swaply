'use client';

import { useState } from 'react';

type BannedUser = {
  id: string;
  user_id: string;
  reason: string | null;
  created_at: string;
};

export default function BannedTable({ banned }: { banned: BannedUser[] }) {
  const [list, setList] = useState(banned);
  const [loading, setLoading] = useState<string | null>(null);

  async function handleUnban(userId: string) {
    setLoading(userId);
    try {
      const res = await fetch(`/api/banned?userId=${userId}`, { method: 'DELETE' });
      if (!res.ok) {
        const d = await res.json();
        alert(d.error || 'فشل إلغاء الحظر');
        return;
      }
      setList((prev) => prev.filter((b) => b.user_id !== userId));
    } finally {
      setLoading(null);
    }
  }

  return (
    <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white">
      <table className="w-full">
        <thead>
          <tr className="border-b border-slate-200 bg-slate-50">
            <th className="px-4 py-3 text-right text-sm font-medium text-slate-600">المستخدم</th>
            <th className="px-4 py-3 text-right text-sm font-medium text-slate-600">السبب</th>
            <th className="px-4 py-3 text-right text-sm font-medium text-slate-600">التاريخ</th>
            <th className="px-4 py-3 text-right text-sm font-medium text-slate-600">الإجراءات</th>
          </tr>
        </thead>
        <tbody>
          {list.map((b) => (
            <tr key={b.id} className="border-b border-slate-100">
              <td className="px-4 py-3 text-sm font-mono" dir="ltr">{b.user_id}</td>
              <td className="px-4 py-3 text-sm text-slate-600">{b.reason || '-'}</td>
              <td className="px-4 py-3 text-sm text-slate-500">
                {new Date(b.created_at).toLocaleDateString('ar')}
              </td>
              <td className="px-4 py-3">
                <button
                  onClick={() => handleUnban(b.user_id)}
                  disabled={!!loading}
                  className="rounded bg-amber-100 px-3 py-1 text-sm text-amber-800 hover:bg-amber-200 disabled:opacity-50"
                >
                  إلغاء الحظر
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      {list.length === 0 && (
        <div className="p-8 text-center text-slate-500">لا يوجد مستخدمين محظورين</div>
      )}
    </div>
  );
}
