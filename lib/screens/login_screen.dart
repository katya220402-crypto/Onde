import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:onde/screens/master_profile_screen.dart';
import 'package:onde/screens/client_profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;

  SupabaseClient get _supa => Supabase.instance.client;

  // ——— Логика после авторизации ———
  Future<void> _afterLogin(User user) async {
    final existing = await _supa
        .from('users')
        .select('role')
        .eq('id', user.id)
        .maybeSingle();
    if (existing == null) {
      await _supa.from('users').insert({
        'id': user.id,
        'email': user.email,
        'name': user.userMetadata?['name'] ?? user.email ?? user.id,
        'role': 'client',
      });
    }

    try {
      await FirebaseMessaging.instance.requestPermission();
      final t = await FirebaseMessaging.instance.getToken();
      if (t != null) {
        await _supa.from('users').update({'fcm_token': t}).eq('id', user.id);
      }
      FirebaseMessaging.instance.onTokenRefresh.listen(
        (nt) async =>
            _supa.from('users').update({'fcm_token': nt}).eq('id', user.id),
      );
    } catch (_) {}

    final me =
        await _supa.from('users').select('role').eq('id', user.id).single();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => (me['role'] == 'master')
            ? const MasterProfileScreen()
            : const ClientProfileScreen(),
      ),
      (_) => false,
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _supa.auth.signInWithOAuth(OAuthProvider.google);
      final user = _supa.auth.currentUser;
      if (user == null) throw 'Пользователь не найден после входа';
      await _afterLogin(user);
    } catch (e) {
      _snack('Ошибка входа Google: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithEmail() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) return _snack('Введите e-mail и пароль');
    setState(() => _isLoading = true);
    try {
      final res =
          await _supa.auth.signInWithPassword(email: email, password: pass);
      final user = res.user ?? _supa.auth.currentUser;
      if (user == null) throw 'Пользователь не найден после входа';
      await _afterLogin(user);
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Ошибка входа: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUpWithEmail() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) return _snack('Введите e-mail и пароль');
    setState(() => _isLoading = true);
    try {
      final res = await _supa.auth.signUp(email: email, password: pass);
      final user = res.user ?? _supa.auth.currentUser;
      if (user == null) {
        _snack('Проверьте почту и подтвердите аккаунт.');
      } else {
        await _afterLogin(user);
      }
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Ошибка регистрации: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return _snack('Введите e-mail для восстановления');
    try {
      await _supa.auth.resetPasswordForEmail(email);
      _snack('Ссылка на смену пароля отправлена на $email');
    } on AuthException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack('Не удалось отправить письмо: $e');
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const lightBlue = Color(0xFFB3E5FC);
    const darkBlue = Color(0xFF01579B);

    return Theme(
      data: ThemeData(
        primaryColor: darkBlue,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
            seedColor: lightBlue, primary: darkBlue, background: Colors.white),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: darkBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: darkBlue,
            side: BorderSide(color: darkBlue),
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
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Вход',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: darkBlue)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'E-mail'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscure
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: darkBlue),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signInWithEmail,
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Войти'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _isLoading ? null : _signUpWithEmail,
                      child: const Text('Зарегистрироваться'),
                    ),
                    TextButton(
                        onPressed: _isLoading ? null : _resetPassword,
                        child: const Text('Забыли пароль?')),
                    const SizedBox(height: 24),
                    Row(children: const [
                      Expanded(child: Divider()),
                      Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('или')),
                      Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      icon: const Icon(Icons.g_mobiledata),
                      label: const Text('Войти через Google'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
