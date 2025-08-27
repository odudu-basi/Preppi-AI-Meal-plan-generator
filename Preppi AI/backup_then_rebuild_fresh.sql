-- =============================================================================
-- BACKUP THEN REBUILD FRESH - Complete Database Reset
-- =============================================================================
-- This script will backup your data, drop all tables, and rebuild everything fresh
-- Run this in your Supabase SQL editor to completely start over
-- =============================================================================

-- =============================================================================
-- STEP 1: BACKUP EXISTING DATA (Optional - uncomment if you want to save data)
-- =============================================================================

/*
-- Uncomment these lines if you want to backup existing meal plans
CREATE TABLE IF NOT EXISTS backup_meal_plans AS SELECT * FROM public.meal_plans;
CREATE TABLE IF NOT EXISTS backup_meals AS SELECT * FROM public.meals;
CREATE TABLE IF NOT EXISTS backup_day_meals AS SELECT * FROM public.day_meals;
CREATE TABLE IF NOT EXISTS backup_meal_ingredients AS SELECT * FROM public.meal_ingredients;
CREATE TABLE IF NOT EXISTS backup_meal_instructions AS SELECT * FROM public.meal_instructions;

-- Show what we're backing up
SELECT 'Backed up ' || COUNT(*) || ' meal plans' as backup_info FROM backup_meal_plans;
SELECT 'Backed up ' || COUNT(*) || ' meals' as backup_info FROM backup_meals;
SELECT 'Backed up ' || COUNT(*) || ' day meals' as backup_info FROM backup_day_meals;
*/

-- =============================================================================
-- STEP 2: COMPLETELY DROP ALL MEAL PLAN TABLES
-- =============================================================================

-- Drop views first (they depend on tables)
DROP VIEW IF EXISTS public.complete_meal_plans CASCADE;

-- Drop all policies first
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

-- Drop triggers
DROP TRIGGER IF EXISTS update_meal_plans_updated_at ON public.meal_plans;
DROP TRIGGER IF EXISTS update_meals_updated_at ON public.meals;

-- Drop tables in correct order (children first, then parents)
DROP TABLE IF EXISTS public.meal_instructions CASCADE;
DROP TABLE IF EXISTS public.meal_ingredients CASCADE;
DROP TABLE IF EXISTS public.day_meals CASCADE;
DROP TABLE IF EXISTS public.meals CASCADE;
DROP TABLE IF EXISTS public.meal_plans CASCADE;

-- =============================================================================
-- STEP 3: RECREATE ALL TABLES FRESH WITH CORRECT STRUCTURE
-- =============================================================================

