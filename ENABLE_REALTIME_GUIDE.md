# Enable Real-time Sync in Supabase

## Problem
The app is not syncing in real-time. Changes don't appear until you refresh or re-enter the room.

## Root Cause
**Supabase Real-time Replication is NOT enabled for the `clients` table.**

By default, Supabase does NOT broadcast database changes via real-time. You must explicitly enable it for each table.

## Solution - Enable Real-time for the `clients` Table

### Step 1: Open Supabase Dashboard
1. Go to https://supabase.com/dashboard
2. Select your project: `eaclcnzyeczqigdidsmi`

### Step 2: Enable Real-time Replication
1. Click on **Database** in the left sidebar
2. Click on **Replication** (under Database section)
3. Find the **`clients`** table in the list
4. Click the toggle switch next to `clients` to **enable** it
5. The toggle should turn **green/blue** when enabled

### Step 3: Verify Real-time is Enabled
Run this query in the SQL Editor to verify:

```sql
SELECT 
    schemaname,
    tablename,
    CASE 
        WHEN tablename = ANY(
            SELECT tablename 
            FROM pg_publication_tables 
            WHERE pubname = 'supabase_realtime'
        ) THEN 'ENABLED ✅'
        ELSE 'DISABLED ❌'
    END as realtime_status
FROM pg_tables
WHERE schemaname = 'public'
AND tablename = 'clients';
```

You should see:
```
schemaname | tablename | realtime_status
-----------+-----------+----------------
public     | clients   | ENABLED ✅
```

### Step 4: Restart Your App
After enabling real-time:
```bash
flutter run
```

### Step 5: Test Real-time Sync
1. Open the app in **two browser tabs** (side by side)
2. In Tab 1: Click "Call Next Client"
3. **Expected:** Tab 2 should update within 1-2 seconds automatically

## Alternative Method - Enable via SQL

If you can't find the Replication UI, run this SQL:

```sql
-- Enable real-time for clients table
ALTER PUBLICATION supabase_realtime ADD TABLE clients;

-- Verify it worked
SELECT tablename 
FROM pg_publication_tables 
WHERE pubname = 'supabase_realtime' 
AND tablename = 'clients';
```

You should see `clients` in the result.

## How to Check if Real-time is Working

### In the Browser Console (F12):
Look for these messages:
```
✅ Real-time subscription active
🔔 Real-time event received: UPDATE
📦 Record data: John Doe - status: called
✅ Client updated via realtime (room): John Doe - status: called
```

### If You See:
```
❌ Real-time subscription error
⏱️ Real-time subscription timed out
```

Then real-time is NOT enabled in Supabase.

## Why This Happens

Supabase real-time is **opt-in** for security and performance reasons:
- Not all tables need real-time updates
- Real-time uses more resources
- You control which tables broadcast changes

## What Happens After Enabling

### Before (Real-time Disabled):
- Click button → Database updates ✅
- Other tabs → No update ❌
- Must refresh manually ❌
- Periodic refresh every 2 seconds (web only)

### After (Real-time Enabled):
- Click button → Database updates ✅
- Real-time event broadcasts ✅
- Other tabs update automatically ✅
- No manual refresh needed ✅

## Troubleshooting

### Still Not Working After Enabling?

1. **Check the browser console** (F12) for error messages
2. **Verify real-time is enabled** using the SQL query above
3. **Check Supabase project status** - make sure it's not paused
4. **Restart the app** completely (not just hot reload)
5. **Clear browser cache** and reload

### Check Supabase Real-time Logs
1. Go to Supabase Dashboard
2. Click **Logs** in the left sidebar
3. Select **Realtime** from the dropdown
4. Look for connection errors or subscription failures

### Common Issues

**Issue:** "Real-time subscription timed out"
**Solution:** Enable replication for the `clients` table

**Issue:** "Real-time subscription error: permission denied"
**Solution:** Check Row Level Security (RLS) policies - they might be blocking real-time

**Issue:** "No real-time events received"
**Solution:** 
1. Verify replication is enabled
2. Check that you're authenticated (anonymous sign-in should work)
3. Verify the table name is correct (`clients`)

## Expected Behavior After Fix

### Test 1: Single Tab
1. Add a client
2. Click "Call Next Client"
3. Status changes to orange **instantly** (optimistic update)

### Test 2: Multiple Tabs
1. Open app in Tab 1 and Tab 2
2. In Tab 1: Click "Call Next Client"
3. In Tab 2: Status updates within 1-2 seconds **automatically**

### Test 3: Console Logs
You should see:
```
📞 Calling client: John Doe
✅ Client status updated in UI (optimistic)
✅ Client status updated in Supabase
🔔 Real-time event received: UPDATE
📦 Record data: John Doe - status: called
✅ Client updated via realtime: John Doe - status: called
```

## Summary

**The fix is simple:**
1. Go to Supabase Dashboard → Database → Replication
2. Enable replication for the `clients` table
3. Restart your app
4. Test with two tabs

This is a **one-time setup** - once enabled, real-time will work forever for this table.

