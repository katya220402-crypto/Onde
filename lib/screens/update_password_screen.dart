import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdatePasswordScreen extends StatefulWidget {
  const UpdatePasswordScreen({super.key});

  @override
  State<UpdatePasswordScreen> createState() => _UpdatePasswordScreenState();
}

class _UpdatePasswordScreenState extends State<UpdatePasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  static const Color lightBlue = Color(0xFFB3E5FC);
  static const Color darkBlue = Color(0xFF01579B);

  Future<void> _updatePassword() async {
    final newPassword = _passwordController.text.trim();
    if (newPassword.length < 6) {
      _snack('Пароль должен быть не меньше 6 символов');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (response.user != null) {
        _snack('Пароль обновлён');
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      } else {
        _snack('Ошибка при обновлении');
      }
    } catch (e) {
      _snack('Ошибка: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: darkBlue,
        scaffoldBackgroundColor: Colors.white,
        colorScheme:
            ColorScheme.fromSeed(seedColor: lightBlue, primary: darkBlue),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: darkBlue, width: 2),
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Обновление пароля'),
          backgroundColor: darkBlue,
          foregroundColor: Colors.white,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Введите новый пароль',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Новый пароль'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _updatePassword,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Сохранить'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
