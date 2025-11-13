-- ============================================
-- Migration: Add Missing 'country' Column to user_profiles
-- Date: October 25, 2025
-- Issue: PGRST204 - "Could not find the 'country' column"
-- ============================================

-- Add the missing 'country' column to user_profiles table
ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS country TEXT;

-- Optional: Add comment to document the column
COMMENT ON COLUMN user_profiles.country IS 'User country - added for new onboarding flow';

-- Verify the column was added
-- Run this to check:
-- SELECT column_name, data_type, is_nullable
-- FROM information_schema.columns
-- WHERE table_name = 'user_profiles' AND column_name = 'country';

-- ============================================
-- How to Apply This Migration
-- ============================================
-- 1. Go to your Supabase Dashboard
-- 2. Navigate to: SQL Editor
-- 3. Create a new query
-- 4. Paste this entire script
-- 5. Click "Run" or press Cmd/Ctrl + Enter
-- 6. Verify success message
-- ============================================

-- ============================================
-- Rollback (if needed)
-- ============================================
-- To remove this column if something goes wrong:
-- ALTER TABLE user_profiles DROP COLUMN IF EXISTS country;
-- ============================================
