-- Add progress_start_date column to user_profiles table
-- This column tracks when the user started their 3-month progress journey
-- It can be null if the user hasn't started tracking yet

ALTER TABLE user_profiles
ADD COLUMN IF NOT EXISTS progress_start_date TIMESTAMP WITH TIME ZONE DEFAULT NULL;

-- Add comment to explain the column
COMMENT ON COLUMN user_profiles.progress_start_date IS 'Date when user started their 3-month progress tracking journey. NULL if not started yet.';
