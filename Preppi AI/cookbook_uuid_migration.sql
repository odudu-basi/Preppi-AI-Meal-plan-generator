-- Migration to update cookbook tables from TEXT user_id to UUID user_id
-- Run this in your Supabase SQL Editor BEFORE running the main cookbook_database_schema.sql

-- First, drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own cookbooks" ON cookbooks;
DROP POLICY IF EXISTS "Users can insert their own cookbooks" ON cookbooks;
DROP POLICY IF EXISTS "Users can update their own cookbooks" ON cookbooks;
DROP POLICY IF EXISTS "Users can delete their own cookbooks" ON cookbooks;
DROP POLICY IF EXISTS "Users can view their own recipes" ON saved_recipes;
DROP POLICY IF EXISTS "Users can insert recipes to their own cookbooks" ON saved_recipes;
DROP POLICY IF EXISTS "Users can update their own recipes" ON saved_recipes;
DROP POLICY IF EXISTS "Users can delete their own recipes" ON saved_recipes;

-- Drop existing tables if they exist (WARNING: This will delete all data!)
DROP TABLE IF EXISTS saved_recipes;
DROP TABLE IF EXISTS cookbooks;

-- Drop the view if it exists
DROP VIEW IF EXISTS cookbook_summaries;

-- Now you can run the updated cookbook_database_schema.sql
-- which will create the tables with proper UUID user_id columns
