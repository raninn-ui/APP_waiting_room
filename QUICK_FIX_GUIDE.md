# Quick Fix Guide - Call Next Client Not Working

## Problem
When you click "Call Next Client", nothing happens because:
1. The Supabase database doesn't have the `status` and `called_at` columns yet
2. The real-time subscription wasn't handling UPDATE events (now fixed)

## Solution - Follow These Steps

### Step 1: Update Supabase Database (REQUIRED)
You **MUST** run the SQL migration to add the new columns:

1. Open your Supabase Dashboard: https://supabase.com/dashboard
2. Go to your project: `eaclcnzyeczqigdidsmi`
3. Click on **SQL Editor** in the left sidebar
4. Click **New Query**
5. Copy the entire contents of `supabase_no_show_feature.sql`
6. Paste into the SQL Editor
7. Click **Run** (or press Ctrl+Enter)

You should see output showing:
- Columns added successfully
- Indexes created
- Verification results

### Step 2: Restart Your App
After running the SQL migration:

```bash
# Stop the current app (if running)
# Then restart:
flutter run
```

### Step 3: Test the Feature
1. Add a new client to the queue
2. Click "Call Next Client"
3. You should see:
   - Client status badge changes from Blue (Waiting) to Orange (Called)
   - Timestamp appears showing "just now"
   - Action buttons appear (green checkmark, orange cancel)

## What Was Fixed in the Code

### Fixed Real-time Updates
Added UPDATE event handling to both subscription methods:
- General subscription (all clients)
- Room-specific subscription

Now when you click "Call Next Client":
1. Status updates in Supabase ✅
2. Real-time event fires ✅
3. UI updates automatically ✅

## Troubleshooting

### If it still doesn't work:

1. **Check the browser console** (F12) for errors
2. **Check the Flutter debug console** for log messages like:
   - `📞 Calling client: [name]`
   - `✅ Client status updated in Supabase`
   - `✅ Client updated via realtime`

3. **Verify the SQL ran successfully**:
   - Go to Supabase SQL Editor
   - Run this query:
   ```sql
   SELECT column_name, data_type, column_default
   FROM information_schema.columns
   WHERE table_name = 'clients'
   AND column_name IN ('status', 'called_at');
   ```
   - You should see both columns listed

4. **Check existing clients**:
   - Old clients added before the migration will have `status = 'waiting'` (default)
   - New clients added after will also have `status = 'waiting'`

5. **Hot reload the app**:
   - Press `r` in the terminal to hot reload
   - Or press `R` for a full restart

## Expected Behavior After Fix

### When you click "Call Next Client":
- Console shows: `📞 Calling client: [name]`
- Console shows: `✅ Client status updated in Supabase`
- Console shows: `✅ Client updated via realtime`
- UI updates immediately with orange badge
- Timestamp shows "just now"
- Action buttons appear

### After 30 minutes:
- Console shows: `🔍 Checking for no-show clients...`
- Console shows: `⚠️ Marking [name] as no-show`
- Status badge changes to red
- Status text changes to "No-show"

## Quick Test (1 minute timeout)

To test faster, temporarily change the timeout:

**In `lib/queue_provider.dart`:**

Line ~533:
```dart
final noShowClients = await _localDb.getClientsForNoShow(1); // Changed from 30 to 1
```

Line ~520:
```dart
final cutoffTime = DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String();
```

Then:
1. Add a client
2. Call next client
3. Wait 1 minute
4. Client should be marked as no-show

**Don't forget to change it back to 30 minutes after testing!**

