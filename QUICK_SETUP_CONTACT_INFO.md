# Quick Setup: Contact Info in Firestore

## Fastest Way to Set Up (3 Steps)

### 1. Run the Setup Script
```bash
cd functions
npx ts-node src/setup-contact-info.ts
```

### 2. Update Firestore Security Rules
Add this to your Firestore rules:
```javascript
match /contact_info/info {
  allow read: if true;
  allow write: if request.auth != null && request.auth.token.admin == true;
}
```

### 3. Test in App
- Open app → Contact Us (verify contact info)
- Open app → About Developers (verify developer info)

---

## Manual Setup (Firebase Console)

1. Firebase Console → Firestore Database
2. Create collection: `contact_info`
3. Create document ID: `info`
4. Add these 17 fields:

```
pawscare_email: pawscareanimalresq@gmail.com
pawscare_insta: https://www.instagram.com/pawscareanimalresq/
pawscare_linkedin: https://www.linkedin.com/company/pawscare/
pawscare_whatsapp: +917057517218
pawscare_volunteerform: [your-google-form-url]

developer1_name: Om Dhamame
developer1_role: Lead Developer
developer1_linkedin: https://www.linkedin.com/in/ohmschrodinger/
developer1_github: https://github.com/ohmschrodinger

developer2_name: Mahi Sharma
developer2_role: Developer
developer2_linkedin: https://www.linkedin.com/in/mahisharma
developer2_github: https://github.com/mahisharma

developer3_name: Kushagra Goyal
developer3_role: Developer
developer3_linkedin: https://www.linkedin.com/in/kushagra
developer3_github: https://github.com/kushagragoyal
```

---

## To Update Contact Info Later

### Method 1: Firebase Console
1. Firestore Database → contact_info → info
2. Click field → Edit → Save

### Method 2: Script
1. Edit `functions/src/setup-contact-info.ts`
2. Run: `npx ts-node src/setup-contact-info.ts --force`

---

## Verification Checklist

✅ Document path: `contact_info/info`  
✅ All 17 fields present  
✅ Security rules allow read  
✅ Contact Us screen loads  
✅ About Developers screen loads  
✅ All links work  

---

## Phone Country Code

✅ Already implemented - India (+91) is now default  
✅ 25+ countries available in dropdown  
✅ No setup required - works out of the box  
