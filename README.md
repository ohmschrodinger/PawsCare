# Firebase to Google Drive Sync

Automated script to sync data from Firebase Firestore to Google Drive using Node.js, Firebase Admin SDK, and Google Drive API with OAuth 2.0 authentication.

## Features

- 🔥 **Firebase Integration**: Fetches data from any Firestore collection
- 📁 **Google Drive Upload**: Automatically uploads to specified Google Drive folder
- 🔄 **Multiple Formats**: Supports JSON and CSV output formats
- 🔐 **OAuth 2.0**: Secure authentication with refresh tokens
- 📊 **Error Handling**: Comprehensive error handling and logging
- ⚡ **Overwrite Protection**: Updates existing files or creates new ones

## Prerequisites

- Node.js (v14 or higher)
- Firebase project with Firestore enabled
- Google Cloud Console project with Drive API enabled
- OAuth 2.0 credentials (client_id, client_secret, refresh_token)

## Installation

1. **Clone or download the files** to your local machine

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Set up environment variables**:
   ```bash
   cp env.example .env
   ```

## Configuration

### 1. Firebase Setup (OAuth 2.0)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings** > **General**
4. Copy your **Project ID**
5. Set `FIREBASE_PROJECT_ID` in your `.env` file
6. Ensure your OAuth credentials have Firebase/Firestore access

### 2. Google OAuth 2.0 Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the **Google Drive API**:
   - Go to **APIs & Services** > **Library**
   - Search for "Google Drive API" and enable it
4. Create OAuth 2.0 credentials:
   - Go to **APIs & Services** > **Credentials**
   - Click **Create Credentials** > **OAuth client ID**
   - Choose **Desktop application**
   - Download the JSON file
5. Get your refresh token:
   - Use the OAuth 2.0 Playground: https://developers.google.com/oauthplayground/
   - Select "Google Drive API v3" and authorize
   - Exchange authorization code for tokens
   - Copy the refresh token

### 3. Google Drive Setup

1. Create a folder in Google Drive where you want the files to be uploaded
2. Get the folder ID from the URL: `https://drive.google.com/drive/folders/FOLDER_ID_HERE`
3. Set `GOOGLE_DRIVE_FOLDER_ID` in your `.env` file

### 4. Environment Variables

Edit your `.env` file with the following values:

```env
# Firebase Configuration (OAuth 2.0)
FIREBASE_PROJECT_ID=your-firebase-project-id

# Firebase Collection to sync
FIREBASE_COLLECTION=animals

# Google OAuth 2.0
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_REFRESH_TOKEN=your-refresh-token

# Google Drive
GOOGLE_DRIVE_FOLDER_ID=your-google-drive-folder-id

# Output Configuration
OUTPUT_FORMAT=json
OUTPUT_FILENAME=firebase-export
```

## Usage

### Run the sync script:

```bash
npm start
```

Or directly:

```bash
node sync.js
```

### Configuration Options

- **FIREBASE_COLLECTION**: The Firestore collection to sync (default: 'animals')
- **OUTPUT_FORMAT**: Output format - 'json' or 'csv' (default: 'json')
- **OUTPUT_FILENAME**: Base filename for the exported file (default: 'firebase-export')

## Output

The script will:

1. ✅ Connect to Firebase and fetch data from the specified collection
2. 🔄 Convert the data to the specified format (JSON/CSV)
3. 📤 Upload the file to your Google Drive folder
4. 📝 Update existing files or create new ones
5. 📊 Display success/failure status with detailed logs

## Error Handling

The script includes comprehensive error handling for:

- Firebase connection issues
- Google Drive API errors
- Authentication failures
- Network connectivity problems
- Data conversion errors

All errors are logged with descriptive messages to help with troubleshooting.

## Automation

To run this script automatically, you can:

1. **Cron Job** (Linux/Mac):
   ```bash
   # Run daily at 2 AM
   0 2 * * * cd /path/to/your/script && node sync.js
   ```

2. **Windows Task Scheduler**:
   - Create a new task
   - Set trigger to your desired schedule
   - Action: Start a program
   - Program: `node`
   - Arguments: `sync.js`
   - Start in: Your script directory

3. **GitHub Actions** (for cloud automation):
   ```yaml
   name: Firebase to Drive Sync
   on:
     schedule:
       - cron: '0 2 * * *'  # Daily at 2 AM UTC
   jobs:
     sync:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v2
         - uses: actions/setup-node@v2
           with:
             node-version: '18'
         - run: npm install
         - run: node sync.js
           env:
             FIREBASE_SERVICE_ACCOUNT_KEY: ${{ secrets.FIREBASE_SERVICE_ACCOUNT_KEY }}
             GOOGLE_CLIENT_ID: ${{ secrets.GOOGLE_CLIENT_ID }}
             GOOGLE_CLIENT_SECRET: ${{ secrets.GOOGLE_CLIENT_SECRET }}
             GOOGLE_REFRESH_TOKEN: ${{ secrets.GOOGLE_REFRESH_TOKEN }}
             GOOGLE_DRIVE_FOLDER_ID: ${{ secrets.GOOGLE_DRIVE_FOLDER_ID }}
   ```

## Troubleshooting

### Common Issues

1. **Firebase Authentication Error**:
   - Verify your project ID is correct
   - Ensure your OAuth credentials have Firebase/Firestore access
   - Check if the OAuth app has the necessary scopes

2. **Google Drive API Error**:
   - Verify OAuth credentials are correct
   - Ensure the refresh token is valid
   - Check if the Drive API is enabled
   - Verify the folder ID is correct

3. **Permission Errors**:
   - Ensure your OAuth app has Firebase/Firestore permissions
   - Verify the OAuth app has Drive access
   - Check if the target folder is accessible

### Debug Mode

For detailed debugging, you can add console logs or use a debugger:

```bash
DEBUG=* node sync.js
```

## Security Notes

- Never commit your `.env` file to version control
- Keep your service account keys secure
- Regularly rotate your OAuth tokens
- Use environment variables in production
- Consider using Google Cloud Secret Manager for production deployments

## License

MIT License - feel free to modify and use as needed.