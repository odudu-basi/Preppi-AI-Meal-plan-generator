-- Run this query in Supabase SQL Editor to check if the migration was applied correctly

-- Check if the recipe columns exist
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'meals' 
AND column_name IN (
    'image_url', 
    'recommended_calories_before_dinner', 
    'detailed_ingredients', 
    'detailed_instructions', 
    'cooking_tips', 
    'serving_info'
)
ORDER BY column_name;

-- This should return 6 rows if the migration was applied correctly:
-- 1. cooking_tips - jsonb
-- 2. detailed_ingredients - jsonb  
-- 3. detailed_instructions - jsonb
-- 4. image_url - text
-- 5. recommended_calories_before_dinner - integer
-- 6. serving_info - text