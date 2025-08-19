import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

// Глобальный ключ для навигации из пуш-уведомлений
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Фоновые уведомления
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Уведомление в фоне: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Supabase
  await Supabase.initialize(
    url: 'https://dntffykaytdzrceskqys.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRudGZmeWtheXRkenJjZXNrcXlzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTMwMjA4NTUsImV4cCI6MjA2ODU5Njg1NX0.GdKkipRIRxKndXuv3yHPvQV6BDtpi0ABojIGpW5qyew',
  );

  // Инициализация Firebase
  await Firebase.initializeApp();

  // Настройка Firebase Messaging
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Разрешения для уведомлений (iOS)
  await FirebaseMessaging.instance.requestPermission();

  // Обработка клика на уведомление, когда приложение в фоне/свёрнуто
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final routeFromMessage = message.data['route'];
    if (routeFromMessage != null && navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushNamed(routeFromMessage);
    }
  });

  runApp(const OndeApp());
}

class OndeApp extends StatelessWidget {
  const OndeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ключ навигатора
      title: 'Onde',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainScreen(role: 'client'),
      },
    );
  }
}
