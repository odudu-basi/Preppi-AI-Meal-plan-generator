-- =============================================================================
-- RESET AND FIX DATABASE - Complete Clean-up and Rebuild
-- =============================================================================
-- This script will clean up any conflicts and rebuild your database properly
-- Run this ONCE in your Supabase SQL editor to fix all issues
-- =============================================================================

-- =============================================================================
-- STEP 1: CLEAN UP EXISTING POLICIES AND INDEXES
-- =============================================================================

-- Drop all existing meal plan policies to avoid conflicts
DROP POLICY IF EXISTS "Users can view own meal plans" ON public.meal_plans;
DROP POLICY IF EXISTS "Users can insert own meal plans" ON public.meal_plans;
DROP POLICY IF EXISTS "Users can update own meal plans" ON public.meal_plans;
DROP POLICY IF EXISTS "Users can delete own meal plans" ON public.meal_plans;

DROP POLICY IF EXISTS "Users can view meals in their meal plans" ON public.meals;
DROP POLICY IF EXISTS "Users can insert meals for their meal plans" ON public.meals;
DROP POLICY IF EXISTS "Users can update meals in their meal plans" ON public.meals;
DROP POLICY IF EXISTS "Users can delete meals in their meal plans" ON public.meals;

DROP POLICY IF EXISTS "Users can view day meals in their meal plans" ON public.day_meals;
DROP POLICY IF EXISTS "Users can insert day meals for their meal plans" ON public.day_meals;
DROP POLICY IF EXISTS "Users can update day meals in their meal plans" ON public.day_meals;
DROP POLICY IF EXISTS "Users can delete day meals in their meal plans" ON public.day_meals;

DROP POLICY IF EXISTS "Users can view ingredients for their meals" ON public.meal_ingredients;
DROP POLICY IF EXISTS "Users can insert ingredients for their meals" ON public.meal_ingredients;
DROP POLICY IF EXISTS "Users can update ingredients for their meals" ON public.meal_ingredients;
DROP POLICY IF EXISTS "Users can delete ingredients for their meals" ON public.meal_ingredients;

DROP POLICY IF EXISTS "Users can view instructions for their meals" ON public.meal_instructions;
DROP POLICY IF EXISTS "Users can insert instructions for their meals" ON public.meal_instructions;
DROP POLICY IF EXISTS "Users can update instructions for their meals" ON public.meal_instructions;
DROP POLICY IF EXISTS "Users can delete instructions for their meals" ON public.meal_instructions;

-- Drop potentially conflicting indexes (safe to drop and recreate)
DROP INDEX IF EXISTS public.idx_meal_plans_user_id;
DROP INDEX IF EXISTS public.idx_meal_plans_week_start_date;
DROP INDEX IF EXISTS public.idx_meal_plans_user_active;
DROP INDEX IF EXISTS public.idx_meal_plans_cuisines;
DROP INDEX IF EXISTS public.idx_day_meals_meal_plan_id;
DROP INDEX IF EXISTS public.idx_day_meals_meal_id;
DROP INDEX IF EXISTS public.idx_day_meals_day_order;
DROP INDEX IF EXISTS public.idx_meal_ingredients_meal_id;
DROP INDEX IF EXISTS public.idx_meal_ingredients_order;
DROP INDEX IF EXISTS public.idx_meal_instructions_meal_id;
DROP INDEX IF EXISTS public.idx_meal_instructions_order;

-- =============================================================================
-- STEP 2: ENSURE ALL REQUIRED COLUMNS EXIST
-- =============================================================================

