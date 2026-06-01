import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';

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

  static final _emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.\w{2,}$');

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
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      setState(() => _error = 'Geçerli bir e-posta adresi gir.');
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
    final l = raw.toLowerCase();
    if (l.contains('rate limit') || l.contains('too many')) {
      return 'Çok fazla istek. Birkaç dakika sonra tekrar dene.';
    }
    if (l.contains('network') || l.contains('socket')) {
      return 'İnternet bağlantısı yok.';
    }
    return 'Bir hata oluştu. Tekrar dene.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
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
                      icon: const Icon(Icons.arrow_back,
                          color: AppColors.primaryContainer, size: 22),
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
    return GlassPanel(
      padding: const EdgeInsets.all(28),
      glowColor: AppColors.primaryContainer,
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
                color: AppColors.primaryContainer.withOpacity(0.12),
                border: Border.all(
                    color: AppColors.primaryContainer.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryContainer.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.lock_reset,
                  color: AppColors.primaryContainer, size: 30),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Şifreni mi unuttun?',
            textAlign: TextAlign.center,
            style: AppText.hero(26,
                    color: AppColors.primary, weight: FontWeight.w700)
                .copyWith(
              shadows: neonGlow(AppColors.primary, blur: 12),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'E-posta adresini gir, sana yeni bir şifre belirleyeceğin bir bağlantı gönderelim.',
            textAlign: TextAlign.center,
            style: AppText.body(13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 24),
          if (error != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.errorContainer.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.error.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(error!,
                        style: AppText.ink(13, color: AppColors.error)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text('E-POSTA',
              style: AppText.label(10,
                  color: AppColors.inkMuted, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          NeonField(
            controller: emailCtrl,
            leadingIcon: Icons.mail_outline,
            hint: 'user@galaxy.net',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 24),
          NeonButton(
            label: 'BAĞLANTI GÖNDER',
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
    return GlassPanel(
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
                    color: AppColors.primaryFixedDim.withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryFixedDim.withOpacity(0.4),
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
            'Bağlantı yola çıktı.',
            textAlign: TextAlign.center,
            style: AppText.hero(26,
                    color: AppColors.primary, weight: FontWeight.w700)
                .copyWith(
              shadows: neonGlow(AppColors.primary, blur: 12),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            email,
            textAlign: TextAlign.center,
            style: AppText.code(13,
                color: AppColors.primaryContainer, weight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            'adresine bir bağlantı gönderdik. Gelen kutunu (ve spam klasörünü) kontrol et — bağlantıya tıkladığında uygulama açılacak ve yeni şifreni belirleyebileceksin.',
            textAlign: TextAlign.center,
            style: AppText.body(13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 28),
          GhostButton(
            label: 'Giriş Ekranına Dön',
            icon: Icons.arrow_back,
            onTap: onBack,
          ),
        ],
      ),
    );
  }
}
