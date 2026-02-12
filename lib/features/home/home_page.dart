import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _targets = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  DateTime _weekStartMonday(DateTime now) {
    final d = DateTime(now.year, now.month, now.day);
    final diff = d.weekday - DateTime.monday; // Mon=1..Sun=7
    return d.subtract(Duration(days: diff));
  }

  String _toDateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('Not logged in.');
      }

      // Profile
      final prof = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      // Weekly targets
      final weekStart = _weekStartMonday(DateTime.now());
      final weekStartStr = _toDateOnly(weekStart);

      final targets = await client
          .from('training_targets')
          .select()
          .eq('user_id', user.id)
          .eq('week_start', weekStartStr)
          .order('created_at', ascending: true);

      setState(() {
        _profile = (prof ?? {}) as Map<String, dynamic>;
        _targets = (targets as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // Simple XP-to-level preview (matches your early ranges roughly, without changing DB)
  // You can replace this later with your real full mapping logic.
  ({int minXp, int maxXp}) _levelXpRange(int level) {
    // You gave:
    // L1 0-99
    // L2 100-249
    // L3 250-499
    // L4 500-999
    // L5 1000-1999
    // We'll clamp at L5 for preview.
    if (level <= 1) return (minXp: 0, maxXp: 99);
    if (level == 2) return (minXp: 100, maxXp: 249);
    if (level == 3) return (minXp: 250, maxXp: 499);
    if (level == 4) return (minXp: 500, maxXp: 999);
    return (minXp: 1000, maxXp: 1999);
  }

  double _levelProgress(int level, int xp) {
    final r = _levelXpRange(level);
    final span = (r.maxXp - r.minXp + 1).toDouble();
    final inside = (xp - r.minXp).clamp(0, r.maxXp - r.minXp + 1).toDouble();
    return span <= 0 ? 0 : (inside / span).clamp(0.0, 1.0);
  }

  String _prettyTraining(String? t) {
    switch ((t ?? '').toLowerCase()) {
      case 'strength':
        return 'STRENGTH';
      case 'cardio':
        return 'CARDIO';
      case 'hybrid':
        return 'HYBRID';
      default:
        return 'STRENGTH';
    }
  }

  IconData _trainingIcon(String? t) {
    switch ((t ?? '').toLowerCase()) {
      case 'cardio':
        return Icons.directions_run;
      case 'hybrid':
        return Icons.bolt;
      default:
        return Icons.fitness_center;
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    // router splash should redirect next refresh, but for safety:
    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Laccrion')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Laccrion')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to load home',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cs.error,
                  ),
                ),
                const SizedBox(height: 10),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final level = (_profile?['level'] ?? 1) as int;
    final xp = (_profile?['xp'] ?? 0) as int;
    final trainingType = _profile?['training_type'] as String?;
    final trainingLabel = _prettyTraining(trainingType);

    final progress = _levelProgress(level, xp);
    final range = _levelXpRange(level);

    final weekStart = _weekStartMonday(DateTime.now());
    final weekStartStr = _toDateOnly(weekStart);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laccrion'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        child: Icon(_trainingIcon(trainingType)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dashboard',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Training: $trainingLabel',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.75),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'LVL $level',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'XP $xp',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // XP Progress card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Level $level progress: $xp XP (range ${range.minXp}–${range.maxXp})',
                        style: TextStyle(color: Colors.white.withOpacity(0.75)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tip: You can add XP after finishing a workout later (Phase 3).',
                        style: TextStyle(color: Colors.white.withOpacity(0.55)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Weekly Targets
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly Targets',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Week of $weekStartStr',
                        style: TextStyle(color: Colors.white.withOpacity(0.65)),
                      ),
                      const SizedBox(height: 12),

                      if (_targets.isEmpty)
                        Text(
                          'No targets found for this week.\nGo to onboarding to generate targets.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                          ),
                        )
                      else
                        Column(
                          children: [
                            ..._targets.take(5).map((t) {
                              final name =
                                  (t['exercise_name'] ?? '-') as String;
                              final sets = (t['target_sets'] ?? 0) as int;
                              final reps = (t['target_reps'] ?? 0) as int;
                              final weight = (t['target_weight'] ?? 0) as num;

                              // cardio uses reps as minutes (our Phase 2 rule)
                              final isCardio = trainingLabel == 'CARDIO';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.06),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.check_circle_outline),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              isCardio
                                                  ? 'Target: $reps min'
                                                  : 'Target: $sets × $reps  •  ${weight.toStringAsFixed(0)} kg',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.75,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            if (_targets.length > 5)
                              Text(
                                '+ ${_targets.length - 5} more targets',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                ),
                              ),
                          ],
                        ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // For now, return to onboarding if they want to regenerate.
                            // Later we can build a full Targets page with navigation.
                            Navigator.of(context).pushNamed('/onboarding');
                          },
                          icon: const Icon(Icons.tune),
                          label: const Text('Adjust / Regenerate Targets'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Phase 2 complete ✅\nNext: workout logging + XP update',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.55)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
