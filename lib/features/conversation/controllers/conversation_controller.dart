import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_character.dart';
import '../../../core/ai/characters.dart';
import '../../../core/ai/gemini_service.dart';
import '../../../core/audio/amplitude_history.dart';
import '../../../core/audio/audio_recorder_service.dart';
import '../../../core/audio/tts_speaker.dart';
import '../../../core/audio/vad_detector.dart';
import '../../../core/config/feature_flags.dart';
import '../../../core/models/scenario.dart';
import '../../../core/perf/perf_trace.dart';
import '../../../core/services/settings_service.dart';
import '../../../features/profile/providers/profile_provider.dart';
import '../../gamification/models/daily_quest.dart';
import '../../gamification/providers/gamification_providers.dart';
import '../models/conversation_message.dart';
import '../services/characters_service.dart';
import '../services/conversation_repository.dart';
import '../services/streaming_tts_buffer.dart';

/// Konuşma ekranı hata kodları — controller BuildContext tutmadığı için
/// lokalize metne çeviri widget tarafında (build sırasında) yapılır.
enum ConvError {
  micPermission,
  micOpen,
  recordFailed,
  audioProcess,
  noSpeech,
  ttsInit,
  tts,
  speak,
  generic,
}

/// Konuşma ekranının tüm iş mantığı: ses kaydı + VAD, Gemini turn/chat,
/// TTS çalma, persistence ve XP/quest yan etkileri.
///
/// UI'da kalanlar: animasyonlar (pulse), scroll, haptics, navigation ve
/// lokalizasyon. Mesaj nesneleri yerinde mutate edilir (optimistic UI),
/// bu yüzden state bilinçli olarak immutable değildir.
class ConversationController extends ChangeNotifier {
  ConversationController({
    required T Function<T>(ProviderListenable<T>) read,
    required void Function(ProviderOrFamily) invalidate,
    required this.scenario,
    required this.isEmbedded,
    required String Function() greetingText,
    required String Function() replyFailedText,
    this.onReplyError,
  })  : _read = read,
        _invalidate = invalidate,
        _greetingText = greetingText,
        _replyFailedText = replyFailedText,
        _audioSvc = read(audioRecorderServiceProvider),
        _ttsRate = read(settingsServiceProvider).ttsRate;

  final T Function<T>(ProviderListenable<T>) _read;
  final void Function(ProviderOrFamily) _invalidate;
  final ScenarioModel? scenario;

  /// HomeScreen'in Practice sekmesine gömülü instance — auto-greet yapmaz
  /// (kullanıcı başka sekmedeyken ses çalmasın).
  final bool isEmbedded;

  final String Function() _greetingText;
  final String Function() _replyFailedText;

  /// AI cevabı alınamadığında widget'ın snackbar göstermesi için.
  final void Function(String detail)? onReplyError;

  final AudioRecorderService _audioSvc;
  late final TtsSpeaker _tts = TtsSpeaker(rate: _ttsRate);
  final AmplitudeHistory amplitudes = AmplitudeHistory();

  VadDetector? _vad;
  StreamSubscription<VadEvent>? _vadSub;
  StreamSubscription<double>? _amplitudeSub;
  StreamingTtsBuffer? _activeBuffer;
  bool _disposed = false;

  /// Status ayrı kanaldan yayınlanır: tur başına 4+ kez değişir ve input bar
  /// gibi sıcak bölgeler yalnız bunu dinler. Mesaj listesi / karakter /
  /// ttsRate gibi yapısal değişiklikler [notifyListeners] kanalında kalır
  /// ([amplitudes] ValueNotifier'ı ile aynı desen).
  final ValueNotifier<ConvStatus> statusNotifier =
      ValueNotifier(ConvStatus.idle);
  ConvStatus get status => statusNotifier.value;

  ConvError? _errorCode;
  ConvError? get errorCode => _errorCode;
  String? _errorDetail;
  String? get errorDetail => _errorDetail;

  final List<ConversationMessage> _messages = [];
  List<ConversationMessage> get messages => _messages;

  bool _ttsInitialized = false;
  String? _conversationId;
  bool _conversationCreated = false;
  String? _lastUserText;

  double _ttsRate;
  double get ttsRate => _ttsRate;

  AICharacter _character = AICharacters.defaultCharacter;
  AICharacter get character => _character;

  bool _handsFreeMode = false;
  bool get handsFreeMode => _handsFreeMode;

  bool get canToggleMic =>
      status == ConvStatus.ready || status == ConvStatus.listening;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _setStatus(ConvStatus s) {
    if (_disposed) return;
    statusNotifier.value = s;
  }

