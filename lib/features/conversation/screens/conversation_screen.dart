import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/ai/ai_character.dart';
import '../../../core/ai/character_avatar.dart';
import '../../../core/ai/characters.dart';
import '../../../core/audio/amplitude_history.dart';
import '../../../core/audio/audio_recorder_service.dart';
import '../../../core/audio/vad_detector.dart';
import '../../../core/audio/waveform_painter.dart';
import '../../../models/scenario.dart';
import '../../../core/ai/gemini_service.dart';
import '../../../core/config/feature_flags.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../providers/profile_provider.dart';
import '../../../services/settings_service.dart';
import '../../../theme/app_theme.dart';
import '../../gamification/models/daily_quest.dart';
import '../../gamification/providers/gamification_providers.dart';
import '../../scenarios/screens/scenario_picker_screen.dart';
import '../services/characters_service.dart';
import 'character_picker_screen.dart';
import '../services/streaming_tts_buffer.dart';
import 'conversation_history_screen.dart';

enum _ConvStatus {
  idle,
  connecting,
  ready,
  listening,
  thinking,
  playing,
  error,
}

class _Message {
  final bool isUser;
  String text;
  SpeechEvaluation? evaluation;
  bool isError;
  bool persisted = false;
  String? remoteId;

  /// Used to run the entrance animation only for freshly added bubbles —
  /// items re-entering the viewport on scroll render statically.
  final DateTime createdAt = DateTime.now();

  _Message({
    required this.isUser,
    required this.text,
    this.isError = false,
  });
}

class ConversationScreen extends ConsumerStatefulWidget {
  final bool showBackButton;
  final ScenarioModel? scenario;
  const ConversationScreen({
    super.key,
    this.showBackButton = true,
    this.scenario,
  });

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AudioRecorderService _audioSvc;
  late final FlutterTts _tts;
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _textCtrl = TextEditingController();
  late final AnimationController _pulse;
  final AmplitudeHistory _amplitudes = AmplitudeHistory();

  VadDetector? _vad;
  StreamSubscription<VadEvent>? _vadSub;
  StreamSubscription<double>? _amplitudeSub;

  _ConvStatus _status = _ConvStatus.idle;
  String? _errorMsg;
  final List<_Message> _messages = [];
  bool _ttsInitialized = false;
  String? _conversationId;
  bool _conversationCreated = false;
  String? _lastUserText;

  double _ttsRate = SettingsService().ttsRate;

