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
import '../models/conversation_message.dart';
import '../services/characters_service.dart';
import '../widgets/bubble_entrance.dart';
import '../widgets/feedback_pill.dart';
import '../widgets/mic_button.dart';
import '../widgets/scenario_strip.dart';
import '../widgets/speed_toggle.dart';
import 'character_picker_screen.dart';
import '../services/streaming_tts_buffer.dart';
import 'conversation_history_screen.dart';

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

  ConvStatus _status = ConvStatus.idle;
  String? _errorMsg;
  final List<ConversationMessage> _messages = [];
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
      if (_status == ConvStatus.playing || _status == ConvStatus.listening) {
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
      setState(() => _status = ConvStatus.ready);
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
        if (_status == ConvStatus.playing) {
          setState(() => _status = ConvStatus.ready);
          // Faz 5: hands-free mod → AI bittiğinde otomatik dinlemeye geç
          if (_handsFreeMode) {
            Future.delayed(const Duration(milliseconds: 250), () {
              if (!mounted) return;
              if (_status == ConvStatus.ready) _startListening();
            });
          }
        }
      });

      _tts.setErrorHandler((msg) {
        if (mounted) {
          setState(() {
            _status = ConvStatus.error;
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
          _status = ConvStatus.error;
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
    setState(() => _status = ConvStatus.ready);

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
    if (_status == ConvStatus.listening) {
      await _stopListening();
    } else if (_status == ConvStatus.ready) {
      await _startListening();
    }
  }

  Future<void> _startListening() async {
    if (!await _audioSvc.hasPermission()) {
      setState(() {
        _status = ConvStatus.error;
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

      setState(() => _status = ConvStatus.listening);
      _pulse.repeat(reverse: true);
    } catch (e) {
      _tearDownVad();
      setState(() {
        _status = ConvStatus.error;
        _errorMsg = AppL10n.of(context).conv_errMicOpen('$e');
      });
    }
  }

  void _onVadEvent(VadEvent event) {
    if (event == VadEvent.speechEnded || event == VadEvent.maxDurationReached) {
      if (_status == ConvStatus.listening) _stopListening();
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
        setState(() => _status = ConvStatus.thinking);
        await _processAudio(path);
      } else {
        setState(() {
          _status = ConvStatus.error;
          _errorMsg = AppL10n.of(context).conv_errRecordFailed;
        });
      }
    } catch (e) {
      setState(() {
        _status = ConvStatus.error;
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
          _status = ConvStatus.error;
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
          _status = ConvStatus.error;
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
    setState(() => _status = ConvStatus.thinking);

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
        _maybePerfectScore(turn.evaluation);
      } else {
        // STT returned nothing — drop the placeholder.
        setState(() => _messages.remove(userMsg));
        setState(() {
          _status = ConvStatus.error;
          _errorMsg = AppL10n.of(context).conv_errNoSpeech;
        });
        return;
      }

      // Render the AI reply and speak it.
      if (turn.reply.isNotEmpty) {
        final aiMsg = _addMessage(isUser: false, text: turn.reply);
        _persistMessage(aiMsg);
        _speakMessage(turn.reply);
        setState(() => _status = ConvStatus.playing);
      } else {
        setState(() => _status = ConvStatus.ready);
      }

      // Daily quest + XP best-effort (same as legacy _replyTo).
      _logTurnSideEffects();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.remove(userMsg);
        _status = ConvStatus.error;
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
    await _bumpQuest(QuestType.conversationTurns);
  }

  /// Daily quest progress'ini best-effort artırır; tamamlanmada XP server'da
  /// yazıldığı için profil cache'i düşürülür.
  Future<void> _bumpQuest(QuestType type, {int delta = 1}) async {
    try {
      final svc = ref.read(dailyQuestsServiceProvider);
      final updated = await svc.incrementByType(type, delta: delta);
      if (updated == null || !mounted) return;
      ref.invalidate(dailyQuestsProvider);
      if (updated.isCompleted) {
        await bustProfileCache();
        if (mounted) ref.invalidate(profileProvider);
      }
    } catch (_) {}
  }

  /// Edge prompt rubriğine göre 90-100 bandı "already perfect" demektir.
  void _maybePerfectScore(SpeechEvaluation? eval) {
    if (eval == null || eval.score < 90) return;
    unawaited(_bumpQuest(QuestType.perfectScore));
  }

  Future<void> _attachEvaluation(
      ConversationMessage userMsg, String text) async {
    try {
      final aiService = ref.read(geminiServiceProvider);
      final eval = await aiService.evaluateSpeech(text);
      if (!mounted) return;
      setState(() => userMsg.evaluation = eval);
      // Backfill the persisted row with evaluation fields.
      _patchEvaluation(userMsg);
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

  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _status == ConvStatus.thinking) return;
    _textCtrl.clear();
    final userMsg = _addMessage(isUser: true, text: text);
    _lastUserText = text;
    _persistMessage(userMsg);
    setState(() => _status = ConvStatus.thinking);
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

      setState(() => _status = ConvStatus.thinking);

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
      setState(() => _status = ConvStatus.playing);

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
      setState(() => _status = ConvStatus.ready);
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
    setState(() => _status = ConvStatus.thinking);
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
          _status = ConvStatus.error;
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

  ConversationMessage _addMessage({
    required bool isUser,
    required String text,
    bool isError = false,
  }) {
    final m = ConversationMessage(isUser: isUser, text: text, isError: isError);
    setState(() => _messages.add(m));
    Future.delayed(const Duration(milliseconds: 80), _scrollToBottom);
    return m;
  }

  Future<void> _persistMessage(ConversationMessage msg) async {
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

  Future<void> _patchEvaluation(ConversationMessage msg) async {
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
      _status == ConvStatus.ready || _status == ConvStatus.listening;

  Color _statusColor(AppPalette c) {
    switch (_status) {
      case ConvStatus.listening:
        return c.secondaryContainer;
      case ConvStatus.ready:
        return c.primaryFixed;
      case ConvStatus.thinking:
        return c.secondary;
      case ConvStatus.playing:
        return c.tertiaryFixedDim;
      case ConvStatus.error:
        return c.error;
      case ConvStatus.idle:
      case ConvStatus.connecting:
        return c.inkDim;
    }
  }

  String _statusLabel(AppL10n l) {
    switch (_status) {
      case ConvStatus.idle:
      case ConvStatus.connecting:
        return l.conv_statusStarting;
      case ConvStatus.ready:
        return l.conv_statusReady;
      case ConvStatus.listening:
        return l.conv_statusListening;
      case ConvStatus.thinking:
        return l.conv_statusThinking;
      case ConvStatus.playing:
        return l.conv_statusSpeaking;
      case ConvStatus.error:
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
                  child: _status == ConvStatus.error && _messages.isEmpty
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
          SpeedToggle(
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
              icon: _status == ConvStatus.connecting
                  ? Icons.sync
                  : _status == ConvStatus.listening
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
      final isBusy = _status == ConvStatus.idle ||
          _status == ConvStatus.connecting ||
          _status == ConvStatus.thinking;
      return _buildEmptyState(isBusy: isBusy);
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _messages.length + (_status == ConvStatus.thinking ? 1 : 0),
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
                BlinkingDot(index: 0),
                SizedBox(width: 4),
                BlinkingDot(index: 1),
                SizedBox(width: 4),
                BlinkingDot(index: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Long-press anywhere on a bubble → copy its text.
  void _copyMessage(ConversationMessage msg) {
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
  Future<void> _replayMessage(ConversationMessage msg) async {
    if (_status == ConvStatus.listening || _status == ConvStatus.thinking) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _status = ConvStatus.playing);
    await _speakMessage(msg.text);
  }

  Widget _buildBubble(ConversationMessage msg) {
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
              child: FeedbackPill(evaluation: msg.evaluation!),
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
    return BubbleEntrance(fromRight: isUser, child: bubble);
  }

  Widget _buildEmptyState({required bool isBusy}) {
    final l = AppL10n.of(context);
    final c = context.c;
    final hint = _status == ConvStatus.connecting
        ? l.conv_preparing
        : _status == ConvStatus.thinking
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
            ScenarioStrip(
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
      _status = ConvStatus.idle;
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
    final isListening = _status == ConvStatus.listening;
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
              if (_status == ConvStatus.listening)
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
                    label: _status == ConvStatus.listening
                        ? l.conv_stopRecording
                        : l.conv_startRecording,
                    button: true,
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => MicButton(
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
