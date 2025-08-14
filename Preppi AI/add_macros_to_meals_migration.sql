-- Migration: Add macros columns to meals table
-- Description: Add nutritional macronutrient columns to store detailed nutritional information for each meal

-- Add macros columns to the meals table
ALTER TABLE public.meals ADD COLUMN IF NOT EXISTS protein DECIMAL(5,2) DEFAULT NULL;
ALTER TABLE public.meals ADD COLUMN IF NOT EXISTS carbohydrates DECIMAL(5,2) DEFAULT NULL;
ALTER TABLE public.meals ADD COLUMN IF NOT EXISTS fat DECIMAL(5,2) DEFAULT NULL;
ALTER TABLE public.meals ADD COLUMN IF NOT EXISTS fiber DECIMAL(5,2) DEFAULT NULL;
ALTER TABLE public.meals ADD COLUMN IF NOT EXISTS sugar DECIMAL(5,2) DEFAULT NULL;
ALTER TABLE public.meals ADD COLUMN IF NOT EXISTS sodium DECIMAL(7,2) DEFAULT NULL; -- Higher precision for sodium (mg)

-- Add comments for documentation
COMMENT ON COLUMN public.meals.protein IS 'Protein content in grams';
COMMENT ON COLUMN public.meals.carbohydrates IS 'Carbohydrate content in grams';
COMMENT ON COLUMN public.meals.fat IS 'Fat content in grams';
COMMENT ON COLUMN public.meals.fiber IS 'Fiber content in grams';
COMMENT ON COLUMN public.meals.sugar IS 'Sugar content in grams';
COMMENT ON COLUMN public.meals.sodium IS 'Sodium content in milligrams';

-- Add indexes for potential macro-based filtering (optional, can be added later if needed)
-- CREATE INDEX IF NOT EXISTS idx_meals_protein ON public.meals(protein) WHERE protein IS NOT NULL;
-- CREATE INDEX IF NOT EXISTS idx_meals_carbohydrates ON public.meals(carbohydrates) WHERE carbohydrates IS NOT NULL;
-- CREATE INDEX IF NOT EXISTS idx_meals_fat ON public.meals(fat) WHERE fat IS NOT NULL;

-- Update the updated_at trigger to include new columns (if trigger exists)
-- The existing trigger should automatically handle these new columns