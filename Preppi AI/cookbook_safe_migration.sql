-- Safe Migration: Update cookbook tables from TEXT user_id to UUID user_id
-- This migration preserves existing data and handles conflicts gracefully
-- Run this in your Supabase SQL Editor

-- Step 1: Disable RLS temporarily to avoid conflicts during migration
ALTER TABLE IF EXISTS cookbooks DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS saved_recipes DISABLE ROW LEVEL SECURITY;

-- Step 2: Drop existing policies (they will be recreated with correct format)
DROP POLICY IF EXISTS "Users can view their own cookbooks" ON cookbooks;
DROP POLICY IF EXISTS "Users can insert their own cookbooks" ON cookbooks;
DROP POLICY IF EXISTS "Users can update their own cookbooks" ON cookbooks;
DROP POLICY IF EXISTS "Users can delete their own cookbooks" ON cookbooks;
DROP POLICY IF EXISTS "Users can view their own recipes" ON saved_recipes;
DROP POLICY IF EXISTS "Users can insert recipes to their own cookbooks" ON saved_recipes;
DROP POLICY IF EXISTS "Users can update their own recipes" ON saved_recipes;
DROP POLICY IF EXISTS "Users can delete their own recipes" ON saved_recipes;

-- Step 3: Drop dependent views first
DROP VIEW IF EXISTS cookbook_summaries;

-- Step 4: Check if tables exist and handle accordingly
DO $$
BEGIN
    -- If cookbooks table exists, alter it
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'cookbooks') THEN
        -- Check if user_id is already UUID type
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'cookbooks' 
            AND column_name = 'user_id' 
            AND data_type = 'text'
        ) THEN
            -- Add new UUID column
            ALTER TABLE cookbooks ADD COLUMN IF NOT EXISTS user_id_new UUID;
            
            -- Convert existing TEXT user_id to UUID (if any data exists)
            -- This assumes user_id was stored as UUID strings
            UPDATE cookbooks 
            SET user_id_new = user_id::UUID 
            WHERE user_id_new IS NULL AND user_id IS NOT NULL;
            
            -- Drop old column and rename new one
            ALTER TABLE cookbooks DROP COLUMN user_id;
            ALTER TABLE cookbooks RENAME COLUMN user_id_new TO user_id;
            
            -- Add NOT NULL constraint and foreign key
            ALTER TABLE cookbooks ALTER COLUMN user_id SET NOT NULL;
            ALTER TABLE cookbooks ADD CONSTRAINT cookbooks_user_id_fkey 
                FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        END IF;
    ELSE
        -- Create table if it doesn't exist
        CREATE TABLE cookbooks (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
            name TEXT NOT NULL,
            description TEXT,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            
            -- Constraints
            CONSTRAINT cookbooks_name_length CHECK (char_length(name) >= 1 AND char_length(name) <= 100),
            CONSTRAINT cookbooks_description_length CHECK (description IS NULL OR char_length(description) <= 500)
        );
    END IF;

    -- If saved_recipes table exists, alter it
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'saved_recipes') THEN
        -- Check if user_id is already UUID type
        IF EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'saved_recipes' 
            AND column_name = 'user_id' 
            AND data_type = 'text'
        ) THEN
            -- Add new UUID column
            ALTER TABLE saved_recipes ADD COLUMN IF NOT EXISTS user_id_new UUID;
            
            -- Convert existing TEXT user_id to UUID (if any data exists)
            UPDATE saved_recipes 
            SET user_id_new = user_id::UUID 
            WHERE user_id_new IS NULL AND user_id IS NOT NULL;
            
            -- Drop old column and rename new one
            ALTER TABLE saved_recipes DROP COLUMN user_id;
            ALTER TABLE saved_recipes RENAME COLUMN user_id_new TO user_id;
            
            -- Add NOT NULL constraint and foreign key
            ALTER TABLE saved_recipes ALTER COLUMN user_id SET NOT NULL;
            ALTER TABLE saved_recipes ADD CONSTRAINT saved_recipes_user_id_fkey 
                FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;
        END IF;
    ELSE
        -- Create table if it doesn't exist
        CREATE TABLE saved_recipes (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            cookbook_id UUID NOT NULL REFERENCES cookbooks(id) ON DELETE CASCADE,
            user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
            recipe_name TEXT NOT NULL,
            recipe_description TEXT NOT NULL,
            ingredients TEXT NOT NULL, -- Base64 encoded JSON
            instructions TEXT NOT NULL, -- Base64 encoded JSON
            nutrition TEXT NOT NULL, -- Base64 encoded JSON
            difficulty_rating INTEGER NOT NULL DEFAULT 1,
            prep_time TEXT NOT NULL DEFAULT '0 min',
            cook_time TEXT NOT NULL DEFAULT '0 min',
            total_time TEXT NOT NULL DEFAULT '0 min',
            servings INTEGER NOT NULL DEFAULT 1,
            shopping_list TEXT NOT NULL, -- Base64 encoded JSON
            image_url TEXT,
            notes TEXT,
            is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            
            -- Constraints
            CONSTRAINT saved_recipes_difficulty_rating_range CHECK (difficulty_rating >= 1 AND difficulty_rating <= 10),
            CONSTRAINT saved_recipes_servings_positive CHECK (servings > 0),
            CONSTRAINT saved_recipes_name_length CHECK (char_length(recipe_name) >= 1 AND char_length(recipe_name) <= 200),
            CONSTRAINT saved_recipes_notes_length CHECK (notes IS NULL OR char_length(notes) <= 1000)
        );
    END IF;
