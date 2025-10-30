# Push Notifications Setup Guide

This guide explains how to set up and test push notifications in your PawsCare Flutter application.

## Features Implemented

### 1. Adoption Request Notifications
- **Approved**: Users receive notifications when their adoption applications are approved
- **Rejected**: Users receive notifications when their adoption applications are rejected

### 2. New Animal Notifications
- Users receive notifications when new animals are added and approved by admins

### 3. User Notification Preferences
- Users can manage their notification preferences in the app
- Granular control over different types of notifications

## Setup Instructions

### 1. Dependencies Added
The following dependencies have been added to `pubspec.yaml`:
```yaml
firebase_messaging: ^15.1.3
flutter_local_notifications: ^17.2.3
```

### 2. Android Configuration
Updated `android/app/src/main/AndroidManifest.xml` with:
- Required permissions for notifications
- Firebase Cloud Messaging service configuration
- Default notification channel setup

### 3. Cloud Functions
Added the following Cloud Functions in `functions/src/index.ts`:
- `onAdoptionApplicationApproved`: Sends notifications when adoption requests are approved
- `onAdoptionApplicationRejected`: Sends notifications when adoption requests are rejected
- `onNewAnimalApproved`: Sends notifications when new animals are approved
- `sendPushNotification`: Helper function to send push notifications

### 4. Flutter Services
Created the following services:
- `NotificationService`: Handles FCM token management and local notifications
- `NotificationTestService`: Provides testing utilities for notifications

### 5. UI Components
Created `NotificationSettingsScreen` for users to manage their notification preferences.

## Testing the Implementation

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Deploy Cloud Functions
```bash
cd functions
npm install
firebase deploy --only functions
```

### 3. Test Notifications

#### Test Adoption Approval Notification:
1. Submit an adoption application
2. As an admin, approve the application
3. The user should receive a push notification

#### Test New Animal Notification:
1. Post a new animal (as a regular user)
2. As an admin, approve the animal
3. All users with new animal notifications enabled should receive a notification

#### Test Notification Settings:
1. Go to the notification settings screen
2. Toggle different notification types
3. Verify that notifications respect user preferences

### 4. Check Notification Status
Use the `NotificationTestService.checkNotificationStatus()` method to verify:
- User is logged in
- FCM token is present
- Notification preferences are set correctly

## Cloud Function Configuration

### Environment Variables
Make sure your Cloud Functions have the following environment variables set:
```bash
firebase functions:config:set gmail.email="your-email@gmail.com"
firebase functions:config:set gmail.password="your-app-password"
```

### Firestore Security Rules
Ensure your Firestore rules allow users to update their notification preferences:
```javascript
// Allow users to update their own notification settings
match /users/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

## Troubleshooting

### Common Issues

1. **Notifications not received on Android**:
   - Check if the app has notification permissions
   - Verify the FCM token is saved in Firestore
   - Check Cloud Function logs for errors

2. **Notifications not received on iOS**:
   - Ensure APNs certificates are configured in Firebase Console
   - Check if the app has notification permissions
   - Verify the FCM token is saved in Firestore

3. **Cloud Functions not triggering**:
   - Check Firestore security rules
   - Verify the document structure matches the trigger conditions
   - Check Cloud Function logs in Firebase Console

### Debug Steps

1. **Check FCM Token**:
   ```dart
   final status = await NotificationTestService.checkNotificationStatus();
   print('Notification Status: $status');
   ```

2. **Check Firestore Data**:
   - Verify user documents have `fcmToken` field
   - Check notification preferences are set correctly

3. **Check Cloud Function Logs**:
   - Go to Firebase Console > Functions > Logs
   - Look for errors or successful execution messages

## User Experience

### Notification Flow
1. User opens the app for the first time
2. App requests notification permissions
3. FCM token is automatically saved to Firestore
4. User can manage notification preferences in settings
5. Notifications are sent based on user preferences and app events

### Notification Content
- **Adoption Approved**: "🎉 Adoption Approved! Your adoption application for [Animal Name] has been approved!"
- **Adoption Rejected**: "Adoption Application Update. Your adoption application for [Animal Name] has been reviewed."
- **New Animal**: "🐾 New Animal Available! Meet [Animal Name] - [Species] available for adoption!"

## Security Considerations

1. **FCM Token Security**: FCM tokens are stored in Firestore and are user-specific
2. **Notification Preferences**: Users can only modify their own notification settings
3. **Cloud Function Security**: Functions validate user permissions before sending notifications

## Future Enhancements

1. **Rich Notifications**: Add images and action buttons to notifications
2. **Scheduled Notifications**: Send reminders about pending applications
3. **Notification History**: Allow users to view past notifications
4. **Push Notification Analytics**: Track notification open rates and engagement

## Support

If you encounter any issues with the push notification setup, check:
1. Firebase Console for Cloud Function logs
2. Device notification settings
3. Firestore data structure
4. Network connectivity

For additional help, refer to the Firebase documentation or contact the development team.
