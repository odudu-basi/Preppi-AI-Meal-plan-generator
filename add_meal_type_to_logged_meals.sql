-- Migration: Add meal_type column to logged_meals table
-- This column tracks whether a logged meal is breakfast, lunch, dinner, or extra

-- Add meal_type column
ALTER TABLE logged_meals 
ADD COLUMN IF NOT EXISTS meal_type TEXT CHECK (meal_type IN ('breakfast', 'lunch', 'dinner') OR meal_type IS NULL);

-- Add comment for documentation
COMMENT ON COLUMN logged_meals.meal_type IS 'Type of meal: breakfast, lunch, dinner, or NULL for extra meals';

-- Create index for meal_type queries
CREATE INDEX IF NOT EXISTS idx_logged_meals_meal_type ON logged_meals(meal_type);

-- Create composite index for user and meal_type queries
CREATE INDEX IF NOT EXISTS idx_logged_meals_user_meal_type ON logged_meals(user_id, meal_type);
