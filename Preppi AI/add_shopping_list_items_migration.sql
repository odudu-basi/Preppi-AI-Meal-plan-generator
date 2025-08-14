-- Migration: Add shopping_list_items table for persistent shopping list check states
-- Description: Create table to store shopping list items and their checked status per user

-- Create shopping_list_items table
CREATE TABLE IF NOT EXISTS public.shopping_list_items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    meal_plan_id UUID REFERENCES public.meal_plans(id) ON DELETE SET NULL,
    item_name TEXT NOT NULL,
    category TEXT NOT NULL,
    is_checked BOOLEAN DEFAULT FALSE,
    checked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_shopping_list_items_user_id ON public.shopping_list_items(user_id);
CREATE INDEX IF NOT EXISTS idx_shopping_list_items_meal_plan_id ON public.shopping_list_items(meal_plan_id);
CREATE INDEX IF NOT EXISTS idx_shopping_list_items_user_item ON public.shopping_list_items(user_id, item_name);

-- Add RLS (Row Level Security) policies
ALTER TABLE public.shopping_list_items ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to handle re-running migration)
DROP POLICY IF EXISTS "Users can view their own shopping list items" ON public.shopping_list_items;
DROP POLICY IF EXISTS "Users can insert their own shopping list items" ON public.shopping_list_items;
DROP POLICY IF EXISTS "Users can update their own shopping list items" ON public.shopping_list_items;
DROP POLICY IF EXISTS "Users can delete their own shopping list items" ON public.shopping_list_items;

-- Policy: Users can only see their own shopping list items
CREATE POLICY "Users can view their own shopping list items" ON public.shopping_list_items
    FOR SELECT USING (auth.uid() = user_id);

-- Policy: Users can insert their own shopping list items
CREATE POLICY "Users can insert their own shopping list items" ON public.shopping_list_items
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own shopping list items
CREATE POLICY "Users can update their own shopping list items" ON public.shopping_list_items
    FOR UPDATE USING (auth.uid() = user_id);

-- Policy: Users can delete their own shopping list items
CREATE POLICY "Users can delete their own shopping list items" ON public.shopping_list_items
    FOR DELETE USING (auth.uid() = user_id);

-- Add trigger for updated_at timestamp
CREATE OR REPLACE FUNCTION update_shopping_list_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Drop trigger if it exists, then recreate
DROP TRIGGER IF EXISTS update_shopping_list_items_updated_at ON public.shopping_list_items;
CREATE TRIGGER update_shopping_list_items_updated_at
    BEFORE UPDATE ON public.shopping_list_items
    FOR EACH ROW
    EXECUTE FUNCTION update_shopping_list_items_updated_at();

-- Grant necessary permissions
GRANT ALL ON public.shopping_list_items TO authenticated;