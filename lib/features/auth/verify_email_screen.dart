import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isChecking = true;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _checkVerification();
  }

  Future<void> _checkVerification() async {
  await FirebaseAuth.instance.currentUser?.reload();
  final user = FirebaseAuth.instance.currentUser;

  if (user != null && user.emailVerified) {
    if (mounted) {
      setState(() {
        _isVerified = true;
        _isChecking = false;
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted && user.emailVerified) {
        context.go('/module-selection');
      }
    }
  } else if (mounted && !_isVerified) {
    setState(() => _isChecking = false);
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isVerified) _checkVerification();
    });
  }
}

  Future<void> _resendEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await user.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Письмо отправлено повторно'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String message = 'Ошибка отправки';
        if (e.code == 'too-many-requests') {
          message = 'Слишком много запросов. Попробуйте через минуту';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(80),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.email_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Подтвердите email',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Мы отправили письмо на\n${FirebaseAuth.instance.currentUser?.email ?? ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.warning.withAlpha(20),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppTheme.warning.withAlpha(60),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: AppTheme.warning, size: 20),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Пожалуйста, проверьте почту и нажмите на ссылку для подтверждения\nТакже проверьте папку Спам',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  if (_isChecking)
                    const Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primary,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Проверка подтверждения...',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ],
                    )
                  else if (_isVerified)
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withAlpha(25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            size: 40,
                            color: AppTheme.success,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Email подтверждён!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.success,
                          ),
                        ),
                        SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _resendEmail,
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('Отправить повторно'),
                    ),
                  ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Выйти'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
