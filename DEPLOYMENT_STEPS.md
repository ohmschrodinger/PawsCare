# Deployment Steps for Notification Features

## Prerequisites
✅ Firebase CLI installed and logged in
✅ Gmail SMTP credentials configured in Firebase

## Step 1: Verify Gmail Configuration

Check if Gmail credentials are set:
```bash
firebase functions:config:get
```

If not set, configure them:
```bash
firebase functions:config:set gmail.email="your-email@gmail.com"
firebase functions:config:set gmail.password="your-16-char-app-password"
```

## Step 2: Build Functions (Already Done ✅)

The TypeScript functions have already been built. You can verify by checking:
```bash
cd functions
ls lib/index.js
```

If you need to rebuild:
```bash
cd functions
npm run build
```

## Step 3: Deploy Cloud Functions

Deploy all functions:
```bash
firebase deploy --only functions
```

Or deploy only the new/updated functions:
```bash
firebase deploy --only functions:onAdoptionApplicationSubmitted,functions:onNewAnimalPostRequest,functions:onAdoptionApplicationRejected
```

## Step 4: Verify Deployment

1. Go to Firebase Console → Functions
2. Check that the following functions are listed:
   - ✅ `onAdoptionApplicationSubmitted` (NEW)
   - ✅ `onNewAnimalPostRequest` (NEW)
   - ✅ `onAdoptionApplicationRejected` (UPDATED)
   - ✅ `onAdoptionApplicationApproved` (EXISTING)
   - ✅ `onAnimalPostApproved` (EXISTING)

## Step 5: Test the Implementation

### Test 1: Adoption Application Submission
1. Open the app as a regular user
2. Browse to an animal and submit an adoption application
3. Check your email inbox for confirmation
4. Check app notifications for push notification

**Expected Results:**
- ✅ Email: "Adoption Application Submitted - PawsCare"
- ✅ Push Notification: "📝 Application Submitted"

### Test 2: New Animal Post Request (Admin Notification)
1. Open the app as a regular user
2. Create a new animal post
3. Check admin email inbox
4. Check admin app notifications

**Expected Results:**
- ✅ Admin receives email: "🐾 New Animal Post Request - PawsCare Admin"
- ✅ Admin receives push notification: "🐾 New Animal Post Request"

### Test 3: Application Approval
1. Login as admin
2. Go to Applications screen
3. Approve a pending application
4. Check applicant's email and notifications

**Expected Results:**
- ✅ Email: "🎉 Adoption Application Approved! - PawsCare"
- ✅ Push Notification: "🎉 Adoption Approved!"

### Test 4: Application Rejection
1. Login as admin
2. Go to Applications screen
3. Reject a pending application with a reason
4. Check applicant's email and notifications

**Expected Results:**
- ✅ Email: "Adoption Application Update - PawsCare" (with rejection reason)
- ✅ Push Notification: "Adoption Application Update"

## Step 6: Monitor Logs

### Real-time Function Logs
```bash
firebase functions:log
```

### Check Email Logs in Firestore
Navigate to: Firebase Console → Firestore → `email_logs`

Each document should contain:
```json
{
  "type": "adoption_submitted | adoption_approved | adoption_rejected | new_post_request_admin",
  "recipientEmail": "user@example.com",
  "data": { /* event details */ },
  "sentAt": "timestamp",
  "status": "sent"
}
```

### Check Notification Logs in Firestore
Navigate to: Firebase Console → Firestore → `notification_logs`

## Troubleshooting

### Issue: Functions not deploying
**Solution:**
```bash
cd functions
npm install
npm run build
firebase deploy --only functions
```

### Issue: Emails not being sent
**Solution:**
1. Check Gmail configuration:
   ```bash
   firebase functions:config:get
   ```
2. Verify Gmail App Password is correct
3. Check function logs for errors:
   ```bash
   firebase functions:log --only onAdoptionApplicationSubmitted
   ```

### Issue: Admin not receiving new post notifications
**Solution:**
1. Check user has role='admin' in Firestore
2. Verify admin email exists in user document
3. Check admin has FCM token for push notifications

### Issue: Push notifications not working
**Solution:**
1. Ensure user has granted notification permissions
2. Check FCM token exists in user document
3. Verify notification preferences are enabled
4. Check notification logs in Firestore

## Important Notes

1. **Gmail Rate Limits**: Gmail has sending limits. For production, consider using SendGrid or similar services.

2. **Admin Users**: Ensure at least one user has `role: 'admin'` in Firestore:
   ```javascript
   // In Firestore Console → users → {user-id}
   {
     "email": "admin@example.com",
     "role": "admin",
     "fcmToken": "...",
     // ... other fields
   }
   ```

3. **Notification Preferences**: Users can toggle notifications in app settings. Functions respect these preferences.

4. **Testing in Development**: Functions can be tested locally using Firebase Emulators:
   ```bash
   firebase emulators:start
   ```

## Summary of Changes

### New Cloud Functions
1. `onAdoptionApplicationSubmitted` - Notifies user when application is submitted
2. `onNewAnimalPostRequest` - Notifies all admins when new post is created

### Updated Cloud Functions
1. `onAdoptionApplicationRejected` - Now sends email in addition to push notification

### New Email Templates
1. `adoption_applied` - Confirmation email for application submission
2. `new_post_request_admin` - Admin notification for new post requests

### Files Modified
1. `functions/src/index.ts` - Added new functions and email templates
2. `functions/lib/index.js` - Compiled JavaScript (auto-generated)

## Next Steps

After deployment:
1. ✅ Test all notification flows
2. ✅ Monitor function logs for any errors
3. ✅ Verify email delivery rates
4. ✅ Check user feedback on notifications
5. ✅ Consider adding notification preferences UI
6. ✅ Monitor Firebase usage and costs

---

**Deployment Date**: October 31, 2025  
**Status**: Ready for Deployment 🚀
