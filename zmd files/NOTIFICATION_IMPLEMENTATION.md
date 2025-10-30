# Notification Implementation Guide

This document describes the comprehensive notification system implemented for PawsCare, including email and push notifications for various events.

## Overview

The notification system sends both **email notifications** and **in-app push notifications** for the following events:

### 1. Adoption Application Notifications

#### User Notifications:
- ✅ **Application Submitted** - When a user submits an adoption application
  - Email notification confirming submission
  - Push notification with application details
  
- ✅ **Application Approved** - When admin approves the application
  - Email notification with approval details
  - Push notification with congratulatory message
  
- ✅ **Application Rejected** - When admin rejects the application
  - Email notification with rejection reason
  - Push notification with update message

### 2. Animal Post Notifications

#### Admin Notifications:
- ✅ **New Post Request** - When a user submits a new animal post for approval
  - Email notification to ALL admins
  - Push notification to ALL admins
  - Includes animal details and poster information

#### User Notifications:
- ✅ **Post Approved** - When admin approves the animal post (existing)
- ✅ **Post Rejected** - When admin rejects the animal post (existing)

## Technical Implementation

### Firebase Cloud Functions

The following Cloud Functions have been added/updated in `functions/src/index.ts`:

1. **`onAdoptionApplicationSubmitted`** (NEW)
   - Triggered when a new adoption application is created in Firestore
   - Sends email and push notification to the applicant
   - Logs notification to `email_logs` collection

2. **`onAdoptionApplicationApproved`** (EXISTING)
   - Triggered when application status changes to 'approved'
   - Sends email and push notification to the applicant

3. **`onAdoptionApplicationRejected`** (UPDATED)
   - Triggered when application status changes to 'rejected'
   - **NOW sends email notification** in addition to push notification
   - Includes admin's rejection message

4. **`onNewAnimalPostRequest`** (NEW)
   - Triggered when a new animal document is created with 'pending' approval status
   - Sends email and push notifications to ALL admin users
   - Includes animal and poster details

### Email Templates

New email templates added to `emailTemplates` object:

1. **`adoption_applied`** (EXISTING - but now used)
   ```
   Subject: Adoption Application Submitted - PawsCare
   Content: Confirmation of application submission with details
   ```

2. **`new_post_request_admin`** (NEW)
   ```
   Subject: 🐾 New Animal Post Request - PawsCare Admin
   Content: Notification about new pending post for admin approval
   ```

3. **`adoption_rejected`** (EXISTING - now fully utilized)
   ```
   Subject: Adoption Application Update - PawsCare
   Content: Notification of rejection with admin message
   ```

## Data Flow

### Adoption Application Submission Flow
```
User submits application
    ↓
Firestore: applications/{applicationId} created
    ↓
Cloud Function: onAdoptionApplicationSubmitted triggered
    ↓
1. Fetch user data from users collection
2. Fetch animal data from animals collection
3. Send email via Gmail SMTP
4. Send push notification via FCM
5. Log to email_logs collection
```

### New Animal Post Request Flow
```
User creates animal post
    ↓
Firestore: animals/{animalId} created with approvalStatus='pending'
    ↓
Cloud Function: onNewAnimalPostRequest triggered
    ↓
1. Query all users with role='admin'
2. For each admin:
   - Send email via Gmail SMTP
   - Send push notification via FCM
   - Log to email_logs collection
```

### Application Approved/Rejected Flow
```
Admin updates application status
    ↓
Firestore: applications/{applicationId} updated
    ↓
Cloud Function: onAdoptionApplicationApproved/Rejected triggered
    ↓
1. Fetch user data
2. Fetch animal data
3. Send email via Gmail SMTP
4. Send push notification via FCM
5. Log to email_logs collection
```

## Firestore Collections Used

1. **`users`**
   - Query: Get user details and admin list
   - Fields used: email, fullName, fcmToken, role, adoptionNotifications

2. **`applications`**
   - Trigger: onCreate, onUpdate
   - Fields used: userId, petId, animalId, applicantEmail, applicantName, status, appliedAt

3. **`animals`**
   - Trigger: onCreate, onUpdate
   - Fields used: name, species, breed, age, postedBy, postedByEmail, approvalStatus, postedAt

4. **`email_logs`**
   - Purpose: Track all sent emails
   - Fields: type, recipientEmail, data, sentAt, status

5. **`notification_logs`**
   - Purpose: Track all push notifications
   - Fields: userId, title, body, data, sentAt, status

## Configuration Requirements

### Gmail SMTP Configuration
Ensure the following Firebase environment variables are set:

