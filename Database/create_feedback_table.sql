-- Create feedback table in Supabase
-- Run this SQL in your Supabase SQL Editor

CREATE TABLE IF NOT EXISTS feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    feedback_text TEXT NOT NULL,
    upvotes INTEGER DEFAULT 0,
    downvotes INTEGER DEFAULT 0,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_feedback_created_at ON feedback(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_feedback_votes ON feedback((upvotes - downvotes) DESC);

-- Enable Row Level Security
ALTER TABLE feedback ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can view all feedback
CREATE POLICY "Anyone can view feedback"
    ON feedback
    FOR SELECT
    USING (true);

-- Policy: Authenticated users can insert feedback
CREATE POLICY "Authenticated users can insert feedback"
    ON feedback
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Policy: Users can update votes on any feedback (for future voting feature)
CREATE POLICY "Users can update votes"
    ON feedback
    FOR UPDATE
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- Add comment to table
COMMENT ON TABLE feedback IS 'Stores user feedback and feature requests with voting capability';
