-- =============================================================================
-- FIX MEAL PLAN TYPES - Update existing meal plans to have correct meal types
-- =============================================================================
-- This script will help distribute existing meal plans across different meal types
-- Run this ONLY if the diagnostic shows all meal plans have meal_plan_type = "dinner"
-- =============================================================================

-- OPTION 1: Manual Update (RECOMMENDED)
-- Update specific meal plans to be breakfast or lunch based on their IDs
-- First, let's see all your current meal plans so you can choose which ones to update

SELECT 
    'Your current meal plans (choose which to update):' as info,
    id,
    name,
    meal_plan_type,
    week_start_date,
    created_at
FROM public.meal_plans
WHERE user_id = auth.uid() AND is_active = true
ORDER BY created_at DESC;

-- MANUAL UPDATE INSTRUCTIONS:
-- 1. Look at the meal plans above
-- 2. Choose which ones you want to be breakfast, lunch, or dinner
-- 3. Update them using the queries below (replace the UUIDs with actual IDs)

-- Example: Update a specific meal plan to be breakfast
-- UPDATE public.meal_plans 
-- SET meal_plan_type = 'breakfast' 
-- WHERE id = 'YOUR-MEAL-PLAN-ID-HERE' AND user_id = auth.uid();

-- Example: Update a specific meal plan to be lunch  
-- UPDATE public.meal_plans 
-- SET meal_plan_type = 'lunch' 
-- WHERE id = 'YOUR-MEAL-PLAN-ID-HERE' AND user_id = auth.uid();

-- =============================================================================
-- OPTION 2: Automatic Distribution (USE WITH CAUTION)
-- Automatically distribute your most recent 3 meal plans across breakfast, lunch, dinner
-- ONLY run this if you want automatic distribution
-- =============================================================================

-- Uncomment and run this ONLY if you want automatic distribution:
/*
DO $$
DECLARE
    breakfast_id UUID;
    lunch_id UUID;
    dinner_id UUID;
BEGIN
    -- Get the 3 most recent meal plans for the current user
    SELECT id INTO dinner_id
    FROM public.meal_plans 
    WHERE user_id = auth.uid() AND is_active = true
    ORDER BY created_at DESC
    LIMIT 1 OFFSET 0;
    
    SELECT id INTO lunch_id
    FROM public.meal_plans 
    WHERE user_id = auth.uid() AND is_active = true
    ORDER BY created_at DESC
    LIMIT 1 OFFSET 1;
    
    SELECT id INTO breakfast_id
    FROM public.meal_plans 
    WHERE user_id = auth.uid() AND is_active = true
    ORDER BY created_at DESC
    LIMIT 1 OFFSET 2;
    
    -- Update the meal plan types
    IF dinner_id IS NOT NULL THEN
        UPDATE public.meal_plans 
        SET meal_plan_type = 'dinner' 
        WHERE id = dinner_id;
        RAISE NOTICE 'Updated most recent meal plan to dinner: %', dinner_id;
    END IF;
    
    IF lunch_id IS NOT NULL THEN
        UPDATE public.meal_plans 
        SET meal_plan_type = 'lunch' 
        WHERE id = lunch_id;
        RAISE NOTICE 'Updated second most recent meal plan to lunch: %', lunch_id;
    END IF;
    
    IF breakfast_id IS NOT NULL THEN
        UPDATE public.meal_plans 
        SET meal_plan_type = 'breakfast' 
        WHERE id = breakfast_id;
        RAISE NOTICE 'Updated third most recent meal plan to breakfast: %', breakfast_id;
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '✅ Automatic distribution completed!';
    RAISE NOTICE '💡 Your app should now show meal plans on the correct cards.';
END $$;
*/

-- =============================================================================
-- VERIFICATION QUERY
-- =============================================================================

-- Run this after making updates to verify the changes
SELECT 
    '✅ AFTER UPDATE - Your meal plans by type:' as verification,
    meal_plan_type,
    COUNT(*) as count,
    array_agg(name ORDER BY created_at DESC) as meal_plan_names
FROM public.meal_plans
WHERE user_id = auth.uid() AND is_active = true
GROUP BY meal_plan_type
ORDER BY meal_plan_type;