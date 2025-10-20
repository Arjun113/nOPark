import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<RemoteMessage> waitForJob(String jobId) {
  final completer = Completer<RemoteMessage>();

  late StreamSubscription subscription;
  late StreamSubscription subscription2;
  subscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('=== FCM MESSAGE RECEIVED ===');
    print('Message ID: ${message.messageId}');
    print('Notification Title: ${message.notification?.title}');
    print('Notification Body: ${message.notification?.body}');

    // Print data payload (most important for your case)
    print('Data:');
    message.data.forEach((key, value) {
      print('  $key: $value');
    });
    if (message.data['notification'] == jobId) {
      completer.complete(message);
      subscription.cancel(); // stop listening
    }
  });

  return completer.future;
}
