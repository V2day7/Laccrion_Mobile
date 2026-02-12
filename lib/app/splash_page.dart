import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/providers/auth_providers.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  Widget build(BuildContext context) {
    Future.microtask(() async {
      final auth = ref.read(authControllerProvider.notifier);
      await auth.refreshProfile();
      if (!mounted) return;
      final state = ref.read(authControllerProvider);
      if (state.user == null) {
        context.go('/login');
        return;
      }
      final onboardingDone = state.profile?['onboarding_done'] == true;
      if (!onboardingDone) {
        context.go('/onboarding');
      } else {
        context.go('/home');
      }
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              FlutterLogo(size: 84),
              SizedBox(height: 12),
              Text(
                'Laccrion',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text('Loading your session...'),
              SizedBox(height: 18),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
