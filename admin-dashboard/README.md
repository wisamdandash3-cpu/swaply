# لوحة تحكم Swaply

لوحة تحكم إدارية للتطبيق Swaply على `admin.getswaply.de`

## الإعداد

1. انسخ `.env.local.example` إلى `.env.local`
2. أضف مفاتيح Supabase:
   - `NEXT_PUBLIC_SUPABASE_URL` و `NEXT_PUBLIC_SUPABASE_ANON_KEY` من Supabase Dashboard
   - `SUPABASE_SERVICE_ROLE_KEY` (لعمليات الإدارة فقط – لا تشاركه أبداً)
3. شغّل سكربتات Supabase:
   - `supabase/migrations/007_admin_panel.sql`
   - عدّل و شغّل `supabase/run_add_first_admin.sql` لإضافة حسابك كمسؤول

## التشغيل

```bash
npm run dev
```

## النشر على admin.getswaply.de

1. اربط المشروع مع Vercel أو Netlify
2. أضف الدومين `admin.getswaply.de`
3. عيّن متغيرات البيئة في لوحة النشر
