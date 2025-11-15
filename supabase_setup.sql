-- ============================================
-- SUPABASE DATABASE SETUP FOR WAITING ROOM APP
-- ============================================
-- Run this SQL in your Supabase SQL Editor
-- (https://supabase.com/dashboard/project/YOUR_PROJECT/sql)

-- 1. Create the clients table
CREATE TABLE IF NOT EXISTS public.clients (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    lat REAL,
    lng REAL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Enable Row Level Security (RLS)
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

-- 4. Enable Realtime for the clients table (skip if already added)
-- ALTER PUBLICATION supabase_realtime ADD TABLE public.clients;
-- Note: Table is already in realtime publication, skipping this step

-- 5. Create an index on created_at for better performance
CREATE INDEX IF NOT EXISTS idx_clients_created_at ON public.clients(created_at);

-- ============================================
-- VERIFICATION QUERIES
-- ============================================
-- Run these to verify everything is set up correctly:

-- Check if table exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'clients';

-- Check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies
WHERE tablename = 'clients';

-- Check if realtime is enabled
SELECT schemaname, tablename
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
AND tablename = 'clients';

