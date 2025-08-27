-- Migration to add meal type support to the database
-- This migration adds the selected_meal_types column to meal_plans table
-- and meal_type column to day_meals table

-- Add selected_meal_types column to meal_plans table
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'meal_plans' 
        AND column_name = 'selected_meal_types'
    ) THEN
        ALTER TABLE meal_plans 
        ADD COLUMN selected_meal_types TEXT[] DEFAULT ARRAY['dinner'];
        
        -- Update existing meal plans to have dinner as default
        UPDATE meal_plans 
        SET selected_meal_types = ARRAY['dinner'] 
        WHERE selected_meal_types IS NULL;
        
        RAISE NOTICE 'Added selected_meal_types column to meal_plans table';
    ELSE
        RAISE NOTICE 'selected_meal_types column already exists in meal_plans table';
    END IF;
END
$$;

-- Add meal_type column to day_meals table
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'day_meals' 
        AND column_name = 'meal_type'
    ) THEN
        ALTER TABLE day_meals 
        ADD COLUMN meal_type TEXT DEFAULT 'dinner';
        
        -- Update existing day meals to be dinner type
        UPDATE day_meals 
        SET meal_type = 'dinner' 
        WHERE meal_type IS NULL;
        
        -- Make meal_type NOT NULL after setting defaults
        ALTER TABLE day_meals 
        ALTER COLUMN meal_type SET NOT NULL;
        
        RAISE NOTICE 'Added meal_type column to day_meals table';
    ELSE
        RAISE NOTICE 'meal_type column already exists in day_meals table';
    END IF;
END
$$;

-- Add check constraint to ensure valid meal types
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'day_meals' 
        AND constraint_name = 'valid_meal_type'
    ) THEN
        ALTER TABLE day_meals 
        ADD CONSTRAINT valid_meal_type 
        CHECK (meal_type IN ('breakfast', 'lunch', 'dinner'));
        
        RAISE NOTICE 'Added valid_meal_type constraint to day_meals table';
    ELSE
        RAISE NOTICE 'valid_meal_type constraint already exists';
    END IF;
END
$$;

-- Create index on meal_type for better query performance
CREATE INDEX IF NOT EXISTS idx_day_meals_meal_type ON day_meals(meal_type);
CREATE INDEX IF NOT EXISTS idx_day_meals_day_order_meal_type ON day_meals(day_order, meal_type);

-- Final completion notice
DO $$
BEGIN
    RAISE NOTICE 'Meal types migration completed successfully';
END
$$;