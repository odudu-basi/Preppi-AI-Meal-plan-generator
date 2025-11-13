-- Migration: Add logged_meals table for user-scanned meals
-- This table stores meals that users have logged via photo analysis

-- Create logged_meals table
CREATE TABLE IF NOT EXISTS logged_meals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    meal_name TEXT NOT NULL,
    description TEXT,
    calories INTEGER NOT NULL,
    
    -- Macronutrients (in grams, except sodium in mg)
    protein DECIMAL(8,2),
    carbohydrates DECIMAL(8,2),
    fat DECIMAL(8,2),
    fiber DECIMAL(8,2),
    sugar DECIMAL(8,2),
    sodium DECIMAL(8,2), -- in milligrams
    
    health_score INTEGER CHECK (health_score >= 1 AND health_score <= 10),
    image_url TEXT, -- URL to uploaded image in Supabase Storage
    logged_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_logged_meals_user_id ON logged_meals(user_id);
CREATE INDEX IF NOT EXISTS idx_logged_meals_logged_at ON logged_meals(logged_at);
CREATE INDEX IF NOT EXISTS idx_logged_meals_user_logged_at ON logged_meals(user_id, logged_at);

-- Enable Row Level Security
ALTER TABLE logged_meals ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
-- Users can only see and manage their own logged meals
CREATE POLICY "Users can view their own logged meals" ON logged_meals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own logged meals" ON logged_meals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own logged meals" ON logged_meals
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own logged meals" ON logged_meals
    FOR DELETE USING (auth.uid() = user_id);

-- Create function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_logged_meals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to automatically update updated_at
CREATE TRIGGER trigger_update_logged_meals_updated_at
    BEFORE UPDATE ON logged_meals
    FOR EACH ROW
    EXECUTE FUNCTION update_logged_meals_updated_at();

-- Grant necessary permissions
GRANT ALL ON logged_meals TO authenticated;

-- Verify the table was created successfully
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'logged_meals') THEN
        RAISE NOTICE 'logged_meals table created successfully';
    ELSE
        RAISE EXCEPTION 'Failed to create logged_meals table';
    END IF;
END $$;
