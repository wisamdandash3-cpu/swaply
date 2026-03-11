# Supabase – تشغيل الـ Migrations

## الطريقة 1: من Supabase Dashboard (الأبسط)

1. افتح [Supabase Dashboard](https://supabase.com/dashboard) واختر مشروعك.
2. من القائمة الجانبية: **SQL Editor**.
3. شغّل الملفات بالترتيب:
   - انسخ محتوى `migrations/001_interactive_profiles.sql` → الصق في المحرر → **Run**.
   - ثم انسخ محتوى `migrations/002_profiles.sql` → الصق → **Run**.

## الطريقة 2: من التيرمنال (Supabase CLI)

إذا ربطت المشروع بـ Supabase CLI:

```bash
cd /Users/wisamdandash/swaply
supabase db push
```

أو تشغيل ملف واحد:

```bash
supabase db execute -f supabase/migrations/001_interactive_profiles.sql
supabase db execute -f supabase/migrations/002_profiles.sql
```

## ترتيب الملفات

| الملف | الوصف |
|-------|--------|
| `001_interactive_profiles.sql` | `profile_questions`, `profile_answers`, `profile_likes` + RLS |
| `002_profiles.sql` | جدول `profiles` (اللغات، الأطفال، الموقع) + RLS |
| … | باقي الـ migrations حسب الأرقام (003–010) |
| `011_security_and_performance.sql` | أمان المحفظة والاشتراكات، استبعاد المحظورين من الاكتشاف، فهرسة، rate limiting |
| `012_global_discovery_age_timezone.sql` | فلتر مسافة + ترقيم صفحات الاكتشاف، timezone في profiles، country/region في subscriptions، تحقق عمر 18+ |
| `013_index_content_cleanup.sql` | فهرس profiles(latitude, longitude)، حد طول محتوى (messages, complaints, profile_answers)، دالة cleanup_old_rate_limits |
| `014_messages_photo_url_length.sql` | حد أقصى لطول عمود photo_url في messages (2048 حرف) |
| `015_read_at_matches_conversations_filters.sql` | read_at في messages، mark_conversation_read، get_conversation_list، get_my_matches، توسيع get_discoverable_profile_ids (عمر/جنس) |

## جدول user_profile_fields (migration 003)

- الأعمدة: `user_id`, `field_key` (TEXT), `value` (TEXT), `visibility`, `created_at`, `updated_at`.
- **لا يوجد قيد (CHECK) على `field_key`** — أي قيمة نصية مسموحة. التطبيق يخزّن تفضيلات الفلتر بمفاتيح مثل `filter_max_distance`, `filter_age_min`, `filter_age_max`, `filter_interested_in` إلخ دون الحاجة لتعديل الجدول.

## migration 011 (أمان وأداء)

شغّل `migrations/011_security_and_performance.sql` بعد تشغيل 001–010. يقوم بما يلي:

- **المحفظة**: المستخدم يقرأ رصيده فقط؛ الإنشاء عبر `get_or_create_wallet()` والخصم عبر `deduct_gift()`.
- **الاشتراكات**: المستخدم يقرأ فقط؛ التحديث من السيرفر (Edge Function).
- **الاكتشاف**: دالة `get_discoverable_profile_ids` تستبعد المحظورين إدارياً.
- **فهرس**: `profile_answers(profile_id)` لتحسين أداء الاكتشاف.
- **Rate limiting**: حد للرسائل (مثلاً 30/دقيقة) والشكاوى (مثلاً 5/ساعة) عبر triggers.

## migration 012 (عالمي: مسافة، ترقيم، عمر، وقت)

شغّل `migrations/012_global_discovery_age_timezone.sql` بعد 011. يقوم بما يلي:

- **الاكتشاف**: دالة `get_discoverable_profile_ids` تدعم فلتر المسافة (p_max_km, p_user_lat, p_user_lng) وترقيم الصفحات (p_limit, p_offset).
- **profiles**: عمود اختياري `timezone` لعرض "آخر نشاط" بالتوقيت المحلي.
- **subscriptions**: أعمدة اختيارية `country` و `region` للإقليم.
- **حد العمر**: trigger على `user_profile_fields` يرفض عمراً أقل من 18 أو تاريخ ميلاد لا يتوافق مع 18+.

## تخزين التسجيل الصوتي (profile-audio)

إذا ظهر خطأ **Bucket not found** عند رفع تسجيل صوتي من تعديل البروفايل:

1. في **SQL Editor** نفّذ **أولاً** محتوى `storage_profile_audio.sql` (ينشئ الـ bucket).
2. ثم نفّذ محتوى `storage_policies_profile_audio.sql` (صلاحيات RLS).

الترتيب مهم: إنشاء الـ bucket قبل السياسات.
