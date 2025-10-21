import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

Future<RemoteMessage> waitForRideUpdates(String jobId) {
  final completer = Completer<RemoteMessage>();

  late StreamSubscription subscription;
  subscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('=== FCM MESSAGE RECEIVED ===');
    debugPrint('Message ID: ${message.messageId}');
    debugPrint('Notification Title: ${message.notification?.title}');
    debugPrint('Notification Body: ${message.notification?.body}');

    // Print data payload (most important for your case)
    debugPrint('Data:');
    message.data.forEach((key, value) {
      debugPrint('  $key: $value');
    });
    if (message.data['notification'] == jobId && message.data['notification_type'] == "ride_updates") {
      completer.complete(message);
      subscription.cancel(); // stop listening
    }
  });

  return completer.future;
}

Future<RemoteMessage> waitForDriverProximity (String other_ride_type) {
  final completer = Completer<RemoteMessage>();

  late StreamSubscription subscription;
  subscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('=== FCM MESSAGE RECEIVED ===');
    debugPrint('Message ID: ${message.messageId}');
    debugPrint('Notification Title: ${message.notification?.title}');
    debugPrint('Notification Body: ${message.notification?.body}');

    // Print data payload (most important for your case)
    debugPrint('Data:');
    message.data.forEach((key, value) {
      debugPrint('  $key: $value');
    });
    if (message.data['notification_type'] == other_ride_type) {
      completer.complete(message);
      subscription.cancel(); // stop listening
    }
  });

  return completer.future;
}
