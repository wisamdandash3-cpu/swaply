# تفعيل التحقق بالـ selfie وشارة التوثيق

## الخطوة 1: قاعدة البيانات (Supabase)

1. افتح **Supabase Dashboard** → **SQL Editor**.
2. إذا لم يكن جدول `user_profile_fields` موجوداً، شغّل أولاً محتوى الملف:
   - `supabase/create_user_profile_fields.sql`
3. ثم شغّل محتوى الملف:
   - `supabase/selfie_verification_setup.sql`

هذا يضيف سياسة (policy) تسمح للجميع بقراءة حقل حالة التوثيق حتى تظهر الشارة للمستخدمين الآخرين.

### منح شارة التوثيق لمستخدم (بعد المراجعة)

في **SQL Editor** نفّذ أحد الأمرين:

**إذا كان المستخدم قد أرسل selfie مسبقاً (الحالة `submitted`):**

```sql
UPDATE user_profile_fields
SET value = 'verified', updated_at = NOW()
WHERE field_key = 'selfie_verification_status'
  AND user_id = 'USER_UUID_HERE';
```

**إذا لم يوجد صف (أو لإنشاء/تحديث):**

```sql
INSERT INTO user_profile_fields (user_id, field_key, value, visibility, updated_at)
VALUES ('USER_UUID_HERE', 'selfie_verification_status', 'verified', 'hidden', NOW())
ON CONFLICT (user_id, field_key) DO UPDATE SET value = 'verified', updated_at = NOW();
```

استبدل `USER_UUID_HERE` بـ `user_id` الفعلي من **Authentication → Users** في Supabase.

---

## الخطوة 2: التطبيق (تم تنفيذها)

- شاشة **التحقق بالـ selfie**: من إعدادات الحساب → الأمان → "التحقق بال selfie" → التقاط صورة وإرسالها.
- الصورة تُرفع إلى Storage: `profile-photos/{user_id}/verification_selfie.jpg`
- الحالة تُحفظ في `user_profile_fields`: `field_key = 'selfie_verification_status'`, `value = 'submitted'`.
- بعد أن تضع في قاعدة البيانات `value = 'verified'` للمستخدم، ستظهر له **شارة التوثيق** (أيقونة ✓) في:
  - قائمة المحادثات
  - رأس شاشة المحادثة
  - قائمة المطابقات
  - تبويب أعجبوك
  - قائمة المحظورين

---

## قيم الحقل في قاعدة البيانات

| value      | المعنى |
|-----------|--------|
| (لا يوجد) | المستخدم لم يرسل selfie |
| `submitted` | أرسل صورة، بانتظار المراجعة |
| `verified`  | تم التحقق، تظهر شارة التوثيق |
