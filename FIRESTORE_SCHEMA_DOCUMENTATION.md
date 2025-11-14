# Firestore Schema Documentation
**Last Updated:** November 14, 2025

This document outlines all Firestore collections and their schemas, along with the corresponding Google Sheets logging structure.

---

## 📊 Collection Schemas

### 1. **users** Collection

**Purpose:** Store user account information

**Schema:**
```typescript
{
  uid: string                    // Firebase Auth UID (document ID)
  email: string                  // User email address
  firstName: string              // User's first name
  lastName: string               // User's last name
  phoneNumber?: string           // User's phone number (optional)
  address?: string               // User's physical address (optional)
  role: string                   // User role: 'user', 'admin', 'superadmin'
  isActive: boolean              // Account status
  profileCompleted: boolean      // Whether user completed profile setup
  isEmailVerified: boolean       // Email verification status
  isPhoneVerified: boolean       // Phone verification status
  signInMethod: string           // 'email', 'phone', 'google'
  fcmToken?: string              // Firebase Cloud Messaging token for push notifications
  createdAt: Timestamp           // Account creation timestamp
  updatedAt: Timestamp           // Last update timestamp
}
```

**Google Sheets Log:** `users_log`
```
Columns: uid | email | firstName | lastName | phoneNumber | address | role | isActive | profileCompleted | isEmailVerified | isPhoneVerified | signInMethod | fcmToken | createdAt | updatedAt | field_updated | timestamp
```

---

### 2. **animals** Collection

**Purpose:** Store animal listings for adoption

**Schema:**
```typescript
{
  name: string                   // Animal's name
  species: string                // 'Dog', 'Cat', 'Other'
  breedType: string              // 'Pure Breed', 'Mixed Breed', 'Unknown'
  breed: string                  // Specific breed name
  age: string                    // Age description (e.g., '2 months', '3 years')
  gender: string                 // 'Male', 'Female'
  status: string                 // 'Available for Adoption', 'Pending Adoption', 'Adopted'
  sterilization: string          // 'Yes', 'No', 'Scheduled'
  vaccination: string            // 'Up to Date', 'Partially Done', 'Not Done'
  deworming: string              // 'Yes', 'No', 'Scheduled'
  motherStatus: string           // 'With Mother', 'Without Mother', 'Unknown'
  medicalIssues: string          // Description of any medical conditions
  location: string               // Location name/address
  latitude?: number              // GPS latitude (optional)
  longitude?: number             // GPS longitude (optional)
  geopoint?: GeoPoint            // Firestore GeoPoint for location queries
  contactPhone: string           // Contact phone number
  rescueStory: string            // Animal's rescue/background story
  approvalStatus: string         // 'pending', 'approved', 'rejected'
  postedBy: string               // User ID who posted the animal
  postedByEmail: string          // Email of user who posted
  postedByName?: string          // Full name of user who posted (new field)
  imageUrls: string[]            // Array of image URLs
  adminMessage: string           // Admin's message/feedback
  isActive: boolean              // Whether listing is active
  approvedAt?: Timestamp         // Approval timestamp (optional)
  approvedBy?: string            // Admin UID who approved (optional)
  postedAt: Timestamp            // Post creation timestamp
  adoptedAt?: Timestamp          // Adoption timestamp (optional)
  adoptedBy?: string             // Adopter's user ID (optional)
  adopterName?: string           // Adopter's name (optional)
  adopterEmail?: string          // Adopter's email (optional)
  adopterPhone?: string          // Adopter's phone (optional)
  adopterAddress?: string        // Adopter's address (optional)
}
```

**Google Sheets Log:** `animals_log`
```
Columns: animalId | name | species | breedType | breed | age | gender | status | sterilization | vaccination | deworming | motherStatus | medicalIssues | location | latitude | longitude | contactPhone | rescueStory | approvalStatus | postedBy | postedByEmail | postedByName | imageUrls | adminMessage | isActive | approvedAt | approvedBy | postedAt | field_updated | timestamp
```

---

### 3. **applications** Collection

**Purpose:** Store adoption applications

