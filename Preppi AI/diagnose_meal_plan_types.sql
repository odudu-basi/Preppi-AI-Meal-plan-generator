-- =============================================================================
-- DIAGNOSE MEAL PLAN TYPES - Check what's actually in the database
-- =============================================================================
-- Run this to see how meal plans are being saved and why they're not showing on the correct cards
-- =============================================================================

-- Check what meal plan types we have in the database
SELECT 
    'Current meal plan types in database:' as info,
    meal_plan_type,
    COUNT(*) as count,
    MIN(created_at) as first_created,
    MAX(created_at) as last_created
FROM public.meal_plans 
WHERE is_active = true
GROUP BY meal_plan_type
ORDER BY count DESC;

-- Check all meal plans with their details
SELECT 
    'All meal plans details:' as info,
    id,
    user_id,
    name,
    meal_plan_type,
    selected_meal_types,
    week_start_date,
    created_at
FROM public.meal_plans
WHERE is_active = true AND user_id = auth.uid()
ORDER BY created_at DESC;

-- Check if meal_plan_type column exists and what values it has
SELECT DISTINCT 
    meal_plan_type,
    'Current meal plan type value' as description
FROM public.meal_plans 
WHERE is_active = true;

-- Check the current user's meal plans for this week
DO $$
DECLARE
    current_week_start DATE;
    current_week_end DATE;
    breakfast_count INTEGER;
    lunch_count INTEGER;
    dinner_count INTEGER;
BEGIN
    -- Calculate current week boundaries (Sunday to Saturday)
    current_week_start := DATE_TRUNC('week', CURRENT_DATE);
    current_week_end := current_week_start + INTERVAL '6 days';
    
    -- Count meal plans by type for current week
    SELECT COUNT(*) INTO breakfast_count
    FROM public.meal_plans 
    WHERE user_id = auth.uid() 
      AND is_active = true 
      AND meal_plan_type = 'breakfast'
      AND week_start_date >= current_week_start 
      AND week_start_date <= current_week_end;
      
    SELECT COUNT(*) INTO lunch_count
    FROM public.meal_plans 
    WHERE user_id = auth.uid() 
      AND is_active = true 
      AND meal_plan_type = 'lunch'
      AND week_start_date >= current_week_start 
      AND week_start_date <= current_week_end;
      
    SELECT COUNT(*) INTO dinner_count
    FROM public.meal_plans 
    WHERE user_id = auth.uid() 
      AND is_active = true 
      AND meal_plan_type = 'dinner'
      AND week_start_date >= current_week_start 
      AND week_start_date <= current_week_end;
    
    RAISE NOTICE '';
    RAISE NOTICE '📊 CURRENT WEEK MEAL PLAN SUMMARY:';
    RAISE NOTICE 'Week: % to %', current_week_start, current_week_end;
    RAISE NOTICE 'Current user: %', auth.uid();
    RAISE NOTICE 'Breakfast meal plans: %', breakfast_count;
    RAISE NOTICE 'Lunch meal plans: %', lunch_count;
    RAISE NOTICE 'Dinner meal plans: %', dinner_count;
    RAISE NOTICE '';
    
    IF breakfast_count = 0 AND lunch_count = 0 AND dinner_count = 0 THEN
        RAISE NOTICE '❌ NO MEAL PLANS found for current week!';
        RAISE NOTICE '💡 This means either:';
        RAISE NOTICE '   1. No meal plans created this week';
        RAISE NOTICE '   2. meal_plan_type values are incorrect';
        RAISE NOTICE '   3. week_start_date calculation is off';
    ELSE
        RAISE NOTICE '✅ Found meal plans for current week';
        IF breakfast_count > 0 THEN
            RAISE NOTICE '   - Breakfast card should show meal plan';
        ELSE
            RAISE NOTICE '   - Breakfast card should be empty';
        END IF;
        IF lunch_count > 0 THEN
            RAISE NOTICE '   - Lunch card should show meal plan';
        ELSE
            RAISE NOTICE '   - Lunch card should be empty';
        END IF;
        IF dinner_count > 0 THEN
            RAISE NOTICE '   - Dinner card should show meal plan';
        ELSE
            RAISE NOTICE '   - Dinner card should be empty';
        END IF;
    END IF;
END $$;