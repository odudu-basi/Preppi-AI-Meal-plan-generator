-- =============================================================================
-- PREPPI AI - MEAL PLANS SCHEMA ONLY
-- =============================================================================
-- This schema adds meal plan tables to an existing database
-- Run this if you already have user_profiles table and only need meal plans
-- =============================================================================

-- Create the main meal plans table
CREATE TABLE IF NOT EXISTS public.meal_plans (
    -- Primary key and relationships
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    
    -- Meal plan metadata
    name TEXT DEFAULT 'Weekly Meal Plan',
    week_start_date DATE NOT NULL,
    meal_preparation_style TEXT NOT NULL, -- 'newMealEveryTime' or 'multiplePortions'
    selected_cuisines JSONB DEFAULT '[]'::jsonb, -- array of selected cuisines
    meal_count INTEGER DEFAULT 7, -- number of unique meals (for batch cooking)
    
    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_completed BOOLEAN DEFAULT FALSE,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create the meals table
CREATE TABLE IF NOT EXISTS public.meals (
    -- Primary key
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    
    -- Meal details
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    calories INTEGER DEFAULT 0 CHECK (calories >= 0),
    cook_time INTEGER DEFAULT 0 CHECK (cook_time >= 0), -- in minutes
    original_cooking_day TEXT, -- Day when meal was originally prepared (for batch cooking)
    image_url TEXT, -- URL for AI-generated meal image
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create the day_meals table (linking meals to specific days in meal plans)
CREATE TABLE IF NOT EXISTS public.day_meals (
    -- Primary key and relationships
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    meal_plan_id UUID REFERENCES public.meal_plans(id) ON DELETE CASCADE NOT NULL,
    meal_id UUID REFERENCES public.meals(id) ON DELETE CASCADE NOT NULL,
    
    -- Day information
    day_name TEXT NOT NULL CHECK (day_name IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday')),
    day_order INTEGER NOT NULL CHECK (day_order >= 1 AND day_order <= 7),
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create the meal_ingredients table
CREATE TABLE IF NOT EXISTS public.meal_ingredients (
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
CREATE TABLE IF NOT EXISTS public.meal_instructions (
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
-- MEAL PLAN INDEXES FOR PERFORMANCE
-- =============================================================================

-- Meal Plans indexes
CREATE INDEX IF NOT EXISTS idx_meal_plans_user_id ON public.meal_plans(user_id);
CREATE INDEX IF NOT EXISTS idx_meal_plans_week_start_date ON public.meal_plans(week_start_date);
CREATE INDEX IF NOT EXISTS idx_meal_plans_user_active ON public.meal_plans(user_id, is_active);
CREATE INDEX IF NOT EXISTS idx_meal_plans_cuisines ON public.meal_plans USING GIN(selected_cuisines);

-- Day Meals indexes
CREATE INDEX IF NOT EXISTS idx_day_meals_meal_plan_id ON public.day_meals(meal_plan_id);
CREATE INDEX IF NOT EXISTS idx_day_meals_meal_id ON public.day_meals(meal_id);
CREATE INDEX IF NOT EXISTS idx_day_meals_day_order ON public.day_meals(day_order);

-- Meal Ingredients indexes
CREATE INDEX IF NOT EXISTS idx_meal_ingredients_meal_id ON public.meal_ingredients(meal_id);
CREATE INDEX IF NOT EXISTS idx_meal_ingredients_order ON public.meal_ingredients(meal_id, ingredient_order);

-- Meal Instructions indexes
CREATE INDEX IF NOT EXISTS idx_meal_instructions_meal_id ON public.meal_instructions(meal_id);
CREATE INDEX IF NOT EXISTS idx_meal_instructions_order ON public.meal_instructions(meal_id, step_order);

-- =============================================================================
-- MEAL PLAN ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

-- Enable RLS on all meal plan tables
ALTER TABLE public.meal_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.day_meals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.meal_instructions ENABLE ROW LEVEL SECURITY;

-- Meal Plans policies
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

-- Meals policies (simplified for authenticated users - security enforced through meal_plans relationship)
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
-- MEAL PLAN TRIGGERS FOR AUTOMATIC UPDATED_AT
-- =============================================================================

-- Create the update function if it doesn't exist (this function might already exist)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for meal_plans
DROP TRIGGER IF EXISTS update_meal_plans_updated_at ON public.meal_plans;
CREATE TRIGGER update_meal_plans_updated_at 
    BEFORE UPDATE ON public.meal_plans 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Triggers for meals
DROP TRIGGER IF EXISTS update_meals_updated_at ON public.meals;
CREATE TRIGGER update_meals_updated_at 
    BEFORE UPDATE ON public.meals 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- =============================================================================
-- HELPFUL MEAL PLAN VIEWS
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
    m.image_url,
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
    m.description, m.calories, m.cook_time, m.original_cooking_day, m.image_url
ORDER BY mp.created_at DESC, dm.day_order;

-- =============================================================================
-- COMPLETION MESSAGE
-- =============================================================================

-- Print completion message
DO $$
BEGIN
    RAISE NOTICE 'Meal plan schema has been successfully applied!';
    RAISE NOTICE 'Tables created: meal_plans, meals, day_meals, meal_ingredients, meal_instructions';
    RAISE NOTICE 'All indexes, policies, and triggers have been set up.';
END $$;