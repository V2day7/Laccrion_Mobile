import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/body_metrics_repo.dart';
import '../../data/repositories/profile_repo.dart';
import '../../data/repositories/training_targets_repo.dart';

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
      return OnboardingController(
        profileRepo: ProfileRepo(),
        bodyRepo: BodyMetricsRepo(),
        targetsRepo: TrainingTargetsRepo(),
      );
    });

class OnboardingState {
  final bool loading;
  final String? error;
  final String trainingType; // 'strength' | 'cardio' | 'hybrid'

  const OnboardingState({
    this.loading = false,
    this.error,
    this.trainingType = 'strength',
  });

  OnboardingState copyWith({
    bool? loading,
    String? error,
    String? trainingType,
  }) {
    return OnboardingState(
      loading: loading ?? this.loading,
      error: error,
      trainingType: trainingType ?? this.trainingType,
    );
  }
}

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController({
    required this.profileRepo,
    required this.bodyRepo,
    required this.targetsRepo,
  }) : super(const OnboardingState());

  final ProfileRepo profileRepo;
  final BodyMetricsRepo bodyRepo;
  final TrainingTargetsRepo targetsRepo;

  void setTrainingTypeLocal(String trainingType) {
    state = state.copyWith(trainingType: trainingType, error: null);
  }

  Future<void> persistTrainingType() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in.');

      await profileRepo.updateTrainingType(
        userId: user.id,
        trainingType: state.trainingType,
      );
      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> submitBmiAndGenerateTargets({
    required double heightCm,
    required double weightKg,
  }) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('Not logged in.');

      final weekStart = _weekStartMonday(DateTime.now());
      final bmi = _calculateBmi(heightCm: heightCm, weightKg: weightKg);
      final bmiCategory = _bmiCategory(bmi);

      // 1) Save body metrics (weekly)
      await bodyRepo.upsertWeeklyMetrics(
        userId: user.id,
        weekStart: weekStart,
        weightKg: weightKg,
        heightCm: heightCm,
        bmi: bmi,
      );

      // 2) Update profile height (nice to keep)
      await profileRepo.updateHeightCm(userId: user.id, heightCm: heightCm);

      // 3) Generate + replace weekly targets
      final targets = _generateTargets(
        trainingType: state.trainingType,
        bmiCategory: bmiCategory,
      );

      await targetsRepo.replaceWeekTargets(
        userId: user.id,
        weekStart: weekStart,
        targets: targets,
      );

      // 4) Mark onboarding done
      await profileRepo.setOnboardingDone(userId: user.id, done: true);

      state = state.copyWith(loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
      rethrow;
    }
  }

  // ---------- Helpers ----------

  DateTime _weekStartMonday(DateTime now) {
    final d = DateTime(now.year, now.month, now.day);
    final weekday = d.weekday; // Mon=1..Sun=7
    final diff = weekday - DateTime.monday;
    return d.subtract(Duration(days: diff));
  }

  double _calculateBmi({required double heightCm, required double weightKg}) {
    final hm = heightCm / 100.0;
    return weightKg / (hm * hm);
  }

  String _bmiCategory(double bmi) {
    if (bmi < 18.5) return 'underweight';
    if (bmi < 25.0) return 'normal';
    if (bmi < 30.0) return 'overweight';
    return 'obese';
  }

  List<Map<String, dynamic>> _generateTargets({
    required String trainingType,
    required String bmiCategory,
  }) {
    // weight scaling suggestion (very simple, deterministic)
    double baseWeight;
    switch (bmiCategory) {
      case 'underweight':
        baseWeight = 10;
        break;
      case 'normal':
        baseWeight = 20;
        break;
      case 'overweight':
        baseWeight = 15;
        break;
      default: // obese
        baseWeight = 10;
    }

    if (trainingType == 'cardio') {
      return [
        _cardio('Jogging', minutes: 20, bmiCategory: bmiCategory),
        _cardio('Jump Rope', minutes: 10, bmiCategory: bmiCategory),
        _cardio('Brisk Walk', minutes: 30, bmiCategory: bmiCategory),
        _cardio('Cycling', minutes: 25, bmiCategory: bmiCategory),
        _core('Plank', sets: 3, reps: 30, weight: 0, bmiCategory: bmiCategory),
      ];
    }

    if (trainingType == 'hybrid') {
      return [
        _strength(
          'Squats',
          sets: 4,
          reps: 8,
          weight: baseWeight + 10,
          bmiCategory: bmiCategory,
        ),
        _strength(
          'Dumbbell Row',
          sets: 3,
          reps: 10,
          weight: baseWeight,
          bmiCategory: bmiCategory,
        ),
        _strength(
          'Push-ups',
          sets: 3,
          reps: 12,
          weight: 0,
          bmiCategory: bmiCategory,
        ),
        _cardio('Jogging', minutes: 15, bmiCategory: bmiCategory),
        _core('Plank', sets: 3, reps: 30, weight: 0, bmiCategory: bmiCategory),
        _strength(
          'Shoulder Press',
          sets: 3,
          reps: 10,
          weight: baseWeight,
          bmiCategory: bmiCategory,
        ),
      ];
    }

    // strength (default)
    return [
      _strength(
        'Bench Press',
        sets: 4,
        reps: 8,
        weight: baseWeight + 10,
        bmiCategory: bmiCategory,
      ),
      _strength(
        'Squats',
        sets: 4,
        reps: 8,
        weight: baseWeight + 15,
        bmiCategory: bmiCategory,
      ),
      _strength(
        'Deadlift',
        sets: 3,
        reps: 6,
        weight: baseWeight + 20,
        bmiCategory: bmiCategory,
      ),
      _strength(
        'Dumbbell Row',
        sets: 3,
        reps: 10,
        weight: baseWeight,
        bmiCategory: bmiCategory,
      ),
      _strength(
        'Push-ups',
        sets: 3,
        reps: 12,
        weight: 0,
        bmiCategory: bmiCategory,
      ),
      _core('Plank', sets: 3, reps: 30, weight: 0, bmiCategory: bmiCategory),
    ];
  }

  Map<String, dynamic> _strength(
    String name, {
    required int sets,
    required int reps,
    required double weight,
    required String bmiCategory,
  }) {
    return {
      'training_type': state.trainingType,
      'bmi_category': bmiCategory,
      'exercise_name': name,
      'target_sets': sets,
      'target_reps': reps,
      'target_weight': weight,
    };
  }

  Map<String, dynamic> _core(
    String name, {
    required int sets,
    required int reps,
    required double weight,
    required String bmiCategory,
  }) {
    return {
      'training_type': state.trainingType,
      'bmi_category': bmiCategory,
      'exercise_name': name,
      'target_sets': sets,
      'target_reps': reps,
      'target_weight': weight,
    };
  }

  Map<String, dynamic> _cardio(
    String name, {
    required int minutes,
    required String bmiCategory,
  }) {
    // For cardio we store minutes in target_reps (simple approach)
    return {
      'training_type': state.trainingType,
      'bmi_category': bmiCategory,
      'exercise_name': name,
      'target_sets': 1,
      'target_reps': minutes,
      'target_weight': 0,
    };
  }
}
