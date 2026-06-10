import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../auth_validators.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String? initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final TextEditingController _emailCtrl;
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppL10n.of(context);
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !authEmailRegex.hasMatch(email)) {
      setState(() => _error = l.auth_err_invalidEmail);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      if (!mounted) return;
      setState(() => _sent = true);
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _error = _humanize(e.message));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = _humanize(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _humanize(String raw) {
    final l = AppL10n.of(context);
    final s = raw.toLowerCase();
    if (s.contains('rate limit') || s.contains('too many')) {
      return l.fp_rateLimit;
    }
    if (s.contains('network') || s.contains('socket')) {
      return l.auth_err_noInternet;
    }
    return l.auth_err_generic;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      body: CosmicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back,
                          color: c.primaryContainer, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 460),
                        child: _sent
                            ? _SentPanel(
                                email: _emailCtrl.text.trim(),
                                onBack: () => Navigator.of(context).pop(),
                              )
                            : _RequestPanel(
                                emailCtrl: _emailCtrl,
                                error: _error,
                                loading: _loading,
                                onSubmit: _submit,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestPanel extends StatelessWidget {
  final TextEditingController emailCtrl;
  final String? error;
  final bool loading;
  final VoidCallback onSubmit;

  const _RequestPanel({
    required this.emailCtrl,
    required this.error,
    required this.loading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return GlassPanel(
      padding: const EdgeInsets.all(28),
      glowColor: c.primaryContainer,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primaryContainer.withOpacity(0.12),
                border: Border.all(color: c.primaryContainer.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: c.primaryContainer.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child:
                  Icon(Icons.lock_reset, color: c.primaryContainer, size: 30),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            l.fp_title,
            textAlign: TextAlign.center,
            style: AppText.hero(26, color: c.primary, weight: FontWeight.w700)
                .copyWith(
              shadows: neonGlow(c.primary, blur: 12),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l.fp_subtitle,
            textAlign: TextAlign.center,
            style: AppText.body(13, color: c.inkMuted),
          ),
          const SizedBox(height: 24),
          if (error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: c.errorContainer.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.error.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: c.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(error!, style: AppText.ink(13, color: c.error)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(l.auth_emailLabel,
              style: AppText.label(10,
                  color: c.inkMuted, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          NeonField(
            controller: emailCtrl,
            leadingIcon: Icons.mail_outline,
            hint: 'user@galaxy.net',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          NeonButton(
            label: l.fp_sendBtn,
            icon: Icons.send,
            loading: loading,
            onTap: onSubmit,
            height: 54,
          ),
        ],
      ),
    );
  }
}

class _SentPanel extends StatelessWidget {
  final String email;
  final VoidCallback onBack;

  const _SentPanel({required this.email, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return GlassPanel(
      padding: const EdgeInsets.all(32),
      glowColor: c.primaryFixedDim,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.primaryFixedDim.withOpacity(0.15),
                border: Border.all(color: c.primaryFixedDim.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: c.primaryFixedDim.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(Icons.mark_email_read_outlined,
                  color: c.primaryFixedDim, size: 30),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l.fp_sentTitle,
            textAlign: TextAlign.center,
            style: AppText.hero(26, color: c.primary, weight: FontWeight.w700)
                .copyWith(
              shadows: neonGlow(c.primary, blur: 12),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            email,
            textAlign: TextAlign.center,
            style: AppText.code(13,
                color: c.primaryContainer, weight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            l.fp_sentBody,
            textAlign: TextAlign.center,
            style: AppText.body(13, color: c.inkMuted),
          ),
          const SizedBox(height: 28),
          GhostButton(
            label: l.auth_backToLogin,
            icon: Icons.arrow_back,
            onTap: onBack,
          ),
        ],
      ),
    );
  }
}
