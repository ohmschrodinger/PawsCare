# Notification Badge System

## Overview
A red dot notification badge appears on the menu icon in the PawsCare app bar to notify users about important application updates.

## How It Works

### For Admins
- **Red dot appears when**: There are applications with "Under Review" status
- **Red dot disappears when**: All applications have been reviewed (Accepted/Rejected)
- Real-time updates using Firestore streams

### For Regular Users
- **Red dot appears when**:
  - A new application is created
  - An application status is updated (Accepted/Rejected)
  - Any application is modified after the last time they viewed their applications
- **Red dot disappears when**: User opens "My Applications" screen
- Tracks the last time user viewed their applications using `lastSeenApplications` timestamp in the user's document

## Implementation Details

### Files Modified/Created

1. **`lib/services/notification_badge_service.dart`** (NEW)
   - `hasUnderReviewApplications()`: Stream that checks for "Under Review" applications (for admins)
   - `hasNewApplicationUpdates(userId)`: Stream that checks if user has unseen application updates
   - `markApplicationsAsSeen(userId)`: Updates user's `lastSeenApplications` timestamp
   - `updateApplicationTimestamp(applicationId)`: Updates application's `updatedAt` field

2. **`lib/widgets/paws_care_app_bar.dart`** (MODIFIED)
   - Added StreamBuilder to listen for notification updates
   - Shows red dot badge on menu icon when notifications are present
   - Automatically marks applications as seen when user clicks "My Applications"

3. **`lib/screens/application_detail_screen.dart`** (MODIFIED)
   - Added `updatedAt` timestamp when application status changes
   - Added to both `_handleApprove()` and `_handleReject()` methods
   - Also updates batch rejected applications with `updatedAt` timestamp

4. **`lib/screens/my_applications_screen.dart`** (MODIFIED)
   - Added `initState()` to mark applications as seen when screen opens
   - This removes the red dot notification badge

## Firestore Schema Updates

### Users Collection
```
users/{userId}
  - lastSeenApplications: Timestamp (when user last viewed their applications)
```

### Applications Collection
```
applications/{applicationId}
  - updatedAt: Timestamp (when application was last modified)
  - appliedAt: Timestamp (when application was created)
  - status: String (Under Review, Accepted, Rejected)
```

## User Experience

1. **User submits application**
   - Application is created with `appliedAt` timestamp
   - Red dot appears on menu for the user (new application)
   - Red dot appears for admins (under review)

2. **Admin reviews application**
   - Status changes to "Accepted" or "Rejected"
   - `updatedAt` timestamp is set
   - Red dot appears for user (status changed)
   - Red dot disappears for admin if no more "Under Review" applications

3. **User checks their applications**
   - Opens "My Applications" screen
   - `lastSeenApplications` timestamp is updated
   - Red dot disappears from menu

## Instagram-like Behavior
- Real-time updates (like Instagram's notification system)
- Red dot indicator for new activity
- Automatically clears when user views the relevant section
- Persistent across app sessions (stored in Firestore)
- Works for both admins and regular users with different logic
