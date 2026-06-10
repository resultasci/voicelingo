import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide MultipartFile;

import '../errors/app_exception.dart';

// AiException artık core/errors hiyerarşisinde yaşar; tarihsel tüketiciler
// onu buradan import etmeye devam edebilsin.
export '../errors/app_exception.dart' show AiException;

/// Structured evaluation of a learner's spoken sentence.
///
/// Mirrors the JSON the `/evaluate` and `/turn` Edge Function endpoints return:
///   { correct, score, explanation, grammar_errors, cefr_band?, next_focus? }
///
/// `cefrBand` and `nextFocus` are nullable for backwards compat — older payloads
/// without them still parse cleanly.
class SpeechEvaluation {
  final String correct;
  final int score;
  final String explanation;
  final List<String> grammarErrors;
  final String? cefrBand;
  final String? nextFocus;

  const SpeechEvaluation({
    required this.correct,
    required this.score,
    required this.explanation,
    required this.grammarErrors,
    this.cefrBand,
    this.nextFocus,
  });

  factory SpeechEvaluation.fromJson(Map<String, dynamic> json) {
    final rawErrors = json['grammar_errors'];
    return SpeechEvaluation(
      correct: (json['correct'] as String?)?.trim() ?? '',
      score: _coerceInt(json['score']),
      explanation: (json['explanation'] as String?)?.trim() ?? '',
      grammarErrors:
          rawErrors is List ? rawErrors.whereType<String>().toList() : const [],
      cefrBand: (json['cefr_band'] as String?)?.trim().isNotEmpty == true
          ? (json['cefr_band'] as String).trim()
          : null,
      nextFocus: (json['next_focus'] as String?)?.trim().isNotEmpty == true
          ? (json['next_focus'] as String).trim()
          : null,
    );
  }

  static int _coerceInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }
}

/// Combined result of a `/turn` multimodal call: transcript + reply + evaluation
/// in a single AI round-trip.
class ConversationTurn {
  final String transcript;
  final String reply;
  final SpeechEvaluation? evaluation;

  const ConversationTurn({
    required this.transcript,
    required this.reply,
    this.evaluation,
  });

  factory ConversationTurn.fromJson(Map<String, dynamic> json) {
    final evalJson = json['evaluation'];
    return ConversationTurn(
      transcript: (json['transcript'] as String?)?.trim() ?? '',
      reply: (json['reply'] as String?)?.trim() ?? '',
      evaluation: evalJson is Map<String, dynamic>
          ? SpeechEvaluation.fromJson(evalJson)
          : null,
    );
  }
}

class WordEnrichment {
  final String? ipa;
  final String? example;
  const WordEnrichment({this.ipa, this.example});

  factory WordEnrichment.fromJson(Map<String, dynamic> json) => WordEnrichment(
        ipa: (json['ipa'] as String?)?.trim(),
        example: (json['example'] as String?)?.trim(),
      );
}

/// A single word/translation pair produced by topic-based AI generation.
/// `en` is the word in the learner's target language; `tr` its Turkish meaning.
class GeneratedWord {
  final String en;
  final String tr;
  const GeneratedWord(this.en, this.tr);
}

/// All AI calls go through the `ai-proxy` Supabase Edge Function. The Gemini
/// API key lives only as a Supabase function secret — never in the app bundle.
class GeminiService {
  final Dio _dio;
  final String _anonKey;