DO $$
BEGIN
    -- Add any missing columns to meal_plans table
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meal_plans' AND column_name = 'selected_meal_types') THEN
        ALTER TABLE public.meal_plans ADD COLUMN selected_meal_types JSONB DEFAULT '[]'::jsonb;
        RAISE NOTICE 'Added selected_meal_types column to meal_plans';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meal_plans' AND column_name = 'meal_plan_type') THEN
        ALTER TABLE public.meal_plans ADD COLUMN meal_plan_type TEXT DEFAULT 'dinner';
        RAISE NOTICE 'Added meal_plan_type column to meal_plans';
    END IF;
    
    -- Add any missing columns to meals table
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meals' AND column_name = 'image_url') THEN
        ALTER TABLE public.meals ADD COLUMN image_url TEXT;
        RAISE NOTICE 'Added image_url column to meals';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meals' AND column_name = 'recommended_calories_before_dinner') THEN
        ALTER TABLE public.meals ADD COLUMN recommended_calories_before_dinner INTEGER DEFAULT 0;
        RAISE NOTICE 'Added recommended_calories_before_dinner column to meals';
    END IF;
    
    -- Add macro columns if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meals' AND column_name = 'protein') THEN
        ALTER TABLE public.meals ADD COLUMN protein DECIMAL(8,2);
        ALTER TABLE public.meals ADD COLUMN carbohydrates DECIMAL(8,2);
        ALTER TABLE public.meals ADD COLUMN fat DECIMAL(8,2);
        ALTER TABLE public.meals ADD COLUMN fiber DECIMAL(8,2);
        ALTER TABLE public.meals ADD COLUMN sugar DECIMAL(8,2);
        ALTER TABLE public.meals ADD COLUMN sodium DECIMAL(8,2);
        RAISE NOTICE 'Added macro columns to meals';
    END IF;
    
    -- Add detailed recipe columns if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'meals' AND column_name = 'detailed_ingredients') THEN
        ALTER TABLE public.meals ADD COLUMN detailed_ingredients JSONB DEFAULT '[]'::jsonb;
        ALTER TABLE public.meals ADD COLUMN detailed_instructions JSONB DEFAULT '[]'::jsonb;
        ALTER TABLE public.meals ADD COLUMN cooking_tips JSONB DEFAULT '[]'::jsonb;
        ALTER TABLE public.meals ADD COLUMN serving_info TEXT;
        RAISE NOTICE 'Added detailed recipe columns to meals';
    END IF;
    
    -- Add meal_type column to day_meals if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'day_meals' AND column_name = 'meal_type') THEN
        ALTER TABLE public.day_meals ADD COLUMN meal_type TEXT DEFAULT 'dinner';
        RAISE NOTICE 'Added meal_type column to day_meals';
    END IF;
END $$;

-- =============================================================================
-- STEP 3: RECREATE INDEXES
-- =============================================================================

-- Meal Plans indexes
CREATE INDEX idx_meal_plans_user_id ON public.meal_plans(user_id);
CREATE INDEX idx_meal_plans_week_start_date ON public.meal_plans(week_start_date);
CREATE INDEX idx_meal_plans_user_active ON public.meal_plans(user_id, is_active);
CREATE INDEX idx_meal_plans_cuisines ON public.meal_plans USING GIN(selected_cuisines);

-- Day Meals indexes
CREATE INDEX idx_day_meals_meal_plan_id ON public.day_meals(meal_plan_id);
CREATE INDEX idx_day_meals_meal_id ON public.day_meals(meal_id);
CREATE INDEX idx_day_meals_day_order ON public.day_meals(day_order);

-- Meal Ingredients indexes
CREATE INDEX idx_meal_ingredients_meal_id ON public.meal_ingredients(meal_id);
CREATE INDEX idx_meal_ingredients_order ON public.meal_ingredients(meal_id, ingredient_order);

-- Meal Instructions indexes
CREATE INDEX idx_meal_instructions_meal_id ON public.meal_instructions(meal_id);
CREATE INDEX idx_meal_instructions_order ON public.meal_instructions(meal_id, step_order);

-- =============================================================================
-- STEP 4: ENABLE RLS AND CREATE FRESH POLICIES
-- =============================================================================

-- Enable RLS on all meal plan tables
ALTER TABLE public.meal_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.day_meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_instructions ENABLE ROW LEVEL SECURITY;

-- Meal Plans policies
CREATE POLICY "Users can view own meal plans" ON public.meal_plans
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own meal plans" ON public.meal_plans
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own meal plans" ON public.meal_plans
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own meal plans" ON public.meal_plans
    FOR DELETE USING (auth.uid() = user_id);

-- Meals policies (simplified for authenticated users)
CREATE POLICY "Users can view meals in their meal plans" ON public.meals
    FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can insert meals for their meal plans" ON public.meals
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Users can update meals in their meal plans" ON public.meals
    FOR UPDATE USING (auth.uid() IS NOT NULL);

