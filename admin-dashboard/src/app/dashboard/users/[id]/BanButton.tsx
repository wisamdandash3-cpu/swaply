'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

type Props = {
  userId: string;
  isBanned: boolean;
};

export default function BanButton({ userId, isBanned }: Props) {
  const [loading, setLoading] = useState(false);
  const [reason, setReason] = useState('');
  const [showModal, setShowModal] = useState(false);
  const router = useRouter();

  async function handleBan() {
    setLoading(true);
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
      setShowModal(false);
      setReason('');
      router.refresh();
    } finally {
      setLoading(false);
    }
  }

  async function handleUnban() {
    setLoading(true);
    try {
      const res = await fetch(`/api/banned?userId=${userId}`, { method: 'DELETE' });
      if (!res.ok) {
        const d = await res.json();
        alert(d.error || 'فشل إلغاء الحظر');
        return;
      }
      router.refresh();
    } finally {
      setLoading(false);
    }
  }

  return (
    <>
      <div className="rounded-xl border border-slate-200 bg-white p-4">
        <h2 className="mb-4 text-lg font-bold text-slate-800">الإجراءات</h2>
        {isBanned ? (
          <button
            onClick={handleUnban}
            disabled={loading}
            className="rounded-lg bg-amber-100 px-4 py-2 text-sm font-medium text-amber-800 hover:bg-amber-200 disabled:opacity-50"
          >
            إلغاء الحظر
          </button>
        ) : (
          <button
            onClick={() => setShowModal(true)}
            disabled={loading}
            className="rounded-lg bg-red-100 px-4 py-2 text-sm font-medium text-red-800 hover:bg-red-200 disabled:opacity-50"
          >
            حظر المستخدم
          </button>
        )}
      </div>

      {showModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50">
          <div className="w-full max-w-md rounded-xl bg-white p-6">
            <h3 className="mb-4 font-bold">حظر المستخدم</h3>
            <input
              type="text"
              placeholder="سبب الحظر (اختياري)"
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              className="mb-4 w-full rounded border px-3 py-2"
            />
            <div className="flex gap-2">
              <button
                onClick={handleBan}
                disabled={loading}
                className="rounded bg-red-600 px-4 py-2 text-white hover:bg-red-700 disabled:opacity-50"
              >
                تأكيد الحظر
              </button>
              <button
                onClick={() => { setShowModal(false); setReason(''); }}
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
