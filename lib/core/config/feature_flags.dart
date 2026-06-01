import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Runtime-toggleable behavior. Sourced from a single `app_config` row in
/// Supabase so we can flip a flag without shipping a new build — useful for
/// rolling back risky features (Gemini /turn, streaming TTS, LazyIndexedStack)
/// if production telemetry goes bad.
///
/// Defaults are chosen so the **new** behavior is on. If `app_config` is
/// missing or unreachable, callers get those defaults; we never block on the
/// network. A read failure simply falls back to defaults.
class FeatureFlags {
  final bool useTurnEndpoint;
  final bool useStreamingTts;
  final bool useLazyStack;
  final bool useContentTreeRpc;

  const FeatureFlags({
    this.useTurnEndpoint = true,
    this.useStreamingTts = true,
    this.useLazyStack = true,
    this.useContentTreeRpc = true,
  });

  static const defaults = FeatureFlags();

  factory FeatureFlags.fromMap(Map<String, dynamic> map) => FeatureFlags(
        useTurnEndpoint:
            _asBool(map['use_turn_endpoint'], defaults.useTurnEndpoint),
        useStreamingTts:
            _asBool(map['use_streaming_tts'], defaults.useStreamingTts),
        useLazyStack: _asBool(map['use_lazy_stack'], defaults.useLazyStack),
        useContentTreeRpc:
            _asBool(map['use_content_tree_rpc'], defaults.useContentTreeRpc),
      );

  static bool _asBool(dynamic v, bool fallback) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    if (v is num) return v != 0;
    return fallback;
  }
}

/// Cached, never-blocking. Read once at app start; UI subscribes via Riverpod.
/// If the table or row doesn't exist, we silently return defaults so a fresh
/// project can run without a config row.
final featureFlagsProvider = FutureProvider<FeatureFlags>((ref) async {
  try {
    final row = await Supabase.instance.client
        .from('app_config')
        .select(
            'use_turn_endpoint,use_streaming_tts,use_lazy_stack,use_content_tree_rpc')
        .eq('id', 1)
        .maybeSingle();
    if (row == null) return FeatureFlags.defaults;
    return FeatureFlags.fromMap(row);
  } catch (_) {
    return FeatureFlags.defaults;
  }
});

/// Synchronous access to the resolved flags. Mirrors the async provider once
/// it settles. Falls back to defaults on first frame.
final resolvedFeatureFlagsProvider = Provider<FeatureFlags>((ref) {
  final async = ref.watch(featureFlagsProvider);
  return async.maybeWhen(
    data: (f) => f,
    orElse: () => FeatureFlags.defaults,
  );
});
