# Swaply — Landing Website (getswaply.de)

Landing site for the Swaply dating app, inspired by [happn](https://www.happn.com/). Uses colors and branding from the Flutter app (`lib/app_colors.dart`).

## Structure

- `index.html` — Home: hero carousel, trust bar, App Store / Google Play CTAs, features, footer
- `css/style.css` — Styles (Warm Sand, Forest Green, Playfair Display)
- `js/main.js` — Hero carousel (4s), language toggle (EN / DE / AR), persisted in `localStorage`
- `legal/` — Terms, Privacy, Cookies, Safety, FAQ (short summaries + link to app for full text)

## Run locally

Serve the `website` folder with any static server, e.g.:

```bash
cd website
npx serve .
# or: python3 -m http.server 8080
```

Then open `http://localhost:3000` (or 8080).

## Deploy to getswaply.de

1. **Upload** the contents of `website/` to your host (FTP, SFTP, or Git-based deploy).
2. **Point the domain** getswaply.de to the root where `index.html` is (document root).
3. **Optional**: Enable HTTPS (Let’s Encrypt) on your hosting.

### Vercel / Netlify

- **Vercel (و getswaply.de مربوط بمشروع "swaply")**: كي تظهر التعديلات **والمحتوى من Supabase** على www.getswaply.de:
  1. مشروع **swaply** → **Settings** → **General** → **Root Directory** = `website` (ثم Save)
  2. **Settings** → **Environment Variables** أضف:
     - `SUPABASE_URL` = `https://tjlbzzmudskkwmdtarfn.supabase.co` (أو Project URL من Supabase → Settings → API)
     - `SUPABASE_ANON_KEY` = مفتاح **anon public** من Supabase → Settings → API
  3. **Build Command** يبقى كما في المشروع: يشغّل `node scripts/write-config.js` فينشئ `config.supabase.js` من المتغيرات أعلاه، فيقرأ الموقع الحي المحتوى من Supabase.
  4. **Deployments** → **Redeploy** (أو `git push`) بعد إضافة المتغيرات.
  5. إذا فشل البناء أو تم عمل Rollback: من **Deployments** اضغط على النشر الفاشل → **Building** (أو **View Function Logs**) واقرأ رسالة الخطأ. تأكد أن **Root Directory** = `website` (Settings → General) وأن التعديلات الأخيرة (مجلد `scripts/` و`vercel.json` و`package.json` مع سكربت `build`) مرفوعة إلى المستودع.
- **Netlify**: Publish directory = `website`، وضَع نفس المتغيرين في Environment Variables ثم Build command: `npm run build` أو `node scripts/write-config.js`.

### After app store links are ready

In `index.html`, replace the `#` in the CTA buttons:

- App Store: `href="https://apps.apple.com/app/swaply/..."`  
- Google Play: `href="https://play.google.com/store/apps/details?id=..."`

## لوحة تحكم المحتوى (Decap CMS)

يمكنك تعديل نصوص الصفحة الرئيسية من المتصفح دون لمس الكود:

1. **افتح لوحة التحكم:** بعد النشر، ادخل إلى `https://www.getswaply.de/admin/` (أو من السيرفر المحلي `http://localhost:3000/admin/`).
2. **تسجيل الدخول:** اضغط "Login with GitHub" واتبع الخطوات (يجب أن يكون لديك صلاحية push على المستودع).
3. **تحرير:** في العمود الجانبي اضغط على **"محتوى الموقع"** (أيقونة القلم) — ستفتح شاشة التحرير وتعرض كل الحقول: عنوان الهيرو، النص، زر CTA، عناوين ونصوص الأقسام (Meet online، Dynamic features، Explore، Search، Reviews، Experts، Success، Advice)، ونص Footer. عدّل ثم "Save" ثم "Publish now". التعديل يُحمّل إلى GitHub ويُفعّل النشر على Vercel تلقائياً.

المحتوى يُخزَّن في `content/site.json` والصفحة الرئيسية تقرأه عند التحميل.

**اختبار اللوحة محلياً (بدون GitHub):**
1. إذا ظهر **EADDRINUSE** (المنفذ مستخدم)، حرّر المنافذ ثم أعد المحاولة:
   ```bash
   lsof -ti :8081 | xargs kill -9
   lsof -ti :8080 | xargs kill -9
   ```
2. **ترمينال 1** — من جذر المستودع: `npx decap-server` (يعمل على المنفذ 8081).
3. **ترمينال 2** — **من مجلد الموقع فقط:** `cd website && npm start` (لا تشغّل `npm start` من جذر swaply — لا يوجد فيه package.json).
4. في المتصفح افتح: **http://localhost:8080/admin/?local_backend=true**

إذا ظهر **"Your GitHub user account does not have access to this repo"**: الحساب الذي سجّلت الدخول به لا يملك صلاحية على المستودع. من GitHub: المستودع **wisamdandash3-cpu/swaply** → **Settings** → **Collaborators** → أضف حسابك واقبل الدعوة، ثم حدّث صفحة اللوحة.

إذا "Login with GitHub" لا يعمل على النطاق المباشر (Vercel)، راجع [Decap CMS GitHub Backend](https://decapcms.org/docs/github-backend/) — قد تحتاج إلى إضافة النطاق إلى تطبيق OAuth أو استخدام proxy.

## لوحة التحكم عبر Supabase (حفظ في القاعدة وعرض فوري)

يمكنك استخدام لوحة تحكم مخصصة تحفظ المحتوى في Supabase ويُعرض على الموقع **فوراً** بعد الحفظ (بدون انتظار إعادة النشر):

1. **تشغيل migration في Supabase:** من Supabase Dashboard → SQL Editor نفّذ محتوى الملف `website/run_020_website_content.sql` (أو `supabase/migrations/020_website_content.sql`). ✓ تم.
2. **إعداد المفاتيح:** انسخ `website/config.supabase.js.example` إلى `website/config.supabase.js` وضَع فيه `SUPABASE_URL` و `SUPABASE_ANON_KEY` من مشروعك (Supabase Dashboard → **Settings** → **API**).
3. **الموقع يقرأ من Supabase:** عند وجود `config.supabase.js`، الصفحة الرئيسية تطلب المحتوى من Supabase؛ إن فشل الطلب أو لم يُضبَط الملف تبقى القراءة من `content/site.json`.
4. **لوحة التحكم:** افتح `https://www.getswaply.de/admin-cms.html` (أو محلياً `http://localhost:8080/admin-cms.html`). سجّل الدخول **ببريد مسؤول مضاف في جدول `admin_users`** (نفس لوحة إدارة التطبيق). بعد الدخول:
   - **تحميل من Supabase** — يعرض المحتوى الحالي في القاعدة.
   - **تحميل من الملف الافتراضي** — يملأ المحرر من `site.json` (مفيد أول مرة لنسخ المحتوى إلى القاعدة).
   - عدّل النص (JSON) ثم **حفظ في Supabase** — التعديل يظهر مباشرة عند تحديث الموقع أو المعاينة.
5. **المعاينة:** الإطار على اليمين يعرض الموقع؛ بعد الحفظ يتم تحديث المعاينة تلقائياً.
6. **رفع الصور من الجهاز:** في تبويب «تحرير سهل» اضغط **«اختر صورة من جهازك»** عند صورة الهيرو لرفع صورة — ثم احفظ. (يجب تشغيل `website/run_021_storage_website.sql` في Supabase مرة واحدة لإنشاء حاوية التخزين.)

## Languages

EN, DE, AR are supported via the header language buttons. The choice is stored in `localStorage` under `swaply_website_lang`.
