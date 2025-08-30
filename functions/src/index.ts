import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as nodemailer from 'nodemailer';
import cors from 'cors';

// Initialize Firebase Admin
admin.initializeApp();

const corsHandler = cors({ origin: true });

// Email templates
const emailTemplates = {
  login_notification: {
    subject: 'New Login to PawsCare',
    template: (data: any) => `
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
    template: (data: any) => `
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
    template: (data: any) => `
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
    template: (data: any) => `
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
    template: (data: any) => `
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
    template: (data: any) => `
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
    template: (data: any) => `
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
    template: (data: any) => `
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
    template: (data: any) => `
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
export const sendEmail = functions.https.onRequest((request, response) => {
  return corsHandler(request, response, async () => {
    try {
      const { emailType, recipientEmail, data } = request.body;

      if (!emailType || !recipientEmail) {
        response.status(400).json({ error: 'Missing required fields' });
        return;
      }

      const template = emailTemplates[emailType as keyof typeof emailTemplates];
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
    } catch (error) {
      console.error('Error sending email:', error);
      response.status(500).json({ error: 'Failed to send email' });
    }
  });
});

// Auth trigger for new user welcome email
export const onUserCreated = functions.auth.user().onCreate(async (user) => {
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
  } catch (error) {
    console.error('Error sending welcome email:', error);
  }
});

