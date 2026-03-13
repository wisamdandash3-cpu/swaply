import BroadcastForm from './BroadcastForm';

export default function BroadcastPage() {
  return (
    <div>
      <h1 className="mb-2 text-2xl font-bold text-slate-800">إرسال رسالة للجميع</h1>
      <p className="mb-6 text-slate-600">
        ستُرسل الرسالة إلى جميع المستخدمين وتظهر في محادثة &quot;فريق سوابلي&quot; في التطبيق (مثل رسالة الترحيب).
      </p>
      <div className="max-w-2xl rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <BroadcastForm />
      </div>
    </div>
  );
}
