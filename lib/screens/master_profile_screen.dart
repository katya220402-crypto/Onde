import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// фирменные цвета
import '../theme/colors.dart';

// экраны навигации (они у тебя уже есть)
import 'update_profile_screen.dart';
import 'services_list_screen.dart';
import 'work_schedule_screen.dart'; // экран «График работы»
import 'booking_calendar_screen.dart'; // «Календарь записей»
import 'analytics_screen.dart';
import 'slot_actions_screen.dart'; // «Слоты (генерация)»
import 'promo_list_screen.dart'; // «Акции и рассылки»
import 'login_screen.dart';

class MasterProfileScreen extends StatefulWidget {
  const MasterProfileScreen({super.key});

  @override
  State<MasterProfileScreen> createState() => _MasterProfileScreenState();
}

class _MasterProfileScreenState extends State<MasterProfileScreen> {
  final _supa = Supabase.instance.client;
  Map<String, dynamic>? _user;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final u = _supa.auth.currentUser;
      if (u == null) {
        setState(() {
          _loading = false;
          _error = 'Не выполнен вход';
        });
        return;
      }
      final row =
          await _supa.from('users').select().eq('id', u.id).maybeSingle();
      setState(() {
        _user = row;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Не удалось загрузить профиль';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = const TextStyle(
      color: AppColors.darkBlue,
      fontSize: 22,
      fontWeight: FontWeight.w700,
    );

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.lightBlue,
        title: const Text('Профиль мастера',
            style: TextStyle(color: AppColors.darkBlue)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: AppColors.darkBlue,
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  // карточка профиля
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.lightBlue,
                            backgroundImage: _user?['avatar_url'] != null
                                ? NetworkImage(_user!['avatar_url'])
                                : null,
                            child: _user?['avatar_url'] == null
                                ? const Icon(Icons.person,
                                    color: AppColors.darkBlue, size: 40)
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _user?['name'] ?? 'Имя не указано',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkBlue,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _user?['email'] ?? '',
                            style: const TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _user?['phone'] ?? '',
                            style: const TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.darkBlue,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const UpdateProfileScreen()),
                                );
                                _load(); // обновим данные после возврата
                              },
                              icon: const Icon(Icons.edit,
                                  color: AppColors.white),
                              label: const Text('Редактировать профиль',
                                  style: TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                          if (_error != null) ...[
                            const SizedBox(height: 8),
                            Text(_error!,
                                style: const TextStyle(color: Colors.red)),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Text('Работа', style: titleStyle),
                  const SizedBox(height: 8),

                  _Tile(
                    icon: Icons.settings_suggest,
                    title: 'Мои услуги',
                    subtitle: 'Создание, редактирование, цены и длительности',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ServicesListScreen()),
                    ),
                  ),
                  _Tile(
                    icon: Icons.schedule,
                    title: 'График работы',
                    subtitle: 'Шаблоны смен и исключения',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WorkScheduleScreen()),
                    ),
                  ),
                  _Tile(
                    icon: Icons.event_note,
                    title: 'Календарь записей',
                    subtitle: 'Кто и на какую услугу записан',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const BookingCalendarScreen()),
                    ),
                  ),
                  _Tile(
                    icon: Icons.bar_chart,
                    title: 'Аналитика',
                    subtitle: 'Выручка, загрузка, популярные услуги',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AnalyticsScreen()),
                    ),
                  ),
                  _Tile(
                    icon: Icons.auto_awesome, // «магическая палочка»
                    title: 'Слоты (генерация)',
                    subtitle: 'Сгенерировать слоты на две недели',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SlotActionsScreen()),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Маркетинг', style: titleStyle),
                  const SizedBox(height: 8),

                  _Tile(
                    icon: Icons.campaign_outlined,
                    title: 'Акции и рассылки',
                    subtitle: 'Создание акций и отправка клиентам',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PromoListScreen()),
                    ),
                  ),

                  const SizedBox(height: 24),
                  // выход
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      await _supa.auth.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                          (_) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Выйти'),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Красивый плиточный пункт
class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      color: AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.lightBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.darkBlue),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.darkBlue)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