**Schema:**
```typescript
{
  userId: string                         // Applicant's user ID
  petId: string                          // Animal's document ID
  petName: string                        // Animal's name (cached)
  petImage: string                       // First image URL (cached)
  applicantName: string                  // Applicant's full name
  applicantEmail: string                 // Applicant's email
  applicantPhone: string                 // Applicant's phone number
  applicantAddress: string               // Applicant's address
  hasCurrentPets: boolean                // Does applicant have pets now?
  currentPetsDetails: string             // Details about current pets
  hasPastPets: boolean                   // Has applicant had pets before?
  pastPetsDetails: string                // Details about past pets
  hasSurrenderedPets: boolean            // Has applicant surrendered pets?
  surrenderedPetsCircumstance: string    // Why they surrendered pets
  homeOwnership: string                  // 'Own', 'Rent', 'Other'
  householdMembers: number               // Number of people in household
  hasAllergies: boolean                  // Any pet allergies in household?
  allMembersAgree: boolean               // Do all members agree to adoption?
  petTypeLookingFor: string              // Type of pet they're looking for
  preferenceForBreedAgeGender: string    // Specific preferences
  whyAdoptPet: string                    // Reason for adoption
  hoursLeftAlone: string                 // Hours pet will be alone daily
  whereKeptWhenAlone: string             // Where pet will be kept
  financiallyPrepared: boolean           // Ready for financial commitment?
  hasVeterinarian: boolean               // Do they have a vet?
  vetContactInfo: string                 // Veterinarian contact details
  willingToProvideVetCare: boolean       // Will provide veterinary care?
  preparedForLifetimeCommitment: boolean // Ready for lifetime commitment?
  ifCannotKeepCare: string               // Plan if can't keep pet
  status: string                         // 'Under Review', 'Approved', 'Rejected'
  appliedAt: Timestamp                   // Application submission timestamp
  reviewedAt?: Timestamp                 // Review timestamp (optional)
  adminMessage: string                   // Admin's feedback/message
}
```

**Google Sheets Log:** `applications_log`
```
Columns: applicationId | userId | petId | petName | applicantName | applicantEmail | applicantPhone | status | appliedAt | reviewedAt | adminMessage | applicationData | field_updated | timestamp
```

**Note:** The `applicationData` column contains the full application as JSON, including all 33+ form fields. Core fields are in dedicated columns for easy filtering/analysis.

---

### 4. **email_logs** Collection

**Purpose:** Track all emails sent by the system

**Schema:**
```typescript
{
  type: string                   // Email type (e.g., 'welcome', 'animal_approved', 'adoption_approved')
  recipientEmail: string         // Email recipient address
  data: object                   // Email-specific data (JSON object with relevant fields)
  sentAt: Timestamp              // Email send timestamp
  status: string                 // 'sent', 'failed'
}
```

**Google Sheets Log:** `emails_log`
```
Columns: logId | type | recipientEmail | sentAt | status | data | field_updated | timestamp
```

---

### 5. **notification_logs** Collection

**Purpose:** Track all push notifications sent

**Schema:**
```typescript
{
  userId: string                 // Notification recipient user ID
  title: string                  // Notification title
  body: string                   // Notification body text
  type: string                   // Notification type (e.g., 'new_animal', 'adoption_approved')
  messageId?: string             // FCM message ID (optional)
  sentAt: Timestamp              // Notification send timestamp
  status: string                 // 'sent', 'failed'
  error?: string                 // Error message if failed (optional)
  data: object                   // Notification-specific data (JSON object)
}
```

**Google Sheets Log:** `notifications_log`
```
Columns: logId | userId | title | body | type | messageId | sentAt | status | error | data | field_updated | timestamp
```

---

### 6. **logs** Collection

**Purpose:** General application event logging (from LoggingService)

**Schema:**
```typescript
{
  eventType: string              // Event name (e.g., 'animal_posted', 'adoption_application_submitted')
  userId?: string                // User ID associated with event (optional)
  userEmail?: string             // User email associated with event (optional)
  data: object                   // Event-specific data (JSON object)
  createdAt: Timestamp           // Event timestamp
}
```

**Google Sheets Log:** `logs`
```
Columns: logId | eventType | userId | userEmail | data | createdAt | field_updated | timestamp
```

