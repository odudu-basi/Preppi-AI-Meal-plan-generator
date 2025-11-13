-- ============================================
-- Database Schema Verification for user_profiles
-- ============================================

-- Check current schema of user_profiles table
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'user_profiles'
ORDER BY ordinal_position;

-- ============================================
-- Required Columns for New Onboarding Flow
-- ============================================
-- Based on UserProfileUpdate struct in LocalUserDataService.swift
--
-- REQUIRED COLUMNS:
-- 1.  id (UUID, PRIMARY KEY) - auto-generated
-- 2.  user_id (UUID, FOREIGN KEY to auth.users)
-- 3.  email (TEXT)
-- 4.  name (TEXT)
-- 5.  sex (TEXT, nullable)
-- 6.  country (TEXT, nullable) ← MISSING - causing error
-- 7.  age (INTEGER)
-- 8.  weight (DOUBLE PRECISION)
-- 9.  height (INTEGER)
-- 10. likes_to_cook (BOOLEAN, nullable)
-- 11. cooking_preference (TEXT, nullable)
-- 12. activity_level (TEXT)
-- 13. target_weight (DOUBLE PRECISION, nullable)
-- 14. weight_loss_speed (TEXT, nullable)
-- 15. marketing_source (TEXT, nullable)
-- 16. motivations (JSONB or TEXT[])
-- 17. motivation_other (TEXT)
-- 18. challenges (JSONB or TEXT[])
-- 19. health_goals (JSONB or TEXT[])
-- 20. dietary_restrictions (JSONB or TEXT[])
-- 21. food_allergies (JSONB or TEXT[])
-- 22. weekly_budget (DOUBLE PRECISION, nullable)
-- 23. onboarding_completed (BOOLEAN)
-- 24. created_at (TIMESTAMP)
-- 25. updated_at (TIMESTAMP)
-- ============================================

-- If you see that 'country' is missing from the results above,
-- you need to run the migration script:
-- DATABASE_MIGRATION_ADD_COUNTRY.sql
