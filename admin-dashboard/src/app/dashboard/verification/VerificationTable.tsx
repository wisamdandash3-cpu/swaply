'use client';

import { useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';

type Verification = {
  userId: string;
  status: string;
  updatedAt: string;
  selfieUrl: string;
  videoUrl: string;
  profilePhotoUrls: string[];
};

export default function VerificationTable({ verifications }: { verifications: Verification[] }) {
  const [list, setList] = useState(verifications);
  const [loading, setLoading] = useState<string | null>(null);
  const [videoErrors, setVideoErrors] = useState<Set<string>>(new Set());

  async function handleStatus(userId: string, status: 'verified' | 'rejected') {
    setLoading(userId);
    try {
      const res = await fetch('/api/verification', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId, status }),
      });
      if (!res.ok) {
        const d = await res.json();
        alert(d.error || 'فشل التحديث');
        return;
      }
      setList((prev) => prev.map((v) => (v.userId === userId ? { ...v, status } : v)));
    } finally {
      setLoading(null);
    }
  }

  function onVideoError(userId: string) {
    setVideoErrors((prev) => new Set(prev).add(userId));
  }

  const submitted = list.filter((v) => v.status === 'submitted');
  const verified = list.filter((v) => v.status === 'verified');

  return (
    <div className="space-y-6">
      <div className="rounded-xl border border-slate-200 bg-white p-4">
        <h2 className="mb-4 font-semibold text-slate-700">معلقة ({submitted.length})</h2>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {submitted.map((v) => (
            <div
              key={v.userId}
              className="rounded-lg border border-slate-200 p-4"
            >
              <div className="mb-2 space-y-2">
                <p className="text-xs font-medium text-slate-600">فيديو / صورة التوثيق</p>
                {!videoErrors.has(v.userId) && (
                  <div className="relative aspect-square overflow-hidden rounded-lg bg-slate-900">
                    <video
                      src={v.videoUrl}
                      controls
                      className="h-full w-full object-contain"
                      onError={() => onVideoError(v.userId)}
                    />
                  </div>
                )}
                {videoErrors.has(v.userId) && (
                  <div className="relative aspect-square overflow-hidden rounded-lg bg-slate-100">
                    <Image
                      src={v.selfieUrl}
                      alt="Selfie"
                      fill
                      className="object-cover"
                      unoptimized
                      onError={(e) => {
                        (e.target as HTMLImageElement).style.display = 'none';
                      }}
                    />
                  </div>
                )}
              </div>
              {v.profilePhotoUrls.length > 0 && (
                <div className="mb-2">
                  <p className="mb-1 text-xs font-medium text-slate-600">صور البروفايل (للمقارنة)</p>
                  <div className="flex flex-wrap gap-1">
                    {v.profilePhotoUrls.map((url, i) => (
                      <a
                        key={i}
                        href={url}
                        target="_blank"
                        rel="noreferrer"
                        className="block h-14 w-14 overflow-hidden rounded border border-slate-200"
                      >
                        <img
                          src={url}
                          alt={`بروفايل ${i + 1}`}
                          className="h-full w-full object-cover"
                        />
                      </a>
                    ))}
                  </div>
                </div>
              )}
              <p className="mb-1 truncate text-xs text-slate-500" dir="ltr">{v.userId}</p>
              <Link
                href={`/dashboard/users/${v.userId}`}
                className="mb-2 block text-xs text-emerald-600 hover:underline"
              >
                عرض الملف الشخصي
              </Link>
              <div className="flex gap-2">
                <button
                  onClick={() => handleStatus(v.userId, 'verified')}
                  disabled={!!loading}
                  className="flex-1 rounded bg-emerald-600 py-1 text-sm text-white hover:bg-emerald-700 disabled:opacity-50"
                >
                  موافقة
                </button>
                <button
                  onClick={() => handleStatus(v.userId, 'rejected')}
                  disabled={!!loading}
                  className="flex-1 rounded bg-red-100 py-1 text-sm text-red-700 hover:bg-red-200 disabled:opacity-50"
                >
                  رفض
                </button>
              </div>
            </div>
          ))}
        </div>
        {submitted.length === 0 && (
          <p className="text-sm text-slate-500">لا توجد طلبات معلقة</p>
        )}
      </div>

      <div className="rounded-xl border border-slate-200 bg-white p-4">
        <h2 className="mb-4 font-semibold text-slate-700">تم التحقق ({verified.length})</h2>
        <div className="space-y-2">
          {verified.map((v) => (
            <div key={v.userId} className="flex items-center justify-between rounded bg-slate-50 px-4 py-2">
              <Link
                href={`/dashboard/users/${v.userId}`}
                className="truncate text-sm text-emerald-700 hover:underline"
                dir="ltr"
              >
                {v.userId}
              </Link>
              <span className="text-xs text-slate-500">{new Date(v.updatedAt).toLocaleDateString('ar')}</span>
            </div>
          ))}
        </div>
        {verified.length === 0 && (
          <p className="text-sm text-slate-500">لا يوجد</p>
        )}
      </div>
    </div>
  );
}
