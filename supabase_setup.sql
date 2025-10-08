-- MotivApp Supabase Database Setup
-- Run this in Supabase SQL Editor

-- 1. Create motivations table
CREATE TABLE IF NOT EXISTS public.motivations (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    frequency TEXT NOT NULL,
    "hasAlarm" INTEGER NOT NULL DEFAULT 0,
    "alarmTime" TEXT,
    "createdAt" TEXT NOT NULL,
    "isCompleted" INTEGER NOT NULL DEFAULT 0,
    "targetMinutes" INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create daily_tasks table
CREATE TABLE IF NOT EXISTS public.daily_tasks (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    "createdAt" TEXT NOT NULL,
    "expiresAt" TEXT NOT NULL,
    status TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create daily_notes table
CREATE TABLE IF NOT EXISTS public.daily_notes (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    "motivationId" TEXT NOT NULL,
    date TEXT NOT NULL,
    note TEXT NOT NULL,
    mood INTEGER NOT NULL,
    tags TEXT,
    completed INTEGER NOT NULL DEFAULT 0,
    "minutesSpent" INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_motivations_user_id ON public.motivations(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_user_id ON public.daily_tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_notes_user_id ON public.daily_notes(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_notes_motivation_id ON public.daily_notes("motivationId");

-- 5. Enable Row Level Security (RLS)
ALTER TABLE public.motivations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_notes ENABLE ROW LEVEL SECURITY;

-- 6. Create RLS Policies for motivations
DROP POLICY IF EXISTS "Users can view their own motivations" ON public.motivations;
CREATE POLICY "Users can view their own motivations"
    ON public.motivations FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own motivations" ON public.motivations;
CREATE POLICY "Users can insert their own motivations"
    ON public.motivations FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own motivations" ON public.motivations;
CREATE POLICY "Users can update their own motivations"
    ON public.motivations FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own motivations" ON public.motivations;
CREATE POLICY "Users can delete their own motivations"
    ON public.motivations FOR DELETE
    USING (auth.uid() = user_id);

-- 7. Create RLS Policies for daily_tasks
DROP POLICY IF EXISTS "Users can view their own tasks" ON public.daily_tasks;
CREATE POLICY "Users can view their own tasks"
    ON public.daily_tasks FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own tasks" ON public.daily_tasks;
CREATE POLICY "Users can insert their own tasks"
    ON public.daily_tasks FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own tasks" ON public.daily_tasks;
CREATE POLICY "Users can update their own tasks"
    ON public.daily_tasks FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own tasks" ON public.daily_tasks;
CREATE POLICY "Users can delete their own tasks"
    ON public.daily_tasks FOR DELETE
    USING (auth.uid() = user_id);

-- 8. Create RLS Policies for daily_notes
DROP POLICY IF EXISTS "Users can view their own notes" ON public.daily_notes;
CREATE POLICY "Users can view their own notes"
    ON public.daily_notes FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own notes" ON public.daily_notes;
CREATE POLICY "Users can insert their own notes"
    ON public.daily_notes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own notes" ON public.daily_notes;
CREATE POLICY "Users can update their own notes"
    ON public.daily_notes FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own notes" ON public.daily_notes;
CREATE POLICY "Users can delete their own notes"
    ON public.daily_notes FOR DELETE
    USING (auth.uid() = user_id);

-- 9. Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 10. Create triggers for updated_at
DROP TRIGGER IF EXISTS update_motivations_updated_at ON public.motivations;
CREATE TRIGGER update_motivations_updated_at
    BEFORE UPDATE ON public.motivations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_daily_tasks_updated_at ON public.daily_tasks;
CREATE TRIGGER update_daily_tasks_updated_at
    BEFORE UPDATE ON public.daily_tasks
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_daily_notes_updated_at ON public.daily_notes;
CREATE TRIGGER update_daily_notes_updated_at
    BEFORE UPDATE ON public.daily_notes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