END $$;

-- Step 5: Create indexes (IF NOT EXISTS prevents conflicts)
CREATE INDEX IF NOT EXISTS idx_cookbooks_user_id ON cookbooks(user_id);
CREATE INDEX IF NOT EXISTS idx_cookbooks_created_at ON cookbooks(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_saved_recipes_cookbook_id ON saved_recipes(cookbook_id);
CREATE INDEX IF NOT EXISTS idx_saved_recipes_user_id ON saved_recipes(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_recipes_created_at ON saved_recipes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_saved_recipes_is_favorite ON saved_recipes(is_favorite) WHERE is_favorite = TRUE;

-- Step 6: Re-enable RLS
ALTER TABLE cookbooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_recipes ENABLE ROW LEVEL SECURITY;

-- Step 7: Create RLS policies with correct UUID format
CREATE POLICY "Users can view their own cookbooks" ON cookbooks
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own cookbooks" ON cookbooks
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own cookbooks" ON cookbooks
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own cookbooks" ON cookbooks
    FOR DELETE USING (auth.uid() = user_id);

CREATE POLICY "Users can view their own recipes" ON saved_recipes
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert recipes to their own cookbooks" ON saved_recipes
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM cookbooks 
            WHERE cookbooks.id = cookbook_id 
            AND cookbooks.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can update their own recipes" ON saved_recipes
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own recipes" ON saved_recipes
    FOR DELETE USING (auth.uid() = user_id);

-- Step 8: Create trigger function and triggers
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS update_cookbooks_updated_at ON cookbooks;
CREATE TRIGGER update_cookbooks_updated_at 
    BEFORE UPDATE ON cookbooks 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_saved_recipes_updated_at ON saved_recipes;
CREATE TRIGGER update_saved_recipes_updated_at 
    BEFORE UPDATE ON saved_recipes 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Step 9: Create or replace the view
CREATE OR REPLACE VIEW cookbook_summaries AS
SELECT 
    c.id,
    c.user_id,
    c.name,
    c.description,
    c.created_at,
    c.updated_at,
    COALESCE(recipe_counts.recipe_count, 0) as recipe_count,
    recipe_counts.last_recipe_added
FROM cookbooks c
LEFT JOIN (
    SELECT 
        cookbook_id,
        COUNT(*) as recipe_count,
        MAX(created_at) as last_recipe_added
    FROM saved_recipes
    GROUP BY cookbook_id
) recipe_counts ON c.id = recipe_counts.cookbook_id;
