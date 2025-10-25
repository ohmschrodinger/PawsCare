# 🔐 API Keys Security Setup

## Why Can't Native Files Use .env Directly?

### The Problem:
- **`AndroidManifest.xml`** - XML config file, no scripting capability
- **`AppDelegate.swift`** - Runs at build time, can't access Flutter runtime assets
- **`.env` files** - Only readable by Flutter at runtime via `flutter_dotenv`

### The Solution:
We use **platform-specific config files** that are:
1. ✅ Read at build time
2. ✅ Git-ignored (not committed to repo)
3. ✅ Simple to set up

---

## 🚀 Quick Setup

### For Android:

1. **API keys are in:** `android/local.properties`
   ```properties
   GOOGLE_MAPS_API_KEY=your_key_here
   GOOGLE_PLACES_API_KEY=your_key_here
   ```

2. **Already configured in:** `android/app/build.gradle.kts`
   - Reads from `local.properties`
   - Injects into `AndroidManifest.xml` at build time

3. **Usage in AndroidManifest.xml:**
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="${GOOGLE_MAPS_API_KEY}" />
   ```

### For iOS:

1. **API keys are in:** `ios/Config.xcconfig`
   ```
   GOOGLE_MAPS_API_KEY = your_key_here
   GOOGLE_PLACES_API_KEY = your_key_here
   ```

2. **Injected into:** `ios/Runner/Info.plist`
   ```xml
   <key>GOOGLE_MAPS_API_KEY</key>
   <string>$(GOOGLE_MAPS_API_KEY)</string>
   ```

3. **Read in AppDelegate.swift:**
   ```swift
   if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String {
       GMSServices.provideAPIKey(apiKey)
   }
   ```

---

## 📝 For Team Members / New Setup:

1. **Copy** `android/local.properties.example` → `android/local.properties` (if exists)
2. **Copy** `ios/Config.xcconfig.example` → `ios/Config.xcconfig` (if exists)
3. **Add your API keys** to both files
4. **Never commit** these files (already in `.gitignore`)

---

## 🔒 Security Features:

✅ **Git-ignored** - Won't be committed to repo  
✅ **Build-time injection** - No hardcoded keys  
✅ **Platform-specific** - Works natively on Android & iOS  
✅ **Simple** - No complex build scripts needed

---

## 🛠 How It Works:

### Build Process:
```
1. Build starts
   ↓
2. Gradle/Xcode reads local config file
   ↓
3. Injects variables into manifest/plist
   ↓
4. Native code reads from manifest/plist
   ↓
5. App runs with API keys
```

### vs. Runtime (Flutter):
```
1. App starts
   ↓
2. flutter_dotenv reads assets/.env
   ↓
3. Dart code uses dotenv.env['KEY']
```

---

## 💡 Alternative Approaches (More Complex):

1. **CI/CD Secrets** - For production builds
2. **--dart-define** - Pass via command line
3. **Firebase Remote Config** - Fetch at runtime
4. **Obfuscation** - Hide keys in compiled code

**Recommendation:** Stick with the current setup unless you need enterprise-level security.

---

## ⚠️ Important Notes:

- **Development:** Current setup is perfect
- **Production:** Consider restricting API keys by package name/bundle ID in Google Cloud Console
- **Public Repos:** These files are already git-ignored
- **Teammates:** Share keys securely (password manager, secure chat)

---

## 🎯 Current Status:

✅ Android: Using `local.properties`  
✅ iOS: Using `Config.xcconfig`  
✅ Flutter runtime: Using `assets/.env`  
✅ All config files git-ignored
