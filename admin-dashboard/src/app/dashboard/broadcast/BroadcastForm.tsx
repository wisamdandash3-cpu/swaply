'use client';

import { useState, useEffect } from 'react';

type BroadcastItem = {
  id: string;
  content: string | null;
  image_url: string | null;
  video_url: string | null;
  created_at: string;
};

export default function BroadcastForm() {
  const [content, setContent] = useState('');
  const [sending, setSending] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  const [list, setList] = useState<BroadcastItem[]>([]);
  const [loadingList, setLoadingList] = useState(true);
  const [imageFile, setImageFile] = useState<File | null>(null);
  const [videoFile, setVideoFile] = useState<File | null>(null);
  const [deletingId, setDeletingId] = useState<string | null>(null);

  async function loadList() {
    setLoadingList(true);
    try {
      const res = await fetch('/api/broadcast');
      const data = await res.json();
      if (res.ok && Array.isArray(data.messages)) setList(data.messages);
    } finally {
      setLoadingList(false);
    }
  }

  useEffect(() => {
    loadList();
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const hasContent = content.trim().length > 0;
    const hasMedia = (imageFile && imageFile.size > 0) || (videoFile && videoFile.size > 0);
    if (!hasContent && !hasMedia) {
      setMessage({ type: 'error', text: 'اكتب نص الرسالة أو أضف صورة أو فيديو' });
      return;
    }
    setSending(true);
    setMessage(null);
    try {
      const formData = new FormData();
      formData.set('content', content.trim());
      if (imageFile && imageFile.size > 0) formData.set('image', imageFile);
      if (videoFile && videoFile.size > 0) formData.set('video', videoFile);
      const res = await fetch('/api/broadcast', {
        method: 'POST',
        body: formData,
      });
      const data = await res.json();
      if (!res.ok) {
        setMessage({ type: 'error', text: data.error || 'فشل الإرسال' });
        return;
      }
      setMessage({
        type: 'success',
        text: 'تم إرسال الرسالة إلى جميع المستخدمين. ستظهر في محادثة "فريق سوابلي" في التطبيق.',
      });
      setContent('');
      setImageFile(null);
      setVideoFile(null);
      loadList();
    } catch (err) {
      setMessage({ type: 'error', text: 'حدث خطأ في الاتصال' });
    } finally {
      setSending(false);
    }
  }

  async function handleDelete(id: string) {
    if (!confirm('حذف هذه الرسالة؟')) return;
    setDeletingId(id);
    try {
      const res = await fetch(`/api/broadcast/${id}`, { method: 'DELETE' });
      if (!res.ok) {
        const data = await res.json();
        setMessage({ type: 'error', text: data.error || 'فشل الحذف' });
        return;
      }
      setList((prev) => prev.filter((m) => m.id !== id));
    } finally {
      setDeletingId(null);
    }
  }

  const formatDate = (iso: string) => {
    try {
      return new Date(iso).toLocaleString('ar-SA', {
        dateStyle: 'medium',
        timeStyle: 'short',
      });
    } catch {
      return iso;
    }
  };

  return (
    <div className="space-y-8">
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="broadcast-content" className="mb-2 block text-sm font-medium text-slate-700">
            نص الرسالة (ستظهر للمستخدمين في محادثة فريق سوابلي)
          </label>
          <textarea
            id="broadcast-content"
            value={content}
            onChange={(e) => setContent(e.target.value)}
            rows={6}
            className="w-full rounded-xl border border-slate-200 p-4 text-slate-800 placeholder:text-slate-400 focus:border-emerald-500 focus:outline-none focus:ring-2 focus:ring-emerald-500/20"
            placeholder="مثال: مرحباً بكم في Swaply. نود إعلامكم بأن..."
            disabled={sending}
          />
        </div>
        <div className="grid gap-4 sm:grid-cols-2">
          <div>
            <label className="mb-2 block text-sm font-medium text-slate-700">صورة (اختياري)</label>
            <input
              type="file"
              accept="image/*"
              onChange={(e) => setImageFile(e.target.files?.[0] ?? null)}
              className="w-full rounded-lg border border-slate-200 p-2 text-sm text-slate-600 file:mr-2 file:rounded file:border-0 file:bg-emerald-50 file:px-3 file:py-1 file:text-emerald-700"
            />
            {imageFile && <p className="mt-1 text-xs text-slate-500">{imageFile.name}</p>}
          </div>
          <div>
            <label className="mb-2 block text-sm font-medium text-slate-700">فيديو (اختياري)</label>
            <input
              type="file"
              accept="video/*"
              onChange={(e) => setVideoFile(e.target.files?.[0] ?? null)}
              className="w-full rounded-lg border border-slate-200 p-2 text-sm text-slate-600 file:mr-2 file:rounded file:border-0 file:bg-emerald-50 file:px-3 file:py-1 file:text-emerald-700"
            />
            {videoFile && <p className="mt-1 text-xs text-slate-500">{videoFile.name}</p>}
          </div>
        </div>
        {message && (
          <div
            className={`rounded-lg border p-3 text-sm ${
              message.type === 'success'
                ? 'border-emerald-200 bg-emerald-50 text-emerald-800'
                : 'border-red-200 bg-red-50 text-red-800'
            }`}
          >
            {message.text}
          </div>
        )}
        <button
          type="submit"
          disabled={sending}
          className="rounded-xl bg-emerald-600 px-6 py-3 font-medium text-white transition hover:bg-emerald-700 disabled:opacity-50"
        >
          {sending ? 'جاري الإرسال...' : 'إرسال للجميع'}
        </button>
      </form>

      <div>
        <h2 className="mb-3 text-lg font-semibold text-slate-800">الرسائل المرسلة</h2>
        {loadingList ? (
          <p className="text-slate-500">جاري التحميل...</p>
        ) : list.length === 0 ? (
          <p className="text-slate-500">لا توجد رسائل مرسلة بعد.</p>
        ) : (
          <ul className="space-y-4">
            {list.map((m) => (
              <li
                key={m.id}
                className="flex flex-col gap-2 rounded-xl border border-slate-200 bg-slate-50/50 p-4"
              >
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0 flex-1">
                    <p className="whitespace-pre-wrap text-slate-800">{m.content || '(بدون نص)'}</p>
                    {m.image_url && (
                      <a
                        href={m.image_url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="mt-2 block text-sm text-emerald-600 hover:underline"
                      >
                        عرض الصورة
                      </a>
                    )}
                    {m.video_url && (
                      <a
                        href={m.video_url}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="mt-1 block text-sm text-emerald-600 hover:underline"
                      >
                        عرض الفيديو
                      </a>
                    )}
                    <p className="mt-2 text-xs text-slate-500">{formatDate(m.created_at)}</p>
                  </div>
                  <button
                    type="button"
                    onClick={() => handleDelete(m.id)}
                    disabled={deletingId === m.id}
                    className="shrink-0 rounded-lg border border-red-200 bg-red-50 px-3 py-1.5 text-sm font-medium text-red-700 hover:bg-red-100 disabled:opacity-50"
                  >
                    {deletingId === m.id ? 'جاري الحذف...' : 'حذف'}
                  </button>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
