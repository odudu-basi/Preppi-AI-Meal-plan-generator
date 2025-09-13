-- Cookbook Database Schema for Supabase
-- Run this in your Supabase SQL Editor

-- Create cookbooks table
CREATE TABLE IF NOT EXISTS cookbooks (
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

-- Create saved_recipes table
CREATE TABLE IF NOT EXISTS saved_recipes (
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

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_cookbooks_user_id ON cookbooks(user_id);
CREATE INDEX IF NOT EXISTS idx_cookbooks_created_at ON cookbooks(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_saved_recipes_cookbook_id ON saved_recipes(cookbook_id);
CREATE INDEX IF NOT EXISTS idx_saved_recipes_user_id ON saved_recipes(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_recipes_created_at ON saved_recipes(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_saved_recipes_is_favorite ON saved_recipes(is_favorite) WHERE is_favorite = TRUE;

-- Enable Row Level Security (RLS)
ALTER TABLE cookbooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_recipes ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for cookbooks table
-- Users can only see their own cookbooks
CREATE POLICY "Users can view their own cookbooks" ON cookbooks
    FOR SELECT USING (auth.uid() = user_id);

-- Users can only insert their own cookbooks
CREATE POLICY "Users can insert their own cookbooks" ON cookbooks
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Users can only update their own cookbooks
CREATE POLICY "Users can update their own cookbooks" ON cookbooks
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can only delete their own cookbooks
CREATE POLICY "Users can delete their own cookbooks" ON cookbooks
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for saved_recipes table
-- Users can only see their own recipes
CREATE POLICY "Users can view their own recipes" ON saved_recipes
    FOR SELECT USING (auth.uid() = user_id);

-- Users can only insert recipes to their own cookbooks
CREATE POLICY "Users can insert recipes to their own cookbooks" ON saved_recipes
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND
        EXISTS (
            SELECT 1 FROM cookbooks 
            WHERE cookbooks.id = cookbook_id 
            AND cookbooks.user_id = auth.uid()
        )
    );

-- Users can only update their own recipes
CREATE POLICY "Users can update their own recipes" ON saved_recipes
    FOR UPDATE USING (auth.uid() = user_id);

-- Users can only delete their own recipes
CREATE POLICY "Users can delete their own recipes" ON saved_recipes
    FOR DELETE USING (auth.uid() = user_id);

-- Create trigger function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers to automatically update updated_at
CREATE TRIGGER update_cookbooks_updated_at 
    BEFORE UPDATE ON cookbooks 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_saved_recipes_updated_at 
    BEFORE UPDATE ON saved_recipes 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- Optional: Create a view for cookbook summaries with recipe counts
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

-- Grant necessary permissions (adjust based on your Supabase setup)
-- These might already be handled by Supabase's default settings

COMMENT ON TABLE cookbooks IS 'User-created cookbooks for organizing recipes';
COMMENT ON TABLE saved_recipes IS 'AI-generated recipes saved to user cookbooks';
COMMENT ON VIEW cookbook_summaries IS 'Cookbook overview with recipe counts and metadata';
