"use strict";
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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.logUserToSheet = exports.onAdoptionApplicationApproved = exports.onAnimalPostApproved = exports.onUserCreated = exports.sendEmail = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const nodemailer = __importStar(require("nodemailer"));
const cors_1 = __importDefault(require("cors"));
// Initialize Firebase Admin
admin.initializeApp();
const corsHandler = (0, cors_1.default)({ origin: true });
// Email templates
const emailTemplates = {
    login_notification: {
        subject: 'New Login to PawsCare',
        template: (data) => `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #2196F3;">🔐 New Login Detected</h2>
        <p>Hello ${data.userName},</p>
        <p>We detected a new login to your PawsCare account.</p>
        <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <p><strong>Login Details:</strong></p>
          <p>Time: ${new Date(data.loginTime).toLocaleString()}</p>
          <p>Device: ${data.deviceInfo}</p>
          <p>Location: ${data.location}</p>
        </div>
        <p>If this wasn't you, please contact us immediately.</p>
        <p>Best regards,<br>The PawsCare Team</p>
      </div>
    `
    },
    animal_posted: {
        subject: 'Animal Posted Successfully - PawsCare',
        template: (data) => `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #4CAF50;">🐾 Animal Posted Successfully!</h2>
        <p>Hello ${data.userName},</p>
        <p>Your animal has been posted successfully and is now under review by our admin team.</p>
        <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <p><strong>Animal Details:</strong></p>
          <p>Name: ${data.animalName}</p>
          <p>Species: ${data.animalSpecies}</p>
          <p>Posted: ${new Date(data.postedAt).toLocaleString()}</p>
        </div>
        <p>We'll notify you once your post has been reviewed and approved.</p>
        <p>Thank you for helping animals find their forever homes!</p>
        <p>Best regards,<br>The PawsCare Team</p>
      </div>
    `
    },
    animal_approved: {
        subject: '🎉 Your Animal Post Has Been Approved! - PawsCare',
        template: (data) => `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #4CAF50;">🎉 Animal Post Approved!</h2>
        <p>Hello ${data.userName},</p>
        <p>Great news! Your animal post has been approved and is now live on PawsCare.</p>
        <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <p><strong>Animal Details:</strong></p>
          <p>Name: ${data.animalName}</p>
          <p>Species: ${data.animalSpecies}</p>
          <p>Approved: ${new Date().toLocaleString()}</p>
          ${data.adminMessage ? `<p><strong>Admin Message:</strong> ${data.adminMessage}</p>` : ''}
        </div>
        <p>Your animal is now visible to potential adopters. You'll be notified when someone applies to adopt.</p>
        <p>Best regards,<br>The PawsCare Team</p>
      </div>
    `
    },
    animal_rejected: {
        subject: 'Animal Post Update - PawsCare',
        template: (data) => `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #f44336;">Animal Post Update</h2>
        <p>Hello ${data.userName},</p>
        <p>We've reviewed your animal post and unfortunately, it couldn't be approved at this time.</p>
        <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <p><strong>Animal Details:</strong></p>
          <p>Name: ${data.animalName}</p>
          <p>Species: ${data.animalSpecies}</p>
          <p><strong>Reason:</strong> ${data.adminMessage}</p>
        </div>
        <p>Please review the feedback and feel free to submit a new post with the necessary changes.</p>
        <p>Best regards,<br>The PawsCare Team</p>
      </div>
    `
    },
    adoption_applied: {
        subject: 'Adoption Application Submitted - PawsCare',
        template: (data) => `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #2196F3;">📝 Adoption Application Submitted</h2>
        <p>Hello ${data.userName},</p>
        <p>Your adoption application has been submitted successfully!</p>
        <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <p><strong>Application Details:</strong></p>
          <p>Animal: ${data.animalName}</p>
          <p>Species: ${data.animalSpecies}</p>
          <p>Application ID: ${data.applicationId}</p>
          <p>Submitted: ${new Date(data.appliedAt).toLocaleString()}</p>
        </div>
        <p>We'll review your application and get back to you soon.</p>
        <p>Best regards,<br>The PawsCare Team</p>
      </div>
    `
    },
    adoption_approved: {
        subject: '🎉 Adoption Application Approved! - PawsCare',
        template: (data) => `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #4CAF50;">🎉 Adoption Approved!</h2>
        <p>Hello ${data.userName},</p>
        <p>Congratulations! Your adoption application has been approved!</p>
        <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <p><strong>Adoption Details:</strong></p>
          <p>Animal: ${data.animalName}</p>
          <p>Species: ${data.animalSpecies}</p>
          <p>Application ID: ${data.applicationId}</p>
          ${data.adminMessage ? `<p><strong>Admin Message:</strong> ${data.adminMessage}</p>` : ''}
        </div>
        <p>Please contact us to arrange the adoption process.</p>
        <p>Best regards,<br>The PawsCare Team</p>
      </div>
    `
    },
    adoption_rejected: {
        subject: 'Adoption Application Update - PawsCare',
        template: (data) => `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #f44336;">Adoption Application Update</h2>
        <p>Hello ${data.userName},</p>
        <p>We've reviewed your adoption application and unfortunately, it couldn't be approved at this time.</p>
        <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <p><strong>Application Details:</strong></p>
          <p>Animal: ${data.animalName}</p>
          <p>Species: ${data.animalSpecies}</p>
          <p><strong>Reason:</strong> ${data.adminMessage}</p>
        </div>
        <p>Please feel free to apply for other animals or contact us with questions.</p>
        <p>Best regards,<br>The PawsCare Team</p>
      </div>
    `
    },
    welcome: {
        subject: 'Welcome to PawsCare! 🐾',
        template: (data) => `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #2196F3;">🐾 Welcome to PawsCare!</h2>
        <p>Hello ${data.userName},</p>
        <p>Welcome to PawsCare! We're excited to have you join our community of pet lovers.</p>
        <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <p><strong>What you can do:</strong></p>
          <p>• Post animals for adoption</p>
          <p>• Apply to adopt pets</p>
          <p>• Connect with other pet lovers</p>
          <p>• Build your pet community</p>
        </div>
        <p>Get started by exploring our platform and finding your perfect companion!</p>
        <p>Best regards,<br>The PawsCare Team</p>
      </div>
    `
    },
    password_reset: {
        subject: 'Password Reset Confirmation - PawsCare',
        template: (data) => `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #FF9800;">🔐 Password Reset Requested</h2>
        <p>Hello ${data.userName},</p>
        <p>We received a request to reset your PawsCare account password.</p>
        <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <p><strong>Reset Details:</strong></p>
          <p>Time: ${new Date(data.resetDate).toLocaleString()}</p>
          <p>Account: ${data.userEmail}</p>
        </div>
        <p>If you didn't request this reset, please ignore this email.</p>
        <p>Best regards,<br>The PawsCare Team</p>
      </div>
    `
    }
};
// HTTP Cloud Function to send emails
exports.sendEmail = functions.https.onRequest((request, response) => {
    return corsHandler(request, response, async () => {
        try {
            const { emailType, recipientEmail, data } = request.body;
            if (!emailType || !recipientEmail) {
                response.status(400).json({ error: 'Missing required fields' });
                return;
            }
            const template = emailTemplates[emailType];
            if (!template) {
                response.status(400).json({ error: 'Invalid email type' });
                return;
            }
            // Get Gmail credentials from environment
            const gmailEmail = functions.config().gmail?.email;
            const gmailPassword = functions.config().gmail?.password;
            if (!gmailEmail || !gmailPassword) {
                console.error('Gmail credentials not configured');
                response.status(500).json({ error: 'Email service not configured' });
                return;
            }
            // Create transporter
            const transporter = nodemailer.createTransport({
                service: 'gmail',
                auth: {
                    user: gmailEmail,
                    pass: gmailPassword
                }
            });
            // Send email
            const mailOptions = {
                from: gmailEmail,
                to: recipientEmail,
                subject: template.subject,
                html: template.template(data)
            };
            await transporter.sendMail(mailOptions);
            // Log to Firestore
            await admin.firestore().collection('email_logs').add({
                type: emailType,
                recipientEmail,
                data,
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
                status: 'sent'
            });
            response.json({ success: true, message: 'Email sent successfully' });
        }
        catch (error) {
            console.error('Error sending email:', error);
            response.status(500).json({ error: 'Failed to send email' });
        }
    });
});
// Auth trigger for new user welcome email
exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
    try {
        const gmailEmail = functions.config().gmail?.email;
        const gmailPassword = functions.config().gmail?.password;
        if (!gmailEmail || !gmailPassword) {
            console.log('Gmail not configured, skipping welcome email');
            return;
        }
        const transporter = nodemailer.createTransport({
            service: 'gmail',
            auth: {
                user: gmailEmail,
                pass: gmailPassword
            }
        });
        const mailOptions = {
            from: gmailEmail,
            to: user.email,
            subject: 'Welcome to PawsCare! 🐾',
            html: emailTemplates.welcome.template({
                userName: user.displayName || 'User',
                userEmail: user.email
            })
        };
        await transporter.sendMail(mailOptions);
        console.log('Welcome email sent to:', user.email);
    }
    catch (error) {
        console.error('Error sending welcome email:', error);
    }
});
// Firestore trigger for when animal post is approved
exports.onAnimalPostApproved = functions.firestore
    .document('animals/{animalId}')
    .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    // Check if approvalStatus changed from pending to approved
    if (beforeData.approvalStatus === 'pending' && afterData.approvalStatus === 'approved') {
        try {
            const gmailEmail = functions.config().gmail?.email;
            const gmailPassword = functions.config().gmail?.password;
            if (!gmailEmail || !gmailPassword) {
                console.log('Gmail not configured, skipping approval email');
                return;
            }
            // Get user data to send email
            const userDoc = await admin.firestore()
                .collection('users')
                .doc(afterData.postedBy)
                .get();
            if (!userDoc.exists) {
                console.log('User document not found for approval email');
                return;
            }
            const userData = userDoc.data();
            const userEmail = userData?.email || afterData.userEmail;
            if (!userEmail) {
                console.log('User email not found for approval email');
                return;
            }
            const transporter = nodemailer.createTransport({
                service: 'gmail',
                auth: {
                    user: gmailEmail,
                    pass: gmailPassword
                }
            });
            const mailOptions = {
                from: gmailEmail,
                to: userEmail,
                subject: '🎉 Your Animal Post Has Been Approved! - PawsCare',
                html: emailTemplates.animal_approved.template({
                    userName: userData?.fullName || 'User',
                    animalName: afterData.name || 'Animal',
                    animalSpecies: afterData.species || 'Pet',
                    adminMessage: afterData.adminMessage || null
                })
            };
            await transporter.sendMail(mailOptions);
            console.log('Animal approval email sent to:', userEmail);
            // Log to Firestore
            await admin.firestore().collection('email_logs').add({
                type: 'animal_approved',
                recipientEmail: userEmail,
                data: {
                    animalId: context.params.animalId,
                    animalName: afterData.name,
                    animalSpecies: afterData.species,
                    adminMessage: afterData.adminMessage
                },
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
                status: 'sent'
            });
        }
        catch (error) {
            console.error('Error sending animal approval email:', error);
        }
    }
});
// Firestore trigger for when adoption application is approved
exports.onAdoptionApplicationApproved = functions.firestore
    .document('applications/{applicationId}')
    .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();
    // Check if status changed from pending to approved
    if (beforeData.status === 'pending' && afterData.status === 'approved') {
        try {
            const gmailEmail = functions.config().gmail?.email;
            const gmailPassword = functions.config().gmail?.password;
            if (!gmailEmail || !gmailPassword) {
                console.log('Gmail not configured, skipping adoption approval email');
                return;
            }
            // Get user data to send email
            const userDoc = await admin.firestore()
                .collection('users')
                .doc(afterData.userId)
                .get();
            if (!userDoc.exists) {
                console.log('User document not found for adoption approval email');
                return;
            }
            const userData = userDoc.data();
            const userEmail = userData?.email || afterData.userEmail;
            if (!userEmail) {
                console.log('User email not found for adoption approval email');
                return;
            }
            // Get animal data for the email
            const animalDoc = await admin.firestore()
                .collection('animals')
                .doc(afterData.animalId)
                .get();
            const animalData = animalDoc.exists ? animalDoc.data() : {};
            const transporter = nodemailer.createTransport({
                service: 'gmail',
                auth: {
                    user: gmailEmail,
                    pass: gmailPassword
                }
            });
            const mailOptions = {
                from: gmailEmail,
                to: userEmail,
                subject: '🎉 Adoption Application Approved! - PawsCare',
                html: emailTemplates.adoption_approved.template({
                    userName: userData?.fullName || 'User',
                    animalName: animalData?.name || 'Animal',
                    animalSpecies: animalData?.species || 'Pet',
                    applicationId: context.params.applicationId,
                    adminMessage: afterData.adminMessage || null
                })
            };
            await transporter.sendMail(mailOptions);
            console.log('Adoption approval email sent to:', userEmail);
            // Log to Firestore
            await admin.firestore().collection('email_logs').add({
                type: 'adoption_approved',
                recipientEmail: userEmail,
                data: {
                    applicationId: context.params.applicationId,
                    animalId: afterData.animalId,
                    animalName: animalData?.name,
                    animalSpecies: animalData?.species,
                    adminMessage: afterData.adminMessage
                },
                sentAt: admin.firestore.FieldValue.serverTimestamp(),
                status: 'sent'
            });
        }
        catch (error) {
            console.error('Error sending adoption approval email:', error);
        }
    }
});

