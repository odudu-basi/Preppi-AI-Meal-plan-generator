-- Migration to add image_url and recommended_calories_before_dinner columns to existing meals table
-- Run this in your Supabase SQL editor

BEGIN;

-- First, drop the existing view to avoid conflicts
DROP VIEW IF EXISTS public.complete_meal_plans;

-- Add the image_url column to the meals table
ALTER TABLE public.meals 
ADD COLUMN IF NOT EXISTS image_url TEXT;

-- Add the recommended_calories_before_dinner column to the meals table
ALTER TABLE public.meals 
ADD COLUMN IF NOT EXISTS recommended_calories_before_dinner INTEGER DEFAULT 0;

-- Add detailed recipe fields to the meals table
ALTER TABLE public.meals 
ADD COLUMN IF NOT EXISTS detailed_ingredients JSONB DEFAULT '[]'::jsonb;

ALTER TABLE public.meals 
ADD COLUMN IF NOT EXISTS detailed_instructions JSONB DEFAULT '[]'::jsonb;

ALTER TABLE public.meals 
ADD COLUMN IF NOT EXISTS cooking_tips JSONB DEFAULT '[]'::jsonb;

ALTER TABLE public.meals 
ADD COLUMN IF NOT EXISTS serving_info TEXT;

-- Recreate the complete_meal_plans view to include the new columns
CREATE VIEW public.complete_meal_plans AS
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
    m.recommended_calories_before_dinner,
    m.detailed_ingredients,
    m.detailed_instructions,
    m.cooking_tips,
    m.serving_info,
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
    m.description, m.calories, m.cook_time, m.original_cooking_day, m.image_url, m.recommended_calories_before_dinner, m.detailed_ingredients, m.detailed_instructions, m.cooking_tips, m.serving_info
ORDER BY mp.created_at DESC, dm.day_order;

COMMIT;

-- Verify the columns were added
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'meals' AND column_name IN ('image_url', 'recommended_calories_before_dinner', 'detailed_ingredients', 'detailed_instructions', 'cooking_tips', 'serving_info');