import 'dart:async';

import 'package:dio/dio.dart';

/// Tek bir Dio instance'ı için fabrika + ortak interceptor'lar.
///
/// `GeminiService` halen kendi private Dio'sunu kuruyor; bu sınıf gelecekte
/// (Faz 7+) yeni AI/REST endpoint'leri eklendikçe paylaşılan client haline
/// gelecek. Faz 1'de altyapı; mevcut servisler değiştirilmiyor.
class DioClientFactory {
  DioClientFactory({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 60),
  });

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;

  Dio build({Map<String, String>? headers}) {
    final dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      headers: headers,
      validateStatus: (s) => s != null && s < 500,
    ));

    dio.interceptors.add(_RetryInterceptor());
    return dio;
  }
}

/// 502/503/504 ve connection-error durumlarında 2 kez retry (exponential
/// backoff: 500ms, 1s). 4xx asla retry edilmez.
class _RetryInterceptor extends Interceptor {
  static const _maxRetries = 2;

  @override
  Future onError(DioException err, ErrorInterceptorHandler handler) async {
    final retryCount = (err.requestOptions.extra['retry'] as int?) ?? 0;
    if (retryCount >= _maxRetries) return handler.next(err);

    final shouldRetry = _isRetryable(err);
    if (!shouldRetry) return handler.next(err);

    final delay = Duration(milliseconds: 500 * (1 << retryCount));
    await Future.delayed(delay);

    final newOptions = err.requestOptions..extra['retry'] = retryCount + 1;

    try {
      final response = await Dio().fetch(newOptions);
      return handler.resolve(response);
    } catch (e) {
      return handler.next(err);
    }
  }

  bool _isRetryable(DioException err) {
    if (err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return true;
    }
    final status = err.response?.statusCode;
    if (status == null) return false;
    return status == 502 || status == 503 || status == 504;
  }
}
