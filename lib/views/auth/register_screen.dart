import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final age = int.tryParse(_ageController.text);
    if (age == null || age < 5 || age > 100) {
      _showSnackBar('Введите корректный возраст (5-100)');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await credential.user?.updateDisplayName(_nameController.text);
      await credential.user?.sendEmailVerification();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'name': _nameController.text,
        'age': age,
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'totalTests': 0,
        'averageScore': 0,
      });

      if (mounted) context.go('/verify-email');
    } on FirebaseAuthException catch (e) {
      String message = 'Ошибка регистрации';
      if (e.code == 'email-already-in-use') {
        message = 'Email уже используется';
      } else if (e.code == 'invalid-email') {
        message = 'Неверный формат email';
      } else if (e.code == 'weak-password') {
        message = 'Слишком слабый пароль';
      }
      if (mounted) _showSnackBar(message);
    } catch (e) {
      if (mounted) _showSnackBar('Произошла ошибка');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.background, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/icon_person.png',
                          width: 96,
                          height: 96,
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Создать аккаунт',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Заполните данные для регистрации',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Имя',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Введите имя';
                            if (v.trim().length < 2) return 'Имя должно содержать минимум 2 символа';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _ageController,
                          decoration: const InputDecoration(
                            labelText: 'Возраст',
                            prefixIcon: Icon(Icons.cake_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Введите возраст';
                            final age = int.tryParse(v);
                            if (age == null || age < 5 || age > 100) {
                              return 'Введите корректный возраст';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Введите email';
                            if (!v.contains('@')) return 'Неверный формат email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Пароль',
                            prefixIcon: const Icon(Icons.lock_outlined),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Введите пароль';
                            if (v.length < 6) return 'Минимум 6 символов';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Подтвердите пароль',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          obscureText: _obscurePassword,
                          validator: (v) {
                            if (v != _passwordController.text) {
                              return 'Пароли не совпадают';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _register,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    'Зарегистрироваться',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Уже есть аккаунт? ',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                            TextButton(
                              onPressed: () => context.pop(),
                              child: const Text(
                                'Войти',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
