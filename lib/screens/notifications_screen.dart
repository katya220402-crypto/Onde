import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Бренд-цвета Onde
  static const Color lightBlue = Color(0xFFB3E5FC);
  static const Color darkBlue = Color(0xFF01579B);

  final _supa = Supabase.instance.client;

  bool _loading = true;
  String? _error;

  // Единая модель для отображения
  final List<_Notif> _items = [];

  @override
  void initState() {
    super.initState();
    _loadFromDb();
    _listenPush();
  }

  Future<void> _loadFromDb() async {
    final user = _supa.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'Не выполнен вход';
      });
      return;
    }
    try {
      setState(() => _loading = true);
      final rows = await _supa
          .from('notifications')
          .select('title, body, created_at, delivered')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final list = (rows as List)
          .map((e) => _Notif(
                title: (e['title'] ?? 'Уведомление') as String,
                body: (e['body'] ?? '') as String,
                createdAt: DateTime.parse(e['created_at'] as String).toLocal(),
                delivered: (e['delivered'] ?? false) as bool,
                source: _NotifSource.database,
              ))
          .toList();

      setState(() {
        _items
          ..clear()
          ..addAll(list);
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Ошибка загрузки: $e';
      });
    }
  }

  void _listenPush() {
    // Приложение на переднем плане
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      setState(() {
        _items.insert(
          0,
          _Notif(
            title: msg.notification?.title ?? 'Уведомление',
            body: msg.notification?.body ?? '',
            createdAt: DateTime.now(),
            delivered: true,
            source: _NotifSource.push,
          ),
        );
      });
    });

    // Открытие из пуша
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      setState(() {
        _items.insert(
          0,
          _Notif(
            title: msg.notification?.title ?? 'Уведомление',
            body: msg.notification?.body ?? '',
            createdAt: DateTime.now(),
            delivered: true,
            source: _NotifSource.push,
          ),
        );
      });
    });
  }

  String _fmt(DateTime t) => DateFormat('dd.MM.yyyy HH:mm').format(t);

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: darkBlue,
        scaffoldBackgroundColor: Colors.white,
        colorScheme:
            ColorScheme.fromSeed(seedColor: lightBlue, primary: darkBlue),
        appBarTheme: const AppBarTheme(
            backgroundColor: darkBlue, foregroundColor: Colors.white),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Уведомления'),
          actions: [
            IconButton(
              tooltip: 'Обновить',
              onPressed: _loading ? null : _loadFromDb,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _items.isEmpty
                    ? const Center(child: Text('Пока нет уведомлений'))
                    : RefreshIndicator(
                        onRefresh: _loadFromDb,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final n = _items[i];
                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: n.source == _NotifSource.push
                                      ? lightBlue.withOpacity(0.7)
                                      : Colors.transparent,
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: lightBlue.withOpacity(0.5),
                                  child: Icon(
                                    n.source == _NotifSource.push
                                        ? Icons.notifications_active
                                        : Icons.notifications,
                                    color: darkBlue,
                                  ),
                                ),
                                title: Text(
                                  n.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (n.body.isNotEmpty) Text(n.body),
                                    const SizedBox(height: 4),
                                    Text(
                                      _fmt(n.createdAt),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}

// — вспомогательная модель для единого списка
enum _NotifSource { database, push }

class _Notif {
  final String title;
  final String body;
  final DateTime createdAt;
  final bool delivered;
  final _NotifSource source;
  _Notif({
    required this.title,
    required this.body,
    required this.createdAt,
    required this.delivered,
    required this.source,
  });
}
