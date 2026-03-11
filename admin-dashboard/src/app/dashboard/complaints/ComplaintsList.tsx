'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';

type Complaint = {
  id: string;
  reporter_id: string;
  reported_id: string;
  reason: string | null;
  context: string | null;
  evidence_url: string | null;
  created_at: string;
};

export default function ComplaintsList({ complaints }: { complaints: Complaint[] }) {
  const router = useRouter();
  const [deletingId, setDeletingId] = useState<string | null>(null);

  async function handleDelete(id: string) {
    if (deletingId) return;
    setDeletingId(id);
    try {
      const res = await fetch(`/api/complaints?id=${encodeURIComponent(id)}`, {
        method: 'DELETE',
      });
      if (!res.ok) {
        const d = await res.json();
        alert(d.error || 'فشل الحذف');
        return;
      }
      router.refresh();
    } finally {
      setDeletingId(null);
    }
  }

  if (complaints.length === 0) {
    return (
      <div className="rounded-xl border border-slate-200 bg-white p-8 text-center text-slate-500">
        لا توجد شكاوى
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {complaints.map((c) => (
        <div
          key={c.id}
          className="rounded-xl border border-slate-200 bg-white p-4"
        >
          <div className="flex flex-wrap items-center justify-between gap-2 text-sm">
            <div className="flex flex-wrap items-center gap-2">
              <span className="font-medium text-slate-600">الشاكي:</span>
              <Link
                href={`/dashboard/users/${c.reporter_id}`}
                className="font-medium text-emerald-700 hover:underline"
              >
                {c.reporter_id.slice(0, 8)}...
              </Link>
              <span className="text-slate-400">→</span>
              <span className="font-medium text-slate-600">المشكو منه:</span>
              <Link
                href={`/dashboard/users/${c.reported_id}`}
                className="font-medium text-red-700 hover:underline"
              >
                {c.reported_id.slice(0, 8)}...
              </Link>
            </div>
            <button
              type="button"
              onClick={() => handleDelete(c.id)}
              disabled={!!deletingId}
              className="rounded bg-red-100 px-3 py-1 text-sm font-medium text-red-700 hover:bg-red-200 disabled:opacity-50"
            >
              {deletingId === c.id ? 'جاري الحذف...' : 'حذف'}
            </button>
          </div>
          {c.reason && (
            <p className="mt-2 text-sm text-slate-700">السبب: {c.reason}</p>
          )}
          {c.context && (
            <p className="mt-1 text-sm text-slate-500">السياق: {c.context}</p>
          )}
          {c.evidence_url && (
            <div className="mt-3">
              <p className="mb-1 text-xs font-medium text-slate-600">الدليل:</p>
              <a
                href={c.evidence_url}
                target="_blank"
                rel="noreferrer"
                className="block"
              >
                <img
                  src={c.evidence_url}
                  alt="Evidence"
                  className="max-h-48 rounded-lg border border-slate-200 object-cover hover:opacity-90"
                />
              </a>
            </div>
          )}
          <p className="mt-2 text-xs text-slate-400">
            {new Date(c.created_at).toLocaleString('ar')}
          </p>
        </div>
      ))}
    </div>
  );
}
