# Contact Info Firestore Setup Guide

This guide explains how to set up the `contact_info` collection in Firestore to store contact details and developer information for the PawsCare app.

## Overview

The app now fetches contact information and developer details from Firestore instead of using hardcoded values. This allows you to update contact information without releasing a new version of the app.

## Collection Structure

**Collection:** `contact_info`  
**Document ID:** `info`

## Setting Up in Firebase Console

### Step 1: Navigate to Firestore Database

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your PawsCare project
3. Click on "Firestore Database" in the left sidebar
4. If prompted, make sure you're in "Cloud Firestore" (not Realtime Database)

### Step 2: Create the Collection

1. Click on "Start collection" (if this is your first collection) or "+ Start collection"
2. Enter Collection ID: `contact_info`
3. Click "Next"

### Step 3: Create the Document

1. For Document ID, enter: `info`
2. Add the following fields:

## Required Fields

### PawsCare Organization Contact Information

| Field Name | Type | Example Value | Description |
|------------|------|---------------|-------------|
| `pawscare_email` | string | `pawscareanimalresq@gmail.com` | Organization email address |
| `pawscare_insta` | string | `https://www.instagram.com/pawscareanimalresq/` | Instagram profile URL |
| `pawscare_linkedin` | string | `https://www.linkedin.com/company/pawscare/` | LinkedIn company page URL |
| `pawscare_whatsapp` | string | `+917057517218` | WhatsApp number with country code |
| `pawscare_volunteerform` | string | `https://docs.google.com/forms/d/e/1FAIpQLSduQq2bKmfyvKAkZPOeWR0ZqboNr0hMW2xyUW4geYIidSvxJg/viewform` | Volunteer form URL |

### Developer 1 Information

| Field Name | Type | Example Value | Description |
|------------|------|---------------|-------------|
| `developer1_name` | string | `Om Dhamame` | Developer's full name |
| `developer1_role` | string | `Lead Developer` | Developer's role/title |
| `developer1_linkedin` | string | `https://www.linkedin.com/in/ohmschrodinger/` | LinkedIn profile URL |
| `developer1_github` | string | `https://github.com/ohmschrodinger` | GitHub profile URL |

### Developer 2 Information

| Field Name | Type | Example Value | Description |
|------------|------|---------------|-------------|
| `developer2_name` | string | `Mahi Sharma` | Developer's full name |
| `developer2_role` | string | `Developer` | Developer's role/title |
| `developer2_linkedin` | string | `https://www.linkedin.com/in/mahisharma` | LinkedIn profile URL |
| `developer2_github` | string | `https://github.com/mahisharma` | GitHub profile URL |

### Developer 3 Information

| Field Name | Type | Example Value | Description |
|------------|------|---------------|-------------|
| `developer3_name` | string | `Kushagra Goyal` | Developer's full name |
| `developer3_role` | string | `Developer` | Developer's role/title |
| `developer3_linkedin` | string | `https://www.linkedin.com/in/kushagra` | LinkedIn profile URL |
| `developer3_github` | string | `https://github.com/kushagragoyal` | GitHub profile URL |

## Step-by-Step Field Addition in Firebase Console

For each field listed above:

1. Click "+ Add field"
2. Enter the Field name (e.g., `pawscare_email`)
3. Select Type: `string`
4. Enter the Value
5. Repeat for all 17 fields

### Example Screenshot Flow:

```
Field: pawscare_email
Type: string
Value: pawscareanimalresq@gmail.com

Field: pawscare_insta
Type: string
Value: https://www.instagram.com/pawscareanimalresq/

... (continue for all fields)
```

## Quick Setup Template (JSON Format)

If you prefer to use the Firebase Console's JSON editor or import via script:

```json
{
  "pawscare_email": "pawscareanimalresq@gmail.com",
  "pawscare_insta": "https://www.instagram.com/pawscareanimalresq/",
  "pawscare_linkedin": "https://www.linkedin.com/company/pawscare/",
  "pawscare_whatsapp": "+917057517218",
  "pawscare_volunteerform": "https://docs.google.com/forms/d/e/1FAIpQLSduQq2bKmfyvKAkZPOeWR0ZqboNr0hMW2xyUW4geYIidSvxJg/viewform",
  
  "developer1_name": "Om Dhamame",
  "developer1_role": "Lead Developer",
  "developer1_linkedin": "https://www.linkedin.com/in/ohmschrodinger/",
  "developer1_github": "https://github.com/ohmschrodinger",
  
  "developer2_name": "Mahi Sharma",
  "developer2_role": "Developer",
  "developer2_linkedin": "https://www.linkedin.com/in/mahisharma",
  "developer2_github": "https://github.com/mahisharma",
  
  "developer3_name": "Kushagra Goyal",
  "developer3_role": "Developer",
  "developer3_linkedin": "https://www.linkedin.com/in/kushagra",
  "developer3_github": "https://github.com/kushagragoyal"
}
```

## Firestore Security Rules

Make sure your Firestore security rules allow reading this document. Add the following rule:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow all users to read contact info
    match /contact_info/info {
      allow read: if true;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
  }
}
```

**Note:** This allows anyone to read the contact info (which is public information), but only admin users can write/update it. Adjust the write rule based on your security requirements.

## Updating Contact Information

To update any contact information after the initial setup:

1. Go to Firebase Console → Firestore Database
2. Navigate to `contact_info` collection → `info` document
3. Click on the field you want to edit
4. Update the value
5. Save

The app will automatically fetch the updated information (cached for 1 hour).

## Testing

After setting up the document:

1. Open the PawsCare app
2. Navigate to "Contact Us" screen
   - Verify all contact information displays correctly
   - Test each contact method (email, WhatsApp, LinkedIn, Instagram)
   - Test the volunteer form link

3. Navigate to "About Developers" screen
   - Verify all developer names and roles display correctly
   - Test LinkedIn and GitHub links for each developer

## Troubleshooting

### Issue: "Failed to load contact information"

**Solutions:**
- Verify the collection name is exactly `contact_info` (lowercase, underscore)
- Verify the document ID is exactly `info` (lowercase)
- Check that all required fields are present and properly spelled
- Verify Firestore security rules allow read access
- Check your internet connection

### Issue: Some fields show empty or "Not set"

**Solutions:**
- Verify all 17 fields are present in the document
- Check field names match exactly (case-sensitive, use underscores not hyphens)
- Ensure field values are strings, not other types

### Issue: Links don't open properly

**Solutions:**
- Ensure URLs include `https://` or `http://` prefix
- For Instagram, use full URL: `https://www.instagram.com/username/`
- For LinkedIn, use full URL: `https://www.linkedin.com/in/username/` or `https://www.linkedin.com/company/companyname/`
- WhatsApp number should include country code with + prefix (e.g., `+917057517218`)

## Benefits of This Approach

✅ **No App Updates Required:** Change contact info without releasing new app versions  
✅ **Centralized Management:** Update information in one place  
✅ **Consistent Data:** Same information across all app users  
✅ **Easy Maintenance:** Non-technical staff can update contact details  
✅ **Performance:** Data is cached for 1 hour to minimize Firestore reads

## Cost Considerations

- Each app user will perform **1 Firestore read** when they first open Contact Us or About Developers screens
- Data is cached for 1 hour, reducing subsequent reads
- Firebase free tier includes 50,000 reads/day, which should be sufficient for most use cases

## Notes

- The app caches contact information for 1 hour to reduce Firestore reads
- If you update the Firestore document, users may see old data for up to 1 hour
- To force cache clear, users can restart the app
- The `ContactInfoService` automatically handles caching and error scenarios
