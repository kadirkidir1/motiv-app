-- MotivApp Supabase Migration: Motivation -> Routine
-- Run this in Supabase SQL Editor

-- 1. Rename motivations table to routines
ALTER TABLE IF EXISTS public.motivations RENAME TO routines;

-- 2. Update daily_notes column name
ALTER TABLE IF EXISTS public.daily_notes 
RENAME COLUMN "motivationId" TO "routineId";

-- 3. Update index name
DROP INDEX IF EXISTS idx_daily_notes_motivation_id;
CREATE INDEX IF NOT EXISTS idx_daily_notes_routine_id ON public.daily_notes("routineId");

-- 4. Update trigger name
DROP TRIGGER IF EXISTS update_motivations_updated_at ON public.routines;
CREATE TRIGGER update_routines_updated_at
    BEFORE UPDATE ON public.routines
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 5. Recreate RLS Policies for routines (with new names)
DROP POLICY IF EXISTS "Users can view their own motivations" ON public.routines;
DROP POLICY IF EXISTS "Users can insert their own motivations" ON public.routines;
DROP POLICY IF EXISTS "Users can update their own motivations" ON public.routines;
DROP POLICY IF EXISTS "Users can delete their own motivations" ON public.routines;

CREATE POLICY "Users can view their own routines"
    ON public.routines FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own routines"
    ON public.routines FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own routines"
    ON public.routines FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own routines"
    ON public.routines FOR DELETE
    USING (auth.uid() = user_id);

-- 6. Update daily_tasks table - add new columns for alarm and deadline type
ALTER TABLE IF EXISTS public.daily_tasks 
ADD COLUMN IF NOT EXISTS "hasAlarm" INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS "alarmTime" TEXT,
ADD COLUMN IF NOT EXISTS "deadlineType" TEXT DEFAULT 'TaskDeadlineType.hours';
