import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<RemoteMessage> waitForJob(String jobId) {
  final completer = Completer<RemoteMessage>();

  late StreamSubscription subscription;
  subscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.data['notification'] == jobId) {
      completer.complete(message);
      subscription.cancel(); // stop listening
    }
  });

  return completer.future;
}
