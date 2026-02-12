import 'package:go_router/go_router.dart';
import '../app/splash_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/signup_page.dart';
import '../features/onboarding/training_type_page.dart';
import '../features/onboarding/bmi_setup_page.dart';
import '../features/home/home_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/signup', builder: (context, state) => const SignupPage()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const TrainingTypePage(),
    ),
    GoRoute(
      path: '/onboarding/bmi',
      builder: (context, state) => const BmiSetupPage(),
    ),
    GoRoute(path: '/home', builder: (context, state) => const HomePage()),
  ],
);
