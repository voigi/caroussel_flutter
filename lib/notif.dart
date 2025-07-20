
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> initNotifications() async {
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: null,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      if (response.payload == 'openFiles') {
        openFileExplorer();
      }
    },
  );
}

// ouverture de l'explorateur de fichiers
Future<void> openFileExplorer() async {
  final intent = AndroidIntent(
    action: 'android.intent.action.VIEW',
    data: 'content://com.android.externalstorage.documents/document/primary%3AMovies',
    package: 'com.android.documentsui',
    flags: <int>[
      Flag.FLAG_ACTIVITY_NEW_TASK,
    ],
  );

  await intent.launch();
}



Future<void> showVideoSavedNotification() async {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'video_channel_id',
    'Video Notifications',
    channelDescription: 'Notifications when video is saved',
    importance: Importance.high,
    priority: Priority.high,
    sound: RawResourceAndroidNotificationSound('notif'), // sans extension
    playSound: true,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  await flutterLocalNotificationsPlugin.show(
    0,
    'Vidéo enregistrée',
    'Vidéo enregistrée dans le dossier Movies',
    platformChannelSpecifics,
    payload: 'openFiles', // utile pour détecter le clic
  );
}
