"use strict";
/**
 * Setup script to initialize contact_info collection in Firestore
 *
 * This script creates the contact_info/info document with initial data.
 * Run this once during initial setup or when you need to reset contact information.
 *
 * To run this script:
 * 1. Make sure you're in the functions directory: cd functions
 * 2. Install dependencies if not already done: npm install
 * 3. Run: npx ts-node src/setup-contact-info.ts
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const admin = __importStar(require("firebase-admin"));
const path = __importStar(require("path"));
// Initialize Firebase Admin with service account
const serviceAccount = require(path.join(__dirname, '../../service-account.json'));
admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();
// Contact information data
const contactInfoData = {
    // PawsCare Organization Contact Information
    pawscare_email: 'pawscareanimalresq@gmail.com',
    pawscare_insta: 'https://www.instagram.com/pawscareanimalresq/',
    pawscare_linkedin: 'https://www.linkedin.com/company/pawscare/',
    pawscare_whatsapp: '+917057517218',
    pawscare_volunteerform: 'https://docs.google.com/forms/d/e/1FAIpQLSduQq2bKmfyvKAkZPOeWR0ZqboNr0hMW2xyUW4geYIidSvxJg/viewform',
    // Developer 1 Information
    developer1_name: 'Om Dhamame',
    developer1_role: 'Lead Developer',
    developer1_linkedin: 'https://www.linkedin.com/in/ohmschrodinger/',
    developer1_github: 'https://github.com/ohmschrodinger',
    // Developer 2 Information
    developer2_name: 'Mahi Sharma',
    developer2_role: 'Developer',
    developer2_linkedin: 'https://www.linkedin.com/in/mahisharma',
    developer2_github: 'https://github.com/mahisharma',
    // Developer 3 Information
    developer3_name: 'Kushagra Goyal',
    developer3_role: 'Developer',
    developer3_linkedin: 'https://www.linkedin.com/in/kushagra',
    developer3_github: 'https://github.com/kushagragoyal',
};
async function setupContactInfo() {
    try {
        console.log('🚀 Setting up contact_info collection...');
        // Check if document already exists
        const docRef = db.collection('contact_info').doc('info');
        const docSnapshot = await docRef.get();
        if (docSnapshot.exists) {
            console.log('⚠️  contact_info/info document already exists!');
            console.log('   Current data:', docSnapshot.data());
            console.log('');
            console.log('Do you want to overwrite it? (This will replace all existing data)');
            console.log('To proceed, re-run this script with the --force flag:');
            console.log('   npx ts-node src/setup-contact-info.ts --force');
            // Check if --force flag is present
            const forceFlag = process.argv.includes('--force');
            if (!forceFlag) {
                console.log('');
                console.log('❌ Setup cancelled. No changes made.');
                process.exit(0);
            }
            console.log('');
            console.log('🔄 Force flag detected. Overwriting existing document...');
        }
        // Create or update the document
        await docRef.set(contactInfoData);
        console.log('✅ Successfully created/updated contact_info/info document!');
        console.log('');
        console.log('📋 Document contains the following fields:');
        console.log('   - PawsCare contact info (email, Instagram, LinkedIn, WhatsApp, volunteer form)');
        console.log('   - Developer 1 info (name, role, LinkedIn, GitHub)');
        console.log('   - Developer 2 info (name, role, LinkedIn, GitHub)');
        console.log('   - Developer 3 info (name, role, LinkedIn, GitHub)');
        console.log('');
        console.log('🎉 Setup complete! The app will now fetch contact information from Firestore.');
        console.log('');
        console.log('📝 To verify, you can:');
        console.log('   1. Check Firebase Console → Firestore Database → contact_info → info');
        console.log('   2. Open the app and navigate to "Contact Us" or "About Developers" screens');
        console.log('');
        process.exit(0);
    }
    catch (error) {
        console.error('❌ Error setting up contact_info:', error);
        process.exit(1);
    }
}
// Run the setup
setupContactInfo();
//# sourceMappingURL=setup-contact-info.js.map