```bash
firebase functions:config:set gmail.email="your-email@gmail.com"
firebase functions:config:set gmail.password="your-app-password"
```

### User Settings
Users must have the following fields in their Firestore document:
- `email`: Email address
- `fcmToken`: Firebase Cloud Messaging token (auto-set on app initialization)
- `adoptionNotifications`: Boolean (default: true)
- `role`: 'user' or 'admin'

## Deployment

### 1. Build TypeScript Functions
```bash
cd functions
npm install
npm run build
```

### 2. Deploy Functions
```bash
firebase deploy --only functions
```

Or deploy specific functions:
```bash
firebase deploy --only functions:onAdoptionApplicationSubmitted,functions:onNewAnimalPostRequest,functions:onAdoptionApplicationRejected
```

### 3. Verify Deployment
Check Firebase Console → Functions to ensure all functions are deployed successfully.

## Testing

### Test Adoption Application Notifications

1. **Application Submission**
   - Submit an adoption application from the app
   - Verify user receives:
     - Email confirmation
     - Push notification

2. **Application Approval**
   - Login as admin
   - Approve an application
   - Verify user receives:
     - Email with approval message
     - Push notification

3. **Application Rejection**
   - Login as admin
   - Reject an application with a reason
   - Verify user receives:
     - Email with rejection reason
     - Push notification

### Test New Animal Post Notifications

1. **New Post Request**
   - Login as regular user
   - Create a new animal post
   - Verify all admins receive:
     - Email notification about new post
     - Push notification

2. **Check Admin Panel**
   - Admins should see the pending post in the approval screen

## Notification Preferences

Users can control their notification preferences from the settings screen:

- **Adoption Notifications**: Toggles email and push notifications for adoption-related events
- **New Animal Notifications**: Toggles notifications for new animals available
- **General Notifications**: Toggles other app notifications

The Cloud Functions respect these preferences when sending notifications.

## Monitoring

### View Email Logs
```javascript
// In Firebase Console → Firestore → email_logs
// Each document contains:
{
  type: 'adoption_submitted' | 'adoption_approved' | 'adoption_rejected' | 'new_post_request_admin',
  recipientEmail: 'user@example.com',
  data: { /* event-specific data */ },
  sentAt: Timestamp,
  status: 'sent' | 'failed'
}
```

### View Push Notification Logs
```javascript
// In Firebase Console → Firestore → notification_logs
// Each document contains:
{
  userId: 'user-id',
  title: 'Notification Title',
  body: 'Notification Body',
  data: { /* event-specific data */ },
  sentAt: Timestamp,
  status: 'sent' | 'failed',
  messageId: 'fcm-message-id' // if successful
}
```

### View Function Logs
```bash
# View real-time logs
firebase functions:log

# Or check Firebase Console → Functions → Logs
```

## Troubleshooting

### Emails Not Sending
1. Check Gmail configuration:
   ```bash
   firebase functions:config:get
   ```
2. Verify Gmail App Password is correct
3. Check `email_logs` collection for error messages
4. Check Function logs for errors

### Push Notifications Not Sending
1. Verify user has FCM token saved in Firestore
2. Check user notification preferences
3. Verify app has notification permissions
4. Check `notification_logs` for errors

### Admin Not Receiving New Post Notifications
1. Verify user role is set to 'admin' in Firestore
2. Check admin email is valid
3. Check admin has FCM token
4. Review Function logs

### Functions Not Triggering
1. Verify functions are deployed:
   ```bash
   firebase functions:list
   ```
2. Check Firestore security rules allow function access
3. Check Function logs for deployment errors

## Security Considerations

1. **Email Privacy**: Email addresses are only accessible to authenticated users and cloud functions
2. **Admin Identification**: Admin role is verified through Firestore user documents
3. **FCM Tokens**: Stored securely in Firestore and user-specific
4. **Email Logs**: Contain recipient information for debugging but are restricted by security rules

## Future Enhancements

Potential improvements:
1. **Rich Email Templates**: Add images and better styling
2. **Email Batching**: Combine multiple notifications into digest emails
3. **Notification History**: UI for users to view past notifications
4. **Custom Admin Emails**: Allow admins to configure notification recipients
5. **SMS Notifications**: Add SMS support for critical notifications
6. **Notification Analytics**: Track open rates and user engagement

## Support

For issues or questions:
1. Check Firebase Console → Functions → Logs
2. Review Firestore collections (email_logs, notification_logs)
3. Verify environment configuration
4. Consult Firebase documentation

---

**Implementation Date**: October 31, 2025  
**Version**: 1.0  
**Status**: ✅ Production Ready