  GeminiService(String supabaseUrl, String anonKey)
      : _anonKey = anonKey,
        _dio = Dio(BaseOptions(
          baseUrl: '$supabaseUrl/functions/v1/ai-proxy',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 60),
          // Don't auto-throw for 4xx; we inspect the body manually.
          validateStatus: (s) => s != null && s < 500,
        ));

  Map<String, String> _headers({String? contentType}) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      throw AiException(401, 'Oturum bulunamadı, lütfen tekrar giriş yap.');
    }
    return {
      'Authorization': 'Bearer ${session.accessToken}',
      'apikey': _anonKey,
      if (contentType != null) 'Content-Type': contentType,
    };
  }

  Future<String> chat(List<Map<String, String>> messages,
      {String? systemPrompt}) async {
    try {
      final res = await _dio.post(
        '/chat',
        data: {
          'messages': messages,
          if (systemPrompt != null && systemPrompt.isNotEmpty)
            'system': systemPrompt,
        },
        options: Options(headers: _headers(contentType: 'application/json')),
      );
      _ensureOk(res);
      final body = res.data;
      if (body is Map && body['content'] is String) {
        return (body['content'] as String).trim();
      }
      throw AiException(502, 'AI servisinden geçersiz cevap alındı.');
    } on DioException catch (e) {
      throw _fromDio(e);
    }
  }

  /// One-shot multimodal turn: audio in, {transcript, reply, evaluation} out.
  /// Replaces the previous transcribe → chat → evaluate sequential chain with
  /// a single Gemini call (much lower latency).
  Future<ConversationTurn> turn(
    String filePath, {
    List<Map<String, String>> history = const [],
    String? systemPrompt,
    String cefr = 'A2',
  }) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: 'audio.opus'),
        if (history.isNotEmpty) 'history': jsonEncode(history),
        if (systemPrompt != null && systemPrompt.isNotEmpty)
          'system': systemPrompt,
        'cefr': cefr,
      });
      final res = await _dio.post(
        '/turn',
        data: form,
        options: Options(
          headers: _headers(),
          contentType: 'multipart/form-data',
        ),
      );
      _ensureOk(res);
      final parsed = _parseJsonBody(res.data);
      return ConversationTurn.fromJson(parsed);
    } on DioException catch (e) {
      throw _fromDio(e);
    }
  }

  /// Returns a parsed [SpeechEvaluation].
  Future<SpeechEvaluation> evaluateSpeech(String text) async {
    try {
      final res = await _dio.post(
        '/evaluate',
        data: {'text': text},
        options: Options(headers: _headers(contentType: 'application/json')),
      );
      _ensureOk(res);
      return SpeechEvaluation.fromJson(_parseJsonBody(res.data));
    } on DioException catch (e) {
      throw _fromDio(e);
    }
  }

  /// Returns the raw JSON string from the evaluator. Kept for legacy callers
  /// that need to persist the unparsed JSON blob.
  Future<String> evaluateSpeechRaw(String text) async {
    try {
      final res = await _dio.post(
        '/evaluate',
        data: {'text': text},
        options: Options(headers: _headers(contentType: 'application/json')),
      );
      _ensureOk(res);
      final body = res.data;
      if (body is String) return body;
      return jsonEncode(body);
    } on DioException catch (e) {
      throw _fromDio(e);
    }
  }

  /// Audio STT. Gemini multimodal — accepts the same Opus files we record.
  Future<String> transcribeAudio(String filePath,
      {String? targetLanguage}) async {
    try {
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath, filename: 'audio.opus'),
        if (targetLanguage != null && targetLanguage.isNotEmpty)
          'language': targetLanguage,
      });
      final res = await _dio.post(
        '/transcribe',
        data: form,
        options: Options(
          headers: _headers(),
          contentType: 'multipart/form-data',
        ),
      );
      _ensureOk(res);
      final body = res.data;
      if (body is Map && body['text'] is String) {
        return (body['text'] as String).trim();
      }
      throw AiException(502, 'Ses tanıma servisinden geçersiz cevap alındı.');
    } on DioException catch (e) {
      throw _fromDio(e);
    }
  }

  /// Asks the LLM for IPA + an example sentence for [word]. Returns null if
  /// the response is unparseable; callers should treat enrichment as optional.
  Future<WordEnrichment?> enrichWord(String word,
      {String targetLanguage = 'en'}) async {
    try {
      final res = await _dio.post(
        '/enrich',
        data: {'word': word, 'target_language': targetLanguage},
        options: Options(headers: _headers(contentType: 'application/json')),
      );
      _ensureOk(res);
      final body = res.data;
      Map<String, dynamic> parsed;
      if (body is Map<String, dynamic>) {
        parsed = body;
      } else if (body is String) {
        final decoded = jsonDecode(body);
        if (decoded is! Map<String, dynamic>) return null;
        parsed = decoded;
      } else {
        return null;
      }
      return WordEnrichment.fromJson(parsed);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _fromDio(e);
    }
  }

  /// Generates up to [count] topic-based word/translation pairs. Returns an
  /// empty list when the response is unparseable; throws [AiException] on
  /// transport/rate-limit errors so the UI can surface the (already localized)
  /// message — notably the 429 daily-limit text.
  Future<List<GeneratedWord>> generateWords(
    String topic, {
    int count = 10,
    String targetLanguage = 'en',
    String userLevel = 'A2',
  }) async {
    try {
      final res = await _dio.post(
        '/generate-words',
        data: {
          'topic': topic,
          'count': count,
          'target_language': targetLanguage,
          'user_level': userLevel,
        },
        options: Options(headers: _headers(contentType: 'application/json')),
      );
      _ensureOk(res);
      final parsed = _parseJsonBody(res.data);
      final raw = parsed['words'];
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((m) => GeneratedWord(
                (m['en'] as String?)?.trim() ?? '',
                (m['tr'] as String?)?.trim() ?? '',
              ))
          .where((w) => w.en.isNotEmpty && w.tr.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw _fromDio(e);
    }
  }

  Map<String, dynamic> _parseJsonBody(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is String) {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
    }
    throw AiException(502, 'AI servisi geçersiz JSON döndü.');
  }

  void _ensureOk(Response res) {
    final status = res.statusCode ?? 0;
    if (status >= 200 && status < 300) return;

    String? serverMessage;
    final body = res.data;
    if (body is Map && body['error'] is String) {
      serverMessage = body['error'] as String;
    } else if (body is String && body.isNotEmpty) {
      serverMessage = body;
    }

    String msg;
    if (status == 401) {
      msg = serverMessage ?? 'Oturum süren doldu, lütfen tekrar giriş yap.';
    } else if (status == 429) {
      msg = serverMessage ??
          'Günlük kullanım limitine ulaştın. Yarın tekrar dene.';
    } else if (status == 413) {
      msg = serverMessage ?? 'Ses kaydı çok uzun. Daha kısa bir kayıt dene.';
    } else if (status == 502) {
      msg = serverMessage ?? 'AI servisi şu an cevap vermiyor.';
    } else {
      msg = serverMessage ?? 'Beklenmeyen bir hata oluştu.';
    }
    throw AiException(status, msg);
  }

  AiException _fromDio(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return AiException(0, 'Bağlantı zaman aşımına uğradı.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return AiException(0, 'Bağlantı sorunu. İnternetini kontrol et.');
    }
    final res = e.response;
    if (res != null) {
      try {
        _ensureOk(res);
      } on AiException catch (ai) {
        return ai;
      }
    }
    return AiException(0, 'Beklenmeyen bir hata oluştu.');
  }
}

/// BCP-47 language code for the user's target_language profile field.
/// Callers need it for Gemini STT language hints.
String? bcp47ForTargetLanguage(String? raw) {
  if (raw == null) return null;
  final v = raw.trim().toLowerCase();
  if (v.isEmpty) return null;
  const known = {
    'en',
    'tr',
    'de',
    'fr',
    'es',
    'it',
    'pt',
    'ru',
    'ja',
    'ko',
    'zh',
    'ar',
    'nl',
    'pl',
    'sv',
    'fi',
    'da',
    'no',
    'cs',
    'el',
    'hu',
    'ro',
  };
  if (known.contains(v)) return v;
  return null;
}

/// Riverpod provider — single AI surface, used everywhere.
final geminiServiceProvider = Provider<GeminiService>((ref) {
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final anonKey = dotenv.env['SUPABASE_ANON_KEY'];
  if (supabaseUrl == null || supabaseUrl.isEmpty) {
    throw StateError('SUPABASE_URL missing from .env');
  }
  if (anonKey == null || anonKey.isEmpty) {
    throw StateError('SUPABASE_ANON_KEY missing from .env');
  }
  return GeminiService(supabaseUrl, anonKey);
});
