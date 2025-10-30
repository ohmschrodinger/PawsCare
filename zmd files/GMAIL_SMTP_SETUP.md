# 📧 Gmail SMTP Email Setup Guide for PawsCare

This guide will help you set up email notifications using Gmail SMTP through Firebase Cloud Functions.

## 🚀 Step-by-Step Setup

### **Step 1: Enable Gmail 2-Factor Authentication**

1. Go to [Google Account Settings](https://myaccount.google.com/)
2. Navigate to **Security** → **2-Step Verification**
3. Enable 2-Step Verification if not already enabled

### **Step 2: Generate Gmail App Password**

1. Go to [Google Account Settings](https://myaccount.google.com/)
2. Navigate to **Security** → **App passwords**
3. Select **Mail** as the app and **Other** as the device
4. Click **Generate**
5. **Copy the 16-character password** (you'll need this)

### **Step 3: Install Firebase CLI**

```bash
npm install -g firebase-tools
```

### **Step 4: Login to Firebase**

```bash
firebase login
```

### **Step 5: Configure Gmail Credentials in Firebase**

```bash
# Set your Gmail email
firebase functions:config:set gmail.email="YOUR_GMAIL@gmail.com"

# Set your Gmail app password
firebase functions:config:set gmail.password="YOUR_16_CHAR_APP_PASSWORD"
```

### **Step 6: Deploy Firebase Cloud Functions**

```bash
# Navigate to functions directory
cd functions

# Install dependencies
npm install

# Build TypeScript
npm run build

# Deploy to Firebase
firebase deploy --only functions
```

### **Step 7: Update Flutter App Configuration**

After deployment, Firebase will give you a URL like:
`https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/sendEmail`

Update this in your Flutter app:

```dart
// In lib/services/email_notification_service.dart
const String cloudFunctionUrl = 'https://us-central1-YOUR_ACTUAL_PROJECT_ID.cloudfunctions.net/sendEmail';
```

### **Step 8: Test the Email System**

1. Post an animal from a user account
2. Approve it from an admin account
3. Check the user's email for the approval notification
4. Check Firebase Console → Functions → Logs for any errors

## 🔧 Configuration Details

### **Gmail SMTP Settings**
- **Server**: smtp.gmail.com
- **Port**: 587
- **Security**: TLS
- **Authentication**: Gmail App Password

### **Firebase Environment Variables**
```bash
gmail.email=your-email@gmail.com
gmail.password=your-16-char-app-password
```

### **Email Types Supported**
- ✅ Login notifications
- ✅ Animal post confirmations
- ✅ Animal approval/rejection
- ✅ Adoption application confirmations
- ✅ Adoption approval/rejection
- ✅ Welcome emails for new users
- ✅ Password reset confirmations

## 🐛 Troubleshooting

### **Common Issues & Solutions**

#### **1. "Email service not configured" Error**
- Ensure you've set the Gmail credentials in Firebase
- Check: `firebase functions:config:get`

#### **2. "Authentication failed" Error**
- Verify your Gmail app password is correct
- Ensure 2-Factor Authentication is enabled
- Check that you're using the app password, not your regular password

#### **3. "Cloud Function not found" Error**
- Verify the Cloud Function URL is correct
- Check that functions are deployed: `firebase functions:list`
- Ensure your project ID is correct in the URL

#### **4. Emails not being sent**
- Check Firebase Console → Functions → Logs
- Verify the recipient email is valid
- Check if the user has email notifications enabled

### **Debug Steps**

1. **Check Firebase Functions Logs:**
   ```bash
   firebase functions:log
   ```

2. **Verify Configuration:**
   ```bash
   firebase functions:config:get
   ```

3. **Test Function Locally:**
   ```bash
   cd functions
   npm run serve
   ```

## 📱 Testing in Flutter App

### **Console Logs to Look For**
```
📧 Attempting to send email: animal_approved to user@example.com
🌐 Calling Cloud Function: https://us-central1-xxx.cloudfunctions.net/sendEmail
✅ Email sent successfully! Response: {"success":true,"message":"Email sent successfully"}
```

### **Firestore Collections Created**
- `email_notifications` - Notification history
- `email_logs` - Email sending logs

## 🔒 Security Notes

- **Never commit Gmail credentials** to version control
- **Use App Passwords** instead of regular passwords
- **Enable 2-Factor Authentication** on your Gmail account
- **Restrict Cloud Function access** if needed

## 📊 Monitoring

### **Firebase Console**
- **Functions** → **Logs** - View function execution logs
- **Firestore** → **email_logs** - View email sending history
- **Functions** → **Usage** - Monitor function calls and costs

### **Gmail**
- Check **Sent Mail** folder for sent emails
- Monitor **App passwords** usage

## 🎯 Next Steps

1. **Customize Email Templates** in `functions/src/index.ts`
2. **Add More Email Types** as needed
3. **Implement Email Preferences** for users
4. **Add Email Analytics** and tracking
5. **Set up Email Bounce Handling**

## 📞 Support

If you encounter issues:
1. Check Firebase Console logs
2. Verify Gmail settings
3. Test with a simple email first
4. Check network connectivity

---

**Happy Email Sending! 🐾📧**