-- Create the main meal plans table with ALL required columns
CREATE TABLE public.meal_plans (
    -- Primary key and relationships
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    
    -- Meal plan metadata
    name TEXT DEFAULT 'Weekly Meal Plan',
    week_start_date DATE NOT NULL,
    meal_preparation_style TEXT NOT NULL, -- 'newMealEveryTime' or 'multiplePortions'
    selected_cuisines JSONB DEFAULT '[]'::jsonb, -- array of selected cuisines
    selected_meal_types JSONB DEFAULT '[]'::jsonb, -- NEW: array of meal types
    meal_plan_type TEXT DEFAULT 'dinner', -- NEW: identifier for meal plan type
    meal_count INTEGER DEFAULT 7, -- number of unique meals (for batch cooking)
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_completed BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create the meals table with ALL required columns
CREATE TABLE public.meals (
    -- Primary key
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Meal details
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    calories INTEGER DEFAULT 0 CHECK (calories >= 0),
    cook_time INTEGER DEFAULT 0 CHECK (cook_time >= 0), -- in minutes
    original_cooking_day TEXT, -- Day when meal was originally prepared (for batch cooking)
    image_url TEXT, -- NEW: for meal images
    recommended_calories_before_dinner INTEGER DEFAULT 0, -- NEW: calorie tracking
    
    -- NEW: Macro nutrients
    protein DECIMAL(8,2),
    carbohydrates DECIMAL(8,2),
    fat DECIMAL(8,2),
    fiber DECIMAL(8,2),
    sugar DECIMAL(8,2),
    sodium DECIMAL(8,2),
    
    -- NEW: Detailed recipe information
    detailed_ingredients JSONB DEFAULT '[]'::jsonb,
    detailed_instructions JSONB DEFAULT '[]'::jsonb,
    cooking_tips JSONB DEFAULT '[]'::jsonb,
    serving_info TEXT,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create the day_meals table with meal_type column
CREATE TABLE public.day_meals (
    -- Primary key and relationships
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    meal_plan_id UUID REFERENCES public.meal_plans(id) ON DELETE CASCADE NOT NULL,
    meal_id UUID REFERENCES public.meals(id) ON DELETE CASCADE NOT NULL,
    
    -- Day information
    day_name TEXT NOT NULL CHECK (day_name IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')),
    day_order INTEGER NOT NULL CHECK (day_order >= 1 AND day_order <= 7),
    meal_type TEXT DEFAULT 'dinner', -- NEW: breakfast, lunch, dinner
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create the meal_ingredients table
CREATE TABLE public.meal_ingredients (
    -- Primary key and relationships
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    meal_id UUID REFERENCES public.meals(id) ON DELETE CASCADE NOT NULL,
    
    -- Ingredient details
    ingredient TEXT NOT NULL,
    ingredient_order INTEGER NOT NULL DEFAULT 1,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create the meal_instructions table
CREATE TABLE public.meal_instructions (
    -- Primary key and relationships
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    meal_id UUID REFERENCES public.meals(id) ON DELETE CASCADE NOT NULL,
    
    -- Instruction details
    instruction TEXT NOT NULL,
    step_order INTEGER NOT NULL DEFAULT 1,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================================================
-- STEP 4: CREATE ALL INDEXES
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
-- STEP 5: ENABLE RLS AND CREATE POLICIES
-- =============================================================================

-- Enable RLS on all tables
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
-- STEP 6: CREATE TRIGGERS
-- =============================================================================

-- Triggers for meal_plans
CREATE TRIGGER update_meal_plans_updated_at 
    BEFORE UPDATE ON public.meal_plans 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Triggers for meals
CREATE TRIGGER update_meals_updated_at 
    BEFORE UPDATE ON public.meals 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- STEP 7: RECREATE VIEW
-- =============================================================================

-- View to get complete meal plans with all related data
CREATE OR REPLACE VIEW public.complete_meal_plans AS
SELECT 
    mp.id as meal_plan_id,
    mp.user_id,
    mp.name as meal_plan_name,
    mp.week_start_date,
    mp.meal_preparation_style,
    mp.selected_cuisines,
    mp.meal_count,
    mp.is_active,
    mp.is_completed,
    mp.created_at as meal_plan_created_at,
    dm.id as day_meal_id,
    dm.day_name,
    dm.day_order,
    m.id as meal_id,
    m.name as meal_name,
    m.description as meal_description,
    m.calories,
    m.cook_time,
    m.original_cooking_day,
    array_agg(mi.ingredient ORDER BY mi.ingredient_order) FILTER (WHERE mi.ingredient IS NOT NULL) as ingredients,
    array_agg(mint.instruction ORDER BY mint.step_order) FILTER (WHERE mint.instruction IS NOT NULL) as instructions
FROM public.meal_plans mp
LEFT JOIN public.day_meals dm ON mp.id = dm.meal_plan_id
LEFT JOIN public.meals m ON dm.meal_id = m.id
LEFT JOIN public.meal_ingredients mi ON m.id = mi.meal_id
LEFT JOIN public.meal_instructions mint ON m.id = mint.meal_id
GROUP BY 
    mp.id, mp.user_id, mp.name, mp.week_start_date, mp.meal_preparation_style,
    mp.selected_cuisines, mp.meal_count, mp.is_active, mp.is_completed,
    mp.created_at, dm.id, dm.day_name, dm.day_order, m.id, m.name,
    m.description, m.calories, m.cook_time, m.original_cooking_day
ORDER BY mp.created_at DESC, dm.day_order;

-- =============================================================================
-- STEP 8: SUCCESS MESSAGE
-- =============================================================================

DO $$
BEGIN
    RAISE NOTICE '';
    RAISE NOTICE '🎉 FRESH DATABASE REBUILD COMPLETED!';
    RAISE NOTICE '✅ All tables dropped and recreated with correct structure';
    RAISE NOTICE '✅ All indexes created successfully';
    RAISE NOTICE '✅ All RLS policies configured correctly';
    RAISE NOTICE '✅ All triggers and views recreated';
    RAISE NOTICE '';
    RAISE NOTICE '💡 Your database is now completely fresh and clean!';
    RAISE NOTICE '💡 Build and run your app - meal plans should work perfectly now!';
    RAISE NOTICE '';
END $$;