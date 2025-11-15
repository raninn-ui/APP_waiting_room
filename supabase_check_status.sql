-- ============================================
-- CHECK SUPABASE CONFIGURATION STATUS
-- ============================================
-- Run this to see the current state of your database

-- 1. Check if clients table exists and its structure
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'clients'
ORDER BY ordinal_position;

-- 2. Check if RLS is enabled
SELECT 
    schemaname,
    tablename,
    rowsecurity as "RLS Enabled"
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'clients';

-- 3. Check existing RLS policies
SELECT 
    schemaname, 
    tablename, 
    policyname, 
    permissive,
    roles,
    cmd as "Command (SELECT/INSERT/UPDATE/DELETE)",
    qual as "USING clause",
    with_check as "WITH CHECK clause"
FROM pg_policies
WHERE tablename = 'clients'
ORDER BY policyname;

-- 4. Check if realtime is enabled
SELECT 
    schemaname, 
    tablename,
    'Realtime Enabled' as status
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime'
AND tablename = 'clients';

-- 5. Count existing clients
SELECT COUNT(*) as "Total Clients" FROM public.clients;

-- 6. Show sample of existing clients (if any)
SELECT * FROM public.clients ORDER BY created_at DESC LIMIT 5;

