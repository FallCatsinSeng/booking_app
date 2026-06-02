import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/notification_payload.dart';
import '../screens/booking_detail_screen.dart';
import '../screens/admin_bookings_screen.dart';
import '../models/booking.dart';
import 'navigation_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    // 1. Initialize Timezone
    tz.initializeTimeZones();

    // 2. Local Notifications Setup
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // 3. FCM Foreground Handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 4. FCM Background Click Handler
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // 5. Handle Initial Message (if app was terminated)
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  Future<void> requestPermissions() async {
    if (Platform.isAndroid) {
      final plugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await plugin?.requestNotificationsPermission();
    }

    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      print('User granted permission: ${settings.authorizationStatus}');
    }
  }

  Future<String?> getToken() async {
    try {
      String? token = await _fcm.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting FCM token: $e');
      }
      return null;
    }
  }

  Future<void> subscribeToAdminTopic() async {
    try {
      await _fcm.subscribeToTopic('admin_notifications');
      if (kDebugMode) {
        print('Subscribed to admin_notifications topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to admin topic: $e');
      }
    }
  }

  Future<void> unsubscribeFromAdminTopic() async {
    try {
      await _fcm.unsubscribeFromTopic('admin_notifications');
      if (kDebugMode) {
        print('Unsubscribed from admin_notifications topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error unsubscribing from admin topic: $e');
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            icon: android.smallIcon,
            priority: Priority.high,
            importance: Importance.max,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    final payload = NotificationPayload.fromJson(message.data);
    _navigateBasedOnPayload(payload);
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      final payload = NotificationPayload.fromJson(data);
      _navigateBasedOnPayload(payload);
    }
  }

  void _navigateBasedOnPayload(NotificationPayload payload) {
    switch (payload.type) {
      case NotificationType.bookingApproved:
      case NotificationType.bookingRejected:
      case NotificationType.bookingReminder:
        if (payload.bookingId != null) {
          NavigationService.navigateToPage(
            BookingDetailScreen(code: payload.bookingId!.toString()),
          );
        }
        break;
      case NotificationType.newBookingRequest:
      case NotificationType.bookingCancelled:
        if (payload.bookingId != null) {
          NavigationService.navigateToPage(
            BookingDetailScreen(code: payload.bookingId!.toString()),
          );
        } else {
          NavigationService.navigateToPage(const AdminBookingsScreen());
        }
        break;
      case NotificationType.bookingEnded:
        // Could navigate to history or detail
        if (payload.bookingId != null) {
          NavigationService.navigateToPage(
            BookingDetailScreen(code: payload.bookingId!.toString()),
          );
        }
        break;
      default:
        // Do nothing or go home
        break;
    }
  }

  /// Schedule a notification locally (e.g., 15 mins before end)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationPayload payload,
  }) async {
    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: jsonEncode(payload.toJson()),
    );
  }

  Future<void> scheduleBookingReminders(Booking booking) async {
    if (booking.bookingDate == null ||
        booking.endTime.isEmpty ||
        booking.status == 'cancelled' ||
        booking.status == 'rejected')
      return;
    try {
      final endTimeParts = booking.endTime.split(':');
      final date = DateTime.parse(booking.bookingDate!);
      int hour = int.parse(endTimeParts[0]);
      int min = int.parse(endTimeParts[1]);

      final endDateTime = DateTime(date.year, date.month, date.day, hour, min);
      if (endDateTime.isBefore(DateTime.now())) return;

      final reminderTime = endDateTime.subtract(const Duration(minutes: 15));
      if (reminderTime.isAfter(DateTime.now())) {
        await scheduleNotification(
          id: booking.id * 10,
          title: 'Waktu Hampir Habis',
          body:
              'Reservasi \${booking.facility?.name ?? "Fasilitas"} akan berakhir dalam 15 menit.',
          scheduledDate: reminderTime,
          payload: NotificationPayload(
            type: NotificationType.bookingReminder,
            bookingId: booking.id,
          ),
        );
      }

      if (endDateTime.isAfter(DateTime.now())) {
        await scheduleNotification(
          id: booking.id * 10 + 1,
          title: 'Waktu Habis',
          body: 'Waktu reservasi Anda telah berakhir.',
          scheduledDate: endDateTime,
          payload: NotificationPayload(
            type: NotificationType.bookingEnded,
            bookingId: booking.id,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error scheduling reminders: $e');
      }
    }
  }

  Future<void> cancelAll() async {
    await _localNotifications.cancelAll();
  }
}
