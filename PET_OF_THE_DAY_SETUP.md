# Pet of the Day Feature

## Overview
The "Pet of the Day" feature automatically selects a random available pet each day to be featured on the home screen of the PawsCare app.

## How It Works

### Automated Daily Update
- **Scheduled Function**: `updatePetOfTheDay` runs every day at midnight UTC
- **Selection Logic**: Randomly selects one pet from all available, approved pets
- **Storage**: Stores the selected pet in Firestore at `app_config/pet_of_the_day`

### Manual Refresh
You can manually trigger an update using the HTTP endpoint:
```bash
curl https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/refreshPetOfTheDay
```

## Firebase Setup

### 1. Deploy Cloud Functions
```bash
cd functions
npm install
firebase deploy --only functions:updatePetOfTheDay,functions:refreshPetOfTheDay
```

### 2. Firestore Structure
The function creates/updates a document at:
```
app_config/
  pet_of_the_day/
    - petId: string
    - petName: string
    - petSpecies: string
    - petAge: string
    - petGender: string
    - petImage: string
    - petDescription: string
    - selectedAt: timestamp
    - hasPet: boolean
    - fullPetData: map (complete pet details)
```

### 3. Security Rules
Add these Firestore security rules:
```javascript
match /app_config/{document} {
  // Allow anyone to read app_config (like pet of the day)
  allow read: if true;
  // Only functions can write
  allow write: if false;
}
```

## Testing

### Test the Scheduled Function Locally
```bash
cd functions
npm run serve
# In another terminal:
firebase functions:shell
# Then run:
updatePetOfTheDay()
```

### Test the HTTP Endpoint
After deployment, test the manual refresh:
```bash
# Replace with your actual endpoint
curl https://us-central1-pawscare.cloudfunctions.net/refreshPetOfTheDay
```

## App Implementation

The home screen (`lib/screens/home_screen.dart`) uses a `StreamBuilder` to:
1. Listen for real-time updates to the pet of the day
2. Display the selected pet's information
3. Show a placeholder if no pets are available
4. Handle loading states

## Monitoring

Check Cloud Functions logs:
```bash
firebase functions:log --only updatePetOfTheDay
```

## Troubleshooting

### No pet is being selected
- Verify pets exist with `status == 'Available'` and `approvalStatus == 'approved'`
- Check Cloud Functions logs for errors
- Manually trigger refresh to test

### Pet not updating in app
- Check that the app has read permissions to `app_config` collection
- Verify the StreamBuilder is working correctly
- Check for network connectivity issues

## Cost Considerations
- Scheduled function runs once per day
- Firestore read/write operations are minimal
- Should fall well within Firebase free tier limits