  void _setError(ConvError code, [String? detail]) {
    if (_disposed) return;
    // Hata alanları status bildiriminden ÖNCE set edilmeli — listener'lar
    // tetiklendiğinde errorCode/errorDetail okunabilir olmalı.
    _errorCode = code;
    _errorDetail = detail;
    if (statusNotifier.value == ConvStatus.error) {
      // Aynı değere set ValueNotifier'ı tetiklemez; ardışık ikinci hatada
      // yeni detayın ekrana yansıması için genel kanaldan duyur.
      _notify();
    } else {
      statusNotifier.value = ConvStatus.error;
    }
  }

  // ---------------------------------------------------------------------------
  // Init / lifecycle
  // ---------------------------------------------------------------------------

  /// Init sırası: önce kullanıcının seçili karakterini yükle, sonra TTS'i
  /// o karakterin sesiyle ayarla, sonra conversation row'unu yarat.
  Future<void> init() async {
    try {
      final c = await _read(charactersServiceProvider).getSelected();
      if (_disposed) return;
      _character = c;
      _notify();
    } catch (_) {
      // Varsayılan karakter zaten _character'da.
    }
    await _initTts();
    await _ensureConversation();
  }

  /// Character picker'dan dönüşte aktif karakteri (ses + system prompt)
  /// sohbeti sıfırlamadan değiştirir.
  Future<void> reloadCharacter() async {
    try {
      final picked = await _read(charactersServiceProvider).getSelected();
      if (_disposed || picked.id == _character.id) return;
      _character = picked;
      _notify();
      await _tts.configure(language: picked.ttsLocale, pitch: picked.ttsPitch);
    } catch (_) {
      // Keep the current character on failure.
    }
  }

  /// Uygulama arka plana alındığında çalan/dinleyen sesleri durdurur.
  void stopAudioAndCleanUp() {
    unawaited(_activeBuffer?.cancel());
    _activeBuffer?.dispose();
    _activeBuffer = null;
    _tts.stop();
    _audioSvc.cancel();
    _tearDownVad();
    _setStatus(ConvStatus.ready);
  }

  Future<void> _initTts() async {
    try {
      // Karaktere göre locale/pitch; kullanıcının ttsRate tercihi karakterin
      // default rate'ini override eder (kullanıcı tercihi her zaman önde).
      await _tts.configure(
        language: _character.ttsLocale,
        pitch: _character.ttsPitch,
        rate: _ttsRate,
      );

      _tts.setCompletionHandler(() {
        if (_disposed) return;
        if (status == ConvStatus.playing) {
          _setStatus(ConvStatus.ready);
          // Hands-free mod → AI bittiğinde otomatik dinlemeye geç
          if (_handsFreeMode) {
            Future.delayed(const Duration(milliseconds: 250), () {
              if (_disposed) return;
              if (status == ConvStatus.ready) startListening();
            });
          }
        }
      });

      _tts.setErrorHandler((msg) {
        if (!_disposed) _setError(ConvError.tts, '$msg');
      });

      if (_disposed) return;
      _ttsInitialized = true;
      await _autoStart();
    } catch (_) {
      if (!_disposed) _setError(ConvError.ttsInit);
    }
  }

  Future<void> _autoStart() async {
    if (_disposed || !_ttsInitialized) return;
    _setStatus(ConvStatus.ready);

    final s = scenario;
    if (s != null) {
      _addMessage(isUser: false, text: s.openingLine);
      await _speakMessage(s.openingLine);
      return;
    }

    if (isEmbedded) return;

    _addMessage(isUser: false, text: _greetingText());
    await _speakMessage(
        'Hello! I am ready to practice English with you. Go ahead and speak!');
  }

