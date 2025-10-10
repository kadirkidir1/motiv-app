-- MotivApp Supabase Database Setup
-- Run this in Supabase SQL Editor

-- 1. Create user_profiles table
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    age INTEGER,
    country TEXT,
    city TEXT,
    subscription_type TEXT DEFAULT 'free',
    premium_until TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    deleted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for user_profiles
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for user_profiles
DROP POLICY IF EXISTS "Users can view their own profile" ON public.user_profiles;
CREATE POLICY "Users can view their own profile"
    ON public.user_profiles FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.user_profiles;
CREATE POLICY "Users can insert their own profile"
    ON public.user_profiles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.user_profiles;
CREATE POLICY "Users can update their own profile"
    ON public.user_profiles FOR UPDATE
    USING (auth.uid() = user_id);

-- Create index
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON public.user_profiles(user_id);

-- 2. Create routines table
CREATE TABLE IF NOT EXISTS public.routines (
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
    "hasAlarm" INTEGER DEFAULT 0,
    "alarmTime" TEXT,
    "deadlineType" TEXT DEFAULT 'TaskDeadlineType.hours',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create daily_notes table
CREATE TABLE IF NOT EXISTS public.daily_notes (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    "routineId" TEXT NOT NULL,
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
CREATE INDEX IF NOT EXISTS idx_routines_user_id ON public.routines(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_tasks_user_id ON public.daily_tasks(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_notes_user_id ON public.daily_notes(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_notes_routine_id ON public.daily_notes("routineId");

-- 5. Enable Row Level Security (RLS)
ALTER TABLE public.routines ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_notes ENABLE ROW LEVEL SECURITY;

-- 6. Create RLS Policies for routines
DROP POLICY IF EXISTS "Users can view their own routines" ON public.routines;
CREATE POLICY "Users can view their own routines"
    ON public.routines FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert their own routines" ON public.routines;
CREATE POLICY "Users can insert their own routines"
    ON public.routines FOR INSERT
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own routines" ON public.routines;
CREATE POLICY "Users can update their own routines"
    ON public.routines FOR UPDATE
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own routines" ON public.routines;
CREATE POLICY "Users can delete their own routines"
    ON public.routines FOR DELETE
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
DROP TRIGGER IF EXISTS update_routines_updated_at ON public.routines;
CREATE TRIGGER update_routines_updated_at
    BEFORE UPDATE ON public.routines
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
