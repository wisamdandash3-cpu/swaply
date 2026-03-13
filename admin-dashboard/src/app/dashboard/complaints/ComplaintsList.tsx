'use client';

import { useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';

type Complaint = {
  id: string;
  reporter_id: string;
  reported_id: string | null;
  reason: string | null;
  context: string | null;
  evidence_url: string | null;
  created_at: string;
};

export default function ComplaintsList({ complaints }: { complaints: Complaint[] }) {
  const router = useRouter();
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [replyingTo, setReplyingTo] = useState<Complaint | null>(null);
  const [replyContent, setReplyContent] = useState('');
  const [replySending, setReplySending] = useState(false);

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

  async function handleSendReply() {
    if (!replyingTo || !replyContent.trim() || replySending) return;
    setReplySending(true);
    try {
      const res = await fetch('/api/complaints/reply', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          userId: replyingTo.reporter_id,
          complaintId: replyingTo.id,
          content: replyContent.trim(),
        }),
      });
      const d = await res.json();
      if (!res.ok) {
        alert(d.error || 'فشل إرسال الرد');
        return;
      }
      setReplyingTo(null);
      setReplyContent('');
      router.refresh();
    } finally {
      setReplySending(false);
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
              {c.reported_id ? (
                <Link
                  href={`/dashboard/users/${c.reported_id}`}
                  className="font-medium text-red-700 hover:underline"
                >
                  {c.reported_id.slice(0, 8)}...
                </Link>
              ) : (
                <span className="font-medium text-amber-700">شكوى عامة</span>
              )}
            </div>
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => {
                  setReplyingTo(c);
                  setReplyContent('');
                }}
                className="rounded bg-emerald-100 px-3 py-1 text-sm font-medium text-emerald-700 hover:bg-emerald-200"
              >
                رد
              </button>
              <button
                type="button"
                onClick={() => handleDelete(c.id)}
                disabled={!!deletingId}
                className="rounded bg-red-100 px-3 py-1 text-sm font-medium text-red-700 hover:bg-red-200 disabled:opacity-50"
              >
                {deletingId === c.id ? 'جاري الحذف...' : 'حذف'}
              </button>
            </div>
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

      {/* نافذة الرد على المستخدم */}
      {replyingTo && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4"
          onClick={() => !replySending && setReplyingTo(null)}
          role="dialog"
          aria-modal="true"
          aria-labelledby="reply-title"
        >
          <div
            className="w-full max-w-md rounded-xl border border-slate-200 bg-white p-6 shadow-lg"
            onClick={(e) => e.stopPropagation()}
          >
            <h2 id="reply-title" className="mb-2 text-lg font-bold text-slate-800">
              الرد على المستخدم (الشاكي)
            </h2>
            <p className="mb-3 text-xs text-slate-500">
              معرّف المستخدم: {replyingTo.reporter_id.slice(0, 8)}...
            </p>
            <textarea
              value={replyContent}
              onChange={(e) => setReplyContent(e.target.value)}
              placeholder="اكتب ردك هنا..."
              rows={5}
              className="mb-4 w-full rounded-lg border border-slate-200 p-3 text-sm text-slate-800 placeholder:text-slate-400 focus:border-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/20"
              disabled={replySending}
            />
            <div className="flex justify-end gap-2">
              <button
                type="button"
                onClick={() => !replySending && setReplyingTo(null)}
                className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
              >
                إلغاء
              </button>
              <button
                type="button"
                onClick={handleSendReply}
                disabled={!replyContent.trim() || replySending}
                className="rounded-lg bg-emerald-600 px-4 py-2 text-sm font-medium text-white hover:bg-emerald-700 disabled:opacity-50"
              >
                {replySending ? 'جاري الإرسال...' : 'إرسال الرد'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