---

### 7. **app_statistics** Collection

**Purpose:** Permanent counters and statistics

**Document: adoption_counter**
```typescript
{
  totalAdoptions: number         // Total adoptions count (never decreases)
  createdAt: Timestamp           // Counter creation timestamp
  updatedAt: Timestamp           // Last update timestamp
  description: string            // Counter description
}
```

**Note:** This collection is NOT logged to Google Sheets as it's a permanent counter.

---

### 8. **contact_info** Collection (Single Document)

**Purpose:** Dynamic contact information for the app

**Document: info**
```typescript
{
  pawscareEmail: string          // Organization email
  pawscareWhatsapp: string       // WhatsApp contact number
  pawscareLinkedin: string       // LinkedIn profile URL
  pawscareInsta: string          // Instagram profile URL
  pawscareVolunteerform: string  // Volunteer form URL
  updatedAt: Timestamp           // Last update timestamp
}
```

**Note:** This collection is NOT logged to Google Sheets as it's configuration data.

---

## 🔄 Cloud Functions Triggers

### Email & Notification Triggers

1. **onUserEmailVerified** - Sends welcome email when user verifies email
2. **onAnimalPostApproved** - Sends approval email to poster and notifications to users
3. **onNewAnimalPostRequest** - Notifies admins of pending animal posts
4. **onAdoptionApplicationSubmitted** - Confirms application submission to applicant
5. **onAdoptionApplicationApproved** - Notifies applicant of approval
6. **onAdoptionApplicationRejected** - Notifies applicant of rejection

### Google Sheets Logging Triggers

1. **logUserToSheet** - Logs user document changes to `users_log` sheet
2. **logAnimalToSheet** - Logs animal document changes to `animals_log` sheet
3. **logApplicationToSheet** - Logs application document changes to `applications_log` sheet
4. **logEmailToSheet** - Logs email sends to `emails_log` sheet
5. **logNotificationToSheet** - Logs push notifications to `notifications_log` sheet
6. **logGeneralToSheet** - Logs general events to `logs` sheet

---

## 📝 Important Notes

### Field Updates Tracking
- All logging functions track which fields changed during updates
- The `field_updated` column shows either:
  - `new_<type>` for new documents (e.g., `new_user`, `new_animal`)
  - Comma-separated list of changed fields for updates (e.g., `status, adminMessage`)
  - `none` if no tracked fields changed

### Timestamps
- All logs include two timestamps:
  - Document's own timestamp field (e.g., `createdAt`, `sentAt`)
  - Logging timestamp (when the log was written to sheets)

### Data Column
- The `data` column in logs contains JSON-stringified objects
- This preserves complex nested data that doesn't fit in dedicated columns

### Boolean Values
- Boolean fields are logged as "TRUE" or "FALSE" strings in sheets
- Empty/null values are logged as empty strings ""

### Arrays
- Array fields (like `imageUrls`) are logged as comma-separated strings

---

## 🔧 Configuration Required

### Firebase Functions Config
```bash
firebase functions:config:set sheets.spreadsheet_id="YOUR_SPREADSHEET_ID"
firebase functions:config:set sheets.key_b64="BASE64_ENCODED_SERVICE_ACCOUNT_KEY"
firebase functions:config:set gmail.email="YOUR_GMAIL@gmail.com"
firebase functions:config:set gmail.password="YOUR_APP_PASSWORD"
```

### Google Sheets Structure
Create sheets with these exact names:
- `users_log`
- `animals_log`
- `applications_log`
- `emails_log`
- `notifications_log`
- `logs`

Headers will be automatically added by the functions on first write.

---

## 🚀 Deployment

After making schema changes:

```bash
cd functions
npm run build
firebase deploy --only functions
```

---

## ✅ Schema Update Checklist

When adding/modifying fields:

- [ ] Update Firestore document structure in client code
- [ ] Update `trackedFields` array in corresponding Cloud Function
- [ ] Update row building logic in Cloud Function
- [ ] Update this documentation
- [ ] Test in development environment
- [ ] Deploy functions
- [ ] Verify Google Sheets columns match

---

## 📧 Contact

For schema questions or updates, contact the development team.
