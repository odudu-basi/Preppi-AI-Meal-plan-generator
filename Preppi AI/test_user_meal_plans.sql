-- =============================================================================
-- TEST USER MEAL PLANS - Check what user ID your app should be using
-- =============================================================================
-- Run this to see if there's a mismatch between your current user and stored meal plans
-- =============================================================================

-- Check what user ID you're currently authenticated as
SELECT 
    'Your current user ID: ' || COALESCE(auth.uid()::text, 'NOT AUTHENTICATED') as current_user_info;

-- Check what user IDs have meal plans
SELECT 
    'User IDs with meal plans:' as info,
    user_id,
    COUNT(*) as meal_plan_count,
    MAX(created_at) as most_recent_plan
FROM public.meal_plans 
WHERE is_active = true
GROUP BY user_id
ORDER BY most_recent_plan DESC;

-- Test if your current session can see any meal plans with explicit filtering
SELECT 
    'Testing explicit user filter:' as test_type,
    COUNT(*) as meal_plans_found
FROM public.meal_plans 
WHERE user_id = auth.uid() AND is_active = true;

-- Test the exact query your updated app should be running
SELECT 
    'Simulating app query:' as test_type,
    id,
    user_id,
    name,
    created_at
FROM public.meal_plans
WHERE user_id = auth.uid() AND is_active = true
ORDER BY created_at DESC;

-- Check if RLS is causing issues by testing with RLS disabled (admin check)
DO $$
DECLARE
    current_user_uuid UUID;
    explicit_count INTEGER;
    rls_count INTEGER;
BEGIN
    current_user_uuid := auth.uid();
    
    -- Count with explicit user_id filter (what our updated code does)
    SELECT COUNT(*) INTO explicit_count
    FROM public.meal_plans 
    WHERE user_id = current_user_uuid AND is_active = true;
    
    -- Count with RLS only (what original code relied on)
    SELECT COUNT(*) INTO rls_count
    FROM public.meal_plans 
    WHERE is_active = true; -- RLS should automatically filter by user
    
    RAISE NOTICE 'Current user: %', COALESCE(current_user_uuid::text, 'NULL');
    RAISE NOTICE 'Explicit filter count: %', explicit_count;
    RAISE NOTICE 'RLS-only count: %', rls_count;
    
    IF current_user_uuid IS NULL THEN
        RAISE NOTICE '❌ You are not authenticated!';
    ELSIF explicit_count = 0 THEN
        RAISE NOTICE '⚠️  No meal plans found for your current user ID';
        RAISE NOTICE '💡 Your meal plans might be under a different user account';
    ELSIF explicit_count != rls_count THEN
        RAISE NOTICE '⚠️  RLS filtering is not working correctly';
        RAISE NOTICE '💡 Updated app code with explicit filtering should fix this';
    ELSE
        RAISE NOTICE '✅ Everything looks good - you should see % meal plans', explicit_count;
    END IF;
END $$;