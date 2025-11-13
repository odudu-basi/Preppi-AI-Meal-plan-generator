-- =============================================================================
-- ADD MISSING ONBOARDING FIELDS MIGRATION (FIXED)
-- =============================================================================
-- This migration adds missing fields to the user_profiles table that are
-- part of the UserOnboardingData model but missing from the database schema
-- =============================================================================

-- Add missing experience tracking fields
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS has_tried_calorie_tracking BOOLEAN DEFAULT NULL;

ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS has_tried_meal_planning BOOLEAN DEFAULT NULL;

-- Add missing weight goal fields
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS target_weight DECIMAL(5,2) DEFAULT NULL CHECK (target_weight >= 0);

ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS weight_loss_speed TEXT DEFAULT NULL;

-- Add nutrition plan field (stores the generated nutrition plan as JSON)
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS nutrition_plan JSONB DEFAULT NULL;

-- =============================================================================
-- CLEAN UP EXISTING DATA BEFORE ADDING CONSTRAINTS
-- =============================================================================

-- First, let's see what values exist in weight_loss_speed column
-- and clean up any invalid values before adding the constraint

-- Update any invalid weight_loss_speed values to NULL
UPDATE public.user_profiles 
SET weight_loss_speed = NULL 
WHERE weight_loss_speed IS NOT NULL 
AND weight_loss_speed NOT IN ('slow', 'moderate', 'fast');

-- =============================================================================
-- UPDATE INDEXES FOR NEW FIELDS
-- =============================================================================

-- Index for experience tracking (useful for analytics)
CREATE INDEX IF NOT EXISTS idx_user_profiles_calorie_tracking_exp 
ON public.user_profiles(has_tried_calorie_tracking) 
WHERE has_tried_calorie_tracking IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_user_profiles_meal_planning_exp 
ON public.user_profiles(has_tried_meal_planning) 
WHERE has_tried_meal_planning IS NOT NULL;

-- Index for target weight (useful for goal tracking)
CREATE INDEX IF NOT EXISTS idx_user_profiles_target_weight 
ON public.user_profiles(target_weight) 
WHERE target_weight IS NOT NULL;

-- Index for weight loss speed (useful for filtering users by goal type)
CREATE INDEX IF NOT EXISTS idx_user_profiles_weight_loss_speed 
ON public.user_profiles(weight_loss_speed) 
WHERE weight_loss_speed IS NOT NULL;

-- GIN index for nutrition plan JSONB field
CREATE INDEX IF NOT EXISTS idx_user_profiles_nutrition_plan 
ON public.user_profiles USING GIN(nutrition_plan) 
WHERE nutrition_plan IS NOT NULL;

-- =============================================================================
-- UPDATE VIEW TO INCLUDE NEW FIELDS
-- =============================================================================

-- Drop and recreate the view to include new columns
DROP VIEW IF EXISTS public.user_profiles_with_auth;

CREATE OR REPLACE VIEW public.user_profiles_with_auth AS
SELECT 
    up.id,
    up.user_id,
    up.email,
    up.name,
    up.sex,
    up.age,
    up.weight,
    up.height,
    up.likes_to_cook,
    up.cooking_preference,
    up.activity_level,
    up.marketing_source,
    up.motivations,
    up.motivation_other,
    up.challenges,
    up.health_goals,
    up.dietary_restrictions,
    up.food_allergies,
    up.weekly_budget,
    -- NEW FIELDS
    up.has_tried_calorie_tracking,
    up.has_tried_meal_planning,
    up.target_weight,
    up.weight_loss_speed,
    up.nutrition_plan,
    -- STATUS AND TIMESTAMPS
    up.onboarding_completed,
    up.created_at,
    up.updated_at,
    au.created_at as auth_created_at,
    au.confirmed_at as auth_confirmed_at,
    au.last_sign_in_at as auth_last_sign_in_at
FROM public.user_profiles up
LEFT JOIN auth.users au ON up.user_id = au.id;

-- =============================================================================
-- VALIDATION CONSTRAINTS (AFTER DATA CLEANUP)
-- =============================================================================

-- Add constraint for weight_loss_speed enum values (only if it doesn't exist)
-- This will now work because we cleaned up the data above
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'check_weight_loss_speed' 
        AND table_name = 'user_profiles'
    ) THEN
        ALTER TABLE public.user_profiles 
        ADD CONSTRAINT check_weight_loss_speed 
        CHECK (weight_loss_speed IS NULL OR weight_loss_speed IN (
            'slow', 'moderate', 'fast'
        ));
    END IF;
END $$;

-- =============================================================================
-- COMMENTS FOR DOCUMENTATION
-- =============================================================================

COMMENT ON COLUMN public.user_profiles.has_tried_calorie_tracking IS 
'Boolean indicating if user has previous experience with calorie tracking apps';

COMMENT ON COLUMN public.user_profiles.has_tried_meal_planning IS 
'Boolean indicating if user has previous experience with meal planning apps';

COMMENT ON COLUMN public.user_profiles.target_weight IS 
'User target weight in pounds (for weight loss/gain goals)';

COMMENT ON COLUMN public.user_profiles.weight_loss_speed IS 
'Preferred speed for reaching weight goals: slow, moderate, fast';

COMMENT ON COLUMN public.user_profiles.nutrition_plan IS 
'Generated nutrition plan data stored as JSON (macros, calories, etc.)';

-- =============================================================================
-- VERIFICATION QUERIES (OPTIONAL - FOR TESTING)
-- =============================================================================

/*
-- Check if migration was successful
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
AND column_name IN (
    'has_tried_calorie_tracking',
    'has_tried_meal_planning', 
    'target_weight',
    'weight_loss_speed',
    'nutrition_plan'
)
ORDER BY column_name;

-- Check constraint was added
SELECT constraint_name, check_clause
FROM information_schema.check_constraints
WHERE constraint_name = 'check_weight_loss_speed';

-- Check for any remaining invalid weight_loss_speed values
SELECT DISTINCT weight_loss_speed, COUNT(*)
FROM public.user_profiles 
GROUP BY weight_loss_speed
ORDER BY weight_loss_speed;
*/
