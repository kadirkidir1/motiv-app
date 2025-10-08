-- RLS'i Aktifleştir ve Politikaları Düzelt

-- 1. RLS'i aktifleştir
ALTER TABLE public.motivations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 2. Eski politikaları sil
DROP POLICY IF EXISTS "Users can view their own motivations" ON public.motivations;
DROP POLICY IF EXISTS "Users can insert their own motivations" ON public.motivations;
DROP POLICY IF EXISTS "Users can update their own motivations" ON public.motivations;
DROP POLICY IF EXISTS "Users can delete their own motivations" ON public.motivations;

DROP POLICY IF EXISTS "Users can view their own tasks" ON public.daily_tasks;
DROP POLICY IF EXISTS "Users can insert their own tasks" ON public.daily_tasks;
DROP POLICY IF EXISTS "Users can update their own tasks" ON public.daily_tasks;
DROP POLICY IF EXISTS "Users can delete their own tasks" ON public.daily_tasks;

DROP POLICY IF EXISTS "Users can view their own notes" ON public.daily_notes;
DROP POLICY IF EXISTS "Users can insert their own notes" ON public.daily_notes;
DROP POLICY IF EXISTS "Users can update their own notes" ON public.daily_notes;
DROP POLICY IF EXISTS "Users can delete their own notes" ON public.daily_notes;

DROP POLICY IF EXISTS "Users can view their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;

-- 3. Motivations politikaları
CREATE POLICY "Users can view their own motivations"
    ON public.motivations FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own motivations"
    ON public.motivations FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own motivations"
    ON public.motivations FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own motivations"
    ON public.motivations FOR DELETE
    USING (auth.uid() = user_id);

-- 4. Daily Tasks politikaları
CREATE POLICY "Users can view their own tasks"
    ON public.daily_tasks FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own tasks"
    ON public.daily_tasks FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own tasks"
    ON public.daily_tasks FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own tasks"
    ON public.daily_tasks FOR DELETE
    USING (auth.uid() = user_id);

-- 5. Daily Notes politikaları
CREATE POLICY "Users can view their own notes"
    ON public.daily_notes FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own notes"
    ON public.daily_notes FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own notes"
    ON public.daily_notes FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own notes"
    ON public.daily_notes FOR DELETE
    USING (auth.uid() = user_id);

-- 6. Profiles politikaları
CREATE POLICY "Users can view their own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);
