-- نفّذ هذا الملف في Supabase SQL Editor لإنشاء جدول الرصيد.
-- Run this file in Supabase SQL Editor to create the wallet table.

-- جدول رصيد المستخدم للهدايا (ورود، خواتم، قهوة).
CREATE TABLE IF NOT EXISTS user_wallet (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  roses_balance INT NOT NULL DEFAULT 0 CHECK (roses_balance >= 0),
  rings_balance INT NOT NULL DEFAULT 0 CHECK (rings_balance >= 0),
  coffee_balance INT NOT NULL DEFAULT 0 CHECK (coffee_balance >= 0),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE user_wallet ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "المستخدم يقرأ رصيده" ON user_wallet;
CREATE POLICY "المستخدم يقرأ رصيده" ON user_wallet
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "المستخدم يعدل رصيده" ON user_wallet;
CREATE POLICY "المستخدم يعدل رصيده" ON user_wallet
  FOR ALL USING (auth.uid() = user_id);

-- تحديث updated_at
DROP TRIGGER IF EXISTS user_wallet_updated_at ON user_wallet;
CREATE TRIGGER user_wallet_updated_at
  BEFORE UPDATE ON user_wallet
  FOR EACH ROW EXECUTE PROCEDURE set_updated_at();
