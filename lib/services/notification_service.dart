import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static bool _isInitialized = false;

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request permission for notifications
      await _requestPermission();

      // Get FCM token and save it
      await _saveFCMToken();

      // Configure message handlers
      await _configureMessageHandlers();

      _isInitialized = true;
      print('NotificationService initialized successfully');
    } catch (e) {
      print('Error initializing NotificationService: $e');
    }
  }

  /// Initialize local notifications plugin
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'pawscare_notifications',
        'PawsCare Notifications',
        description: 'Notifications for adoption updates and new animals',
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  /// Request notification permissions
  static Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  /// Save FCM token to Firestore
  static Future<void> _saveFCMToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
          'notificationsEnabled': true, // Default to enabled
          'adoptionNotifications': true, // Default to enabled
          'newAnimalNotifications': true, // Default to enabled
          'generalNotifications': true, // Default to enabled
        });
        print('FCM token saved: $token');
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Configure message handlers
  static Future<void> _configureMessageHandlers() async {
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.messageId}');
      _showLocalNotification(message);
    });

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification tapped: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Handle notification taps when app is terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from terminated state via notification: ${initialMessage.messageId}');
      _handleNotificationTap(initialMessage);
    }
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'pawscare_notifications',
            'PawsCare Notifications',
            channelDescription: 'Notifications for adoption updates and new animals',
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon,
            playSound: true,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    // Handle local notification tap
    if (response.payload != null) {
      // Parse payload and navigate accordingly
      _navigateFromNotification(response.payload!);
    }
  }

  /// Handle notification tap from FCM
  static void _handleNotificationTap(RemoteMessage message) {
    _navigateFromNotification(message.data.toString());
  }

  /// Navigate based on notification data
  static void _navigateFromNotification(String payload) {
    // This will be implemented based on your navigation structure
    // For now, we'll just print the payload
    print('Navigating from notification: $payload');
  }

  /// Send notification to specific user
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // Get user's FCM token
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        print('User document not found for notification');
        return;
      }

      final userData = userDoc.data();
      final fcmToken = userData?['fcmToken'] as String?;

      if (fcmToken == null) {
        print('No FCM token found for user');
        return;
      }

      // This would typically be done via Cloud Functions
      // For now, we'll just log the notification details
      print('Would send notification to user $userId: $title - $body');
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  /// Refresh FCM token
  static Future<void> refreshToken() async {
    await _saveFCMToken();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  // Handle background message here
}
