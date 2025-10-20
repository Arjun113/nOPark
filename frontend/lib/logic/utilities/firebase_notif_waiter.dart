import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

Future<RemoteMessage> waitForJob(String jobId) {
  final completer = Completer<RemoteMessage>();

  late StreamSubscription subscription;
  late StreamSubscription subscription2;
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
    if (message.data['notification'] == jobId) {
      completer.complete(message);
      subscription.cancel(); // stop listening
    }
  });

  return completer.future;
}
