const admin = require('firebase-admin');
const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');
const { URL } = require('url');
const stream = require('stream');
require('dotenv').config();

class FirebaseToDriveSync {
  constructor() {
    this.drive = null;
    this.auth = null;
    this.db = null;
    this.storage = null;
    this.folderId = process.env.GOOGLE_DRIVE_FOLDER_ID;
    this.projectId = process.env.FIREBASE_PROJECT_ID;
  }

  /**
   * Initialize Firebase with Service Account
   */
  async initializeFirebase() {
    try {
      console.log('🔥 Initializing Firebase with Service Account...');
      const serviceAccount = require('./serviceAccountKey.json');
      
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
      });

      this.db = admin.firestore();
      this.storage = admin.storage();
      console.log('✅ Firebase initialized successfully with Service Account');
    } catch (error) {
      console.error('❌ Firebase initialization failed:', error.message);
      throw error;
    }
  }

  /**
   * Initialize OAuth 2.0 for Google Drive
   */
  async initializeAuth() {
    try {
      console.log('🔐 Initializing OAuth 2.0 for Google Drive...');
      this.auth = new google.auth.OAuth2(
        process.env.GOOGLE_CLIENT_ID,
        process.env.GOOGLE_CLIENT_SECRET
      );
      this.auth.setCredentials({
        refresh_token: process.env.GOOGLE_REFRESH_TOKEN
      });
      console.log('✅ OAuth 2.0 initialized successfully');
    } catch (error) {
      console.error('❌ OAuth initialization failed:', error.message);
      throw error;
    }
  }

  /**
   * Initialize Google Drive API
   */
  async initializeGoogleDrive() {
    try {
      console.log('📁 Initializing Google Drive API...');
      this.drive = google.drive({ version: 'v3', auth: this.auth });
      console.log('✅ Google Drive API initialized successfully');
    } catch (error) {
      console.error('❌ Google Drive initialization failed:', error.message);
      throw error;
    }
  }

  /**
   * Fetch animal data from Firestore
   */
  async fetchFirebaseData(collectionName) {
    try {
      console.log(`📊 Fetching data from Firebase collection: ${collectionName}`);
      const snapshot = await this.db.collection(collectionName).get();
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      console.log(`✅ Fetched ${data.length} documents from ${collectionName}`);
      return data;
    } catch (error) {
      console.error(`❌ Failed to fetch data from ${collectionName}:`, error.message);
      throw error;
    }
  }

  /**
   * Download image from URL and return as buffer
   */
  async downloadImage(url) {
    return new Promise((resolve, reject) => {
      const parsedUrl = new URL(url);
      const protocol = parsedUrl.protocol === 'https:' ? https : http;
      
      protocol.get(url, (response) => {
        if (response.statusCode !== 200) {
          reject(new Error(`Failed to download image: ${response.statusCode}`));
          return;
        }
        
        const chunks = [];
        response.on('data', (chunk) => chunks.push(chunk));
        response.on('end', () => resolve(Buffer.concat(chunks)));
        response.on('error', reject);
      }).on('error', reject);
    });
  }

  /**
   * Get file extension from URL or content type
   */
  getFileExtension(url, contentType) {
    const urlPath = new URL(url).pathname;
    const urlExt = path.extname(urlPath);
    if (urlExt) return urlExt;
    if (contentType) {
      const ext = contentType.split('/')[1];
      if (ext) return `.${ext}`;
    }
    return '.jpg';
  }

  /**
   * Create or get folder in Google Drive
   */
  async createOrGetFolder(folderName, parentFolderId) {
    try {
      // Check if folder already exists
      const existingFolders = await this.drive.files.list({
        q: `name='${folderName}' and parents in '${parentFolderId}' and mimeType='application/vnd.google-apps.folder' and trashed=false`,
        fields: 'files(id, name)'
      });

      if (existingFolders.data.files.length > 0) {
        return existingFolders.data.files[0].id;
      }

      // Create new folder
      const folderMetadata = {
        name: folderName,
        mimeType: 'application/vnd.google-apps.folder',
        parents: [parentFolderId]
      };

      const folder = await this.drive.files.create({
        resource: folderMetadata,
        fields: 'id, name'
      });

      return folder.data.id;
    } catch (error) {
      console.error(`❌ Failed to create folder ${folderName}:`, error.message);
      throw error;
    }
  }

  /**
   * Upload image buffer to Google Drive
   */
  async uploadImageToDrive(fileName, imageBuffer, mimeType, folderId, skipIfExists = true) {
    try {
      console.log(`📤 Uploading image ${fileName} to Google Drive...`);

      const existingFiles = await this.drive.files.list({
        q: `name='${fileName}' and parents in '${folderId}' and trashed=false`,
        fields: 'files(id, name)'
      });

      let fileId = null;
      if (existingFiles.data.files.length > 0) {
        fileId = existingFiles.data.files[0].id;
        
        // If skipIfExists is true, just return the existing file
        if (skipIfExists) {
          console.log(`⏭️  Skipping ${fileName} - already exists`);
          return existingFiles.data.files[0];
        }
        
        console.log(`📝 Image ${fileName} already exists, will update it`);
      }

      const fileMetadata = {
        name: fileName,
        parents: [folderId]
      };

      // Create a readable stream from the buffer
      const bufferStream = new stream.PassThrough();
      bufferStream.end(imageBuffer);

      const media = {
        mimeType: mimeType,
        body: bufferStream
      };

      let result;
      if (fileId) {
        result = await this.drive.files.update({
          fileId: fileId,
          media: media,
          fields: 'id, name'
        });
        console.log(`✅ Updated existing image: ${fileName}`);
      } else {
        result = await this.drive.files.create({
          resource: fileMetadata,
          media: media,
          fields: 'id, name'
        });
        console.log(`✅ Created new image: ${fileName}`);
      }

      return result.data;
    } catch (error) {
      console.error(`❌ Failed to upload image ${fileName}:`, error.message);
      throw error;
    }
  }

  /**
   * Main sync process - uploads only image files
   */
  async sync() {
    try {
      console.log('🚀 Starting Firebase to Google Drive image sync...');
      console.log('='.repeat(50));

      // Initialize services
      await this.initializeFirebase();
      await this.initializeAuth();
      await this.initializeGoogleDrive();

      const collectionName = process.env.FIREBASE_COLLECTION || 'animals';
      const data = await this.fetchFirebaseData(collectionName);

      if (data.length === 0) {
        console.log('⚠️  No animals found in the collection');
        return;
      }

      let totalImages = 0;
      let successfulUploads = 0;
      let skippedUploads = 0;
      let failedUploads = 0;

      console.log(`📊 Found ${data.length} animals to process`);

      for (const animal of data) {
        const animalId = animal.id;
        const animalName = animal.name || 'Unknown';
        const imageUrls = animal.imageUrls || [];

        if (imageUrls.length === 0) {
          console.log(`⚠️  No images found for animal: ${animalName} (${animalId})`);
          continue;
        }

        console.log(`🐾 Processing animal: ${animalName} (${imageUrls.length} images)`);

        // Create or get the animal's folder
        const safeAnimalName = animalName.replace(/[^a-zA-Z0-9\s_-]/g, '_');
        const animalFolderName = `${animalId}_${safeAnimalName}`;
        
        let animalFolderId;
        try {
          animalFolderId = await this.createOrGetFolder(animalFolderName, this.folderId);
          console.log(`📁 Folder: ${animalFolderName}`);
        } catch (error) {
          console.error(`❌ Failed to create folder for ${animalName}:`, error.message);
          failedUploads += imageUrls.length;
          continue;
        }

        for (let i = 0; i < imageUrls.length; i++) {
          const imageUrl = imageUrls[i];

          // ✅ Skip non-image files (check for image extensions, handling query params)
          const urlWithoutParams = imageUrl.split('?')[0];
          if (!urlWithoutParams.match(/\.(jpg|jpeg|png|gif|webp)$/i)) {
            console.log(`⚠️  Skipping non-image file for ${animalName}: ${imageUrl}`);
            continue;
          }

          totalImages++;

          try {
            console.log(`📥 Checking image ${i + 1}/${imageUrls.length} for ${animalName}...`);
            
            const fileExtension = this.getFileExtension(imageUrl);
            const fileName = `image_${i + 1}${fileExtension}`;

            // Check if file already exists first
            const existingFiles = await this.drive.files.list({
              q: `name='${fileName}' and parents in '${animalFolderId}' and trashed=false`,
              fields: 'files(id, name)'
            });

            if (existingFiles.data.files.length > 0) {
              skippedUploads++;
              console.log(`⏭️  Skipping ${fileName} - already exists`);
              continue;
            }

            // Download and upload if it doesn't exist
            console.log(`📥 Downloading image...`);
            const imageBuffer = await this.downloadImage(imageUrl);

            const mimeType = `image/${fileExtension.substring(1)}`;
            await this.uploadImageToDrive(fileName, imageBuffer, mimeType, animalFolderId);
            
            successfulUploads++;
            console.log(`✅ Successfully synced: ${fileName}`);

          } catch (error) {
            failedUploads++;
            console.error(`❌ Failed to sync image ${i + 1} for ${animalName}:`, error.message);
          }
        }
      }

      console.log('='.repeat(50));
      console.log('🎉 Image sync completed!');
      console.log(`📊 Animals processed: ${data.length}`);
      console.log(`🖼️  Total images processed: ${totalImages}`);
      console.log(`✅ Successful uploads: ${successfulUploads}`);
      console.log(`⏭️  Skipped (already exists): ${skippedUploads}`);
      console.log(`❌ Failed uploads: ${failedUploads}`);
      console.log(`📂 Drive folder ID: ${this.folderId}`);

    } catch (error) {
      console.error('💥 Sync failed:', error.message);
      process.exit(1);
    }
  }
}

// Run the sync if executed directly
if (require.main === module) {
  const sync = new FirebaseToDriveSync();
  sync.sync().catch(error => {
    console.error('💥 Fatal error:', error);
    process.exit(1);
  });
}

module.exports = FirebaseToDriveSync;
