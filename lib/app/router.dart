import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'splash_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/signup_page.dart';
import '../features/onboarding/training_type_page.dart';
import '../features/onboarding/bmi_setup_page.dart';
import '../features/home/home_page.dart';
import '../features/workout/log_workout_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (c, s) => const SplashPage()),
      GoRoute(path: '/login', builder: (c, s) => const LoginPage()),
      GoRoute(path: '/signup', builder: (c, s) => const SignupPage()),
      GoRoute(path: '/onboarding', builder: (c, s) => const TrainingTypePage()),
      GoRoute(path: '/onboarding/bmi', builder: (c, s) => const BmiSetupPage()),
      GoRoute(path: '/home', builder: (c, s) => const HomePage()),

      // Phase 3.1
      GoRoute(path: '/workout/log', builder: (c, s) => const LogWorkoutPage()),
    ],
  );
});