  // Faz 5: AI karakter sistemi
  AICharacter _character = AICharacters.defaultCharacter;
  bool _handsFreeMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioSvc = ref.read(audioRecorderServiceProvider);
    _tts = FlutterTts();

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _loadCharacterThenInit();
  }

  /// Init sırası: önce kullanıcının seçili karakterini yükle, sonra TTS'i
  /// o karakterin sesiyle ayarla, sonra conversation row'unu yarat.
  Future<void> _loadCharacterThenInit() async {
    try {
      final svc = ref.read(charactersServiceProvider);
      final c = await svc.getSelected();
      if (mounted) setState(() => _character = c);
    } catch (_) {
      // Varsayılan karakter zaten _character'da.
    }
    await _initTts();
    await _ensureConversation();
  }

  /// Header avatar tap → character picker. On return, hot-swap the active
  /// character (voice + system prompt) without resetting the conversation.
  Future<void> _openCharacterPicker() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CharacterPickerScreen()),
    );
    if (!mounted) return;
    try {
      final picked = await ref.read(charactersServiceProvider).getSelected();
      if (!mounted || picked.id == _character.id) return;
      setState(() => _character = picked);
      await _tts.setLanguage(picked.ttsLocale);
      await _tts.setPitch(picked.ttsPitch);
    } catch (_) {
      // Keep the current character on failure.
    }
  }

  StreamingTtsBuffer? _activeBuffer;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (_status == _ConvStatus.playing || _status == _ConvStatus.listening) {
        _stopAudioAndCleanUp();
      }
    }
  }

  void _stopAudioAndCleanUp() {
    _activeBuffer?.cancel();
    _activeBuffer?.dispose();
    _activeBuffer = null;
    _tts.stop();
    _audioSvc.cancel();
    _tearDownVad();
    _pulse.stop();
    if (mounted) {
      setState(() => _status = _ConvStatus.ready);
    }
  }

  Future<void> _initTts() async {
    try {
      // Faz 5: karaktere göre locale/pitch/rate. Kullanıcının ttsRate
      // tercihi karakterin default rate'ini override eder (kullanıcı tercihi
      // her zaman önde).
      await _tts.setLanguage(_character.ttsLocale);
      await _tts.setPitch(_character.ttsPitch);
      await _tts.setSpeechRate(_ttsRate);

      _tts.setCompletionHandler(() {
        if (!mounted) return;
        if (_status == _ConvStatus.playing) {
          setState(() => _status = _ConvStatus.ready);
          // Faz 5: hands-free mod → AI bittiğinde otomatik dinlemeye geç
          if (_handsFreeMode) {
            Future.delayed(const Duration(milliseconds: 250), () {
              if (!mounted) return;
              if (_status == _ConvStatus.ready) _startListening();
            });
          }
        }
      });

      _tts.setErrorHandler((msg) {
        if (mounted) {
          setState(() {
            _status = _ConvStatus.error;
            _errorMsg = AppL10n.of(context).conv_errTts(msg);
          });
        }
      });

      if (!mounted) return;
      setState(() => _ttsInitialized = true);
      await _autoStart();
    } catch (_) {
      if (mounted) {
        setState(() {
          _status = _ConvStatus.error;
          _errorMsg = AppL10n.of(context).conv_errTtsInit;
        });
      }
    }
  }

  // Embedded Practice tab is built inside HomeScreen's IndexedStack — it mounts
  // even when the user is on a different tab, so we must not auto-speak there
  // (would blare audio while the user is on Dashboard). Pushed instances
  // (scenario picker → ConversationScreen) are user-intentional, so we greet.
  bool get _isEmbeddedTab => !widget.showBackButton;

  Future<void> _autoStart() async {
    if (!mounted || !_ttsInitialized) return;
    setState(() => _status = _ConvStatus.ready);

    final scenario = widget.scenario;
    if (scenario != null) {
      _addMessage(isUser: false, text: scenario.openingLine);
      await _speakMessage(scenario.openingLine);
      return;
    }

    if (_isEmbeddedTab) return;

    _addMessage(
      isUser: false,
      text: AppL10n.of(context).conv_greeting,
    );
    await _speakMessage(
        'Hello! I am ready to practice English with you. Go ahead and speak!');
  }

  Future<void> _ensureConversation() async {
    if (_conversationCreated) return;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    try {
      final row = await Supabase.instance.client
          .from('conversations')
          .insert({
            'user_id': userId,
            'scenario': widget.scenario?.id,
            'title': widget.scenario?.title,
            // Faz 5: karakter snapshot — sohbet history'sinde immutable kalır
            'character_id': _character.id,
          })
          .select()
          .single();
      _conversationId = row['id'] as String;
      _conversationCreated = true;
    } catch (_) {
      // Persistence is best-effort: user can still chat in-memory.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tearDownVad();
    _activeBuffer?.cancel();
    _activeBuffer?.dispose();
    _amplitudeSub?.cancel();
    _amplitudes.dispose();
    _tts.stop();
    _pulse.dispose();
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _tearDownVad() {
    _vadSub?.cancel();
    _vadSub = null;
    _vad?.dispose();
    _vad = null;
  }

  Future<void> _toggleMic() async {
    HapticFeedback.lightImpact();
    if (_status == _ConvStatus.listening) {
      await _stopListening();
    } else if (_status == _ConvStatus.ready) {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!await _audioSvc.hasPermission()) {
      setState(() {
        _status = _ConvStatus.error;
        _errorMsg = AppL10n.of(context).conv_errMicPermission;
      });
      return;
    }

    try {
      await _tts.stop();
      _amplitudes.clear();

      // Hands-free açıkken VAD ile auto-stop; manuel mode'da sadece amplitude
      // history (waveform) için stream'i dinleriz.
      _tearDownVad();
      final useVad = _handsFreeMode;
      if (useVad) {
        _vad = VadDetector();
        _vadSub = _vad!.events.listen(_onVadEvent);
      }

      await _audioSvc.start(vad: _vad);

      _amplitudeSub?.cancel();
      _amplitudeSub = _audioSvc.amplitudeStream.listen(_amplitudes.addDb);

      setState(() => _status = _ConvStatus.listening);
      _pulse.repeat(reverse: true);
    } catch (e) {
      _tearDownVad();
      setState(() {
        _status = _ConvStatus.error;
        _errorMsg = AppL10n.of(context).conv_errMicOpen('$e');
      });
    }
  }

  void _onVadEvent(VadEvent event) {
    if (event == VadEvent.speechEnded || event == VadEvent.maxDurationReached) {
      if (_status == _ConvStatus.listening) _stopListening();
    }
  }

  Future<void> _stopListening() async {
    try {
      _pulse.stop();
      await _amplitudeSub?.cancel();
      _amplitudeSub = null;
      _tearDownVad();
      final path = await _audioSvc.stop();

      if (path != null && path.isNotEmpty) {
        setState(() => _status = _ConvStatus.thinking);
        await _processAudio(path);
      } else {
        setState(() {
          _status = _ConvStatus.error;
          _errorMsg = AppL10n.of(context).conv_errRecordFailed;
        });
      }
    } catch (e) {
      setState(() {
        _status = _ConvStatus.error;
        _errorMsg = AppL10n.of(context).conv_errAudioProcess('$e');
      });
    }
  }

  Future<void> _processAudio(String filePath) async {
    try {
      final aiService = ref.read(geminiServiceProvider);
      final profile = ref.read(profileProvider).value;
      final flags = ref.read(resolvedFeatureFlagsProvider);

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

      if (userText.isEmpty) {
        setState(() {
          _status = _ConvStatus.error;
          _errorMsg = AppL10n.of(context).conv_errNoSpeech;
        });
        return;
      }

      final userMsg = _addMessage(isUser: true, text: userText);
      _lastUserText = userText;
      _persistMessage(userMsg);

      // Reply + evaluate in parallel — evaluation must never crash chat.
      final replyFuture = _replyTo(userText);
      _attachEvaluation(userMsg, userText);

      await replyFuture;
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = _ConvStatus.error;
          _errorMsg = AppL10n.of(context).conv_errGeneric('$e');
        });
      }
    } finally {
      _deleteAudioFile(filePath);
    }
  }

  /// Multimodal one-shot: audio + history + system → {transcript, reply, eval}.
  /// Optimistic UI: pushes a "…" user message immediately, then replaces text
  /// when the transcript field arrives so the screen never feels frozen.
  Future<void> _processAudioWithTurn(String filePath, String cefr) async {
    final aiService = ref.read(geminiServiceProvider);

    // Optimistic placeholder so the user sees their bubble immediately.
    final userMsg = _addMessage(isUser: true, text: '…');
    setState(() => _status = _ConvStatus.thinking);

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
      scenarioContext: widget.scenario?.systemPrompt,
    );

    try {
      final turn = await aiService.turn(
        filePath,
        history: history,
        systemPrompt: systemPrompt,
        cefr: cefr,
      );

      if (!mounted) return;

      // Surface transcript by patching the optimistic message in place.
      if (turn.transcript.isNotEmpty) {
        setState(() {
          userMsg.text = turn.transcript;
          if (turn.evaluation != null) userMsg.evaluation = turn.evaluation;
        });
        _lastUserText = turn.transcript;
        _persistMessage(userMsg);
        if (turn.evaluation != null) _patchEvaluation(userMsg);
      } else {
        // STT returned nothing — drop the placeholder.
        setState(() => _messages.remove(userMsg));
        setState(() {
          _status = _ConvStatus.error;
          _errorMsg = AppL10n.of(context).conv_errNoSpeech;
        });
        return;
      }

      // Render the AI reply and speak it.
      if (turn.reply.isNotEmpty) {
        final aiMsg = _addMessage(isUser: false, text: turn.reply);
        _persistMessage(aiMsg);
        _speakMessage(turn.reply);
        setState(() => _status = _ConvStatus.playing);
      } else {
        setState(() => _status = _ConvStatus.ready);
      }

      // Daily quest + XP best-effort (same as legacy _replyTo).
      _logTurnSideEffects();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.remove(userMsg);
        _status = _ConvStatus.error;
        _errorMsg = AppL10n.of(context).conv_errGeneric('$e');
      });
    }
  }

  Future<void> _logTurnSideEffects() async {
    try {
      final tzo = DateTime.now().timeZoneOffset.inHours;
      final sign = tzo >= 0 ? '+' : '-';
      final tzStr = '$sign${tzo.abs().toString().padLeft(2, '0')}:00';
      await Supabase.instance.client.rpc('log_practice_session', params: {
        'p_mode': 'conversation',
        'p_words_practiced': 0,
        'p_avg_score': 5.0,
        'p_xp_earned': 5,
        'p_timezone_offset': tzStr,
      });
      // XP/streak just changed server-side — drop the cached profile so the
      // dashboard HUD reflects it on next read instead of after the 6h TTL.
      await bustProfileCache();
      if (mounted) ref.invalidate(profileProvider);
    } catch (_) {}
    try {
      final quests = ref.read(dailyQuestsProvider).value ?? const [];
      final target = quests.where(
          (q) => q.type == QuestType.conversationTurns && !q.isCompleted);
      if (target.isNotEmpty) {
        final svc = ref.read(dailyQuestsServiceProvider);
        await svc.updateProgress(questId: target.first.id, delta: 1);
        ref.invalidate(dailyQuestsProvider);
      }
    } catch (_) {}
  }

  Future<void> _attachEvaluation(_Message userMsg, String text) async {
    try {
      final aiService = ref.read(geminiServiceProvider);
      final eval = await aiService.evaluateSpeech(text);
      if (!mounted) return;
      setState(() => userMsg.evaluation = eval);
      // Backfill the persisted row with evaluation fields.
      _patchEvaluation(userMsg);
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

  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _status == _ConvStatus.thinking) return;
    _textCtrl.clear();
    final userMsg = _addMessage(isUser: true, text: text);
    _lastUserText = text;
    _persistMessage(userMsg);
    setState(() => _status = _ConvStatus.thinking);
    _attachEvaluation(userMsg, text);
    await _replyTo(text);
  }

  Future<void> _replyTo(String _) async {
    try {
      final aiService = ref.read(geminiServiceProvider);
      final messages = _messages
          .where((msg) => msg.text.isNotEmpty && !msg.isError)
          .map((msg) => {
                'role': msg.isUser ? 'user' : 'assistant',
                'content': msg.text,
              })
          .toList();

      setState(() => _status = _ConvStatus.thinking);

      // Faz 5: AI karakter sistem prompt'u her zaman gönderilir.
      // Senaryo varsa karakterin prompt'una ek bağlam olarak eklenir.
      final cefr = ref.read(profileProvider).value?.cefrLevel ?? 'A2';
      final systemPrompt = _character.renderSystemPrompt(
        cefrLevel: cefr,
        scenarioContext: widget.scenario?.systemPrompt,
      );

      final aiResponse = await aiService.chat(
        messages,
        systemPrompt: systemPrompt,
      );
      if (!mounted) return;

      final msg = _addMessage(isUser: false, text: aiResponse);
      _persistMessage(msg);
      _speakMessage(aiResponse);
      setState(() => _status = _ConvStatus.playing);

      // XP + daily quest — best-effort, never delays rendering the reply.
      unawaited(_logTurnSideEffects());
    } catch (e) {
      if (!mounted) return;
      final l = AppL10n.of(context);
      _addMessage(
        isUser: false,
        text: l.conv_replyFailed,
        isError: true,
      );
      setState(() => _status = _ConvStatus.ready);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: context.c.bgCard,
          content: Text(
            l.conv_aiNoResponse('$e'),
            style: AppText.ink(13, color: context.c.error),
          ),
        ),
      );
    }
  }

  Future<void> _retryLastReply() async {
    if (_lastUserText == null) return;
    setState(() {
      _messages.removeWhere((m) => m.isError);
    });
    setState(() => _status = _ConvStatus.thinking);
    await _replyTo(_lastUserText!);
  }

  Future<void> _speakMessage(String text) async {
    try {
      final flags = ref.read(resolvedFeatureFlagsProvider);

      _activeBuffer?.cancel();
      _activeBuffer?.dispose();

      if (flags.useStreamingTts && text.length > 80) {
        // Long reply → chunk into sentences. First sentence begins playback
        // immediately while later sentences wait their turn in FlutterTts'
        // internal queue. The buffer is created per-call (one-shot) so it
        // doesn't outlive the message.
        _activeBuffer = StreamingTtsBuffer(_tts);
        await _activeBuffer!.add(text);
        await _activeBuffer!.flush();
        _activeBuffer?.dispose();
        _activeBuffer = null;
      } else {
        await _tts.speak(text);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = _ConvStatus.error;
          _errorMsg = AppL10n.of(context).conv_errSpeak('$e');
        });
      }
    }
  }

  Future<void> _setTtsRate(double rate) async {
    setState(() => _ttsRate = rate);
    await SettingsService().setTtsRate(rate);
    try {
      await _tts.setSpeechRate(rate);
    } catch (_) {}
  }

  _Message _addMessage({
    required bool isUser,
    required String text,
    bool isError = false,
  }) {
    final m = _Message(isUser: isUser, text: text, isError: isError);
    setState(() => _messages.add(m));
    Future.delayed(const Duration(milliseconds: 80), _scrollToBottom);
    return m;
  }

  Future<void> _persistMessage(_Message msg) async {
    if (msg.persisted) return;
    final convId = _conversationId;
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (convId == null || userId == null) return;
    final role = msg.isUser ? 'user' : 'assistant';
    try {
      // Single round-trip: insert + bump conversations.updated_at in one RPC.
      final id = await Supabase.instance.client.rpc('append_message', params: {
        'p_conversation_id': convId,
        'p_role': role,
        'p_content': msg.text,
      });
      msg.persisted = true;
      msg.remoteId = id as String?;
    } catch (_) {
      // Persistence is best-effort.
    }
  }

  Future<void> _patchEvaluation(_Message msg) async {
    final remoteId = msg.remoteId;
    final eval = msg.evaluation;
    if (remoteId == null || eval == null) return;
    try {
      await Supabase.instance.client.from('messages').update({
        'eval_score': eval.score,
        'eval_suggestion': eval.correct,
        'eval_explanation': eval.explanation,
        'grammar_errors': eval.grammarErrors,
      }).eq('id', remoteId);
    } catch (_) {}
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  bool get _canToggleMic =>
      _status == _ConvStatus.ready || _status == _ConvStatus.listening;

  Color _statusColor(AppPalette c) {
    switch (_status) {
      case _ConvStatus.listening:
        return c.secondaryContainer;
      case _ConvStatus.ready:
        return c.primaryFixed;
      case _ConvStatus.thinking:
        return c.secondary;
      case _ConvStatus.playing:
        return c.tertiaryFixedDim;
      case _ConvStatus.error:
        return c.error;
      case _ConvStatus.idle:
      case _ConvStatus.connecting:
        return c.inkDim;
    }
  }

  String _statusLabel(AppL10n l) {
    switch (_status) {
      case _ConvStatus.idle:
      case _ConvStatus.connecting:
        return l.conv_statusStarting;
      case _ConvStatus.ready:
        return l.conv_statusReady;
      case _ConvStatus.listening:
        return l.conv_statusListening;
      case _ConvStatus.thinking:
        return l.conv_statusThinking;
      case _ConvStatus.playing:
        return l.conv_statusSpeaking;
      case _ConvStatus.error:
        return l.conv_statusError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _status == _ConvStatus.error && _messages.isEmpty
                      ? _buildError()
                      : _buildMessages(),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: _buildInputBar(),
        ),
      ],
    );

    if (!widget.showBackButton) return body;

    return Scaffold(
      backgroundColor: context.c.bg,
      body: CosmicBackground(child: SafeArea(child: body)),
    );
  }

  Widget _buildHeader() {
    final l = AppL10n.of(context);
    final c = context.c;
    const compactBtn = VisualDensity(horizontal: -4, vertical: -4);
    const tightConstraints = BoxConstraints(minWidth: 36, minHeight: 36);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      child: Row(
        children: [
          if (widget.showBackButton) ...[
            Semantics(
              label: l.common_back,
              child: IconButton(
                icon:
                    Icon(Icons.arrow_back, color: c.primaryContainer, size: 22),
                padding: const EdgeInsets.all(6),
                constraints: tightConstraints,
                visualDensity: compactBtn,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: widget.scenario != null
                ? Text(
                    widget.scenario!.title,
                    style: AppText.title(18,
                            color: c.primary, weight: FontWeight.w600)
                        .copyWith(
                      shadows: neonGlow(c.primary, blur: 8, opacity: 0.3),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : Semantics(
                    label: l.conv_practiceMode,
                    button: true,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(99),
                      onTap: _openCharacterPicker,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CharacterAvatar(character: _character, size: 30),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _character.displayName,
                              style: AppText.title(17,
                                      color: c.primary, weight: FontWeight.w600)
                                  .copyWith(
                                shadows:
                                    neonGlow(c.primary, blur: 8, opacity: 0.3),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(Icons.expand_more, color: c.inkDim, size: 16),
                        ],
                      ),
                    ),
                  ),
          ),
          _SpeedToggle(
            rate: _ttsRate,
            onChanged: _setTtsRate,
          ),
          const SizedBox(width: 4),
          // Faz 5: Hands-free toggle — AI cevap verince otomatik mikrofon
          Semantics(
            label: l.conversation_handsfree,
            button: true,
            child: IconButton(
              icon: Icon(
                _handsFreeMode ? Icons.hearing : Icons.hearing_disabled,
                color: _handsFreeMode ? c.primaryContainer : c.inkDim,
                size: 20,
              ),
              padding: const EdgeInsets.all(6),
              constraints: tightConstraints,
              visualDensity: compactBtn,
              tooltip: _handsFreeMode
                  ? l.conv_handsFreeOnTip
                  : l.conv_handsFreeOffTip,
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _handsFreeMode = !_handsFreeMode);
              },
            ),
          ),
          Semantics(
            label: l.nav_scenarios,
            button: true,
            child: IconButton(
              icon: Icon(Icons.theater_comedy_outlined,
                  color: c.primaryContainer, size: 20),
              padding: const EdgeInsets.all(6),
              constraints: tightConstraints,
              visualDensity: compactBtn,
              tooltip: l.conv_pickScenario,
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ScenarioPickerScreen()));
              },
            ),
          ),
          if (_messages.isNotEmpty)
            Semantics(
              label: l.conv_newChat,
              child: IconButton(
                icon:
                    Icon(Icons.add_comment_outlined, color: c.inkDim, size: 20),
                padding: const EdgeInsets.all(6),
                constraints: tightConstraints,
                visualDensity: compactBtn,
                onPressed: _resetConversation,
                tooltip: l.conv_newChat,
              ),
            ),
          Semantics(
            label: l.conv_chatHistory,
            child: IconButton(
              icon: Icon(Icons.history, color: c.primaryContainer, size: 20),
              padding: const EdgeInsets.all(6),
              constraints: tightConstraints,
              visualDensity: compactBtn,
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ConversationHistoryScreen()));
              },
            ),
          ),
          const SizedBox(width: 2),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(scale: anim, child: child),
            ),
            child: NeonChip(
              key: ValueKey(_status),
              text: _statusLabel(l),
              color: _statusColor(c),
              icon: _status == _ConvStatus.connecting
                  ? Icons.sync
                  : _status == _ConvStatus.listening
                      ? Icons.fiber_manual_record
                      : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_messages.isEmpty) {
      final isBusy = _status == _ConvStatus.idle ||
          _status == _ConvStatus.connecting ||
          _status == _ConvStatus.thinking;
      return _buildEmptyState(isBusy: isBusy);
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _messages.length + (_status == _ConvStatus.thinking ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _messages.length) {
          return _buildThinkingBubble();
        }
        return _buildBubble(_messages[i]);
      },
    );
  }

  Widget _buildThinkingBubble() {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: CharacterAvatar(character: _character, size: 32),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: c.surfaceHighest.withOpacity(0.5),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BlinkingDot(index: 0),
                SizedBox(width: 4),
                _BlinkingDot(index: 1),
                SizedBox(width: 4),
                _BlinkingDot(index: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Long-press anywhere on a bubble → copy its text.
  void _copyMessage(_Message msg) {
    Clipboard.setData(ClipboardData(text: msg.text));
    HapticFeedback.selectionClick();
    final l = AppL10n.of(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(l.conv_copied),
        duration: const Duration(seconds: 1),
      ));
  }

  /// Speaker button under AI bubbles — re-listen to any past reply.
  Future<void> _replayMessage(_Message msg) async {
    if (_status == _ConvStatus.listening || _status == _ConvStatus.thinking) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _status = _ConvStatus.playing);
    await _speakMessage(msg.text);
  }

  Widget _buildBubble(_Message msg) {
    final l = AppL10n.of(context);
    final c = context.c;
    final isUser = msg.isUser;
    final bubble = Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: CharacterAvatar(character: _character, size: 32),
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72),
                  child: GestureDetector(
                    onLongPress: () => _copyMessage(msg),
                    child: isUser
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: c.primaryContainer.withOpacity(0.10),
                              border: Border.all(
                                  color: c.primaryContainer.withOpacity(0.4)),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(4),
                                bottomLeft: Radius.circular(18),
                                bottomRight: Radius.circular(18),
                              ),
                            ),
                            child: Text(
                              msg.text,
                              style: AppText.ink(14,
                                  color: c.primary, weight: FontWeight.w500),
                            ),
                          )
                        : GlassPanel(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            radius: 18,
                            borderColor:
                                msg.isError ? c.error.withOpacity(0.5) : null,
                            child: Text(
                              msg.text,
                              style: AppText.ink(
                                14,
                                color: msg.isError ? c.error : c.ink,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 10),
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.primaryContainer.withOpacity(0.18),
                    border:
                        Border.all(color: c.primaryContainer.withOpacity(0.5)),
                  ),
                  child:
                      Icon(Icons.person, color: c.primaryContainer, size: 16),
                ),
              ],
            ],
          ),
          if (msg.isUser && msg.evaluation != null)
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 42),
              child: _FeedbackPill(evaluation: msg.evaluation!),
            ),
          if (!isUser && !msg.isError)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 42),
              child: Semantics(
                label: l.conv_replay,
                button: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(99),
                  onTap: () => _replayMessage(msg),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.volume_up_outlined,
                        color: c.inkDim, size: 18),
                  ),
                ),
              ),
            ),
          if (msg.isError)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 42),
              child: Semantics(
                label: l.conv_tryAgain,
                button: true,
                child: GhostButton(
                  label: l.conv_tryAgain,
                  icon: Icons.refresh,
                  color: c.error,
                  onTap: _retryLastReply,
                ),
              ),
            ),
        ],
      ),
    );

    // Entrance animation only for freshly appended bubbles; recycled items
    // (scrolling back up) and reduce-motion users get a static render.
    final isFresh =
        DateTime.now().difference(msg.createdAt).inMilliseconds < 600;
    if (!isFresh || reduceMotion(context)) return bubble;
    return _BubbleEntrance(fromRight: isUser, child: bubble);
  }

  Widget _buildEmptyState({required bool isBusy}) {
    final l = AppL10n.of(context);
    final c = context.c;
    final hint = _status == _ConvStatus.connecting
        ? l.conv_preparing
        : _status == _ConvStatus.thinking
            ? l.conv_aiPreparing
            : l.conv_emptyHint;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: isBusy
                ? Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.primaryContainer.withOpacity(0.12),
                      border: Border.all(
                          color: c.primaryContainer.withOpacity(0.45)),
                      boxShadow: [
                        BoxShadow(
                          color: c.primaryContainer.withOpacity(0.25),
                          blurRadius: 22,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.primaryContainer,
                      ),
                    ),
                  )
                : Semantics(
                    label: l.conv_changeCoach,
                    button: true,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _openCharacterPicker,
                      child: CharacterAvatar(character: _character, size: 84),
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              widget.scenario?.title ??
                  (isBusy ? l.conv_aiPracticeMode : _character.displayName),
              style:
                  AppText.title(22, color: c.primary, weight: FontWeight.w600)
                      .copyWith(
                shadows: neonGlow(c.primary, blur: 8, opacity: 0.3),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                hint,
                style: AppText.body(13, color: c.inkMuted),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (widget.scenario == null && !isBusy) ...[
            const SizedBox(height: 24),
            SectionLabel(l.conv_readyScenarios),
            const SizedBox(height: 12),
            _ScenarioStrip(
              onPick: (s) {
                if (_isEmbeddedTab) {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ConversationScreen(scenario: s)));
                } else {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (_) => ConversationScreen(scenario: s)));
                }
              },
              onSeeAll: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const ScenarioPickerScreen()));
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _resetConversation() async {
    setState(() {
      _messages.clear();
      _status = _ConvStatus.idle;
      _errorMsg = null;
      _conversationId = null;
      _conversationCreated = false;
      _lastUserText = null;
    });
    await _ensureConversation();
    await _autoStart();
  }

  Widget _buildError() {
    final l = AppL10n.of(context);
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: GlassPanel(
          borderColor: c.error.withOpacity(0.4),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: c.error, size: 32),
              const SizedBox(height: 12),
              Text(
                _errorMsg ?? l.conv_errUnknown,
                style: AppText.body(14, color: c.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              GhostButton(
                label: l.conv_restart,
                icon: Icons.refresh,
                onTap: _resetConversation,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    final l = AppL10n.of(context);
    final c = context.c;
    final isListening = _status == _ConvStatus.listening;
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
          decoration: BoxDecoration(
            color: c.surfaceHighest.withOpacity(0.85),
            border: Border.all(
              color: isListening
                  ? c.primaryContainer
                  : (c.isDark ? Colors.white : Colors.black).withOpacity(0.12),
            ),
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(c.isDark ? 0.5 : 0.12),
                blurRadius: 24,
                offset: const Offset(0, 4),
              ),
              if (isListening)
                BoxShadow(
                  color: c.primaryContainer.withOpacity(0.4),
                  blurRadius: 20,
                ),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  style: AppText.ink(14, color: c.ink),
                  cursorColor: c.primaryContainer,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendText(),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: l.conv_inputHint,
                    hintStyle: AppText.body(13, color: c.inkDim),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                  ),
                ),
              ),
              if (_status == _ConvStatus.listening)
                Expanded(
                  flex: 0,
                  child: SizedBox(
                    width: 80,
                    height: 32,
                    child: AnimatedBuilder(
                      animation: _amplitudes,
                      builder: (_, __) => CustomPaint(
                        painter: WaveformPainter(
                          amplitudes: _amplitudes.value,
                          color: c.primaryContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              // Per-keystroke updates only swap this trailing button — listening
              // to the controller here avoids rebuilding the whole screen.
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _textCtrl,
                builder: (context, value, _) {
                  if (value.text.isNotEmpty) {
                    return Semantics(
                      label: l.conv_sendMessage,
                      button: true,
                      child: IconButton(
                        onPressed: _sendText,
                        icon: Icon(Icons.send,
                            color: c.primaryContainer, size: 22),
                      ),
                    );
                  }
                  return Semantics(
                    label: _status == _ConvStatus.listening
                        ? l.conv_stopRecording
                        : l.conv_startRecording,
                    button: true,
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => _MicButton(
                        status: _status,
                        pulse: _pulse.value,
                        onTap: _canToggleMic ? _toggleMic : null,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// TTS speed toggle: cycles through 0.5x / 0.75x / 1.0x.
// ===========================================================================
class _SpeedToggle extends StatelessWidget {
  final double rate;
  final ValueChanged<double> onChanged;
  const _SpeedToggle({required this.rate, required this.onChanged});

  static const _options = [0.5, 0.75, 1.0];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final idx = _options.indexOf(rate).clamp(0, _options.length - 1);
    final label =
        '${_options[idx].toStringAsFixed(2).replaceAll(RegExp(r"0+$"), "").replaceAll(RegExp(r"\.$"), "")}×';
    return Semantics(
      label: AppL10n.of(context).settings_ttsSpeed,
      value: label,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: () {
          final next = _options[(idx + 1) % _options.length];
          onChanged(next);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: c.primaryContainer.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            label,
            style: AppText.label(11,
                color: c.primaryContainer, weight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Feedback pill — TASK 2.1
// ===========================================================================
class _FeedbackPill extends StatefulWidget {
  final SpeechEvaluation evaluation;
  const _FeedbackPill({required this.evaluation});

  @override
  State<_FeedbackPill> createState() => _FeedbackPillState();
}

class _FeedbackPillState extends State<_FeedbackPill> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    final eval = widget.evaluation;
    final isHigh = eval.score >= 80;
    final color = isHigh ? c.primaryFixed : c.tertiaryFixedDim;
    final label = isHigh
        ? l.conv_feedbackGreat
        : l.conv_feedbackMoreNatural(
            eval.correct.isNotEmpty ? eval.correct : "—");

    return Semantics(
      label: l.conv_evalSemantics(label),
      button: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                border: Border.all(color: color.withOpacity(0.45)),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: AppText.label(10,
                          color: color, weight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: color,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: GlassPanel(
                  padding: const EdgeInsets.all(12),
                  borderColor: color.withOpacity(0.35),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l.conv_score(eval.score),
                          style: AppText.label(10,
                              color: color, weight: FontWeight.w700)),
                      if (eval.explanation.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(eval.explanation,
                            style: AppText.body(12, color: c.ink)),
                      ],
                      if (eval.grammarErrors.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(l.conv_errorsLabel,
                            style: AppText.label(9,
                                color: c.inkDim, weight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        ...eval.grammarErrors.map((e) => Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text('• $e',
                                  style: AppText.body(12, color: c.inkMuted)),
                            )),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Horizontal scenario strip — surfaces scenarios on the empty Practice screen
// so users discover them without hunting for the FAB.
// ===========================================================================
class _ScenarioStrip extends StatelessWidget {
  final ValueChanged<ScenarioModel> onPick;
  final VoidCallback onSeeAll;
  const _ScenarioStrip({required this.onPick, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: builtInScenarios.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          if (i == builtInScenarios.length) {
            return _AllScenariosTile(onTap: onSeeAll);
          }
          final s = builtInScenarios[i];
          return _ScenarioTile(scenario: s, onTap: () => onPick(s));
        },
      ),
    );
  }
}

class _ScenarioTile extends StatelessWidget {
  final ScenarioModel scenario;
  final VoidCallback onTap;
  const _ScenarioTile({required this.scenario, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: 168,
      child: GlassPanel(
        padding: const EdgeInsets.all(14),
        glowColor: c.primaryContainer,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primaryContainer.withOpacity(0.15),
                border: Border.all(color: c.primaryContainer.withOpacity(0.4)),
              ),
              child: Icon(scenario.icon, color: c.primaryContainer, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              scenario.title,
              style:
                  AppText.title(14, color: c.primary, weight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                scenario.description,
                style: AppText.body(11, color: c.inkMuted),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AllScenariosTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AllScenariosTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: 132,
      child: GlassPanel(
        padding: const EdgeInsets.all(14),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.tertiaryFixedDim.withOpacity(0.15),
                border: Border.all(color: c.tertiaryFixedDim.withOpacity(0.4)),
              ),
              child: Icon(Icons.grid_view_rounded,
                  color: c.tertiaryFixedDim, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              AppL10n.of(context).conv_seeAll,
              style: AppText.label(11,
                  color: c.tertiaryFixedDim, weight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// One-shot entrance for chat bubbles: fade + slide-up + a tiny horizontal
/// push from the sender's side. Owns its controller so the animation runs
/// exactly once per insertion and survives parent rebuilds mid-flight.
class _BubbleEntrance extends StatefulWidget {
  final Widget child;
  final bool fromRight;
  const _BubbleEntrance({required this.child, required this.fromRight});

  @override
  State<_BubbleEntrance> createState() => _BubbleEntranceState();
}

class _BubbleEntranceState extends State<_BubbleEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  )..forward();
  late final CurvedAnimation _t =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);

  @override
  void dispose() {
    _t.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dx = widget.fromRight ? 0.06 : -0.06;
    return FadeTransition(
      opacity: _t,
      child: SlideTransition(
        position: _t.drive(
          Tween(begin: Offset(dx, 0.25), end: Offset.zero),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Self-animating "AI is thinking" dot. Owns its controller so the blink loop
/// repaints only this 6×6 dot — the previous TweenAnimationBuilder+onEnd
/// approach rebuilt the entire conversation screen every cycle.
class _BlinkingDot extends StatefulWidget {
  final int index;
  const _BlinkingDot({required this.index});

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600 + (widget.index * 200)),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl.drive(Tween(begin: 0.2, end: 1.0)),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: context.c.primaryContainer,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final _ConvStatus status;
  final double pulse;
  final VoidCallback? onTap;
  const _MicButton({
    required this.status,
    required this.pulse,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isListening = status == _ConvStatus.listening;
    final isThinking = status == _ConvStatus.thinking;
    final size = isListening ? 48.0 + pulse * 4 : 48.0;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (isListening)
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: c.primaryContainer.withOpacity(0.3 + pulse * 0.4),
                    width: 1.5,
                  ),
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primaryContainer,
                boxShadow: [
                  BoxShadow(
                    color: c.primaryContainer.withOpacity(0.6),
                    blurRadius: 18,
                  ),
                ],
              ),
              child: Center(
                child: isThinking
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.onPrimary,
                        ),
                      )
                    : Icon(
                        isListening ? Icons.stop_rounded : Icons.mic,
                        color: c.onPrimary,
                        size: 22,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
