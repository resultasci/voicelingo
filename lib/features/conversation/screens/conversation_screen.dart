import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ai/character_avatar.dart';
import '../../../core/audio/waveform_painter.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../models/scenario.dart';
import '../../../theme/app_theme.dart';
import '../../scenarios/screens/scenario_picker_screen.dart';
import '../controllers/conversation_controller.dart';
import '../models/conversation_message.dart';
import '../widgets/bubble_entrance.dart';
import '../widgets/feedback_pill.dart';
import '../widgets/mic_button.dart';
import '../widgets/scenario_strip.dart';
import '../widgets/speed_toggle.dart';
import 'character_picker_screen.dart';
import 'conversation_history_screen.dart';

/// Konuşma ekranı — iş mantığı [ConversationController]'da; burada yalnızca
/// görsel katman, animasyon yan etkileri (pulse, scroll), haptics ve
/// navigation var. Üç bölge (header / mesajlar / input bar) ayrı
/// ListenableBuilder'larla dinler; controller notify'ları Scaffold +
/// CosmicBackground kabuğunu rebuild etmez.
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
  late final ConversationController _c;
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _textCtrl = TextEditingController();
  late final AnimationController _pulse;
  int _lastMsgCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _c = ConversationController(
      read: ref.read,
      invalidate: ref.invalidate,
      scenario: widget.scenario,
      // Embedded Practice tab is built inside HomeScreen's IndexedStack — it
      // mounts even when the user is on a different tab, so we must not
      // auto-speak there. Pushed instances are user-intentional, so we greet.
      isEmbedded: !widget.showBackButton,
      greetingText: () => mounted ? AppL10n.of(context).conv_greeting : '',
      replyFailedText: () =>
          mounted ? AppL10n.of(context).conv_replyFailed : '',
      onReplyError: _showReplyError,
    );
    _c.addListener(_onControllerEvent);
    _c.init();
  }

  /// Controller bildirimlerinin UI yan etkileri: mic pulse animasyonu ve
  /// yeni mesajda en alta kaydırma. Rebuild'ler ListenableBuilder'larda.
  void _onControllerEvent() {
    if (!mounted) return;
    if (_c.status == ConvStatus.listening) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else if (_pulse.isAnimating) {
      _pulse.stop();
    }
    if (_c.messages.length > _lastMsgCount) {
      Future.delayed(const Duration(milliseconds: 80), _scrollToBottom);
    }
    _lastMsgCount = _c.messages.length;
  }

  void _showReplyError(String detail) {
    if (!mounted) return;
    final l = AppL10n.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: context.c.bgCard,
        content: Text(
          l.conv_aiNoResponse(detail),
          style: AppText.ink(13, color: context.c.error),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (_c.status == ConvStatus.playing ||
          _c.status == ConvStatus.listening) {
        _c.stopAudioAndCleanUp();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c.removeListener(_onControllerEvent);
    _c.dispose();
    _pulse.dispose();
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  /// Header avatar tap → character picker. On return, hot-swap the active
  /// character (voice + system prompt) without resetting the conversation.
  Future<void> _openCharacterPicker() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CharacterPickerScreen()),
    );
    if (!mounted) return;
    await _c.reloadCharacter();
  }

  Future<void> _toggleMic() async {
    HapticFeedback.lightImpact();
    await _c.toggleMic();
  }

  Future<void> _sendText() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _c.status == ConvStatus.thinking) return;
    _textCtrl.clear();
    await _c.sendText(text);
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
    HapticFeedback.selectionClick();
    await _c.replayMessage(msg);
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

  String _errorText(AppL10n l) {
    final d = _c.errorDetail ?? '';
    return switch (_c.errorCode) {
      ConvError.micPermission => l.conv_errMicPermission,
      ConvError.micOpen => l.conv_errMicOpen(d),
      ConvError.recordFailed => l.conv_errRecordFailed,
      ConvError.audioProcess => l.conv_errAudioProcess(d),
      ConvError.noSpeech => l.conv_errNoSpeech,
      ConvError.ttsInit => l.conv_errTtsInit,
      ConvError.tts => l.conv_errTts(d),
      ConvError.speak => l.conv_errSpeak(d),
      ConvError.generic => l.conv_errGeneric(d),
      null => l.conv_errUnknown,
    };
  }

  Color _statusColor(AppPalette c) {
    switch (_c.status) {
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
    switch (_c.status) {
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
                ListenableBuilder(
                  listenable: _c,
                  builder: (_, __) => _buildHeader(),
                ),
                Expanded(
                  child: ListenableBuilder(
                    listenable: _c,
                    builder: (_, __) =>
                        _c.status == ConvStatus.error && _c.messages.isEmpty
                            ? _buildError()
                            : _buildMessages(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: ListenableBuilder(
            listenable: _c,
            builder: (_, __) => _buildInputBar(),
          ),
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
                          CharacterAvatar(character: _c.character, size: 30),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _c.character.displayName,
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
            rate: _c.ttsRate,
            onChanged: _c.setTtsRate,
          ),
          const SizedBox(width: 4),
          // Hands-free toggle — AI cevap verince otomatik mikrofon
          Semantics(
            label: l.conversation_handsfree,
            button: true,
            child: IconButton(
              icon: Icon(
                _c.handsFreeMode ? Icons.hearing : Icons.hearing_disabled,
                color: _c.handsFreeMode ? c.primaryContainer : c.inkDim,
                size: 20,
              ),
              padding: const EdgeInsets.all(6),
              constraints: tightConstraints,
              visualDensity: compactBtn,
              tooltip: _c.handsFreeMode
                  ? l.conv_handsFreeOnTip
                  : l.conv_handsFreeOffTip,
              onPressed: () {
                HapticFeedback.selectionClick();
                _c.setHandsFree(!_c.handsFreeMode);
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
          if (_c.messages.isNotEmpty)
            Semantics(
              label: l.conv_newChat,
              child: IconButton(
                icon:
                    Icon(Icons.add_comment_outlined, color: c.inkDim, size: 20),
                padding: const EdgeInsets.all(6),
                constraints: tightConstraints,
                visualDensity: compactBtn,
                onPressed: _c.reset,
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
              key: ValueKey(_c.status),
              text: _statusLabel(l),
              color: _statusColor(c),
              icon: _c.status == ConvStatus.connecting
                  ? Icons.sync
                  : _c.status == ConvStatus.listening
                      ? Icons.fiber_manual_record
                      : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_c.messages.isEmpty) {
      final isBusy = _c.status == ConvStatus.idle ||
          _c.status == ConvStatus.connecting ||
          _c.status == ConvStatus.thinking;
      return _buildEmptyState(isBusy: isBusy);
    }

    return ListView.builder(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount:
          _c.messages.length + (_c.status == ConvStatus.thinking ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _c.messages.length) {
          return _buildThinkingBubble();
        }
        return _buildBubble(_c.messages[i]);
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
            child: CharacterAvatar(character: _c.character, size: 32),
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
                  child: CharacterAvatar(character: _c.character, size: 32),
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
                  onTap: _c.retryLastReply,
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
    final hint = _c.status == ConvStatus.connecting
        ? l.conv_preparing
        : _c.status == ConvStatus.thinking
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
                      child: CharacterAvatar(character: _c.character, size: 84),
                    ),
                  ),
          ),
          const SizedBox(height: 18),
          Center(
            child: Text(
              widget.scenario?.title ??
                  (isBusy ? l.conv_aiPracticeMode : _c.character.displayName),
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
                if (!widget.showBackButton) {
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
                _errorText(l),
                style: AppText.body(14, color: c.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              GhostButton(
                label: l.conv_restart,
                icon: Icons.refresh,
                onTap: _c.reset,
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
    final isListening = _c.status == ConvStatus.listening;
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
              if (isListening)
                Expanded(
                  flex: 0,
                  child: SizedBox(
                    width: 80,
                    height: 32,
                    child: AnimatedBuilder(
                      animation: _c.amplitudes,
                      builder: (_, __) => CustomPaint(
                        painter: WaveformPainter(
                          amplitudes: _c.amplitudes.value,
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
                    label: isListening
                        ? l.conv_stopRecording
                        : l.conv_startRecording,
                    button: true,
                    child: AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => MicButton(
                        status: _c.status,
                        pulse: _pulse.value,
                        onTap: _c.canToggleMic ? _toggleMic : null,
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
