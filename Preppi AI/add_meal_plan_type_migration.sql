-- Add meal_plan_type column to meal_plans table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='meal_plans' AND column_name='meal_plan_type') THEN
        ALTER TABLE meal_plans ADD COLUMN meal_plan_type TEXT DEFAULT 'dinner';
        RAISE NOTICE 'meal_plan_type column added to meal_plans table';
    ELSE
        RAISE NOTICE 'meal_plan_type column already exists in meal_plans table';
    END IF;
END
$$;

-- Update existing meal_plans records to set meal_plan_type based on selected_meal_types
DO $$
BEGIN
    -- Set meal_plan_type to 'breakfast' for plans that contain breakfast
    UPDATE meal_plans 
    SET meal_plan_type = 'breakfast' 
    WHERE 'breakfast' = ANY(selected_meal_types) AND meal_plan_type = 'dinner';
    
    -- Set meal_plan_type to 'lunch' for plans that contain lunch
    UPDATE meal_plans 
    SET meal_plan_type = 'lunch' 
    WHERE 'lunch' = ANY(selected_meal_types) AND meal_plan_type = 'dinner';
    
    -- Plans with only dinner will keep the default 'dinner' value
    
    RAISE NOTICE 'Updated existing meal_plans with appropriate meal_plan_type values';
END
$$;

-- Add a check constraint for valid meal_plan_type values
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'valid_meal_plan_type' AND conrelid = 'meal_plans'::regclass) THEN
        ALTER TABLE meal_plans ADD CONSTRAINT valid_meal_plan_type CHECK (meal_plan_type IN ('breakfast', 'lunch', 'dinner'));
        RAISE NOTICE 'valid_meal_plan_type constraint added';
    ELSE
        RAISE NOTICE 'valid_meal_plan_type constraint already exists';
    END IF;
END
$$;

-- Create index on meal_plan_type for better query performance
CREATE INDEX IF NOT EXISTS idx_meal_plans_meal_plan_type ON meal_plans(meal_plan_type);
CREATE INDEX IF NOT EXISTS idx_meal_plans_user_meal_type ON meal_plans(user_id, meal_plan_type);

-- Final completion notice
DO $$
BEGIN
    RAISE NOTICE 'Meal plan type migration completed successfully';
END
$$;