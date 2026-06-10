import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Uygulama genelinde tek FlutterTts sarmalayıcısı.
///
/// Her ekran kendi instance'ını oluşturur (engine state'i platformda zaten
/// global; singleton handler çakışması yaratır). [init] idempotenttir ve
/// language/pitch/rate ayarlarını paralel uygular; [speak] çağrısı init'i
/// otomatik bekler, bu yüzden ayrıca init çağırmak zorunlu değildir.
///
/// Kullanıcının Ayarlar'daki TTS hızına saygı için kurulum noktası
/// `rate: ref.read(settingsServiceProvider).ttsRate` geçmelidir; geçilmezse
/// 0.5 varsayılanı kullanılır.
class TtsSpeaker {
  TtsSpeaker({String language = 'en-US', double pitch = 1.0, double? rate})
      : _language = language,
        _pitch = pitch,
        _rate = rate ?? 0.5;

  final FlutterTts _tts = FlutterTts();
  String _language;
  double _pitch;
  double _rate;
  Future<void>? _initFuture;

  /// Düşük seviye tüketiciler (ör. StreamingTtsBuffer) için ham engine.
  FlutterTts get raw => _tts;

  /// TTS metinlerinden okunamayan kısımları ayıklar: parantez/köşeli parantez
  /// içeriği ve İngilizce TTS'in telaffuz edemeyeceği semboller.
  static String sanitize(String text) => text
      .replaceAll(RegExp(r'\(.*?\)'), '')
      .replaceAll(RegExp(r'\[.*?\]'), '')
      .replaceAll(RegExp(r"[^a-zA-Z0-9\s'\-]"), '')
      .trim();

  Future<void> init() => _initFuture ??= _doInit();

  Future<void> _doInit() async {
    await Future.wait([
      _tts.setLanguage(_language),
      _tts.setPitch(_pitch),
      _tts.setSpeechRate(_rate),
    ]);
  }

  /// Önce çalan sesi durdurur, sonra konuşur. Best-effort: hatalar yutulur;
  /// engine hatalarını dinlemek için [setErrorHandler] kullanın.
  ///
  /// [sanitize] kelime/kısa metin telaffuzu içindir; cümle okurken prosodi
  /// için noktalamayı korumak adına `false` geçin.
  Future<void> speak(String text, {bool sanitize = true}) async {
    try {
      final spoken = sanitize ? TtsSpeaker.sanitize(text) : text.trim();
      if (spoken.isEmpty) return;
      await init();
      await _tts.stop();
      await _tts.speak(spoken);
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  /// Birden fazla ayarı tek seferde, paralel uygular (karakter değişimi vb.).
  Future<void> configure(
      {String? language, double? pitch, double? rate}) async {
    await init();
    await Future.wait([
      if (language != null && language != _language)
        _tts.setLanguage(_language = language),
      if (pitch != null && pitch != _pitch) _tts.setPitch(_pitch = pitch),
      if (rate != null && rate != _rate) _tts.setSpeechRate(_rate = rate),
    ]);
  }

  Future<void> setRate(double rate) => configure(rate: rate);

  Future<void> setAwaitSpeakCompletion(bool value) async {
    await _tts.awaitSpeakCompletion(value);
  }

  void setCompletionHandler(VoidCallback handler) =>
      _tts.setCompletionHandler(handler);

  void setErrorHandler(void Function(dynamic message) handler) =>
      _tts.setErrorHandler(handler);

  void dispose() {
    _tts.stop();
  }
}
