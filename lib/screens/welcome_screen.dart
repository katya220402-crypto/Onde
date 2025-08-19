import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'main_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  Timer? _timer;
  bool _bootstrapping = false;

  // Бренд‑цвета Onde
  static const Color lightBlue = Color(0xFFB3E5FC);
  static const Color darkBlue = Color(0xFF01579B);
  static const Color titleBlue = Color(0xFF1F3344);
  static const Color subtitleBlue = Color(0xFF5D7488);

  SupabaseClient get _supa => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // Небольшая задержка на splash, затем стартуем инициализацию
    _timer = Timer(const Duration(seconds: 3), _bootstrap);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    if (_bootstrapping) return;
    _bootstrapping = true;

    try {
      final authUser = _supa.auth.currentUser;

      if (authUser == null) {
        // Нет сессии — на экран логина
        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
        return;
      }

      // Есть сессия: убеждаемся, что запись в public.users существует
      Map<String, dynamic>? userRow = await _supa
          .from('users')
          .select('id, role')
          .eq('id', authUser.id)
          .maybeSingle();

      if (userRow == null) {
        // Новый пользователь: создаём запись с ролью client (мастера заведены заранее)
        await _supa.from('users').insert({
          'id': authUser.id,
          'email': authUser.email,
          'name':
              authUser.userMetadata?['name'] ?? authUser.email ?? authUser.id,
          'role': 'client',
        });
        userRow = {'id': authUser.id, 'role': 'client'};
      }

      // Синхронизируем FCM‑токен (тихо, чтобы не мешать навигации)
      try {
        await FirebaseMessaging.instance.requestPermission();
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await _supa
              .from('users')
              .update({'fcm_token': token}).eq('id', authUser.id);
        }
        FirebaseMessaging.instance.onTokenRefresh.listen(
          (t) async => _supa
              .from('users')
              .update({'fcm_token': t}).eq('id', authUser.id),
        );
      } catch (_) {/* не блокируем запуск */}

      // Навигация по роли (мастера заранее отмечены role='master')
      final role = (userRow['role'] as String?)?.trim().isNotEmpty == true
          ? (userRow['role'] as String)
          : 'client';

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainScreen(role: role)),
      );
    } catch (e) {
      // В случае ошибки — мягко уводим на логин
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось запустить приложение: $e')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Фирменный минимализм в голубых тонах
    return Scaffold(
      body: Stack(
        children: [
          // Градиент‑фон
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFDEEAF6), Color(0xFFE3F1F3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Контент
          Center(
            child: FadeTransition(
              opacity: _fade,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.waves, size: 64, color: titleBlue),
                  SizedBox(height: 20),
                  Text(
                    'Добро пожаловать в Onde',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: titleBlue,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Мир красоты и лёгкости',
                    style: TextStyle(
                      fontSize: 16,
                      color: subtitleBlue,
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Нижний прогресс‑индикатор
          Positioned(
            left: 24,
            right: 24,
            bottom: 28,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 6,
                valueColor: const AlwaysStoppedAnimation<Color>(darkBlue),
                backgroundColor: lightBlue.withOpacity(0.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
