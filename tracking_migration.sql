-- MotivApp Tracking System Migration
-- Bu script'i Supabase SQL Editor'de çalıştır

-- ============================================
-- 1. YENİ TABLOLAR OLUŞTUR
-- ============================================

-- Rutin tamamlanma kayıtları
CREATE TABLE IF NOT EXISTS public.routine_completions (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    routine_id TEXT NOT NULL,
    date DATE NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE NOT NULL,
    minutes_spent INTEGER DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT unique_routine_date UNIQUE(routine_id, date)
);

-- Task tamamlanma kayıtları
CREATE TABLE IF NOT EXISTS public.task_completions (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    task_id TEXT NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE NOT NULL,
    completion_time_minutes INTEGER,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- 2. İNDEXLER OLUŞTUR
-- ============================================

CREATE INDEX IF NOT EXISTS idx_routine_completions_user_id ON public.routine_completions(user_id);
CREATE INDEX IF NOT EXISTS idx_routine_completions_routine_id ON public.routine_completions(routine_id);
CREATE INDEX IF NOT EXISTS idx_routine_completions_date ON public.routine_completions(date);
CREATE INDEX IF NOT EXISTS idx_task_completions_user_id ON public.task_completions(user_id);
CREATE INDEX IF NOT EXISTS idx_task_completions_task_id ON public.task_completions(task_id);

-- ============================================
-- 3. RLS POLİTİKALARI
-- ============================================

ALTER TABLE public.routine_completions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_completions ENABLE ROW LEVEL SECURITY;

-- routine_completions policies
DROP POLICY IF EXISTS "Users can view their own routine completions" ON public.routine_completions;
CREATE POLICY "Users can view their own routine completions"
    ON public.routine_completions FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own routine completions" ON public.routine_completions;
CREATE POLICY "Users can insert their own routine completions"
    ON public.routine_completions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own routine completions" ON public.routine_completions;
CREATE POLICY "Users can update their own routine completions"
    ON public.routine_completions FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own routine completions" ON public.routine_completions;
CREATE POLICY "Users can delete their own routine completions"
    ON public.routine_completions FOR DELETE
    USING (auth.uid() = user_id);

-- task_completions policies
DROP POLICY IF EXISTS "Users can view their own task completions" ON public.task_completions;
CREATE POLICY "Users can view their own task completions"
    ON public.task_completions FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own task completions" ON public.task_completions;
CREATE POLICY "Users can insert their own task completions"
    ON public.task_completions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own task completions" ON public.task_completions;
CREATE POLICY "Users can delete their own task completions"
    ON public.task_completions FOR DELETE
    USING (auth.uid() = user_id);

-- ============================================
-- 4. MEVCUT VERİLERİ MİGRATE ET
-- ============================================

-- daily_notes'taki tamamlanma kayıtlarını routine_completions'a taşı
INSERT INTO public.routine_completions (id, user_id, routine_id, date, completed_at, minutes_spent, notes)
SELECT 
    dn.id || '_' || dn.date::TEXT as id,
    dn.user_id,
    dn.routine_id,
    dn.date::DATE,
    dn.date,
    COALESCE(dn.minutes_spent, 0),
    CASE WHEN dn.completed = true THEN dn.note ELSE NULL END
FROM public.daily_notes dn
WHERE dn.completed = true
ON CONFLICT (routine_id, date) DO NOTHING;

-- ============================================
-- 5. DAILY_NOTES TABLOSUNU DÜZELT
-- ============================================

-- completed ve minutes_spent kolonlarını kaldır
ALTER TABLE public.daily_notes DROP COLUMN IF EXISTS completed;
ALTER TABLE public.daily_notes DROP COLUMN IF EXISTS minutes_spent;

-- note kolonunu opsiyonel yap
ALTER TABLE public.daily_notes ALTER COLUMN note DROP NOT NULL;

-- ============================================
-- 6. ROUTINES TABLOSUNU DÜZELT
-- ============================================

-- isCompleted yerine isArchived ekle
ALTER TABLE public.routines ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT FALSE;

-- Mevcut isCompleted verilerini is_archived'a taşı (eğer varsa)
-- UPDATE public.routines SET is_archived = ("isCompleted" = 1) WHERE "isCompleted" IS NOT NULL;

-- ============================================
-- 7. DAILY_TASKS TABLOSUNU DÜZELT
-- ============================================

-- completed_at kolonu ekle
ALTER TABLE public.daily_tasks ADD COLUMN IF NOT EXISTS completed_at TIMESTAMP WITH TIME ZONE;

-- Mevcut completed task'ların completed_at'ini güncelle
UPDATE public.daily_tasks 
SET completed_at = created_at 
WHERE status = 'TaskStatus.completed' AND completed_at IS NULL;

-- ============================================
-- 8. TRIGGER'LAR (Otomatik updated_at)
-- ============================================
-- Yeni tablolarda updated_at kolonu yok, trigger'lara gerek yok

-- ============================================
-- 9. VERİFİKASYON QUERY'LERİ
-- ============================================

-- Kaç tane routine completion var?
-- SELECT COUNT(*) as routine_completions_count FROM public.routine_completions;

-- Kaç tane task completion var?
-- SELECT COUNT(*) as task_completions_count FROM public.task_completions;

-- Migration başarılı mı?
-- SELECT 
--     (SELECT COUNT(*) FROM public.routine_completions) as completions,
--     (SELECT COUNT(*) FROM public.daily_notes WHERE completed = 1) as old_notes,
--     (SELECT COUNT(*) FROM public.routines WHERE is_archived = true) as archived_routines;

-- ============================================
-- NOTLAR
-- ============================================

-- 1. Bu script'i çalıştırmadan önce BACKUP al!
-- 2. Test ortamında önce dene
-- 3. Migration sonrası eski kolonları hemen silme, önce test et
-- 4. Uygulama kodunu güncelledikten sonra eski kolonları silebilirsin