  Future<void> _ensureConversation() async {
    if (_conversationCreated) return;
    final id = await _read(conversationRepositoryProvider).createConversation(
      scenarioId: scenario?.id,
      title: scenario?.title,
      characterId: _character.id,
    );
    if (id != null) {
      _conversationId = id;
      _conversationCreated = true;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _tearDownVad();
    unawaited(_activeBuffer?.cancel());
    _activeBuffer?.dispose();
    unawaited(_amplitudeSub?.cancel());
    amplitudes.dispose();
    statusNotifier.dispose();
    _tts.dispose();
    super.dispose();
  }

  void _tearDownVad() {
    _vadSub?.cancel();
    _vadSub = null;
    _vad?.dispose();
    _vad = null;
  }

  // ---------------------------------------------------------------------------
  // Mikrofon / dinleme
  // ---------------------------------------------------------------------------

  Future<void> toggleMic() async {
    if (status == ConvStatus.listening) {
      await stopListening();
    } else if (status == ConvStatus.ready) {
      await startListening();
    }
  }

  Future<void> startListening() async {
    if (!await _audioSvc.hasPermission()) {
      _setError(ConvError.micPermission);
      return;
    }

    try {
      await _tts.stop();
      amplitudes.clear();

      // Hands-free açıkken VAD ile auto-stop; manuel mode'da sadece amplitude
      // history (waveform) için stream'i dinleriz.
      _tearDownVad();
      if (_handsFreeMode) {
        _vad = VadDetector();
        _vadSub = _vad!.events.listen(_onVadEvent);
      }

      await _audioSvc.start(vad: _vad);

      unawaited(_amplitudeSub?.cancel());
      _amplitudeSub = _audioSvc.amplitudeStream.listen(amplitudes.addDb);

      _setStatus(ConvStatus.listening);
    } catch (e) {
      _tearDownVad();
      _setError(ConvError.micOpen, '$e');
    }
  }

  void _onVadEvent(VadEvent event) {
    if (event == VadEvent.speechEnded || event == VadEvent.maxDurationReached) {
      if (status == ConvStatus.listening) stopListening();
    }
  }

  Future<void> stopListening() async {
    try {
      await _amplitudeSub?.cancel();
      _amplitudeSub = null;
      _tearDownVad();
      final path = await _audioSvc.stop();

      if (path != null && path.isNotEmpty) {
        PerfTrace.start('turn');
        _setStatus(ConvStatus.thinking);
        await _processAudio(path);
      } else {
        _setError(ConvError.recordFailed);
      }
    } catch (e) {
      _setError(ConvError.audioProcess, '$e');
    }
  }

  // ---------------------------------------------------------------------------
  // AI turn / chat
  // ---------------------------------------------------------------------------

  Future<void> _processAudio(String filePath) async {
    try {
      final aiService = _read(geminiServiceProvider);
      final profile = _read(profileProvider).value;
      final flags = _read(resolvedFeatureFlagsProvider);

      // Fast path: single Gemini multimodal call returns transcript + reply +
      // evaluation together. Previous chain was 3 sequential round-trips (STT
      // → chat → evaluate), often 4-6s total. /turn is ~2-3s.
      if (flags.useTurnEndpoint) {
        await _processAudioWithTurn(filePath, profile?.cefrLevel ?? 'A2');
        return;
      }

      // Fallback: legacy 3-step flow, kept behind the flag so a bad /turn
      // deployment can be rolled back from app_config without rebuild.
      final lang = bcp47ForTargetLanguage(profile?.targetLanguage) ?? 'en';
      final userText =
          await aiService.transcribeAudio(filePath, targetLanguage: lang);
      PerfTrace.lap('turn', 'stt done');

      if (userText.isEmpty) {
        _setError(ConvError.noSpeech);
        return;
      }

      final userMsg = _addMessage(isUser: true, text: userText);
      _lastUserText = userText;
      final persisted = _persistMessage(userMsg);

      // Reply + evaluate in parallel — evaluation must never crash chat.
      final replyFuture = _replyTo(userText);
      unawaited(_attachEvaluation(userMsg, userText, persisted));

      await replyFuture;
    } catch (e) {
      if (!_disposed) _setError(ConvError.generic, '$e');
    } finally {
      unawaited(_deleteAudioFile(filePath));
    }
  }

  /// Multimodal one-shot: audio + history + system → {transcript, reply, eval}.
  /// Optimistic UI: pushes a "…" user message immediately, then replaces text
  /// when the transcript field arrives so the screen never feels frozen.
  Future<void> _processAudioWithTurn(String filePath, String cefr) async {
    final aiService = _read(geminiServiceProvider);

    // Optimistic placeholder so the user sees their bubble immediately.
    final userMsg = _addMessage(isUser: true, text: '…');
    _setStatus(ConvStatus.thinking);

    final history = _messages
        .where((m) =>
            m != userMsg && m.text.isNotEmpty && !m.isError && m.text != '…')
        .map((m) => {
              'role': m.isUser ? 'user' : 'assistant',
              'content': m.text,
            })
        .toList();

    final systemPrompt = _character.renderSystemPrompt(
      cefrLevel: cefr,
      scenarioContext: scenario?.systemPrompt,
    );

    try {
      final turn = await aiService.turn(
        filePath,
        history: history,
        systemPrompt: systemPrompt,
        cefr: cefr,
      );
      PerfTrace.lap('turn', 'gemini response');

      if (_disposed) return;

      // Surface transcript by patching the optimistic message in place.
      if (turn.transcript.isNotEmpty) {
        userMsg.text = turn.transcript;
        if (turn.evaluation != null) userMsg.evaluation = turn.evaluation;
        _notify();
        _lastUserText = turn.transcript;
        // Patch persist'e ZİNCİRLENİR: persist bitmeden koşarsa remoteId
        // henüz null olur ve değerlendirme DB'ye hiç yazılmaz.
        unawaited(
            _persistMessage(userMsg).then((_) => _patchEvaluation(userMsg)));
        _maybePerfectScore(turn.evaluation);
      } else {
        // STT returned nothing — drop the placeholder.
        _messages.remove(userMsg);
        _setError(ConvError.noSpeech);
        return;
      }

      // Render the AI reply and speak it.
      if (turn.reply.isNotEmpty) {
        final aiMsg = _addMessage(isUser: false, text: turn.reply);
        unawaited(_persistMessage(aiMsg));
        unawaited(_speakMessage(turn.reply));
        _setStatus(ConvStatus.playing);
      } else {
        _setStatus(ConvStatus.ready);
      }

      // Daily quest + XP best-effort (same as legacy _replyTo).
      unawaited(_logTurnSideEffects());
    } catch (e) {
      if (_disposed) return;
      _messages.remove(userMsg);
      _setError(ConvError.generic, '$e');
    }
  }

  Future<void> _logTurnSideEffects() async {
    final logged =
        await _read(conversationRepositoryProvider).logConversationTurn();
    if (logged && !_disposed) {
      // XP/streak just changed server-side — drop the cached profile so the
      // dashboard HUD reflects it on next read instead of after the 6h TTL.
      await bustProfileCache();
      if (!_disposed) _invalidate(profileProvider);
    }
    await _bumpQuest(QuestType.conversationTurns);
  }

  /// Daily quest progress'ini best-effort artırır; tamamlanmada XP server'da
  /// yazıldığı için profil cache'i düşürülür.
  Future<void> _bumpQuest(QuestType type, {int delta = 1}) async {
    try {
      final svc = _read(dailyQuestsServiceProvider);
      final updated = await svc.incrementByType(type, delta: delta);
      if (updated == null || _disposed) return;
      _invalidate(dailyQuestsProvider);
      if (updated.isCompleted) {
        await bustProfileCache();
        if (!_disposed) _invalidate(profileProvider);
      }
    } catch (_) {}
  }

  /// Edge prompt rubriğine göre 90-100 bandı "already perfect" demektir.
  void _maybePerfectScore(SpeechEvaluation? eval) {
    if (eval == null || eval.score < 90) return;
    unawaited(_bumpQuest(QuestType.perfectScore));
  }

  /// [persisted] mesajın persist future'ı — patch'ten önce beklenir, yoksa
  /// remoteId henüz null'ken patch sessizce düşer ve değerlendirme DB'ye
  /// yazılmaz.
  Future<void> _attachEvaluation(
      ConversationMessage userMsg, String text, Future<void> persisted) async {
    try {
      final aiService = _read(geminiServiceProvider);
      final eval = await aiService.evaluateSpeech(text);
      if (_disposed) return;
      userMsg.evaluation = eval;
      _notify();
      // Backfill the persisted row with evaluation fields.
      await persisted;
      unawaited(_patchEvaluation(userMsg));
      _maybePerfectScore(eval);
    } catch (_) {
      // Evaluation is optional; never break the conversation flow.
    }
  }

  Future<void> _deleteAudioFile(String path) async {
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {
      // Cleanup is best-effort — never crash the app for a stale temp file.
    }
  }

  Future<void> sendText(String text) async {
    if (text.isEmpty || status == ConvStatus.thinking) return;
    final userMsg = _addMessage(isUser: true, text: text);
    _lastUserText = text;
    final persisted = _persistMessage(userMsg);
    _setStatus(ConvStatus.thinking);
    unawaited(_attachEvaluation(userMsg, text, persisted));
    await _replyTo(text);
  }

  Future<void> _replyTo(String _) async {
    try {
      final aiService = _read(geminiServiceProvider);
      final history = _messages
          .where((msg) => msg.text.isNotEmpty && !msg.isError)
          .map((msg) => {
                'role': msg.isUser ? 'user' : 'assistant',
                'content': msg.text,
              })
          .toList();

      _setStatus(ConvStatus.thinking);

      // AI karakter sistem prompt'u her zaman gönderilir. Senaryo varsa
      // karakterin prompt'una ek bağlam olarak eklenir.
      final cefr = _read(profileProvider).value?.cefrLevel ?? 'A2';
      final systemPrompt = _character.renderSystemPrompt(
        cefrLevel: cefr,
        scenarioContext: scenario?.systemPrompt,
      );

      final aiResponse = await aiService.chat(
        history,
        systemPrompt: systemPrompt,
      );
      PerfTrace.lap('turn', 'chat response');
      if (_disposed) return;

      final msg = _addMessage(isUser: false, text: aiResponse);
      unawaited(_persistMessage(msg));
      unawaited(_speakMessage(aiResponse));
      _setStatus(ConvStatus.playing);

      // XP + daily quest — best-effort, never delays rendering the reply.
      unawaited(_logTurnSideEffects());
    } catch (e) {
      if (_disposed) return;
      _addMessage(isUser: false, text: _replyFailedText(), isError: true);
      _setStatus(ConvStatus.ready);
      onReplyError?.call('$e');
    }
  }

  Future<void> retryLastReply() async {
    if (_lastUserText == null) return;
    _messages.removeWhere((m) => m.isError);
    _setStatus(ConvStatus.thinking);
    await _replyTo(_lastUserText!);
  }

  // ---------------------------------------------------------------------------
  // TTS
  // ---------------------------------------------------------------------------

  Future<void> _speakMessage(String text) async {
    try {
      // Turn dışı çağrılarda (greeting, replay) lap/stop no-op'tur.
      PerfTrace.lap('turn', 'tts speak');
      PerfTrace.stop('turn');
      final flags = _read(resolvedFeatureFlagsProvider);

      unawaited(_activeBuffer?.cancel());
      _activeBuffer?.dispose();

      if (flags.useStreamingTts && text.length > 80) {
        // Long reply → chunk into sentences. First sentence begins playback
        // immediately while later sentences wait their turn in FlutterTts'
        // internal queue. The buffer is created per-call (one-shot) so it
        // doesn't outlive the message.
        _activeBuffer = StreamingTtsBuffer(_tts.raw);
        await _activeBuffer!.add(text);
        await _activeBuffer!.flush();
        _activeBuffer?.dispose();
        _activeBuffer = null;
      } else {
        await _tts.raw.speak(text);
      }
    } catch (e) {
      if (!_disposed) _setError(ConvError.speak, '$e');
    }
  }

  /// Geçmiş bir AI cevabını yeniden seslendirir.
  Future<void> replayMessage(ConversationMessage msg) async {
    if (status == ConvStatus.listening || status == ConvStatus.thinking) {
      return;
    }
    _setStatus(ConvStatus.playing);
    await _speakMessage(msg.text);
  }

  Future<void> setTtsRate(double rate) async {
    _ttsRate = rate;
    _notify();
    await _read(settingsServiceProvider).setTtsRate(rate);
    try {
      await _tts.setRate(rate);
    } catch (_) {}
  }

  void setHandsFree(bool value) {
    _handsFreeMode = value;
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Mesaj listesi + persistence
  // ---------------------------------------------------------------------------

  ConversationMessage _addMessage({
    required bool isUser,
    required String text,
    bool isError = false,
  }) {
    final m = ConversationMessage(isUser: isUser, text: text, isError: isError);
    _messages.add(m);
    _notify();
    return m;
  }

  Future<void> _persistMessage(ConversationMessage msg) async {
    if (msg.persisted) return;
    final convId = _conversationId;
    if (convId == null) return;
    final id = await _read(conversationRepositoryProvider).appendMessage(
      conversationId: convId,
      role: msg.isUser ? 'user' : 'assistant',
      content: msg.text,
    );
    if (id != null) {
      msg.persisted = true;
      msg.remoteId = id;
    }
  }

  Future<void> _patchEvaluation(ConversationMessage msg) async {
    final remoteId = msg.remoteId;
    final eval = msg.evaluation;
    if (remoteId == null || eval == null) return;
    await _read(conversationRepositoryProvider).patchEvaluation(remoteId, eval);
  }

  Future<void> reset() async {
    _messages.clear();
    _setStatus(ConvStatus.idle);
    _errorCode = null;
    _errorDetail = null;
    _conversationId = null;
    _conversationCreated = false;
    _lastUserText = null;
    _notify();
    await _ensureConversation();
    await _autoStart();
  }
}
