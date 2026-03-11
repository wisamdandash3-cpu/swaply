# تفعيل تسجيل الدخول عبر Google (Swaply)

التطبيق جاهز من ناحية الكود. ليعمل تسجيل الدخول عبر Google يجب إعداد **Supabase** و**Google Cloud Console** كما يلي.

## 1. Supabase Dashboard

1. افتح مشروعك: [Supabase Dashboard](https://supabase.com/dashboard) → اختر مشروع **swaply**.
2. **تفعيل Google**:
   - اذهب إلى **Authentication** → **Providers**.
   - اختر **Google** وفعّله (Enable).
3. **إضافة Redirect URL للتطبيق**:
   - اذهب إلى **Authentication** → **URL Configuration**.
   - في **Redirect URLs** أضف:
     ```
     swaply://auth-callback
     ```
   - احفظ التغييرات.
4. لاحقاً ستضيف **Client ID** و**Client Secret** من Google (الخطوة 3).

## 2. Google Cloud Console

1. ادخل إلى [Google Cloud Console](https://console.cloud.google.com/).
2. أنشئ مشروعاً جديداً أو اختر مشروعاً موجوداً.
3. فعّل **Google+ API** (أو **Google Identity**) إذا طُلب.
4. اذهب إلى **APIs & Services** → **Credentials** → **Create Credentials** → **OAuth client ID**.
5. إذا ظهرت رسالة لإعداد شاشة الموافقة (OAuth consent screen):
   - اختر **External** (أو Internal للتجارب فقط).
   - أدخل اسم التطبيق (مثل Swaply) وبريد الدعم ثم احفظ.
6. أنشئ **OAuth 2.0 Client ID**:
   - **Application type**: اختر **Web application** (للاستخدام مع Supabase).
   - **Name**: مثلاً "Swaply Web".
   - **Authorized redirect URIs**: أضف **Callback URL** الخاص بمشروع Supabase:
     - من Supabase: **Authentication** → **Providers** → **Google** → انسخ **Callback URL** (شكلها مثل `https://xxxxx.supabase.co/auth/v1/callback`).
     - الصقه في "Authorized redirect URIs" في Google ثم أضفه.
   - احفظ ثم انسخ **Client ID** و**Client Secret**.

## 3. ربط Google بـ Supabase

1. في Supabase: **Authentication** → **Providers** → **Google**.
2. الصق **Client ID** و**Client Secret** من Google.
3. احفظ.

## 4. (اختياري) للتجربة على المحاكي أو جهاز حقيقي

- **iOS**: لا حاجة لإعداد إضافي إذا استخدمت الـ scheme `swaply` (وهو مضاف في المشروع).
- **Android**: لا حاجة لإعداد إضافي إذا استخدمت الـ scheme `swaply` (وهو مضاف في المشروع).

بعد تنفيذ الخطوات أعلاه، زر "Sign in with Google" في التطبيق يفتح شاشة اختيار حساب Google ثم يعيد المستخدم إلى Swaply بعد تسجيل الدخول.
