import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';

/// Generic read-through cache for JSON-shaped Supabase reads.
///
/// Pattern (per "stale-while-revalidate"):
///   1. Yield cached value immediately if present (instant UI).
///   2. Fire remote fetch in background.
///   3. Yield fresh value once it arrives, writing it back to the box.
///   4. On remote failure, the stale value already shown stays — graceful.
///
/// Callers convert between domain models and `Map<String, dynamic>` via
/// `toJson` / `fromJson` adapters they pass in.
///
/// Example:
/// ```dart
/// final stream = CachedRepository.streamSingle<UserProfile>(
///   box: Hive.box<Map>(HiveBoxes.profiles),
///   key: userId,
///   fromJson: UserProfile.fromMap,
///   toJson: (p) => p.toMap(),
///   fetchRemote: () => supabase.from('profiles')...,
/// );
/// stream.listen((profile) { ... });
/// ```
class CachedRepository {
  CachedRepository._();

  /// Stream a single entity. First event is cached (if any), second is fresh.
  /// If no cache and remote fails, the stream errors.
  static Stream<T> streamSingle<T>({
    required Box<Map> box,
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    required Future<T?> Function() fetchRemote,
    Duration maxAge = const Duration(hours: 24),
  }) async* {
    final cached = _readCached<T>(box, key, fromJson, maxAge);
    if (cached != null) yield cached;

    try {
      final fresh = await fetchRemote();
      if (fresh != null) {
        await box.put(key, _wrap(toJson(fresh)));
        yield fresh;
      }
    } catch (e) {
      // If cache was empty, propagate; otherwise the stale value is enough.
      if (cached == null) rethrow;
    }
  }

  /// One-shot fetch: returns cache immediately if present, otherwise blocks on
  /// remote. Background-refreshes the cache from remote after returning a hit.
  /// Useful for FutureProvider that does not care about the second emission.
  static Future<T> getOrFetch<T>({
    required Box<Map> box,
    required String key,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    required Future<T> Function() fetchRemote,
    Duration maxAge = const Duration(hours: 24),
  }) async {
    final cached = _readCached<T>(box, key, fromJson, maxAge);
    if (cached != null) {
      // Background refresh — never awaited, errors swallowed.
      unawaited(_refresh(box, key, toJson, fetchRemote));
      return cached;
    }
    final fresh = await fetchRemote();
    await box.put(key, _wrap(toJson(fresh)));
    return fresh;
  }

  /// Explicitly bust a cache entry (e.g. after a write).
  static Future<void> invalidate(Box<Map> box, String key) async {
    await box.delete(key);
  }

  static T? _readCached<T>(
    Box<Map> box,
    String key,
    T Function(Map<String, dynamic>) fromJson,
    Duration maxAge,
  ) {
    final raw = box.get(key);
    if (raw == null) return null;
    final cachedAt = raw['_cached_at'];
    if (cachedAt is int) {
      final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
      if (age > maxAge.inMilliseconds) return null;
    }
    final payload = raw['data'];
    if (payload is! Map) return null;
    try {
      return fromJson(Map<String, dynamic>.from(payload));
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _wrap(Map<String, dynamic> data) => {
        '_cached_at': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      };

  static Future<void> _refresh<T>(
    Box<Map> box,
    String key,
    Map<String, dynamic> Function(T) toJson,
    Future<T> Function() fetchRemote,
  ) async {
    try {
      final fresh = await fetchRemote();
      await box.put(key, _wrap(toJson(fresh)));
    } catch (_) {
      // Background refresh failures are silent by design.
    }
  }
}
