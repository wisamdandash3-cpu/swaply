-- دالة: إضافة رصيد للمحفظة (لاستدعائها من Edge Function فقط بـ service_role)
CREATE OR REPLACE FUNCTION public.add_wallet_balance(
  p_user_id uuid,
  p_roses_delta int DEFAULT 0,
  p_rings_delta int DEFAULT 0,
  p_coffee_delta int DEFAULT 0
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF p_roses_delta = 0 AND p_rings_delta = 0 AND p_coffee_delta = 0 THEN
    RETURN false;
  END IF;

  INSERT INTO user_wallet (user_id, roses_balance, rings_balance, coffee_balance)
  VALUES (p_user_id, GREATEST(0, p_roses_delta), GREATEST(0, p_rings_delta), GREATEST(0, p_coffee_delta))
  ON CONFLICT (user_id) DO UPDATE SET
    roses_balance = user_wallet.roses_balance + GREATEST(0, p_roses_delta),
    rings_balance = user_wallet.rings_balance + GREATEST(0, p_rings_delta),
    coffee_balance = user_wallet.coffee_balance + GREATEST(0, p_coffee_delta),
    updated_at = NOW();

  RETURN true;
END;
$$;
