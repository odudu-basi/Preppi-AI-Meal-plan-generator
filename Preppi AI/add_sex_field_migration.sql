-- Migration: Add sex field to user_profiles table
-- Description: Add sex column to store user's sex (Male/Female) for personalized meal planning
-- Date: 2025-01-18

-- Drop existing view to avoid conflicts when adding new columns
DROP VIEW IF EXISTS public.user_profiles_with_auth;

-- Add sex column to user_profiles table
ALTER TABLE public.user_profiles 
ADD COLUMN IF NOT EXISTS sex TEXT;

-- Add comment for documentation
COMMENT ON COLUMN public.user_profiles.sex IS 'User sex for personalized nutrition (Male/Female)';

-- Optional: Add a check constraint to ensure only valid values
-- First drop the constraint if it exists, then add it
DO $$ 
BEGIN
    -- Try to drop the constraint if it exists
    BEGIN
        ALTER TABLE public.user_profiles DROP CONSTRAINT IF EXISTS check_sex_valid;
    EXCEPTION
        WHEN undefined_object THEN NULL;
    END;
    
    -- Add the constraint
    ALTER TABLE public.user_profiles 
    ADD CONSTRAINT check_sex_valid 
    CHECK (sex IS NULL OR sex IN ('Male', 'Female'));
END $$;

-- Create index for potential filtering (if needed)
CREATE INDEX IF NOT EXISTS idx_user_profiles_sex ON public.user_profiles(sex);

-- Recreate the view with the new sex column included
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
    up.onboarding_completed,
    up.created_at,
    up.updated_at,
    au.created_at as auth_created_at,
    au.confirmed_at as auth_confirmed_at,
    au.last_sign_in_at as auth_last_sign_in_at
FROM public.user_profiles up
LEFT JOIN auth.users au ON up.user_id = au.id;

-- Verify the migration
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
AND column_name = 'sex';