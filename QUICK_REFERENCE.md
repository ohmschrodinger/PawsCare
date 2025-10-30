# Quick Reference Guide - PawsCare Notifications

## 🚀 Quick Deploy

```bash
# 1. Navigate to functions directory
cd "z:\Coding eh\pawscare\functions"

# 2. Build TypeScript (if needed)
npm run build

# 3. Deploy to Firebase
firebase deploy --only functions
```

## 📧 Notification Types

### User Notifications

| Event | Email Subject | Push Notification | Cloud Function |
|-------|--------------|-------------------|----------------|
| Application Submitted | "Adoption Application Submitted" | "📝 Application Submitted" | `onAdoptionApplicationSubmitted` |
| Application Approved | "🎉 Adoption Application Approved!" | "🎉 Adoption Approved!" | `onAdoptionApplicationApproved` |
| Application Rejected | "Adoption Application Update" | "Adoption Application Update" | `onAdoptionApplicationRejected` |

### Admin Notifications

| Event | Email Subject | Push Notification | Cloud Function |
|-------|--------------|-------------------|----------------|
| New Animal Post | "🐾 New Animal Post Request" | "🐾 New Animal Post Request" | `onNewAnimalPostRequest` |

## 🔧 Configuration Commands

```bash
# Check current config
firebase functions:config:get

# Set Gmail credentials
firebase functions:config:set gmail.email="your-email@gmail.com"
firebase functions:config:set gmail.password="your-app-password"

# View function logs
firebase functions:log

# Deploy specific functions
firebase deploy --only functions:onAdoptionApplicationSubmitted,functions:onNewAnimalPostRequest
```

## 📊 Monitor Notifications

### Firestore Collections to Check

1. **`email_logs`** - All sent emails
2. **`notification_logs`** - All push notifications
3. **`users`** - User FCM tokens and preferences
4. **`applications`** - Application data
5. **`animals`** - Animal post data

### Query Examples

```javascript
// Check recent email logs
db.collection('email_logs')
  .orderBy('sentAt', 'desc')
  .limit(10)
  .get()

// Check recent notification logs
db.collection('notification_logs')
  .orderBy('sentAt', 'desc')
  .limit(10)
  .get()

// Find all admin users
db.collection('users')
  .where('role', '==', 'admin')
  .get()
```

## 🧪 Testing Checklist

### Test 1: Application Submission
- [ ] Submit adoption application
- [ ] Check email inbox
- [ ] Check app notification
- [ ] Verify in `email_logs` collection
- [ ] Verify in `notification_logs` collection

### Test 2: Admin Notification for New Post
- [ ] Create new animal post
- [ ] Check admin email inbox
- [ ] Check admin app notification
- [ ] Verify all admins received notification
- [ ] Check logs in Firebase Console

### Test 3: Application Approval
- [ ] Login as admin
- [ ] Approve pending application
- [ ] Check applicant's email
- [ ] Check applicant's app notification
- [ ] Verify in logs

### Test 4: Application Rejection
- [ ] Login as admin
- [ ] Reject application with reason
- [ ] Check applicant's email contains reason
- [ ] Check applicant's app notification
- [ ] Verify in logs

## ⚠️ Troubleshooting

### Emails Not Sending
```bash
# 1. Check config
firebase functions:config:get

# 2. Check logs
firebase functions:log --only onAdoptionApplicationSubmitted

# 3. Verify Gmail app password
# - Must be 16 characters
# - From Google Account → Security → App Passwords
```

### Push Notifications Not Working
```bash
# 1. Check user FCM token in Firestore
db.collection('users').doc('USER_ID').get()
# Should have: fcmToken: "..."

# 2. Check notification permissions in app
# Settings → Notifications → Allow

# 3. Check function logs
firebase functions:log
```

### Admin Not Receiving New Post Notifications
```bash
# 1. Verify admin role
db.collection('users').doc('ADMIN_ID').get()
# Should have: role: "admin"

# 2. Check admin email exists
# email: "admin@example.com"

# 3. Check function execution
firebase functions:log --only onNewAnimalPostRequest
```

## 📝 Key Files

| File | Purpose |
|------|---------|
| `functions/src/index.ts` | Cloud Functions source code |
| `functions/lib/index.js` | Compiled JavaScript |
| `NOTIFICATION_IMPLEMENTATION.md` | Complete implementation guide |
| `DEPLOYMENT_STEPS.md` | Step-by-step deployment |
| `IMPLEMENTATION_SUMMARY.md` | Feature summary |

## 🎯 Quick Commands

```bash
# Build functions
cd functions && npm run build

# Deploy all functions
firebase deploy --only functions

# View real-time logs
firebase functions:log --tail

# Deploy specific function
firebase deploy --only functions:onAdoptionApplicationSubmitted

# Check function status
firebase functions:list

# Delete a function
firebase functions:delete functionName
```

## 📞 Support Checklist

When debugging issues, collect:

1. **Function Logs**: `firebase functions:log`
2. **Email Logs**: Check `email_logs` collection
3. **Notification Logs**: Check `notification_logs` collection
4. **User Data**: Check user's FCM token and preferences
5. **Admin Data**: Verify admin role and email
6. **Config**: Verify Gmail credentials set

## 🔗 Useful Links

- Firebase Console: https://console.firebase.google.com/
- Gmail App Passwords: https://myaccount.google.com/apppasswords
- Firebase Functions Docs: https://firebase.google.com/docs/functions
- Nodemailer Docs: https://nodemailer.com/

---

**Last Updated**: October 31, 2025  
**Quick Access**: Keep this file handy for quick reference!
