-- Workshop 6: Distributed Waiting Rooms Schema Update
-- Run this in your Supabase SQL Editor

-- Step 1: Create waiting_rooms table
CREATE TABLE IF NOT EXISTS waiting_rooms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Step 2: Add waiting_room_id column to clients table
-- First, check if the column doesn't already exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'clients' AND column_name = 'waiting_room_id'
  ) THEN
    ALTER TABLE clients ADD COLUMN waiting_room_id UUID REFERENCES waiting_rooms(id);
  END IF;
END $$;

-- Step 3: Seed sample waiting rooms with realistic coordinates
INSERT INTO waiting_rooms (name, latitude, longitude) VALUES
  ('Downtown Clinic', 40.7128, -74.0060),      -- New York City
  ('Uptown Office', 40.7589, -73.9851),        -- Upper West Side, NYC
  ('Suburban Center', 40.6782, -73.9442),      -- Brooklyn
  ('East Side Medical', 40.7614, -73.9776),    -- Upper East Side, NYC
  ('West End Practice', 40.7061, -74.0134)     -- Lower Manhattan
ON CONFLICT DO NOTHING;

-- Step 4: Enable Row Level Security (RLS) for waiting_rooms
ALTER TABLE waiting_rooms ENABLE ROW LEVEL SECURITY;

-- Step 5: Create policies for waiting_rooms (allow read for all authenticated users)
CREATE POLICY "Allow read access to waiting_rooms" 
  ON waiting_rooms FOR SELECT 
  USING (true);

-- Step 6: Update existing clients table policy if needed
-- (Assuming you already have policies from previous workshops)

-- Step 7: Create an index on waiting_room_id for faster queries
CREATE INDEX IF NOT EXISTS idx_clients_waiting_room_id 
  ON clients(waiting_room_id);

-- Verification queries:
-- SELECT * FROM waiting_rooms;
-- SELECT * FROM clients;
-- \d clients  -- to see the schema

