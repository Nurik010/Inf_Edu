import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../views/auth/login_screen.dart';
import '../views/auth/register_screen.dart';
import '../views/auth/verify_email_screen.dart';
import '../views/screens/completed_topics_screen.dart';
import '../views/screens/edit_profile.dart';
import '../views/screens/home_screen.dart';
import '../views/screens/module_selection_screen.dart';
import '../views/screens/profile_screen.dart';
import '../views/screens/stats_screen.dart';
import '../views/screens/test_screen.dart';
import '../views/screens/final_test_screen.dart';
import '../views/splash/splash_screen.dart';
import '../viewmodels/auth_viewmodel.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      if (authState.isLoading || authState.isRefreshing) return null;

      final user = authState.value;
      final isLoggedIn = user != null;
      final isEmailVerified = user?.emailVerified ??
          FirebaseAuth.instance.currentUser?.emailVerified ?? false;
      final location = state.matchedLocation;

      if (location == '/splash') {
        if (!isLoggedIn) return '/login';
        if (!isEmailVerified) return '/verify-email';
        return '/home';
      }

      if (!isLoggedIn && location != '/login' && location != '/register') {
        return '/login';
      }

      if (isLoggedIn && !isEmailVerified && location != '/verify-email') {
        return '/verify-email';
      }

      if (isLoggedIn && isEmailVerified && location == '/verify-email') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/verify-email',
        builder: (_, __) => const VerifyEmailScreen(),
      ),
      GoRoute(
        path: '/module-selection',
        builder: (_, __) => const ModuleSelectionScreen(),
      ),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(
        path: '/edit-profile',
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/completed-topics',
        builder: (_, __) => const CompletedTopicsScreen(),
      ),
      GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
      GoRoute(path: '/test', builder: (_, __) => const TestScreen()),
      GoRoute(
        path: '/final-test',
        builder: (_, __) => const FinalTestScreen(),
      ),
    ],
  );
});
