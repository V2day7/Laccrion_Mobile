import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
    final diff = d.weekday - DateTime.monday;
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
      if (user == null) throw Exception('Not logged in.');

      final prof = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

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

  ({int minXp, int maxXp}) _levelXpRange(int level) {
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

  @override
  Widget build(BuildContext context) {
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
                const Text(
                  'Failed to load home',
                  style: TextStyle(fontWeight: FontWeight.w800),
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
    final progress = _levelProgress(level, xp);
    final range = _levelXpRange(level);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laccrion'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
          IconButton(
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (!mounted) return;
              context.go('/login');
            },
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        child: const Icon(Icons.fitness_center),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      FilledButton(
                        onPressed: () => context.go('/workout/log'),
                        child: const Text('Start Today'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Progress',
                        style: TextStyle(fontWeight: FontWeight.w900),
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
                        'LVL $level • XP $xp (range ${range.minXp}–${range.maxXp})',
                        style: TextStyle(color: Colors.white.withOpacity(0.75)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weekly Targets',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 12),
                      if (_targets.isEmpty)
                        Text(
                          'No targets found for this week.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                          ),
                        )
                      else
                        ..._targets.take(5).map((t) {
                          final name = (t['exercise_name'] ?? '-') as String;
                          final sets = (t['target_sets'] ?? 0) as int;
                          final reps = (t['target_reps'] ?? 0) as int;
                          final weight = (t['target_weight'] ?? 0) as num;

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
                                          'Target: $sets × $reps • ${weight.toStringAsFixed(0)} kg',
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
                        }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
