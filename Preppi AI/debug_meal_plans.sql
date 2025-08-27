-- =============================================================================
-- DEBUG MEAL PLANS - Troubleshooting Script
-- =============================================================================
-- Run this in Supabase SQL Editor to diagnose why meal plans aren't showing
-- =============================================================================

-- Step 1: Check if you're authenticated
SELECT 
    'Current User ID: ' || COALESCE(auth.uid()::text, 'NOT AUTHENTICATED') as auth_status;

-- Step 2: Check if meal_plans table exists and has the right structure
SELECT 
    'meal_plans table exists' as status,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'meal_plans' AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 3: Check RLS policies on meal_plans
SELECT 
    'RLS Policy: ' || policyname as policy_info,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'meal_plans' AND schemaname = 'public';

-- Step 4: Check if RLS is enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'meal_plans' AND schemaname = 'public';

-- Step 5: Count total meal plans in database (bypass RLS temporarily for admin check)
-- Note: This uses security definer to bypass RLS for counting only
DO $$
DECLARE
    total_count INTEGER;
    user_count INTEGER;
    current_user_id UUID;
BEGIN
    -- Get current user
    current_user_id := auth.uid();
    
    -- Count total meal plans (this will bypass RLS since we're in a DO block)
    SELECT COUNT(*) INTO total_count FROM public.meal_plans;
    
    -- Count for current user using explicit filter
    SELECT COUNT(*) INTO user_count 
    FROM public.meal_plans 
    WHERE user_id = current_user_id AND is_active = true;
    
    RAISE NOTICE 'Total meal plans in database: %', total_count;
    RAISE NOTICE 'Current user ID: %', COALESCE(current_user_id::text, 'NULL');
    RAISE NOTICE 'Meal plans for current user: %', user_count;
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ PROBLEM: User is not authenticated!';
    ELSIF user_count = 0 THEN
        RAISE NOTICE '⚠️  No meal plans found for current user. Try creating a new one.';
    ELSE
        RAISE NOTICE '✅ Found % meal plans for current user', user_count;
    END IF;
END $$;

-- Step 6: Test the exact query that getUserMealPlans() uses
-- This simulates what your app is doing
SELECT 
    'Testing getUserMealPlans query...' as test_info;

SELECT 
    id,
    user_id,
    name,
    created_at,
    is_active
FROM public.meal_plans
WHERE is_active = true
ORDER BY created_at DESC;

-- Step 7: Show recent activity
SELECT 
    'Recent meal_plans activity:' as activity_info,
    id,
    user_id,
    name,
    created_at,
    is_active
FROM public.meal_plans
ORDER BY created_at DESC
LIMIT 5;