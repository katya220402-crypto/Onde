import 'package:flutter/material.dart';

// фирменные цвета
import 'package:onde/theme/colors.dart';

import 'package:onde/screens/client_profile_screen.dart';
import 'package:onde/screens/master_profile_screen.dart';
import 'package:onde/screens/service_selection_screen.dart';
import 'package:onde/screens/master_bookings_screen.dart';
import 'package:onde/screens/main_home_screen.dart';

class MainScreen extends StatefulWidget {
  final String role; // 'client' или 'master'
  const MainScreen({super.key, required this.role});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  // стартуем с профиля как с "домашней" страницы
  int _selectedIndex = 2;
  late final bool isMaster;

  // Плавная анимация смены вкладок
  late final AnimationController _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 220));
  late final Animation<double> _fade =
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeInOut);

  @override
  void initState() {
    super.initState();
    isMaster = widget.role == 'master';
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    setState(() {
      _selectedIndex = index;
      _fadeCtrl
        ..reset()
        ..forward();
    });
  }

  // Порядок экранов жёстко соответствует вкладкам:
  // [0] Главная (новости), [1] Записи (мастер/клиент), [2] Профиль (мастер/клиент)
  List<Widget> get _pages => [
        const MainHomeScreen(),
        isMaster
            ? const MasterBookingsScreen()
            : const ServiceSelectionScreen(),
        isMaster ? const MasterProfileScreen() : const ClientProfileScreen(),
      ];

  @override
  Widget build(BuildContext context) {
    final pages = _pages;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: FadeTransition(
        opacity: _fade,
        child: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: AppColors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.darkBlue,
            unselectedItemColor: Colors.grey,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Главная',
              ),
              BottomNavigationBarItem(
                icon: Icon(isMaster ? Icons.calendar_month : Icons.event),
                label: 'Записи',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Профиль',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
