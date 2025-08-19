import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  static const Color lightBlue = Color(0xFFB3E5FC);
  static const Color darkBlue = Color(0xFF01579B);

  SupabaseClient get _supa => Supabase.instance.client;

  bool _isValidEmail(String s) =>
      RegExp(r'^[\w\.\-+]+@[\w\-]+\.[\w\.\-]+$').hasMatch(s);

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();

    if (!_isValidEmail(email)) {
      _snack('Введите корректный e‑mail');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _supa.auth.resetPasswordForEmail(
        email,
        // если используешь deep link — укажи редирект:
        // emailRedirectTo: 'onde://reset-password',
      );
      if (!mounted) return;
      _snack('Ссылка для восстановления отправлена на $email');
      Navigator.pop(context);
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Ошибка отправки письма: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

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
        appBar: AppBar(title: const Text('Восстановление пароля')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                'Введите e‑mail, и мы отправим ссылку для сброса пароля.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E‑mail'),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                onSubmitted: (_) => _sendResetLink(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendResetLink,
                  child: _isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Отправить ссылку'),
                ),
              ),
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