// DELETE THE FOLLOWING LINE LATER 
const googleapis_1 = require("googleapis");
exports.logUserToSheet = functions
    .region("us-central1")
    .firestore.document("users/{uid}")
    .onWrite(async (change, context) => {
    try {
        const cfg = functions.config();
        const SPREADSHEET_ID = cfg.sheets?.spreadsheet_id;
        const KEY_B64 = cfg.sheets?.key_b64;
        if (!SPREADSHEET_ID || !KEY_B64) {
            console.error("Missing functions config: sheets.spreadsheet_id or sheets.key_b64");
            return null;
        }
        const uid = context.params.uid;
        const before = change.before.exists ? change.before.data() : null;
        const after = change.after.exists ? change.after.data() : null;
        // Ignore deletes
        if (before && !after)
            return null;
        const eventType = (!before && after) ? "create" : "update";
        // Prepare list of fields to track
        const fieldsToTrack = [
            "email",
            "fullName",
            "role",
            "phoneNumber",
            "address",
            "isActive",
            "profileCompleted",
            "pushNotificationsEnabled",
            "createdAt",
            "updatedAt"
        ];
        const row = [eventType, uid];
        const changedFields = [];
        for (const field of fieldsToTrack) {
            const beforeValue = before?.[field];
            const afterValue = after?.[field];
            // Convert timestamps to ISO strings if needed
            const formatValue = (val) => (val?.toDate ? val.toDate().toISOString() : val);
            row.push(formatValue(afterValue));
            if (eventType === "update" && beforeValue !== afterValue) {
                changedFields.push(field);
            }
        }
        const loggedAt = new Date().toISOString();
        row.push(loggedAt);
        // Add last column with changed fields (comma separated)
        row.push(eventType === "update" ? changedFields.join(", ") || "none" : "all");
        // Authenticate with Google Sheets
        const keyJson = JSON.parse(Buffer.from(KEY_B64, "base64").toString("utf8"));
        const jwt = new googleapis_1.google.auth.JWT(keyJson.client_email, undefined, keyJson.private_key, ["https://www.googleapis.com/auth/spreadsheets"]);
        await jwt.authorize();
        const sheets = googleapis_1.google.sheets({ version: "v4", auth: jwt });
        await sheets.spreadsheets.values.append({
            spreadsheetId: SPREADSHEET_ID,
            range: "Sheet1!A1", // <-- target Sheet1
            valueInputOption: "USER_ENTERED",
            insertDataOption: "INSERT_ROWS",
            requestBody: { values: [row] },
        });
        console.log(`logUserToSheet: row appended for user ${uid}`);
        return null;
    }
    catch (err) {
        console.error("logUserToSheet error:", err);
        throw err;
    }
});
//# sourceMappingURL=index.js.map