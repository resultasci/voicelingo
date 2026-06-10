import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  bool _obscurePass = true;
  String? _error;
  bool _showConfirmEmail = false;

  static final _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$');

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppL10n.of(context);
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = l.auth_validation_fillAll);
      return;
    }
    if (!_isLogin && name.isEmpty) {
      setState(() => _error = l.auth_err_enterName);
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _error = l.auth_err_invalidEmail);
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = l.auth_err_passwordMin6);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = ref.read(authServiceProvider);
    try {
      if (_isLogin) {
        await auth.signIn(email, pass);
      } else {
        await auth.signUp(email, pass, username: name);
        if (mounted) setState(() => _showConfirmEmail = true);
      }
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
    if (s.contains('invalid login') || s.contains('invalid credentials')) {
      return l.auth_err_invalidCredentials;
    }
    if (s.contains('email') && s.contains('confirm')) {
      return l.auth_err_emailNotConfirmed;
    }
    if (s.contains('email not confirmed')) {
      return l.auth_err_emailNotConfirmed;
    }
    if (s.contains('user already') || s.contains('already registered')) {
      return l.auth_err_alreadyRegistered;
    }
    if (s.contains('password') && s.contains('6')) {
      return l.auth_err_passwordMin6;
    }
    if (s.contains('network') || s.contains('socket')) {
      return l.auth_err_noInternet;
    }
    return l.auth_err_generic;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (_showConfirmEmail) {
      return _ConfirmEmailScreen(
        email: _emailCtrl.text.trim(),
        onBack: () => setState(() {
          _showConfirmEmail = false;
          _isLogin = true;
        }),
      );
    }

    return Scaffold(
      backgroundColor: c.bg,
      body: CosmicBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.vertical),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    // One-shot entrance: panel fades in and settles upward.
                    child: reduceMotion(context)
                        ? _buildPanel()
                        : TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutCubic,
                            builder: (_, t, child) => Opacity(
                              opacity: t,
                              child: Transform.translate(
                                offset: Offset(0, (1 - t) * 24),
                                child: child,
                              ),
                            ),
                            child: _buildPanel(),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel() {
    final l = AppL10n.of(context);
    final c = context.c;
    final dark = c.isDark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
          decoration: BoxDecoration(
            color: (dark ? Colors.black : Colors.white).withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: (dark ? Colors.white : Colors.black).withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(dark ? 0.8 : 0.15),
                blurRadius: 50,
                spreadRadius: -10,
              ),
              BoxShadow(
                color: c.primaryContainer.withOpacity(0.08),
                blurRadius: 40,
              ),
            ],
          ),
          // AnimatedSize: login ↔ signup toggle ve hata banner'ı yumuşak
          // yükseklik geçişiyle girer/çıkar.
          child: AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBrand(),
                const SizedBox(height: 28),
                if (_error != null) ...[
                  _ErrorBanner(message: _error!),
                  const SizedBox(height: 16),
                ],
                if (!_isLogin) ...[
                  _FieldGroup(
                    label: l.auth_fullName,
                    child: NeonField(
                      controller: _nameCtrl,
                      leadingIcon: Icons.person_outline,
                      hint: l.auth_nameHint,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                _FieldGroup(
                  label: _isLogin ? l.auth_emailLabel : l.auth_commsChannel,
                  child: NeonField(
                    controller: _emailCtrl,
                    leadingIcon: Icons.mail_outline,
                    hint: 'user@galaxy.net',
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(height: 18),
                _FieldGroup(
                  label: _isLogin ? l.auth_securityCode : l.auth_accessKey,
                  child: NeonField(
                    controller: _passCtrl,
                    leadingIcon: Icons.lock_outline,
                    hint: '••••••••',
                    obscure: _obscurePass,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: c.inkDim,
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                ),
                if (_isLogin)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ForgotPasswordScreen(
                            initialEmail: _emailCtrl.text.trim(),
                          ),
                        ));
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: c.inkMuted,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l.auth_forgotPassword,
                        style: AppText.body(12, color: c.primaryContainer),
                      ),
                    ),
                  ),
                SizedBox(height: _isLogin ? 16 : 28),
                NeonButton(
                  label: _isLogin ? l.auth_loginBtn : l.auth_signupBtn,
                  loading: _loading,
                  onTap: _submit,
                  height: 56,
                ),
                const SizedBox(height: 22),
                _buildToggle(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrand() {
    final l = AppL10n.of(context);
    final c = context.c;
    return Column(
      children: [
        const BrandLogo(size: 76),
        const SizedBox(height: 18),
        Text(
          'VOICELINGO',
          style: AppText.hero(34,
                  color: c.primaryContainer, weight: FontWeight.w700)
              .copyWith(
            shadows: neonGlow(c.primaryContainer, blur: 18, opacity: 0.6),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin ? l.auth_subtitleLogin : l.auth_subtitleSignup,
          style: AppText.body(14, color: c.inkMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildToggle() {
    final l = AppL10n.of(context);
    final c = context.c;
    return Center(
      child: TextButton(
        onPressed: () => setState(() {
          _isLogin = !_isLogin;
          _error = null;
        }),
        style: TextButton.styleFrom(
          foregroundColor: c.inkMuted,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        child: RichText(
          text: TextSpan(
            style: AppText.body(13, color: c.inkMuted),
            children: [
              TextSpan(
                  text:
                      _isLogin ? l.auth_toggleToSignup : l.auth_toggleToLogin),
              TextSpan(
                text: _isLogin ? l.auth_signUpShort : l.auth_signInShort,
                style: AppText.ink(13,
                    color: c.primaryContainer, weight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
class _FieldGroup extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldGroup({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppText.label(10,
                color: context.c.inkMuted, weight: FontWeight.w600)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
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
            child: Text(message, style: AppText.ink(13, color: c.error)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
class _ConfirmEmailScreen extends StatelessWidget {
  final String email;
  final VoidCallback onBack;
  const _ConfirmEmailScreen({required this.email, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.c;
    return Scaffold(
      backgroundColor: c.bg,
      body: CosmicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: GlassPanel(
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
                            border: Border.all(
                                color: c.primaryFixedDim.withOpacity(0.5)),
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
                        l.auth_confirmTitle,
                        textAlign: TextAlign.center,
                        style: AppText.hero(28,
                                color: c.primary, weight: FontWeight.w700)
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
                        l.auth_confirmBody,
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
