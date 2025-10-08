-- Premium özelliklerini profiles tablosuna ekle
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS subscription_type TEXT DEFAULT 'free',
ADD COLUMN IF NOT EXISTS premium_until TIMESTAMP WITH TIME ZONE;

-- Mevcut kullanıcılara 30 gün premium ver
UPDATE profiles 
SET subscription_type = 'premium',
    premium_until = created_at + INTERVAL '30 days'
WHERE premium_until IS NULL;

-- Yeni kullanıcılar için otomatik 30 gün premium trigger
CREATE OR REPLACE FUNCTION set_initial_premium()
RETURNS TRIGGER AS $$
BEGIN
  NEW.subscription_type = 'premium';
  NEW.premium_until = NEW.created_at + INTERVAL '30 days';
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_user_created_set_premium ON profiles;
CREATE TRIGGER on_user_created_set_premium
  BEFORE INSERT ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION set_initial_premium();
