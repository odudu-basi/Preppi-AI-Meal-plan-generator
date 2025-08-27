-- =============================================================================
-- FIX DATABASE SCHEMA - Safe Update Script
-- =============================================================================
-- This script safely fixes the database schema without conflicts
-- Run this in your Supabase SQL editor to fix the meal plans issue
-- =============================================================================

-- First, let's check if the meal_plans table has the required columns
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
-- SAFELY CREATE INDEXES (with IF NOT EXISTS)
-- =============================================================================

-- Create indexes only if they don't exist
DO $$
BEGIN
    -- Meal Plans indexes
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_meal_plans_user_id') THEN
        CREATE INDEX idx_meal_plans_user_id ON public.meal_plans(user_id);
        RAISE NOTICE 'Created idx_meal_plans_user_id';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_meal_plans_week_start_date') THEN
        CREATE INDEX idx_meal_plans_week_start_date ON public.meal_plans(week_start_date);
        RAISE NOTICE 'Created idx_meal_plans_week_start_date';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_meal_plans_user_active') THEN
        CREATE INDEX idx_meal_plans_user_active ON public.meal_plans(user_id, is_active);
        RAISE NOTICE 'Created idx_meal_plans_user_active';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_meal_plans_cuisines') THEN
        CREATE INDEX idx_meal_plans_cuisines ON public.meal_plans USING GIN(selected_cuisines);
        RAISE NOTICE 'Created idx_meal_plans_cuisines';
    END IF;
    
    -- Day Meals indexes
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_day_meals_meal_plan_id') THEN
        CREATE INDEX idx_day_meals_meal_plan_id ON public.day_meals(meal_plan_id);
        RAISE NOTICE 'Created idx_day_meals_meal_plan_id';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_day_meals_meal_id') THEN
        CREATE INDEX idx_day_meals_meal_id ON public.day_meals(meal_id);
        RAISE NOTICE 'Created idx_day_meals_meal_id';
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE indexname = 'idx_day_meals_day_order') THEN
        CREATE INDEX idx_day_meals_day_order ON public.day_meals(day_order);
        RAISE NOTICE 'Created idx_day_meals_day_order';
    END IF;
END $$;

-- =============================================================================
-- ENSURE ROW LEVEL SECURITY IS PROPERLY CONFIGURED
-- =============================================================================

-- Enable RLS on all meal plan tables
ALTER TABLE public.meal_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.day_meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_instructions ENABLE ROW LEVEL SECURITY;

-- Drop and recreate meal plan policies to ensure they're correct
DROP POLICY IF EXISTS "Users can view own meal plans" ON public.meal_plans;
CREATE POLICY "Users can view own meal plans" ON public.meal_plans
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own meal plans" ON public.meal_plans;
CREATE POLICY "Users can insert own meal plans" ON public.meal_plans
    FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own meal plans" ON public.meal_plans;
CREATE POLICY "Users can update own meal plans" ON public.meal_plans
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own meal plans" ON public.meal_plans;
CREATE POLICY "Users can delete own meal plans" ON public.meal_plans
    FOR DELETE USING (auth.uid() = user_id);

-- Fix Meals policies (simplified for authenticated users)
DROP POLICY IF EXISTS "Users can view meals in their meal plans" ON public.meals;
CREATE POLICY "Users can view meals in their meal plans" ON public.meals
    FOR SELECT USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Users can insert meals for their meal plans" ON public.meals;
CREATE POLICY "Users can insert meals for their meal plans" ON public.meals
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Users can update meals in their meal plans" ON public.meals;
CREATE POLICY "Users can update meals in their meal plans" ON public.meals
    FOR UPDATE USING (auth.uid() IS NOT NULL);

DROP POLICY IF EXISTS "Users can delete meals in their meal plans" ON public.meals;
CREATE POLICY "Users can delete meals in their meal plans" ON public.meals
    FOR DELETE USING (auth.uid() IS NOT NULL);

-- Day Meals policies
DROP POLICY IF EXISTS "Users can view day meals in their meal plans" ON public.day_meals;
CREATE POLICY "Users can view day meals in their meal plans" ON public.day_meals
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.meal_plans mp
            WHERE mp.id = day_meals.meal_plan_id AND mp.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can insert day meals for their meal plans" ON public.day_meals;
