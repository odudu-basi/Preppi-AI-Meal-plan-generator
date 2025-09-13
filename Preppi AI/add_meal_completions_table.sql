-- =============================================================================
-- ADD MEAL COMPLETIONS TABLE FOR STREAKS FEATURE
-- =============================================================================
-- This migration adds support for tracking meal completions and calculating streaks
-- =============================================================================

-- Create the meal_completions table
CREATE TABLE IF NOT EXISTS public.meal_completions (
    -- Primary key and relationships
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    
    -- Meal completion details
    date DATE NOT NULL,
    meal_type TEXT NOT NULL, -- "breakfast", "lunch", "dinner", etc.
    completion TEXT NOT NULL CHECK (completion IN ('none', 'ateExact', 'ateSimilar')),
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create unique constraint to prevent duplicate completions for same user/date/meal_type
CREATE UNIQUE INDEX IF NOT EXISTS idx_meal_completions_unique 
ON public.meal_completions(user_id, date, meal_type);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_meal_completions_user_id ON public.meal_completions(user_id);
CREATE INDEX IF NOT EXISTS idx_meal_completions_date ON public.meal_completions(date);
CREATE INDEX IF NOT EXISTS idx_meal_completions_user_date ON public.meal_completions(user_id, date);
CREATE INDEX IF NOT EXISTS idx_meal_completions_completion ON public.meal_completions(completion);

-- Enable Row Level Security
ALTER TABLE public.meal_completions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Users can view own meal completions" ON public.meal_completions;
CREATE POLICY "Users can view own meal completions" ON public.meal_completions
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own meal completions" ON public.meal_completions;
CREATE POLICY "Users can insert own meal completions" ON public.meal_completions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own meal completions" ON public.meal_completions;
CREATE POLICY "Users can update own meal completions" ON public.meal_completions
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own meal completions" ON public.meal_completions;
CREATE POLICY "Users can delete own meal completions" ON public.meal_completions
    FOR DELETE USING (auth.uid() = user_id);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_meal_completions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
DROP TRIGGER IF EXISTS trigger_update_meal_completions_updated_at ON public.meal_completions;
CREATE TRIGGER trigger_update_meal_completions_updated_at
    BEFORE UPDATE ON public.meal_completions
    FOR EACH ROW
    EXECUTE FUNCTION update_meal_completions_updated_at();

-- =============================================================================
-- MIGRATION COMPLETE
-- =============================================================================
-- The meal_completions table is now ready to track meal completions
-- and support streak calculations for the Preppi AI app
-- =============================================================================
