import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../errors/app_exception.dart';
import 'vad_detector.dart';

/// Yeni nesil ses kayıt servisi.
///
/// Mevcut [services/audio_service.dart]'tan farkları:
///   - Opus codec (raw WAV yerine ~10x daha küçük dosya)
///   - VOICE_COMMUNICATION audio source (Android echo/AGC otomatik)
///   - Amplitude stream broadcast (waveform UI'a beslenir)
///   - VAD entegrasyonu opsiyonel — caller [VadDetector] verirse otomatik
///     auto-stop tetikler
class AudioRecorderService {
  AudioRecorderService(this._recorder);
  final AudioRecorder _recorder;

  StreamSubscription<Amplitude>? _ampSub;
  String? _activeFilePath;

  final _amplitudeCtrl = StreamController<double>.broadcast();

  /// dBFS biriminde amplitude stream (waveform + VAD bunu dinler).
  Stream<double> get amplitudeStream => _amplitudeCtrl.stream;

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Kayda başla. Kayıt yolu döner; [stop] çağrıldığında bu yola kayıt biter.
  ///
  /// [vad] verilirse VAD event'lerine göre auto-stop tetiklenir; caller
  /// [VadDetector.events] stream'ini ayrıca dinlemelidir.
  Future<String> start({VadDetector? vad}) async {
    if (!await _recorder.hasPermission()) {
      throw const AuthException('Mikrofon izni reddedildi.');
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.opus';

    const config = RecordConfig(
      // Opus: Whisper bunu kabul ediyor, dosya ~%85 küçülüyor.
      encoder: AudioEncoder.opus,
      bitRate: 32000,
      sampleRate: 16000,
      numChannels: 1,
      // Android VOICE_COMMUNICATION: echo cancel + AGC + noise suppression
      // platform-level (cihaz destekliyorsa).
      androidConfig: AndroidRecordConfig(
        audioSource: AndroidAudioSource.voiceCommunication,
      ),
      iosConfig: IosRecordConfig(
        categoryOptions: [
          IosAudioCategoryOption.allowBluetooth,
          IosAudioCategoryOption.defaultToSpeaker,
        ],
      ),
    );

    await _recorder.start(config, path: path);
    _activeFilePath = path;

    vad?.reset();
    _ampSub = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 50))
        .listen((amp) {
      final db = amp.current;
      if (!_amplitudeCtrl.isClosed) _amplitudeCtrl.add(db);
      vad?.onAmplitude(db);
    });

    return path;
  }

  /// Kaydı durdur. Dönen yol [start]'tan dönen path ile aynı (veya null,
  /// platform kaydı başarısız ettiyse).
  Future<String?> stop() async {
    await _ampSub?.cancel();
    _ampSub = null;
    final path = await _recorder.stop();
    return path ?? _activeFilePath;
  }

  /// Aktif kaydı iptal eder ve dosyayı siler (gönderim öncesi cancel).
  Future<void> cancel() async {
    await _ampSub?.cancel();
    _ampSub = null;
    try {
      await _recorder.stop();
    } catch (_) {}
    final p = _activeFilePath;
    if (p != null) {
      try {
        final f = File(p);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
    _activeFilePath = null;
  }

  /// Belirli bir kayıt dosyasını sil (gönderim sonrası temizlik).
  Future<void> deleteRecording(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _ampSub?.cancel();
    await _amplitudeCtrl.close();
    await _recorder.dispose();
  }
}

final audioRecorderServiceProvider = Provider<AudioRecorderService>((ref) {
  final svc = AudioRecorderService(AudioRecorder());
  ref.onDispose(svc.dispose);
  return svc;
});
