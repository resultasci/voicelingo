import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';

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
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final name = _nameCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Tüm alanları doldur.');
      return;
    }
    if (!_isLogin && name.isEmpty) {
      setState(() => _error = 'Adını gir.');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _error = 'Geçerli bir e-posta adresi gir.');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Şifre en az 6 karakter olmalı.');
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
    final l = raw.toLowerCase();
    if (l.contains('invalid login') || l.contains('invalid credentials')) {
      return 'E-posta veya şifre yanlış.';
    }
    if (l.contains('email') && l.contains('confirm')) {
      return 'E-posta adresini doğrulaman gerekiyor.';
    }
    if (l.contains('email not confirmed')) {
      return 'E-posta adresini doğrulaman gerekiyor.';
    }
    if (l.contains('user already') || l.contains('already registered')) {
      return 'Bu e-posta zaten kayıtlı. Giriş yapmayı dene.';
    }
    if (l.contains('password') && l.contains('6')) {
      return 'Şifre en az 6 karakter olmalı.';
    }
    if (l.contains('network') || l.contains('socket')) {
      return 'İnternet bağlantısı yok.';
    }
    return 'Bir hata oluştu. Tekrar dene.';
  }

  @override
  Widget build(BuildContext context) {
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
      backgroundColor: AppColors.bg,
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
                    child: _buildPanel(),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.8),
                blurRadius: 50,
                spreadRadius: -10,
              ),
              BoxShadow(
                color: AppColors.primaryContainer.withOpacity(0.08),
                blurRadius: 40,
              ),
            ],
          ),
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
                  label: 'AD SOYAD',
                  child: NeonField(
                    controller: _nameCtrl,
                    leadingIcon: Icons.person_outline,
                    hint: 'Adın',
                  ),
                ),
                const SizedBox(height: 18),
              ],
              _FieldGroup(
                label: _isLogin ? 'E-POSTA' : 'İLETİŞİM KANALI',
                child: NeonField(
                  controller: _emailCtrl,
                  leadingIcon: Icons.mail_outline,
                  hint: 'user@galaxy.net',
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(height: 18),
              _FieldGroup(
                label: _isLogin ? 'GÜVENLİK KODU' : 'ERİŞİM ANAHTARI',
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
                      color: AppColors.inkDim,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              NeonButton(
                label: _isLogin ? 'GİRİŞ YAP' : 'KAYDOL',
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
    );
  }

  Widget _buildBrand() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.primaryContainer.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryContainer.withOpacity(0.4),
                blurRadius: 24,
              ),
            ],
          ),
          child: const Icon(Icons.public,
              color: AppColors.primaryContainer, size: 28),
        ),
        const SizedBox(height: 18),
        Text(
          'VOICELINGO',
          style: AppText.hero(34,
                  color: AppColors.primaryContainer, weight: FontWeight.w700)
              .copyWith(
            shadows:
                neonGlow(AppColors.primaryContainer, blur: 18, opacity: 0.6),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin ? 'İletişim Kanalını Başlat' : 'Dilbilim yolculuğuna başla.',
          style: AppText.body(14, color: AppColors.inkMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildToggle() {
    return Center(
      child: TextButton(
        onPressed: () => setState(() {
          _isLogin = !_isLogin;
          _error = null;
        }),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.inkMuted,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
        child: RichText(
          text: TextSpan(
            style: AppText.body(13, color: AppColors.inkMuted),
            children: [
              TextSpan(
                  text: _isLogin
                      ? 'Henüz yörüngede değil misin? '
                      : 'Zaten yörüngede misin? '),
              TextSpan(
                text: _isLogin ? 'Kaydol' : 'Giriş yap',
                style: AppText.ink(13,
                    color: AppColors.primaryContainer, weight: FontWeight.w600),
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
                color: AppColors.inkMuted, weight: FontWeight.w600)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child:
                Text(message, style: AppText.ink(13, color: AppColors.error)),
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CosmicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: GlassPanel(
                  padding: const EdgeInsets.all(32),
                  glowColor: AppColors.primaryFixedDim,
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
                            color: AppColors.primaryFixedDim.withOpacity(0.15),
                            border: Border.all(
                                color:
                                    AppColors.primaryFixedDim.withOpacity(0.5)),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.primaryFixedDim.withOpacity(0.4),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.mark_email_read_outlined,
                              color: AppColors.primaryFixedDim, size: 30),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Gelen kutunu aç.',
                        textAlign: TextAlign.center,
                        style: AppText.hero(28,
                                color: AppColors.primary,
                                weight: FontWeight.w700)
                            .copyWith(
                          shadows: neonGlow(AppColors.primary, blur: 12),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        email,
                        textAlign: TextAlign.center,
                        style: AppText.code(13,
                            color: AppColors.primaryContainer,
                            weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'adresine bir doğrulama linki gönderdik. Linke tıkladıktan sonra giriş yapabilirsin.',
                        textAlign: TextAlign.center,
                        style: AppText.body(13),
                      ),
                      const SizedBox(height: 28),
                      GhostButton(
                        label: 'Giriş Ekranına Dön',
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
