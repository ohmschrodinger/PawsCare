
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as nodemailer from 'nodemailer';
import cors from 'cors';
import { google } from 'googleapis';

// Export Pet of the Day functions
export { updatePetOfTheDay, refreshPetOfTheDay } from './pet_of_day';

// Initialize Firebase Admin
admin.initializeApp();

const corsHandler = cors({ origin: true });

// Helper function to send push notifications
async function sendPushNotification({
  userId,
  title,
  body,
  data = {}
}: {
  userId: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}) {
  try {
    // Get user's FCM token
    const userDoc = await admin.firestore().collection('users').doc(userId).get();

    if (!userDoc.exists) {
      console.log('User document not found for push notification');
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      console.log('No FCM token found for user:', userId);
      return;
    }

    // Send push notification
    const message = {
      token: fcmToken,
      notification: {
        title: title,
        body: body,
      },
      data: data,
      android: {
        notification: {
          icon: 'ic_launcher',
          color: '#5AC8F2',
          sound: 'default',
        },
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1,
          },
        },
      },
    };

    const response = await admin.messaging().send(message);
    console.log('Push notification sent successfully:', response);

    // Log notification to Firestore
    await admin.firestore().collection('notification_logs').add({
      userId: userId,
      title: title,
      body: body,
      data: data,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'sent',
      messageId: response
    });

  } catch (error) {
    console.error('Error sending push notification:', error);

    // Log failed notification
    await admin.firestore().collection('notification_logs').add({
      userId: userId,
      title: title,
      body: body,
      data: data,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'failed',
      error: String(error)
    });
  }
}

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
  },

  new_post_request_admin: {
    subject: '🐾 New Animal Post Request - PawsCare Admin',
    template: (data: any) => `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h2 style="color: #FF9800;">🐾 New Animal Post Pending Approval</h2>
        <p>Hello Admin,</p>
        <p>A new animal post has been submitted and is pending your approval.</p>
        <div style="background-color: #f5f5f5; padding: 15px; border-radius: 5px; margin: 20px 0;">
          <p><strong>Post Details:</strong></p>
          <p>Animal Name: ${data.animalName}</p>
          <p>Species: ${data.animalSpecies}</p>
          <p>Breed: ${data.breed || 'Not specified'}</p>
          <p>Age: ${data.age || 'Not specified'}</p>
          <p>Posted by: ${data.postedByEmail}</p>
          <p>Posted at: ${new Date(data.postedAt).toLocaleString()}</p>
        </div>
        <p>Please log in to the admin panel to review and approve or reject this post.</p>
        <p>Best regards,<br>The PawsCare System</p>
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

// Firestore trigger for sending welcome email after email verification
export const onUserEmailVerified = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // Check if email verification status changed from false to true
    if (!beforeData.isEmailVerified && afterData.isEmailVerified) {
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
          to: afterData.email,
          subject: 'Welcome to PawsCare! 🐾',
          html: emailTemplates.welcome.template({
            userName: afterData.displayName || `${afterData.firstName} ${afterData.lastName}` || 'User',
            userEmail: afterData.email
          })
        };

        await transporter.sendMail(mailOptions);
        console.log('Welcome email sent to:', afterData.email);
      } catch (error) {
        console.error('Error sending welcome email:', error);
      }
    }
  });

// Firestore trigger for when animal post is approved
export const onAnimalPostApproved = functions.firestore
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

      } catch (error) {
        console.error('Error sending animal approval email:', error);
      }
    }
  });

// Firestore trigger for when new animal is added and approved
export const onNewAnimalApproved = functions.firestore
  .document('animals/{animalId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // Check if approvalStatus changed from pending to approved
    if (beforeData.approvalStatus === 'pending' && afterData.approvalStatus === 'approved') {
      try {
        // Get all users who have opted in for new animal notifications
        const usersSnapshot = await admin.firestore()
          .collection('users')
          .where('newAnimalNotifications', '==', true)
          .get();

        if (usersSnapshot.empty) {
          console.log('No users found with notifications enabled');
          return;
        }

        // Send notification to all users
        const notificationPromises = usersSnapshot.docs.map(async (userDoc) => {
          const userId = userDoc.id;

          await sendPushNotification({
            userId: userId,
            title: '🐾 New Animal Available!',
            body: `Meet ${afterData.name || 'a new friend'} - ${afterData.species || 'pet'} available for adoption!`,
            data: {
              type: 'new_animal',
              animalId: context.params.animalId,
              animalName: afterData.name || 'Animal',
              animalSpecies: afterData.species || 'Pet'
            }
          });
        });

        await Promise.all(notificationPromises);
        console.log(`New animal notification sent to ${usersSnapshot.docs.length} users`);

      } catch (error) {
        console.error('Error sending new animal notifications:', error);
      }
    }
  });

// Firestore trigger for when adoption application is approved
export const onAdoptionApplicationApproved = functions.firestore
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

        // Send push notification if user has adoption notifications enabled
        if (userData?.adoptionNotifications !== false) {
          await sendPushNotification({
            userId: afterData.userId,
            title: '🎉 Adoption Approved!',
            body: `Your adoption application for ${animalData?.name || 'the animal'} has been approved!`,
            data: {
              type: 'adoption_approved',
              applicationId: context.params.applicationId,
              animalId: afterData.animalId,
              animalName: animalData?.name || 'Animal'
            }
          });
        }

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

      } catch (error) {
        console.error('Error sending adoption approval email:', error);
      }
    }
  });

// Firestore trigger for when adoption application is rejected
export const onAdoptionApplicationRejected = functions.firestore
  .document('applications/{applicationId}')
  .onUpdate(async (change, context) => {
    const beforeData = change.before.data();
    const afterData = change.after.data();

    // Check if status changed from pending to rejected
    if (beforeData.status === 'pending' && afterData.status === 'rejected') {
      try {
        const gmailEmail = functions.config().gmail?.email;
        const gmailPassword = functions.config().gmail?.password;

        // Get user data
        const userDoc = await admin.firestore()
          .collection('users')
          .doc(afterData.userId)
          .get();

        if (!userDoc.exists) {
          console.log('User document not found for adoption rejection notification');
          return;
        }

        const userData = userDoc.data();
        const userEmail = userData?.email || afterData.userEmail;

        // Get animal data
        const animalDoc = await admin.firestore()
          .collection('animals')
          .doc(afterData.animalId)
          .get();

        const animalData = animalDoc.exists ? animalDoc.data() : {};

        // Send email notification
        if (gmailEmail && gmailPassword && userEmail) {
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
            subject: 'Adoption Application Update - PawsCare',
            html: emailTemplates.adoption_rejected.template({
              userName: userData?.fullName || 'User',
              animalName: animalData?.name || 'Animal',
              animalSpecies: animalData?.species || 'Pet',
              adminMessage: afterData.adminMessage || 'Your application has been reviewed.'
            })
          };

          await transporter.sendMail(mailOptions);
          console.log('Adoption rejection email sent to:', userEmail);

          // Log to Firestore
          await admin.firestore().collection('email_logs').add({
            type: 'adoption_rejected',
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

        // Send push notification if user has adoption notifications enabled
        if (userData?.adoptionNotifications !== false) {
          await sendPushNotification({
            userId: afterData.userId,
            title: 'Adoption Application Update',
            body: `Your adoption application for ${animalData?.name || 'the animal'} has been reviewed.`,
            data: {
              type: 'adoption_rejected',
              applicationId: context.params.applicationId,
              animalId: afterData.animalId,
              animalName: animalData?.name || 'Animal'
            }
          });
        }

        console.log('Adoption rejection notification sent to user:', afterData.userId);

      } catch (error) {
        console.error('Error sending adoption rejection notification:', error);
      }
    }
  });




// Firestore trigger for when a new adoption application is submitted
export const onAdoptionApplicationSubmitted = functions.firestore
  .document('applications/{applicationId}')
  .onCreate(async (snapshot, context) => {
    const applicationData = snapshot.data();
    
    try {
      const gmailEmail = functions.config().gmail?.email;
      const gmailPassword = functions.config().gmail?.password;

      if (!gmailEmail || !gmailPassword) {
        console.log('Gmail not configured, skipping adoption application submitted email');
        return;
      }

      // Get user data
      const userDoc = await admin.firestore()
        .collection('users')
        .doc(applicationData.userId)
        .get();

      if (!userDoc.exists) {
        console.log('User document not found for adoption application submitted email');
        return;
      }

      const userData = userDoc.data();
      const userEmail = userData?.email || applicationData.applicantEmail;

      if (!userEmail) {
        console.log('User email not found for adoption application submitted email');
        return;
      }

      // Get animal data
      const animalDoc = await admin.firestore()
        .collection('animals')
        .doc(applicationData.petId || applicationData.animalId)
        .get();

      const animalData = animalDoc.exists ? animalDoc.data() : {};

      // Send email notification to user
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
        subject: 'Adoption Application Submitted - PawsCare',
        html: emailTemplates.adoption_applied.template({
          userName: userData?.fullName || applicationData.applicantName || 'User',
          animalName: animalData?.name || applicationData.petName || 'Animal',
          animalSpecies: animalData?.species || 'Pet',
          applicationId: context.params.applicationId,
          appliedAt: applicationData.appliedAt || new Date()
        })
      };

      await transporter.sendMail(mailOptions);
      console.log('Adoption application submitted email sent to:', userEmail);

      // Send push notification if user has adoption notifications enabled
      if (userData?.adoptionNotifications !== false) {
        await sendPushNotification({
          userId: applicationData.userId,
          title: '📝 Application Submitted',
          body: `Your adoption application for ${animalData?.name || 'the animal'} has been submitted successfully!`,
          data: {
            type: 'adoption_submitted',
            applicationId: context.params.applicationId,
            animalId: applicationData.petId || applicationData.animalId,
            animalName: animalData?.name || 'Animal'
          }
        });
      }

      // Log to Firestore
      await admin.firestore().collection('email_logs').add({
        type: 'adoption_submitted',
        recipientEmail: userEmail,
        data: {
          applicationId: context.params.applicationId,
          animalId: applicationData.petId || applicationData.animalId,
          animalName: animalData?.name,
          animalSpecies: animalData?.species,
        },
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'sent'
      });

    } catch (error) {
      console.error('Error sending adoption application submitted notification:', error);
    }
  });


// Firestore trigger for when a new animal post is created (pending approval)
export const onNewAnimalPostRequest = functions.firestore
  .document('animals/{animalId}')
  .onCreate(async (snapshot, context) => {
    const animalData = snapshot.data();
    
    // Only notify admins if the post is pending approval
    if (animalData.approvalStatus !== 'pending') {
      return;
    }

    try {
      const gmailEmail = functions.config().gmail?.email;
      const gmailPassword = functions.config().gmail?.password;

      if (!gmailEmail || !gmailPassword) {
        console.log('Gmail not configured, skipping new animal post request notification');
        return;
      }

      // Get all admin users
      const adminsSnapshot = await admin.firestore()
        .collection('users')
        .where('role', '==', 'admin')
        .get();

      if (adminsSnapshot.empty) {
        console.log('No admin users found to notify about new animal post');
        return;
      }

      const transporter = nodemailer.createTransport({
        service: 'gmail',
        auth: {
          user: gmailEmail,
          pass: gmailPassword
        }
      });

      // Send email and push notification to each admin
      const notificationPromises = adminsSnapshot.docs.map(async (adminDoc) => {
        const adminData = adminDoc.data();
        const adminEmail = adminData?.email;

        if (!adminEmail) {
          console.log('Admin email not found for admin:', adminDoc.id);
          return;
        }

        // Send email to admin
        const mailOptions = {
          from: gmailEmail,
          to: adminEmail,
          subject: '🐾 New Animal Post Request - PawsCare Admin',
          html: emailTemplates.new_post_request_admin.template({
            animalName: animalData.name || 'Unknown',
            animalSpecies: animalData.species || 'Unknown',
            breed: animalData.breed,
            age: animalData.age,
            postedByEmail: animalData.postedByEmail || 'Unknown',
            postedAt: animalData.postedAt || new Date()
          })
        };

        await transporter.sendMail(mailOptions);
        console.log('New animal post request email sent to admin:', adminEmail);

        // Send push notification to admin
        await sendPushNotification({
          userId: adminDoc.id,
          title: '🐾 New Animal Post Request',
          body: `New post for ${animalData.name || 'an animal'} is pending your approval`,
          data: {
            type: 'new_animal_post_request',
            animalId: context.params.animalId,
            animalName: animalData.name || 'Animal',
            postedBy: animalData.postedByEmail || 'User'
          }
        });

        // Log to Firestore
        await admin.firestore().collection('email_logs').add({
          type: 'new_post_request_admin',
          recipientEmail: adminEmail,
          data: {
            animalId: context.params.animalId,
            animalName: animalData.name,
            animalSpecies: animalData.species,
            postedByEmail: animalData.postedByEmail
          },
          sentAt: admin.firestore.FieldValue.serverTimestamp(),
          status: 'sent'
        });
      });

      await Promise.all(notificationPromises);
      console.log(`New animal post request notifications sent to ${adminsSnapshot.docs.length} admins`);

    } catch (error) {
      console.error('Error sending new animal post request notification:', error);
    }
  });




/**
 * Append to users_log sheet:
 * [uid, email, Fullname, role, phonenumber, address, field_updated, timestamp]
 */
// Temporarily commented out due to googleapis import issues

export const logUserToSheet = functions
  .region("us-central1")
  .firestore.document("users/{uid}")
  .onWrite(async (change, context) => {
    try {
      const cfg = functions.config();
      const SPREADSHEET_ID = cfg.sheets?.spreadsheet_id;
      const KEY_B64 = cfg.sheets?.key_b64;

      if (!SPREADSHEET_ID || !KEY_B64) {
        console.error(
          "Missing functions config: sheets.spreadsheet_id or sheets.key_b64"
        );
        return null;
      }

      const uid = context.params.uid;
      const before = change.before.exists ? change.before.data() : null;
      const after = change.after.exists ? change.after.data() : null;

      // ignore deletes
      if (before && !after) return null;

      // Fields we track (and the column order after uid)
      const trackedFields = [
        "email",
        "fullName",
        "role",
        "phoneNumber",
        "address",
      ];

      const normalize = (val: any): string => {
        if (val === null || val === undefined) return "";
        if (typeof val?.toDate === "function") {
          try {
            return val.toDate().toISOString();
          } catch {
            return String(val);
          }
        }
        if (val instanceof Date) return val.toISOString();
        if (typeof val === "object") {
          try {
            return JSON.stringify(val);
          } catch {
            return String(val);
          }
        }
        return String(val);
      };

      const isCreate = !before && !!after;
      const isUpdate = !!before && !!after;

      // Build normalized maps for comparison
      const beforeNormalized: Record<string, string> = {};
      const afterNormalized: Record<string, string> = {};

      for (const f of trackedFields) {
        beforeNormalized[f] = normalize(before?.[f]);
        afterNormalized[f] = normalize(after?.[f]);
      }

      // Determine changed tracked fields
      const changedFields: string[] = [];
      if (isUpdate) {
        for (const f of trackedFields) {
          if (beforeNormalized[f] !== afterNormalized[f]) {
            changedFields.push(f);
          }
        }
      }

      // Decide whether to append:
      // - always append for create
      // - for update append only if any tracked field changed
      if (!isCreate && !(isUpdate && changedFields.length > 0)) {
        // nothing to log
        return null;
      }

      // Build the row in requested order:
      // uid, email, Fullname, role, phonenumber, address, field_updated, timestamp
      const rowValues: string[] = [
        uid,
        afterNormalized["email"] || "",
        afterNormalized["fullName"] || "",
        afterNormalized["role"] || "",
        afterNormalized["phoneNumber"] || "",
        afterNormalized["address"] || "",
      ];

      const fieldUpdated = isCreate ? "new_user" : changedFields.join(", ");
      const timestampISO = new Date().toISOString();

      rowValues.push(fieldUpdated || "none", timestampISO);

      // Authenticate to Sheets
      const keyJson = JSON.parse(
        Buffer.from(KEY_B64, "base64").toString("utf8")
      );
      const jwt = new google.auth.JWT(
        keyJson.client_email,
        undefined,
        keyJson.private_key,
        ["https://www.googleapis.com/auth/spreadsheets"]
      );
      await jwt.authorize();

      const sheets = google.sheets({ version: "v4", auth: jwt });
      await sheets.spreadsheets.values.append({
        spreadsheetId: SPREADSHEET_ID,
        range: "users_log!A1",
        valueInputOption: "RAW",
        insertDataOption: "INSERT_ROWS",
        requestBody: { values: [rowValues] },
      });

      console.log(
        `logUserToSheet: appended for uid=${uid} fieldUpdated=${fieldUpdated}`
      );
      return null;
    } catch (err) {
      console.error("logUserToSheet error:", err);
      throw err;
    }
  });


/**
 * Append to animals_log sheet:
 * [animalId, name, species, breed, age, gender, status, approvalStatus, postedBy, description, images, adminMessage, field_updated, timestamp]
 */
export const logAnimalToSheet = functions
  .region("us-central1")
  .firestore.document("animals/{animalId}")
  .onWrite(async (change, context) => {
    try {
      // Spreadsheet config
      const cfg = functions.config();
      const SPREADSHEET_ID = cfg.sheets?.spreadsheet_id;
      const KEY_B64 = cfg.sheets?.key_b64;

      if (!SPREADSHEET_ID || !KEY_B64) {
        console.error("Missing functions config: sheets.spreadsheet_id or sheets.key_b64");
        return null;
      }

      const animalId = context.params.animalId;
      const before = change.before.exists ? change.before.data() : null;
      const after = change.after.exists ? change.after.data() : null;

      // ignore deletes
      if (before && !after) return null;

      // Fields to track and log
      const trackedFields = [
        "name",
        "species",
        "breed",
        "age",
        "gender",
        "status",
        "approvalStatus",
        "postedBy",
        "description",
        "images",
        "adminMessage"
      ];

      const normalize = (val: any): string => {
        if (val === null || val === undefined) return "";
        if (typeof val?.toDate === "function") {
          try {
            return val.toDate().toISOString();
          } catch {
            return String(val);
          }
        }
        if (val instanceof Date) return val.toISOString();
        if (Array.isArray(val)) return val.join(", ");
        if (typeof val === "object") {
          try {
            return JSON.stringify(val);
          } catch {
            return String(val);
          }
        }
        return String(val);
      };

      const isCreate = !before && !!after;
      const isUpdate = !!before && !!after;

      // Build normalized maps for comparison
      const beforeNormalized: Record<string, string> = {};
      const afterNormalized: Record<string, string> = {};
      for (const f of trackedFields) {
        beforeNormalized[f] = normalize(before?.[f]);
        afterNormalized[f] = normalize(after?.[f]);
      }

      // Determine changed tracked fields
      const changedFields: string[] = [];
      if (isUpdate) {
        for (const f of trackedFields) {
          if (beforeNormalized[f] !== afterNormalized[f]) {
            changedFields.push(f);
          }
        }
      }

      // Decide whether to append:
      // - always append for create
      // - for update append only if any tracked field changed
      if (!isCreate && !(isUpdate && changedFields.length > 0)) {
        // nothing to log
        return null;
      }

      // Build the row in requested order:
      // animalId, name, species, breed, age, gender, status, approvalStatus, postedBy, description, images, adminMessage, field_updated, timestamp
      const rowValues: string[] = [
        animalId,
        afterNormalized["name"] || "",
        afterNormalized["species"] || "",
        afterNormalized["breed"] || "",
        afterNormalized["age"] || "",
        afterNormalized["gender"] || "",
        afterNormalized["status"] || "",
        afterNormalized["approvalStatus"] || "",
        afterNormalized["postedBy"] || "",
        afterNormalized["description"] || "",
        afterNormalized["images"] || "",
        afterNormalized["adminMessage"] || ""
      ];

      const fieldUpdated = isCreate ? "new_animal" : changedFields.join(", ");
      const timestampISO = new Date().toISOString();
      rowValues.push(fieldUpdated || "none", timestampISO);

      // Authenticate to Sheets
      const keyJson = JSON.parse(Buffer.from(KEY_B64, "base64").toString("utf8"));
      const jwt = new google.auth.JWT(
        keyJson.client_email,
        undefined,
        keyJson.private_key,
        ["https://www.googleapis.com/auth/spreadsheets"]
      );
      await jwt.authorize();

      const sheets = google.sheets({ version: "v4", auth: jwt });
      await sheets.spreadsheets.values.append({
        spreadsheetId: SPREADSHEET_ID,
        range: "animals_log!A1",
        valueInputOption: "RAW",
        insertDataOption: "INSERT_ROWS",
        requestBody: { values: [rowValues] },
      });

      console.log(`logAnimalToSheet: appended for animalId=${animalId} fieldUpdated=${fieldUpdated}`);
      return null;
    } catch (err) {
      console.error("logAnimalToSheet error:", err);
      throw err;
    }
  });

/**
 * Append to applications_log sheet:
 * [applicationId, adminMessage, allMembersAgree, applicantAddress, applicantEmail, applicantName, applicantPhone, appliedAt, currentPetsDetails, financiallyPrepared, hasAllergies, hasCurrentPets, hasPastPets, hasSurrenderedPets, hasVeterinarian, homeOwnership, hoursLeftAlone, householdMembers, ifCannotKeepCare, pastPetsDetails, petId, petImage, petName, petTypeLookingFor, preferenceForBreedAgeGender, preparedForLifetimeCommitment, reviewedAt, status, surrenderedPetsCircumstance, userId, vetContactInfo, whereKeptWhenAlone, whyAdoptPet, willingToProvideVetCare, field_updated, timestamp]
 */
export const logApplicationToSheet = functions
  .region("us-central1")
  .firestore.document("applications/{applicationId}")
  .onWrite(async (change, context) => {
    try {
      // Spreadsheet config
      const cfg = functions.config();
      const SPREADSHEET_ID = cfg.sheets?.spreadsheet_id;
      const KEY_B64 = cfg.sheets?.key_b64;

      if (!SPREADSHEET_ID || !KEY_B64) {
        console.error("Missing functions config: sheets.spreadsheet_id or sheets.key_b64");
        return null;
      }

      const applicationId = context.params.applicationId;
      const before = change.before.exists ? change.before.data() : null;
      const after = change.after.exists ? change.after.data() : null;

      // ignore deletes
      if (before && !after) return null;

      // Fields to track and log (order matches your list)
      const trackedFields = [
        "adminMessage",
        "allMembersAgree",
        "applicantAddress",
        "applicantEmail",
        "applicantName",
        "applicantPhone",
        "appliedAt",
        "currentPetsDetails",
        "financiallyPrepared",
        "hasAllergies",
        "hasCurrentPets",
        "hasPastPets",
        "hasSurrenderedPets",
        "hasVeterinarian",
        "homeOwnership",
        "hoursLeftAlone",
        "householdMembers",
        "ifCannotKeepCare",
        "pastPetsDetails",
        "petId",
        "petImage",
        "petName",
        "petTypeLookingFor",
        "preferenceForBreedAgeGender",
        "preparedForLifetimeCommitment",
        "reviewedAt",
        "status",
        "surrenderedPetsCircumstance",
        "userId",
        "vetContactInfo",
        "whereKeptWhenAlone",
        "whyAdoptPet",
        "willingToProvideVetCare"
      ];

      // Header row for the sheet
      const headerRow = [
        "applicationId",
        ...trackedFields,
        "field_updated",
        "timestamp"
      ];

      const normalize = (val: any): string => {
        if (val === null || val === undefined) return "";
        if (typeof val?.toDate === "function") {
          try {
            return val.toDate().toISOString();
          } catch {
            return String(val);
          }
        }
        if (val instanceof Date) return val.toISOString();
        if (typeof val === "boolean") return val ? "TRUE" : "FALSE";
        if (typeof val === "number") return String(val);
        if (Array.isArray(val)) return val.join(", ");
        if (typeof val === "object") {
          try {
            return JSON.stringify(val);
          } catch {
            return String(val);
          }
        }
        return String(val);
      };

      const isCreate = !before && !!after;
      const isUpdate = !!before && !!after;

      // Build normalized maps for comparison
      const beforeNormalized: Record<string, string> = {};
      const afterNormalized: Record<string, string> = {};
      for (const f of trackedFields) {
        beforeNormalized[f] = normalize(before?.[f]);
        afterNormalized[f] = normalize(after?.[f]);
      }

      // Determine changed tracked fields
      const changedFields: string[] = [];
      if (isUpdate) {
        for (const f of trackedFields) {
          if (beforeNormalized[f] !== afterNormalized[f]) {
            changedFields.push(f);
          }
        }
      }

      // Decide whether to append:
      // - always append for create
      // - for update append only if any tracked field changed
      if (!isCreate && !(isUpdate && changedFields.length > 0)) {
        // nothing to log
        return null;
      }

      // Build the row in requested order:
      // applicationId, ...fields..., field_updated, timestamp
      const rowValues: string[] = [
        applicationId,
        ...trackedFields.map(f => afterNormalized[f] || ""),
      ];

      const fieldUpdated = isCreate ? "new_application" : changedFields.join(", ");
      const timestampISO = new Date().toISOString();
      rowValues.push(fieldUpdated || "none", timestampISO);

      // Authenticate to Sheets
      const keyJson = JSON.parse(Buffer.from(KEY_B64, "base64").toString("utf8"));
      const jwt = new google.auth.JWT(
        keyJson.client_email,
        undefined,
        keyJson.private_key,
        ["https://www.googleapis.com/auth/spreadsheets"]
      );
      await jwt.authorize();

      const sheets = google.sheets({ version: "v4", auth: jwt });

      // Write header row if sheet is empty
      const getSheet = await sheets.spreadsheets.values.get({
        spreadsheetId: SPREADSHEET_ID,
        range: "applications_log!A1:Z1"
      });
      if (!getSheet.data.values || getSheet.data.values.length === 0) {
        await sheets.spreadsheets.values.append({
          spreadsheetId: SPREADSHEET_ID,
          range: "applications_log!A1",
          valueInputOption: "RAW",
          insertDataOption: "INSERT_ROWS",
          requestBody: { values: [headerRow] },
        });
      }

      // Append the application row
      await sheets.spreadsheets.values.append({
        spreadsheetId: SPREADSHEET_ID,
        range: "applications_log!A1",
        valueInputOption: "RAW",
        insertDataOption: "INSERT_ROWS",
        requestBody: { values: [rowValues] },
      });

      console.log(`logApplicationToSheet: appended for applicationId=${applicationId} fieldUpdated=${fieldUpdated}`);
      return null;
    } catch (err) {
      console.error("logApplicationToSheet error:", err);
      throw err;
    }
  });



/**
* Append to emails_log sheet:
* [logId, type, recipientEmail, animalId, animalName, animalSpecies, adminMessage, sentAt, status, data, field_updated, timestamp]
*/
export const logEmailToSheet = functions
  .region("us-central1")
  .firestore.document("email_logs/{logId}")
  .onWrite(async (change, context) => {
    try {
      const cfg = functions.config();
      const SPREADSHEET_ID = cfg.sheets?.spreadsheet_id;
      const KEY_B64 = cfg.sheets?.key_b64;
      if (!SPREADSHEET_ID || !KEY_B64) {
        console.error("Missing functions config: sheets.spreadsheet_id or sheets.key_b64");
        return null;
      }
      const logId = context.params.logId;
      const before = change.before.exists ? change.before.data() : null;
      const after = change.after.exists ? change.after.data() : null;
      if (!after) return null; // Only log creates/updates
      const trackedFields = [
        "type",
        "recipientEmail",
        "animalId",
        "animalName",
        "animalSpecies",
        "adminMessage",
        "sentAt",
        "status",
        "data"
      ];
      const headerRow = ["logId", ...trackedFields, "field_updated", "timestamp"];
      const normalize = (val: any): string => {
        if (val === null || val === undefined) return "";
        if (typeof val?.toDate === "function") { try { return val.toDate().toISOString(); } catch { return String(val); } }
        if (val instanceof Date) return val.toISOString();
        if (typeof val === "boolean") return val ? "TRUE" : "FALSE";
        if (typeof val === "number") return String(val);
        if (Array.isArray(val)) return val.join(", ");
        if (typeof val === "object") { try { return JSON.stringify(val); } catch { return String(val); } }
        return String(val);
      };
      const isCreate = !before && !!after;
      const isUpdate = !!before && !!after;
      const beforeNormalized: Record<string, string> = {};
      const afterNormalized: Record<string, string> = {};
      for (const f of trackedFields) {
        beforeNormalized[f] = normalize(before?.[f]);
        afterNormalized[f] = normalize(after?.[f]);
      }
      const changedFields: string[] = [];
      if (isUpdate) {
        for (const f of trackedFields) {
          if (beforeNormalized[f] !== afterNormalized[f]) {
            changedFields.push(f);
          }
        }
      }
      if (!isCreate && !(isUpdate && changedFields.length > 0)) return null;
      const rowValues: string[] = [
        logId,
        ...trackedFields.map(f => afterNormalized[f] || ""),
      ];
      const fieldUpdated = isCreate ? "new_email_log" : changedFields.join(", ");
      const timestampISO = new Date().toISOString();
      rowValues.push(fieldUpdated || "none", timestampISO);
      const keyJson = JSON.parse(Buffer.from(KEY_B64, "base64").toString("utf8"));
      const jwt = new google.auth.JWT(keyJson.client_email, undefined, keyJson.private_key, ["https://www.googleapis.com/auth/spreadsheets"]);
      await jwt.authorize();
      const sheets = google.sheets({ version: "v4", auth: jwt });
      const getSheet = await sheets.spreadsheets.values.get({ spreadsheetId: SPREADSHEET_ID, range: "emails_log!A1:Z1" });
      if (!getSheet.data.values || getSheet.data.values.length === 0) {
        await sheets.spreadsheets.values.append({ spreadsheetId: SPREADSHEET_ID, range: "emails_log!A1", valueInputOption: "RAW", insertDataOption: "INSERT_ROWS", requestBody: { values: [headerRow] }, });
      }
      await sheets.spreadsheets.values.append({ spreadsheetId: SPREADSHEET_ID, range: "emails_log!A1", valueInputOption: "RAW", insertDataOption: "INSERT_ROWS", requestBody: { values: [rowValues] }, });
      console.log(`logEmailToSheet: appended for logId=${logId} fieldUpdated=${fieldUpdated}`);
      return null;
    } catch (err) {
      console.error("logEmailToSheet error:", err);
      throw err;
    }
  });

/**
 * Append to notifications_log sheet:
 * [logId, userId, title, body, animalId, animalName, animalSpecies, type, messageId, sentAt, status, data, field_updated, timestamp]
 */
export const logNotificationToSheet = functions
  .region("us-central1")
  .firestore.document("notification_logs/{logId}")
  .onWrite(async (change, context) => {
    try {
      const cfg = functions.config();
      const SPREADSHEET_ID = cfg.sheets?.spreadsheet_id;
      const KEY_B64 = cfg.sheets?.key_b64;
      if (!SPREADSHEET_ID || !KEY_B64) {
        console.error("Missing functions config: sheets.spreadsheet_id or sheets.key_b64");
        return null;
      }
      const logId = context.params.logId;
      const before = change.before.exists ? change.before.data() : null;
      const after = change.after.exists ? change.after.data() : null;
      if (!after) return null;
      const trackedFields = [
        "userId",
        "title",
        "body",
        "animalId",
        "animalName",
        "animalSpecies",
        "type",
        "messageId",
        "sentAt",
        "status",
        "data"
      ];
      const headerRow = ["logId", ...trackedFields, "field_updated", "timestamp"];
      const normalize = (val: any): string => {
        if (val === null || val === undefined) return "";
        if (typeof val?.toDate === "function") { try { return val.toDate().toISOString(); } catch { return String(val); } }
        if (val instanceof Date) return val.toISOString();
        if (typeof val === "boolean") return val ? "TRUE" : "FALSE";
        if (typeof val === "number") return String(val);
        if (Array.isArray(val)) return val.join(", ");
        if (typeof val === "object") { try { return JSON.stringify(val); } catch { return String(val); } }
        return String(val);
      };
      const isCreate = !before && !!after;
      const isUpdate = !!before && !!after;
      const beforeNormalized: Record<string, string> = {};
      const afterNormalized: Record<string, string> = {};
      for (const f of trackedFields) {
        beforeNormalized[f] = normalize(before?.[f]);
        afterNormalized[f] = normalize(after?.[f]);
      }
      const changedFields: string[] = [];
      if (isUpdate) {
        for (const f of trackedFields) {
          if (beforeNormalized[f] !== afterNormalized[f]) {
            changedFields.push(f);
          }
        }
      }
      if (!isCreate && !(isUpdate && changedFields.length > 0)) return null;
      const rowValues: string[] = [
        logId,
        ...trackedFields.map(f => afterNormalized[f] || ""),
      ];
      const fieldUpdated = isCreate ? "new_notification_log" : changedFields.join(", ");
      const timestampISO = new Date().toISOString();
      rowValues.push(fieldUpdated || "none", timestampISO);
      const keyJson = JSON.parse(Buffer.from(KEY_B64, "base64").toString("utf8"));
      const jwt = new google.auth.JWT(keyJson.client_email, undefined, keyJson.private_key, ["https://www.googleapis.com/auth/spreadsheets"]);
      await jwt.authorize();
      const sheets = google.sheets({ version: "v4", auth: jwt });
      const getSheet = await sheets.spreadsheets.values.get({ spreadsheetId: SPREADSHEET_ID, range: "notifications_log!A1:Z1" });
      if (!getSheet.data.values || getSheet.data.values.length === 0) {
        await sheets.spreadsheets.values.append({ spreadsheetId: SPREADSHEET_ID, range: "notifications_log!A1", valueInputOption: "RAW", insertDataOption: "INSERT_ROWS", requestBody: { values: [headerRow] }, });
      }
      await sheets.spreadsheets.values.append({ spreadsheetId: SPREADSHEET_ID, range: "notifications_log!A1", valueInputOption: "RAW", insertDataOption: "INSERT_ROWS", requestBody: { values: [rowValues] }, });
      console.log(`logNotificationToSheet: appended for logId=${logId} fieldUpdated=${fieldUpdated}`);
      return null;
    } catch (err) {
      console.error("logNotificationToSheet error:", err);
      throw err;
    }
  });

  /**
 * Append to general_log sheet:
 * [logId, userId, userEmail, animalId, eventType, adminMessage, createdAt, data, field_updated, timestamp]
 */

export const logGeneralToSheet = functions
  .region("us-central1")
  .firestore.document("general_logs/{logId}")
  .onWrite(async (change, context) => {
    try {
      const cfg = functions.config();
      const SPREADSHEET_ID = cfg.sheets?.spreadsheet_id;
      const KEY_B64 = cfg.sheets?.key_b64;
      if (!SPREADSHEET_ID || !KEY_B64) {
        console.error("Missing functions config: sheets.spreadsheet_id or sheets.key_b64");
        return null;
      }
      const logId = context.params.logId;
      const before = change.before.exists ? change.before.data() : null;
      const after = change.after.exists ? change.after.data() : null;
      if (!after) return null;
      const trackedFields = [
        "userId",
        "userEmail",
        "animalId",
        "eventType",
        "adminMessage",
        "createdAt",
        "data"
      ];
      const headerRow = ["logId", ...trackedFields, "field_updated", "timestamp"];
      const normalize = (val: any): string => {
        if (val === null || val === undefined) return "";
        if (typeof val?.toDate === "function") { try { return val.toDate().toISOString(); } catch { return String(val); } }
        if (val instanceof Date) return val.toISOString();
        if (typeof val === "boolean") return val ? "TRUE" : "FALSE";
        if (typeof val === "number") return String(val);
        if (Array.isArray(val)) return val.join(", ");
        if (typeof val === "object") { try { return JSON.stringify(val); } catch { return String(val); } }
        return String(val);
      };
      const isCreate = !before && !!after;
      const isUpdate = !!before && !!after;
      const beforeNormalized: Record<string, string> = {};
      const afterNormalized: Record<string, string> = {};
      for (const f of trackedFields) {
        beforeNormalized[f] = normalize(before?.[f]);
        afterNormalized[f] = normalize(after?.[f]);
      }
      const changedFields: string[] = [];
      if (isUpdate) {
        for (const f of trackedFields) {
          if (beforeNormalized[f] !== afterNormalized[f]) {
            changedFields.push(f);
          }
        }
      }
      if (!isCreate && !(isUpdate && changedFields.length > 0)) return null;
      const rowValues: string[] = [
        logId,
        ...trackedFields.map(f => afterNormalized[f] || ""),
      ];
      const fieldUpdated = isCreate ? "new_general_log" : changedFields.join(", ");
      const timestampISO = new Date().toISOString();
      rowValues.push(fieldUpdated || "none", timestampISO);
      const keyJson = JSON.parse(Buffer.from(KEY_B64, "base64").toString("utf8"));
      const jwt = new google.auth.JWT(keyJson.client_email, undefined, keyJson.private_key, ["https://www.googleapis.com/auth/spreadsheets"]);
      await jwt.authorize();
      const sheets = google.sheets({ version: "v4", auth: jwt });
      const getSheet = await sheets.spreadsheets.values.get({ spreadsheetId: SPREADSHEET_ID, range: "general_log!A1:Z1" });
      if (!getSheet.data.values || getSheet.data.values.length === 0) {
        await sheets.spreadsheets.values.append({ spreadsheetId: SPREADSHEET_ID, range: "general_log!A1", valueInputOption: "RAW", insertDataOption: "INSERT_ROWS", requestBody: { values: [headerRow] }, });
      }
      await sheets.spreadsheets.values.append({ spreadsheetId: SPREADSHEET_ID, range: "general_log!A1", valueInputOption: "RAW", insertDataOption: "INSERT_ROWS", requestBody: { values: [rowValues] }, });
      console.log(`logGeneralToSheet: appended for logId=${logId} fieldUpdated=${fieldUpdated}`);
      return null;
    } catch (err) {
      console.error("logGeneralToSheet error:", err);
      throw err;
    }
  });