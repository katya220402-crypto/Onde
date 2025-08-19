import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Навигация — экраны, которые у тебя уже есть
import 'update_profile_screen.dart';
import 'my_booking_screen.dart';
import 'notifications_screen.dart';
import 'help_screen.dart';
import 'login_screen.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _supa = Supabase.instance.client;

  Map<String, dynamic>? _userRow; // строка из таблицы users
  bool _loading = true;
  String? _error;

  // Удобные геттеры для фирменных цветов/темы
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  TextTheme get _text => Theme.of(context).textTheme;

  @override
  void initState() {
    super.initState();
    _loadUserRow();
  }

  Future<void> _loadUserRow() async {
    final user = _supa.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'Не выполнен вход';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res =
          await _supa.from('users').select().eq('id', user.id).maybeSingle();

      setState(() {
        _userRow = res;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Не удалось загрузить профиль';
        _loading = false;
      });
      debugPrint('load user error: $e');
    }
  }

  String _initials(String? name) {
    final n = (name ?? '').trim();
    if (n.isEmpty) return '🙂';
    final parts = n.split(RegExp(r'\s+'));
    final first = parts.first.characters.first;
    final second = parts.length > 1 ? parts.last.characters.first : '';
    return (first + second).toUpperCase();
  }

  Future<void> _signOut() async {
    await _supa.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = _text.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      color: _scheme.onSurface,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль клиента'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserRow,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      _ErrorCard(
                        message: _error!,
                        onRetry: _loadUserRow,
                      ),
                    ],
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Шапка с аватаром/инициалами и краткими данными
                      _ProfileHeader(
                        initials: _initials(_userRow?['name'] as String?),
                        name: (_userRow?['name'] as String?)?.trim().isEmpty ==
                                true
                            ? 'Без имени'
                            : (_userRow?['name'] as String?) ?? 'Без имени',
                        email: _userRow?['email'] as String? ?? '',
                        phone: _userRow?['phone'] as String? ??
                            'Телефон не указан',
                        scheme: _scheme,
                        text: _text,
                      ),

                      const SizedBox(height: 16),

                      // Кнопка "Редактировать профиль"
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit_rounded),
                          label: const Text('Редактировать профиль'),
                          onPressed: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) => const UpdateProfileScreen(),
                                  ),
                                )
                                .then((_) => _loadUserRow());
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Секция навигации
                      Text('Навигация', style: titleStyle),
                      const SizedBox(height: 8),
                      _NavTile(
                        icon: Icons.event_note_rounded,
                        title: 'Мои записи',
                        subtitle: 'Кто и на что вы записаны',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const MyBookingsScreen()),
                          );
                        },
                      ),
                      _NavTile(
                        icon: Icons.notifications_active_rounded,
                        title: 'Уведомления',
                        subtitle: 'Напоминания и системные оповещения',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const NotificationsScreen()),
                          );
                        },
                      ),
                      _NavTile(
                        icon: Icons.help_outline_rounded,
                        title: 'Помощь',
                        subtitle: 'Частые вопросы и поддержка',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const HelpScreen()),
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      // Выход
                      OutlinedButton.icon(
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Выйти'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _scheme.error,
                          side: BorderSide(
                              color: _scheme.error.withValues(alpha: 0.4)),
                        ),
                        onPressed: _signOut,
                      ),

                      const SizedBox(height: 12),
                      // Мелкая подпись о приватности
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          'ONDE • приватность и безопасность данных',
                          style: _text.bodySmall?.copyWith(
                            color: _scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

// ---------- Виджеты-помощники ----------

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.initials,
    required this.name,
    required this.email,
    required this.phone,
    required this.scheme,
    required this.text,
  });

  final String initials;
  final String name;
  final String email;
  final String phone;
  final ColorScheme scheme;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(
          color: scheme.primary.withValues(alpha: 0.15),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Аватар/инициалы
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: text.titleMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Имя + контакты
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  phone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: scheme.primary),
        ),
        title: Text(
          title,
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
        trailing: Icon(Icons.chevron_right_rounded,
            color: scheme.onSurface.withValues(alpha: 0.6)),
        onTap: onTap,
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.error.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ошибка',
              style: text.titleMedium?.copyWith(
                  color: scheme.onErrorContainer, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(message,
              style: text.bodyMedium?.copyWith(color: scheme.onErrorContainer)),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onRetry,
              child: const Text('Повторить'),
            ),
          ),
        ],
      ),
    );
  }
}
