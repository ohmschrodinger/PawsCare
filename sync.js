const admin = require('firebase-admin');
const { google } = require('googleapis');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

class FirebaseToDriveSync {
  constructor() {
    this.drive = null;
    this.auth = null;
    this.db = null;
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
      console.log('✅ Firebase initialized successfully with Service Account');
    } catch (error) {
      console.error('❌ Firebase initialization failed:', error.message);
      throw error;
    }
  }

  /**
   * Initialize OAuth 2.0 for Google Drive only
   */
  async initializeAuth() {
    try {
      console.log('🔐 Initializing OAuth 2.0 for Google Drive...');

      // Create OAuth2 client for Google Drive
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
   * Initialize Google Drive API with OAuth 2.0
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
   * Fetch data from Firebase Firestore using Admin SDK
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
   * Convert data to JSON format
   */
  convertToJSON(data) {
    try {
      console.log('🔄 Converting data to JSON format...');
      const jsonData = JSON.stringify(data, null, 2);
      console.log('✅ Data converted to JSON successfully');
      return jsonData;
    } catch (error) {
      console.error('❌ JSON conversion failed:', error.message);
      throw error;
    }
  }

  /**
   * Convert data to CSV format
   */
  convertToCSV(data) {
    try {
      console.log('🔄 Converting data to CSV format...');
      
      if (data.length === 0) {
        return '';
      }

      // Get all unique keys from all objects
      const allKeys = [...new Set(data.flatMap(obj => Object.keys(obj)))];
      
      // Create CSV header
      const header = allKeys.join(',');
      
      // Create CSV rows
      const rows = data.map(obj => {
        return allKeys.map(key => {
          const value = obj[key];
          // Escape commas and quotes in CSV
          if (typeof value === 'string' && (value.includes(',') || value.includes('"'))) {
            return `"${value.replace(/"/g, '""')}"`;
          }
          return value || '';
        }).join(',');
      });

      const csvData = [header, ...rows].join('\n');
      console.log('✅ Data converted to CSV successfully');
      return csvData;
    } catch (error) {
      console.error('❌ CSV conversion failed:', error.message);
      throw error;
    }
  }

  /**
   * Upload file to Google Drive
   */
  async uploadToDrive(fileName, fileContent, mimeType) {
    try {
      console.log(`📤 Uploading ${fileName} to Google Drive...`);
      
      // Check if file already exists
      const existingFiles = await this.drive.files.list({
        q: `name='${fileName}' and parents in '${this.folderId}' and trashed=false`,
        fields: 'files(id, name)'
      });

      let fileId = null;
      if (existingFiles.data.files.length > 0) {
        fileId = existingFiles.data.files[0].id;
        console.log(`📝 File ${fileName} already exists, will update it`);
      }

      const fileMetadata = {
        name: fileName,
        parents: [this.folderId]
      };

      const media = {
        mimeType: mimeType,
        body: fileContent
      };

      let result;
      if (fileId) {
        // Update existing file
        result = await this.drive.files.update({
          fileId: fileId,
          media: media
        });
        console.log(`✅ Updated existing file: ${fileName}`);
      } else {
        // Create new file
        result = await this.drive.files.create({
          resource: fileMetadata,
          media: media
        });
        console.log(`✅ Created new file: ${fileName}`);
      }

      return result.data;
    } catch (error) {
      console.error(`❌ Failed to upload ${fileName}:`, error.message);
      throw error;
    }
  }

  /**
   * Main sync process
   */
  async sync() {
    try {
      console.log('🚀 Starting Firebase to Google Drive sync...');
      console.log('=' .repeat(50));

      // Initialize services
      await this.initializeFirebase();
      await this.initializeAuth();
      await this.initializeGoogleDrive();

      // Get configuration from environment
      const collectionName = process.env.FIREBASE_COLLECTION || 'animals';
      const outputFormat = process.env.OUTPUT_FORMAT || 'json';
      const fileName = process.env.OUTPUT_FILENAME || `firebase-export-${new Date().toISOString().split('T')[0]}`;

      // Fetch data from Firebase
      const data = await this.fetchFirebaseData(collectionName);

      if (data.length === 0) {
        console.log('⚠️  No data found in the collection');
        return;
      }

      // Convert data based on format
      let fileContent, mimeType, fileExtension;
      
      if (outputFormat.toLowerCase() === 'csv') {
        fileContent = this.convertToCSV(data);
        mimeType = 'text/csv';
        fileExtension = '.csv';
      } else {
        fileContent = this.convertToJSON(data);
        mimeType = 'application/json';
        fileExtension = '.json';
      }

      const fullFileName = `${fileName}${fileExtension}`;

      // Upload to Google Drive
      await this.uploadToDrive(fullFileName, fileContent, mimeType);

      console.log('=' .repeat(50));
      console.log('🎉 Sync completed successfully!');
      console.log(`📁 File uploaded: ${fullFileName}`);
      console.log(`📊 Records synced: ${data.length}`);
      console.log(`📂 Drive folder ID: ${this.folderId}`);

    } catch (error) {
      console.error('💥 Sync failed:', error.message);
      process.exit(1);
    }
  }
}

// Run the sync if this file is executed directly
if (require.main === module) {
  const sync = new FirebaseToDriveSync();
  sync.sync().catch(error => {
    console.error('💥 Fatal error:', error);
    process.exit(1);
  });
}

module.exports = FirebaseToDriveSync;
