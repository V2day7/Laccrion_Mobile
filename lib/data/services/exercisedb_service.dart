import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/env.dart';

class ExerciseDbExercise {
  final String id;
  final String name;
  final String? gifUrl;

  ExerciseDbExercise({
    required this.id,
    required this.name,
    required this.gifUrl,
  });
}

class ExerciseDbService {
  ExerciseDbService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  /// Searches ExerciseDB by name and returns the best match (first result).
  /// If nothing found, returns null.
  ///
  /// NOTE: ExerciseDB formats can vary. This parser tries common shapes:
  /// - {"data":[{...}]}
  /// - {"results":[{...}]}
  /// - [{...}]
  Future<ExerciseDbExercise?> searchBestMatchByName(String name) async {
    final base = Env.exerciseDbBaseUrl;
    if (base.isEmpty) return null;

    // Your base is: https://www.exercisedb.dev/api/v1
    // This endpoint path may differ; we try common patterns.
    final candidates = <Uri>[
      Uri.parse('$base/exercises/search?query=${Uri.encodeComponent(name)}'),
      Uri.parse('$base/exercises?search=${Uri.encodeComponent(name)}'),
      Uri.parse('$base/exercises/name/${Uri.encodeComponent(name)}'),
    ];

    for (final uri in candidates) {
      try {
        final res = await _client.get(uri);
        if (res.statusCode < 200 || res.statusCode >= 300) continue;

        final decoded = json.decode(res.body);
        final list = _extractList(decoded);
        if (list.isEmpty) continue;

        final first = list.first;
        final id = (first['id'] ?? first['exerciseId'] ?? first['_id'] ?? '')
            .toString();
        final exName =
            (first['name'] ?? first['exerciseName'] ?? first['title'] ?? name)
                .toString();
        final gif =
            (first['gifUrl'] ??
                    first['gif_url'] ??
                    first['gif'] ??
                    first['image'] ??
                    '')
                .toString();

        if (id.isEmpty) continue;

        return ExerciseDbExercise(
          id: id,
          name: exName,
          gifUrl: gif.isEmpty ? null : gif,
        );
      } catch (_) {
        // try next candidate endpoint
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _extractList(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'] ?? decoded['results'] ?? decoded['items'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return [];
  }
}
