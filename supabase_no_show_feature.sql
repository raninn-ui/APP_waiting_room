-- ============================================
-- NO-SHOW HANDLING FEATURE
-- ============================================
-- Run this SQL in your Supabase SQL Editor to add no-show handling

-- Step 1: Add status column to clients table
-- Possible values: 'waiting', 'called', 'served', 'no-show'
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'clients' AND column_name = 'status'
  ) THEN
    ALTER TABLE clients ADD COLUMN status TEXT NOT NULL DEFAULT 'waiting';
  END IF;
END $$;

-- Step 2: Add called_at timestamp column
-- This tracks when a client was called (moved from waiting to called status)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'clients' AND column_name = 'called_at'
  ) THEN
    ALTER TABLE clients ADD COLUMN called_at TIMESTAMPTZ;
  END IF;
END $$;

-- Step 3: Create index on status for better query performance
CREATE INDEX IF NOT EXISTS idx_clients_status ON clients(status);

-- Step 4: Create index on called_at for no-show detection queries
CREATE INDEX IF NOT EXISTS idx_clients_called_at ON clients(called_at);

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check if columns were added successfully
SELECT 
    column_name, 
    data_type, 
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' 
AND table_name = 'clients'
AND column_name IN ('status', 'called_at')
ORDER BY ordinal_position;

-- Check indexes
SELECT 
    indexname, 
    indexdef
FROM pg_indexes
WHERE tablename = 'clients'
AND indexname IN ('idx_clients_status', 'idx_clients_called_at');

-- Sample query to find clients who should be marked as no-show
-- (called more than 30 minutes ago and still in 'called' status)
SELECT 
    id,
    name,
    status,
    called_at,
    EXTRACT(EPOCH FROM (NOW() - called_at))/60 as minutes_since_called
FROM clients
WHERE status = 'called'
AND called_at < NOW() - INTERVAL '30 minutes'
ORDER BY called_at;

