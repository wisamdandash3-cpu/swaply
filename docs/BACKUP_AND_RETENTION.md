# النسخ الاحتياطي وسياسة الاحتفاظ بالبيانات (عالمي / GDPR)

## النسخ الاحتياطي

- **Supabase**: تفعيل النسخ الاحتياطي التلقائي من لوحة Supabase: **Project Settings → Database → Backups**. يوفّر Supabase نسخاً يومية حسب الخطة.
- **استعادة**: من **Database → Backups** يمكن استعادة نقطة زمنية سابقة عند الحاجة.

## سياسة الاحتفاظ

- **بيانات الحساب**: تُحذف عند طلب المستخدم (حذف الحساب من التطبيق أو عبر دالة `delete-account`). الجداول المرتبطة بـ `auth.users` تستخدم `ON DELETE CASCADE` فتُحذف تلقائياً.
- **سجلات rate limiting**: جدول `rate_limit_tracking` ينمو مع الاستخدام. تشغيل الدالة `cleanup_old_rate_limits()` يَحذف السجلات الأقدم من 24 ساعة. يُنصح بجدولة تشغيلها (مثلاً **pg_cron** أو Edge Function مجدولة يومياً):

  ```sql
  SELECT cleanup_old_rate_limits();
  ```

### جدولة cleanup_old_rate_limits

- **pg_cron (إن وُجد في المشروع)**: إنشاء مهمة يومية لتشغيل الدالة من SQL Editor:
  ```sql
  SELECT cron.schedule(
    'cleanup-rate-limits',
    '0 3 * * *',  -- كل يوم الساعة 03:00 UTC
    $$SELECT cleanup_old_rate_limits()$$
  );
  ```
- **بدون pg_cron**: تشغيل يدوي دوري من Supabase Dashboard → SQL Editor: `SELECT cleanup_old_rate_limits();` أو استدعاء الدالة من Edge Function مجدولة (Supabase لا يدعم pg_cron في كل الخطط؛ تحقق من خطة مشروعك).

- **الاحتفاظ للامتثال**: احتفظ بنسخ احتياطية وسجلات فقط للمدة المطلوبة قانونياً في المناطق التي تخدمها (مثلاً حسب GDPR أو القوانين المحلية).

## حذف الحساب

- المستخدم يمكنه حذف حسابه من **إعدادات الحساب → Delete or pause account → Confirm**.
- التطبيق يستدعي Edge Function **delete-account** التي تحذف المستخدم من `auth.users`؛ باقي البيانات تُحذف تلقائياً بسبب CASCADE.
- إذا لم تُنشر الدالة `delete-account`، يظهر خطأ للمستخدم؛ يمكنه عندها التواصل مع الدعم للحذف اليدوي.
