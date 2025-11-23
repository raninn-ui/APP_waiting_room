# No-Show Handling Feature

## Overview
This feature automatically detects and marks clients as "no-show" if they don't respond within 30 minutes after being called. It includes a complete client status management system with visual indicators and manual controls.

## Features Implemented

### 1. Client Status System
Clients can now have one of four statuses:
- **Waiting** (blue) - Client is in the queue waiting to be called
- **Called** (orange) - Client has been called and has 30 minutes to respond
- **Served** (green) - Client has been successfully served
- **No-show** (red) - Client didn't respond within 30 minutes after being called

### 2. Automatic No-Show Detection
- A background timer runs every minute to check for clients who should be marked as no-show
- Clients in "called" status for more than 30 minutes are automatically marked as "no-show"
- Works both online (Supabase) and offline (SQLite)

### 3. UI Enhancements
- **Status Badges**: Each client card shows a colored badge indicating their current status
- **Status Icons**: Visual icons for each status (hourglass, phone, checkmark, cancel)
- **Timestamp Display**: Shows when a client was called (e.g., "5m ago", "1h ago")
- **Action Buttons**:
  - "Call Next Client" - Calls the next waiting client
  - "Mark as Served" - Manually mark a called client as served
  - "Mark as No-show" - Manually mark a called client as no-show
  - "Delete" - Remove client from queue

## Database Schema Changes

### Supabase (PostgreSQL)
Two new columns added to the `clients` table:
- `status` (TEXT, default: 'waiting') - Current status of the client
- `called_at` (TIMESTAMPTZ, nullable) - Timestamp when client was called

### SQLite (Local Database)
Same columns added to the `local_clients` table:
- `status` (TEXT, default: 'waiting')
- `called_at` (TEXT, nullable) - ISO 8601 timestamp

## Setup Instructions

### Step 1: Update Supabase Database
Run the SQL script in your Supabase SQL Editor:
```bash
# File: supabase_no_show_feature.sql
```

This will:
- Add `status` and `called_at` columns to the `clients` table
- Create indexes for better query performance
- Set up default values

### Step 2: Update Local Database
The local SQLite database will automatically upgrade to version 4 when the app runs.
The migration adds the same `status` and `called_at` columns.

### Step 3: Run the App
```bash
flutter run
```

The app will automatically:
- Upgrade the local database schema
- Start the no-show detection timer
- Display the new UI with status badges

## How It Works

### Calling a Client
1. Click "Call Next Client" button
2. The first client with "waiting" status is marked as "called"
3. The `called_at` timestamp is set to the current time
4. The client's status badge changes to orange
5. A 30-minute countdown begins

### Automatic No-Show Detection
1. Every minute, the system checks for clients in "called" status
2. If `called_at` is more than 30 minutes ago, the client is marked as "no-show"
3. The status badge changes to red
4. The client remains in the queue but can be manually removed

### Manual Actions
- **Mark as Served**: Click the green checkmark on a called client
- **Mark as No-show**: Click the orange cancel icon on a called client
- **Delete**: Click the red delete icon to remove any client

## Customization

### Change No-Show Timeout
To change the 30-minute timeout, modify the value in two places:

**lib/queue_provider.dart** (line ~533):
```dart
final noShowClients = await _localDb.getClientsForNoShow(30); // Change 30 to desired minutes
```

**lib/queue_provider.dart** (line ~520):
```dart
.lt('called_at', cutoffTime) // Uses 30 minutes from Duration above
```

### Change Timer Frequency
To change how often the system checks for no-shows (default: 1 minute):

**lib/queue_provider.dart** (line ~103):
```dart
_noShowCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
  // Change minutes: 1 to desired frequency
});
```

## Testing

### Manual Testing Steps
1. Add a client to the queue
2. Click "Call Next Client"
3. Verify the client status changes to "Called" (orange)
4. Wait 30 minutes (or modify the timeout for faster testing)
5. Verify the client is automatically marked as "No-show" (red)

### Quick Testing (Modify Timeout)
For faster testing, temporarily change the timeout to 1 minute:
```dart
// In lib/queue_provider.dart
final noShowClients = await _localDb.getClientsForNoShow(1); // 1 minute instead of 30
```

## Files Modified
- `lib/queue_provider.dart` - Added status management and no-show detection logic
- `lib/local_queue_service.dart` - Added status columns and helper methods
- `lib/main.dart` - Updated UI with status badges and action buttons
- `supabase_no_show_feature.sql` - Database migration script

## Files Created
- `NO_SHOW_FEATURE_GUIDE.md` - This documentation file
- `supabase_no_show_feature.sql` - Supabase schema update script

## Future Enhancements
- Configurable timeout per room
- SMS/push notifications when client is called
- Analytics dashboard showing no-show rates
- Automatic queue position updates for waiting clients
- Sound/voice announcements when calling clients