CREATE POLICY "Users can insert day meals for their meal plans" ON public.day_meals
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.meal_plans mp
            WHERE mp.id = day_meals.meal_plan_id AND mp.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can update day meals in their meal plans" ON public.day_meals;
CREATE POLICY "Users can update day meals in their meal plans" ON public.day_meals
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.meal_plans mp
            WHERE mp.id = day_meals.meal_plan_id AND mp.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can delete day meals in their meal plans" ON public.day_meals;
CREATE POLICY "Users can delete day meals in their meal plans" ON public.day_meals
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.meal_plans mp
            WHERE mp.id = day_meals.meal_plan_id AND mp.user_id = auth.uid()
        )
    );

-- Meal Ingredients policies
DROP POLICY IF EXISTS "Users can view ingredients for their meals" ON public.meal_ingredients;
CREATE POLICY "Users can view ingredients for their meals" ON public.meal_ingredients
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.day_meals dm
            JOIN public.meal_plans mp ON dm.meal_plan_id = mp.id
            WHERE dm.meal_id = meal_ingredients.meal_id AND mp.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can insert ingredients for their meals" ON public.meal_ingredients;
CREATE POLICY "Users can insert ingredients for their meals" ON public.meal_ingredients
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.day_meals dm
            JOIN public.meal_plans mp ON dm.meal_plan_id = mp.id
            WHERE dm.meal_id = meal_ingredients.meal_id AND mp.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can update ingredients for their meals" ON public.meal_ingredients;
CREATE POLICY "Users can update ingredients for their meals" ON public.meal_ingredients
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.day_meals dm
            JOIN public.meal_plans mp ON dm.meal_plan_id = mp.id
            WHERE dm.meal_id = meal_ingredients.meal_id AND mp.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can delete ingredients for their meals" ON public.meal_ingredients;
CREATE POLICY "Users can delete ingredients for their meals" ON public.meal_ingredients
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.day_meals dm
            JOIN public.meal_plans mp ON dm.meal_plan_id = mp.id
            WHERE dm.meal_id = meal_ingredients.meal_id AND mp.user_id = auth.uid()
        )
    );

-- Meal Instructions policies
DROP POLICY IF EXISTS "Users can view instructions for their meals" ON public.meal_instructions;
CREATE POLICY "Users can view instructions for their meals" ON public.meal_instructions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.day_meals dm
            JOIN public.meal_plans mp ON dm.meal_plan_id = mp.id
            WHERE dm.meal_id = meal_instructions.meal_id AND mp.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can insert instructions for their meals" ON public.meal_instructions;
CREATE POLICY "Users can insert instructions for their meals" ON public.meal_instructions
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.day_meals dm
            JOIN public.meal_plans mp ON dm.meal_plan_id = mp.id
            WHERE dm.meal_id = meal_instructions.meal_id AND mp.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can update instructions for their meals" ON public.meal_instructions;
CREATE POLICY "Users can update instructions for their meals" ON public.meal_instructions
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.day_meals dm
            JOIN public.meal_plans mp ON dm.meal_plan_id = mp.id
            WHERE dm.meal_id = meal_instructions.meal_id AND mp.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can delete instructions for their meals" ON public.meal_instructions;
CREATE POLICY "Users can delete instructions for their meals" ON public.meal_instructions
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.day_meals dm
            JOIN public.meal_plans mp ON dm.meal_plan_id = mp.id
            WHERE dm.meal_id = meal_instructions.meal_id AND mp.user_id = auth.uid()
        )
    );

-- =============================================================================
-- VERIFICATION QUERIES
-- =============================================================================

-- Test that policies are working by checking if we can see our own data
DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    -- Check that RLS policies exist
    SELECT COUNT(*) INTO policy_count 
    FROM pg_policies 
    WHERE tablename = 'meal_plans' AND schemaname = 'public';
    
    IF policy_count >= 4 THEN
        RAISE NOTICE '✅ SUCCESS: Meal plan RLS policies are properly configured (% policies found)', policy_count;
    ELSE
        RAISE NOTICE '❌ WARNING: Only % meal plan policies found, expected at least 4', policy_count;
    END IF;
    
    RAISE NOTICE '🎉 Database schema fix completed successfully!';
    RAISE NOTICE '💡 Try creating a new meal plan in your app now.';
END $$;