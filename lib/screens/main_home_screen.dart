import 'package:flutter/material.dart';
import 'package:onde/theme/colors.dart';
import 'package:onde/screens/service_selection_screen.dart';

class MainHomeScreen extends StatelessWidget {
  const MainHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.darkBlue,
        foregroundColor: AppColors.white,
        title: const Text('Главная'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderBanner(onTapBook: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ServiceSelectionScreen()),
              );
            }),
            const SizedBox(height: 16),
            _SectionTitle('Новости'),
            const SizedBox(height: 8),
            _NewsCard(
                title: 'Мы открылись!',
                subtitle: 'Теперь вы можете записаться онлайн.'),
            _NewsCard(
                title: 'Новинка!',
                subtitle: 'Свадебный макияж со скидкой 10% до конца месяца.'),
            const SizedBox(height: 20),
            _SectionTitle('О салоне'),
            const SizedBox(height: 8),
            _InfoCard(
              text:
                  'Onde — это уютное место с вниманием к деталям. Мы бережно подбираем услуги под ваш образ и настроение.',
            ),
            const SizedBox(height: 20),
            _SectionTitle('Наши мастера'),
            const SizedBox(height: 8),
            _MasterTile(name: 'Екатерина', role: 'Визажист и стилист'),
            _MasterTile(name: 'Дарья', role: 'Парикмахер‑колорист'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const ServiceSelectionScreen()),
                ),
                icon: const Icon(Icons.event_available),
                label: const Text('Записаться онлайн'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.darkBlue,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ——— Виджеты разделов ———

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black87),
    );
  }
}

class _HeaderBanner extends StatelessWidget {
  final VoidCallback onTapBook;
  const _HeaderBanner({required this.onTapBook});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDEEAF6), Color(0xFFE3F1F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.lightBlue.withValues(alpha: 0.6),
            child: const Icon(Icons.waves, color: AppColors.darkBlue, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Onde — мир красоты и лёгкости',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4),
                Text(
                  'Запишитесь за пару кликов — быстро и удобно.',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onTapBook,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.darkBlue,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Записаться'),
          ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  const _NewsCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        leading: CircleAvatar(
          backgroundColor: AppColors.lightBlue.withValues(alpha: 0.5),
          child: const Icon(Icons.campaign, color: AppColors.darkBlue),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String text;
  const _InfoCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text, style: const TextStyle(height: 1.4)),
      ),
    );
  }
}

class _MasterTile extends StatelessWidget {
  final String name;
  final String role;
  const _MasterTile({required this.name, required this.role});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.lightBlue.withValues(alpha: 0.5),
        child: const Icon(Icons.person, color: AppColors.darkBlue),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(role),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    );
  }
}
