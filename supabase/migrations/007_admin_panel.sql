-- ============================================================
-- لوحة التحكم الإدارية - Swaply
-- تشغيل: Supabase Dashboard → SQL Editor → Run
-- ============================================================

-- 1) جدول المسؤولين: من يملك صلاحية الدخول للوحة التحكم
CREATE TABLE IF NOT EXISTS admin_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  role TEXT DEFAULT 'admin' CHECK (role IN ('super_admin', 'admin', 'moderator')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_admin_users_user_id ON admin_users(user_id);

ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;

-- المسؤول يقرأ نفسه فقط
DROP POLICY IF EXISTS "admin_read_self" ON admin_users;
CREATE POLICY "admin_read_self" ON admin_users
  FOR SELECT USING (auth.uid() = user_id);

-- 2) جدول المحظورين إدارياً (حظر من الإدارة، ليس حظر مستخدم-مستخدم)
CREATE TABLE IF NOT EXISTS admin_banned_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  banned_by UUID REFERENCES auth.users(id),
  reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id)
);

CREATE INDEX IF NOT EXISTS idx_admin_banned_users_user ON admin_banned_users(user_id);

ALTER TABLE admin_banned_users ENABLE ROW LEVEL SECURITY;

-- لا يقرأ المستخدمون العاديون من هذا الجدول (سيستخدم التطبيق الدالة فقط)
-- Service role يتخطى RLS

-- 3) دالة: هل المستخدم الحالي محظور؟
-- المستخدم المصادق يستدعيها بدون params، تُرجع true/false
CREATE OR REPLACE FUNCTION public.is_current_user_banned()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM admin_banned_users WHERE user_id = auth.uid()
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- السماح للمستخدمين المصادقين باستدعاء الدالة
GRANT EXECUTE ON FUNCTION public.is_current_user_banned() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_current_user_banned() TO anon;

-- 4) إضافة سياسة لقراءة user_profile_fields للجميع (موجودة في selfie_verification_setup)
-- المسؤولون يحتاجون قراءة الطلبات المعلقة عبر service_role