CREATE POLICY "Users can delete meals in their meal plans" ON public.meals
    FOR DELETE USING (auth.uid() IS NOT NULL);

-- Day Meals policies
CREATE POLICY "Users can view day meals in their meal plans" ON public.day_meals
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.meal_plans mp
            WHERE mp.id = day_meals.meal_plan_id AND mp.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert day meals for their meal plans" ON public.day_meals
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.meal_plans mp
            WHERE mp.id = day_meals.meal_plan_id AND mp.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update day meals in their meal plans" ON public.day_meals
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.meal_plans mp
            WHERE mp.id = day_meals.meal_plan_id AND mp.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete day meals in their meal plans" ON public.day_meals
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.meal_plans mp
            WHERE mp.id = day_meals.meal_plan_id AND mp.user_id = auth.uid()
        )
    );

-- Meal Ingredients policies
CREATE POLICY "Users can view ingredients for their meals" ON public.meal_ingredients
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.day_meals dm
            JOIN public.meal_plans mp ON dm.meal_plan_id = mp.id
            WHERE dm.meal_id = meal_ingredients.meal_id AND mp.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert ingredients for their meals" ON public.meal_ingredients
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.day_meals dm
            JOIN public.meal_plans mp ON dm.meal_plan_id = mp.id
            WHERE dm.meal_id = meal_ingredients.meal_id AND mp.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update ingredients for their meals" ON public.meal_ingredients
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.day_meals dm
            JOIN public.meal_plans mp ON dm.meal_plan_id = mp.id
            WHERE dm.meal_id = meal_ingredients.meal_id AND mp.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete ingredients for their meals" ON public.meal_ingredients
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.day_meals dm
            JOIN public.meal_plans mp ON dm.meal_plan_id = mp.id
            WHERE dm.meal_id = meal_ingredients.meal_id AND mp.user_id = auth.uid()
        )
    );

-- Meal Instructions policies
CREATE POLICY "Users can view instructions for their meals" ON public.meal_instructions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.day_meals dm
            JOIN public.meal_plans mp ON dm.meal_plan_id = mp.id
            WHERE dm.meal_id = meal_instructions.meal_id AND mp.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert instructions for their meals" ON public.meal_instructions
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.day_meals dm
            JOIN public.meal_plans mp ON dm.meal_plan_id = mp.id
            WHERE dm.meal_id = meal_instructions.meal_id AND mp.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update instructions for their meals" ON public.meal_instructions
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.day_meals dm
            JOIN public.meal_plans mp ON dm.meal_plan_id = mp.id
            WHERE dm.meal_id = meal_instructions.meal_id AND mp.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete instructions for their meals" ON public.meal_instructions
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.day_meals dm
            JOIN public.meal_plans mp ON dm.meal_plan_id = mp.id
            WHERE dm.meal_id = meal_instructions.meal_id AND mp.user_id = auth.uid()
        )
    );

-- =============================================================================
-- STEP 5: VERIFICATION AND SUCCESS MESSAGE
-- =============================================================================

DO $$
DECLARE
    policy_count INTEGER;
    index_count INTEGER;
BEGIN
    -- Check that RLS policies exist
    SELECT COUNT(*) INTO policy_count 
    FROM pg_policies 
    WHERE tablename = 'meal_plans' AND schemaname = 'public';
    
    -- Check that indexes exist
    SELECT COUNT(*) INTO index_count
    FROM pg_indexes 
    WHERE tablename = 'meal_plans' AND schemaname = 'public';
    
    RAISE NOTICE '';
    RAISE NOTICE '🎉 DATABASE RESET AND FIX COMPLETED!';
    RAISE NOTICE '✅ Found % RLS policies for meal_plans', policy_count;
    RAISE NOTICE '✅ Found % indexes for meal_plans', index_count;
    RAISE NOTICE '';
    RAISE NOTICE '💡 Next steps:';
    RAISE NOTICE '   1. Run the test_user_meal_plans.sql script';
    RAISE NOTICE '   2. Build and run your updated app';
    RAISE NOTICE '   3. Try creating a new meal plan';
    RAISE NOTICE '';
END $$;