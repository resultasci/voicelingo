import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// AuthException Supabase ve core/errors'tan geliyor; bizimkini kullanıyoruz.
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import '../../../core/errors/app_exception.dart';
import '../models/dynamic_scenario.dart';

/// Senaryo CRUD + AI ile dinamik senaryo üretimi.
///
/// AI çağrısı: `/ai-proxy/generate-scenario` (TS Edge function).
class ScenariosService {
  ScenariosService(this._db, this._dio, this._anonKey);

  final SupabaseClient _db;
  final Dio _dio;
  final String _anonKey;

  // ---------------------------------------------------------------------------
  // List
  // ---------------------------------------------------------------------------
  Future<List<DynamicScenario>> listVisible() async {
    final data = await _db
        .from('scenarios')
        .select()
        .order('created_at', ascending: false)
        .limit(100);
    return (data as List)
        .map((e) => DynamicScenario.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DynamicScenario>> listMine() async {
    final user = _db.auth.currentUser;
    if (user == null) return const [];
    final data = await _db
        .from('scenarios')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(100);
    return (data as List)
        .map((e) => DynamicScenario.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<DynamicScenario?> getById(String id) async {
    final row = await _db.from('scenarios').select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return DynamicScenario.fromMap(row);
  }

  /// İngilizce başlığına göre sistem senaryosu bul. Lesson runner içerikteki
  /// `scenario_title_en`'i resolve etmek için kullanılır. Birden fazla varsa
  /// ilk eşleşme döner.
  Future<DynamicScenario?> getByTitleEn(String titleEn) async {
    final row = await _db
        .from('scenarios')
        .select()
        .eq('title_en', titleEn)
        .limit(1)
        .maybeSingle();
    if (row == null) return null;
    return DynamicScenario.fromMap(row);
  }

  // ---------------------------------------------------------------------------
  // Generate + Save
  // ---------------------------------------------------------------------------
  Future<DynamicScenario> generate({
    required String description,
    required String category,
    required ScenarioDifficulty difficulty,
    required String userLevel,
    String targetLanguage = 'en',
  }) async {
    final session = _db.auth.currentSession;
    if (session == null) {
      throw const AuthException('Oturum bulunamadı.');
    }
    try {
      final res = await _dio.post(
        '/generate-scenario',
        data: {
          'description': description,
          'category': category,
          'difficulty': difficulty.code,
          'user_level': userLevel,
          'target_language': targetLanguage,
        },
        options: Options(headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'apikey': _anonKey,
          'Content-Type': 'application/json',
        }),
      );
      // The Dio client treats any status < 500 as "valid" (validateStatus), so
      // 4xx error bodies arrive here instead of throwing. Inspect the status +
      // `error` payload explicitly, otherwise a rate-limit/auth response would
      // be parsed into a blank "Untitled scenario".
      final status = res.statusCode ?? 0;
      final body = res.data;
      final serverError = (body is Map && body['error'] is String)
          ? body['error'] as String
          : null;
      if (status == 429) {
        throw RateLimitException(serverError ??
            'Günlük senaryo üretim limitine ulaştın. Yarın tekrar dene.');
      }
      if (status == 401) {
        throw AuthException(
            serverError ?? 'Oturum süren doldu, tekrar giriş yap.');
      }
      if (status < 200 || status >= 300 || serverError != null) {
        throw NetworkException(
            serverError ?? 'AI servisi geçersiz cevap döndü (HTTP $status).');
      }
      if (body is! Map<String, dynamic>) {
        throw const NetworkException('AI servisi geçersiz cevap döndü.');
      }
      return DynamicScenario(
        id: '',
        titleEn: body['title'] as String? ?? 'Untitled scenario',
        titleTr: body['title_tr'] as String?,
        setting: body['setting'] as String? ?? '',
        aiRole: body['ai_role'] as String? ?? '',
        userRole: body['user_role'] as String? ?? '',
        starterLine: body['starter_line'] as String?,
        keyPhrases: _coerceStringList(body['key_phrases']),
        objectives: _coerceStringList(body['objectives']),
        estimatedTurns: (body['estimated_turns'] as num?)?.toInt() ?? 6,
        difficulty: difficulty,
        category: category,
        iconCode: body['icon_code'] as String?,
        systemPrompt: body['system_prompt'] as String?,
        createdAt: DateTime.now(),
      );
    } on DioException catch (e) {
      // Reaches here for transport errors and 5xx (validateStatus blocks <500).
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const NetworkException('Bağlantı zaman aşımına uğradı.');
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkException(
            'Bağlantı sorunu. İnternetini kontrol et.');
      }
      final data = e.response?.data;
      final serverError = (data is Map && data['error'] is String)
          ? data['error'] as String
          : null;
      throw NetworkException(
          serverError ?? 'Senaryo üretim servisi şu an cevap vermiyor.');
    }
  }

  Future<DynamicScenario> save(DynamicScenario draft) async {
    final user = _db.auth.currentUser;
    if (user == null) throw const AuthException('Oturum bulunamadı.');

    final row = await _db
        .from('scenarios')
        .insert({
          'user_id': user.id,
          'is_public': false,
          'category': draft.category,
          'difficulty': draft.difficulty.code,
          'title_en': draft.titleEn,
          'title_tr': draft.titleTr,
          'setting': draft.setting,
          'ai_role': draft.aiRole,
          'user_role': draft.userRole,
          'starter_line': draft.starterLine,
          'key_phrases': draft.keyPhrases,
          'objectives': draft.objectives,
          'estimated_turns': draft.estimatedTurns,
          'icon_code': draft.iconCode,
          'system_prompt': draft.systemPrompt,
        })
        .select()
        .single();
    return DynamicScenario.fromMap(row);
  }

  Future<void> delete(String id) async {
    await _db.from('scenarios').delete().eq('id', id);
  }

  static List<String> _coerceStringList(dynamic raw) {
    if (raw is List) return raw.whereType<String>().toList();
    if (raw is String) {
      return raw
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return const [];
  }
}

final scenariosServiceProvider = Provider<ScenariosService>((ref) {
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null || supabaseUrl.isEmpty) {
    throw StateError('SUPABASE_URL .env\'de yok.');
  }
  if (anonKey == null || anonKey.isEmpty) {
    throw StateError('SUPABASE_ANON_KEY .env\'de yok.');
  }
  final dio = Dio(BaseOptions(
    baseUrl: '$supabaseUrl/functions/v1/ai-proxy',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    validateStatus: (s) => s != null && s < 500,
  ));
  return ScenariosService(Supabase.instance.client, dio, anonKey);
});

/// Tüm görülebilir senaryolar (sistem + kullanıcının kendi).
final visibleScenariosProvider =
    FutureProvider.autoDispose<List<DynamicScenario>>((ref) async {
  final svc = ref.watch(scenariosServiceProvider);
  return svc.listVisible();
});

/// Sadece kullanıcının kendi yarattığı senaryolar.
final myScenariosProvider =
    FutureProvider.autoDispose<List<DynamicScenario>>((ref) async {
  final svc = ref.watch(scenariosServiceProvider);
  return svc.listMine();
});
