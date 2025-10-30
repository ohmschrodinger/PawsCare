# Google Places API Setup Guide

This guide will help you set up Google Places API for PawsCare app to enable location autocomplete and "Near Me" filtering.

## Prerequisites

✅ Google Cloud Console account
✅ Places API enabled (already done according to your message)
✅ API key created

---

## Step 1: Add Your API Key

### Option A: Direct in Code (Quick but less secure)

1. Open `lib/screens/post_animal_screen.dart`
2. Find line 63 with:
   ```dart
   static const String _googleApiKey = 'YOUR_GOOGLE_PLACES_API_KEY';
   ```
3. Replace `YOUR_GOOGLE_PLACES_API_KEY` with your actual API key from Google Cloud Console

### Option B: Using Environment Variables (Recommended for production)

1. Create a `.env` file in the project root:
   ```
   GOOGLE_PLACES_API_KEY=your_actual_api_key_here
   ```

2. Update `pubspec.yaml` assets to include the `.env` file:
   ```yaml
   flutter:
     assets:
       - .env
       - assets/images/
   ```

3. Update `post_animal_screen.dart` to load from environment:
   ```dart
   import 'package:flutter_dotenv/flutter_dotenv.dart';
   
   // Replace the hardcoded key with:
   static final String _googleApiKey = dotenv.env['GOOGLE_PLACES_API_KEY'] ?? '';
   ```

4. Initialize dotenv in `main.dart` before `runApp()`:
   ```dart
   await dotenv.load(fileName: ".env");
   ```

---

## Step 2: Configure API Restrictions (Recommended)

### For Android:

1. Go to Google Cloud Console → APIs & Services → Credentials
2. Click on your API key
3. Under "Application restrictions", select "Android apps"
4. Click "Add an item"
5. Get your SHA-1 fingerprint:
   ```powershell
   cd android
   .\gradlew signingReport
   ```
6. Add the SHA-1 fingerprint and package name: `com.example.pawscare`

### For iOS:

1. In Google Cloud Console, under "Application restrictions", select "iOS apps"
2. Add your bundle identifier (found in `ios/Runner.xcodeproj`)

---

## Step 3: Enable Required APIs

Make sure these APIs are enabled in Google Cloud Console:

- ✅ Places API (New) - Already enabled
- ✅ Places API
- ✅ Geocoding API
- ✅ Geolocation API (optional, for better accuracy)

---

## Step 4: Test the Implementation

### Run the app and install dependencies:

```powershell
flutter pub get
flutter run
```

### Test Location Autocomplete:

1. Navigate to "Post New Animal" screen
2. Tap on the "Location of Animal*" field
3. Start typing a location (e.g., "Koregaon Park, Pune")
4. You should see location suggestions appear
5. Select a location - you'll see a green checkmark confirming selection

### Test "Near Me" Filter:

1. Navigate to "Adopt Love" (Animal Adoption) screen
2. Tap the "Filter" button
3. In "Sort by", select "Near Me"
4. Grant location permissions when prompted
5. Animals should now be sorted by distance from your location

---

## Features Implemented

### 1. **Location Autocomplete in Post Animal Screen**
   - Google Places autocomplete dropdown
   - Restricted to India (`countries: ["in"]`)
   - Shows location icon and formatted address
   - Validates that user selects from dropdown (not just types)
   - Stores coordinates, place_id, and formatted address

### 2. **Firestore Schema Updates**
   - Each animal document now includes:
     - `address` - Display address string
     - `latitude` - Decimal latitude
     - `longitude` - Decimal longitude
     - `geopoint` - GeoPoint object for Firestore geo queries
     - `placeId` - Google Places ID
     - `formattedAddress` - Full formatted address

### 3. **"Sort by Near Me" Filter**
   - Available in Animal Adoption screen
   - Requests location permission
   - Calculates distance using Haversine formula
   - Sorts animals by proximity
   - Fallback to "Recently Added" if location unavailable

### 4. **Backward Compatibility**
   - Old animal posts without coordinates still work
   - They appear at the end when sorting by "Near Me"

---

## Troubleshooting

### Issue: No autocomplete suggestions appear
**Solution:** 
- Check API key is correct
- Verify Places API is enabled in Cloud Console
- Check network connectivity
- Look for errors in console logs

### Issue: "Location permission denied"
**Solution:**
- User needs to grant location permission
- On Android: Settings → Apps → PawsCare → Permissions → Location
- On iOS: Settings → Privacy → Location Services → PawsCare

### Issue: API quota exceeded
**Solution:**
- Check usage in Google Cloud Console
- Places API has free tier: 
  - Autocomplete: $2.83 per 1000 requests (first $200 free monthly)
  - Consider implementing request caching

### Issue: "Billing not enabled" error
**Solution:**
- Enable billing in Google Cloud Console
- You still get $200 free monthly credit

---

## Cost Estimation

With the free tier ($200/month credit):
- **Autocomplete requests:** ~70,000 free requests/month
- **Geocoding requests:** ~40,000 free requests/month

For a small app, this should be more than sufficient!

---

## Next Steps (Optional Enhancements)

1. **Add distance display on animal cards**
   - Show "2.5 km away" on each card when sorted by Near Me

2. **Add radius filter**
   - Let users filter animals within X km radius

3. **Cache locations**
   - Store frequently searched locations to reduce API calls

4. **Implement Firestore geo queries**
   - Use `geoflutterfire` package for efficient geo queries
   - Query only animals within certain radius

5. **Add map view**
   - Show animals on a map using `google_maps_flutter`

---

## Files Modified

✅ `pubspec.yaml` - Added dependencies
✅ `lib/models/animal_location.dart` - New location model
✅ `lib/services/location_service.dart` - Location utilities
✅ `lib/services/animal_service.dart` - Updated to store location data
✅ `lib/screens/post_animal_screen.dart` - Added Places autocomplete
✅ `lib/screens/animal_adoption_screen.dart` - Added "Near Me" sorting
✅ `android/app/src/main/AndroidManifest.xml` - Added location permissions

---

## Support

If you encounter any issues:
1. Check console logs for detailed error messages
2. Verify all steps in this guide are completed
3. Ensure API key has proper permissions
4. Check that billing is enabled (even for free tier)

Happy coding! 🐾
