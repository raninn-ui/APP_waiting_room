-- ============================================
-- FIX RLS POLICIES FOR EXISTING CLIENTS TABLE
-- ============================================
-- Run this SQL in your Supabase SQL Editor
-- This script is safe to run multiple times

-- 1. First, drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Allow anonymous read access" ON public.clients;
DROP POLICY IF EXISTS "Allow anonymous insert access" ON public.clients;
DROP POLICY IF EXISTS "Allow anonymous delete access" ON public.clients;
DROP POLICY IF EXISTS "Allow anonymous update access" ON public.clients;

-- 2. Enable Row Level Security (if not already enabled)
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;

-- 3. Create policies to allow anonymous users to read/write
-- Policy: Allow anonymous users to SELECT (read) all clients
CREATE POLICY "Allow anonymous read access"
ON public.clients
FOR SELECT
TO anon
USING (true);

-- Policy: Allow anonymous users to INSERT (create) clients
CREATE POLICY "Allow anonymous insert access"
ON public.clients
FOR INSERT
TO anon
WITH CHECK (true);

-- Policy: Allow anonymous users to DELETE clients
CREATE POLICY "Allow anonymous delete access"
ON public.clients
FOR DELETE
TO anon
USING (true);

-- Policy: Allow anonymous users to UPDATE clients
CREATE POLICY "Allow anonymous update access"
ON public.clients
FOR UPDATE
TO anon
USING (true)
WITH CHECK (true);

-- 4. Verify the policies were created
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive, 
    roles, 
    cmd
FROM pg_policies
WHERE tablename = 'clients'
ORDER BY policyname;

