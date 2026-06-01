import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;
  bool _success = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text;
    final next = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Tüm alanları doldur.');
      return;
    }
    if (next.length < 6) {
      setState(() => _error = 'Yeni şifre en az 6 karakter olmalı.');
      return;
    }
    if (next != confirm) {
      setState(() => _error = 'Yeni şifreler eşleşmiyor.');
      return;
    }
    if (current == next) {
      setState(() => _error = 'Yeni şifre eskisinden farklı olmalı.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).changePassword(
            currentPassword: current,
            newPassword: next,
          );
      if (!mounted) return;
      setState(() => _success = true);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop();
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
    if (l.contains('invalid login') || l.contains('invalid credentials')) {
      return 'Mevcut şifre yanlış.';
    }
    if (l.contains('same password') ||
        l.contains('new password should be different')) {
      return 'Yeni şifre eskisinden farklı olmalı.';
    }
    if (l.contains('weak password')) {
      return 'Şifre çok zayıf, daha güçlü bir şifre seç.';
    }
    if (l.contains('network') || l.contains('socket')) {
      return 'İnternet bağlantısı yok.';
    }
    return 'Şifre güncellenemedi. Tekrar dene.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            children: [
              const _TopBar(title: 'ŞİFRE DEĞİŞTİR'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: GlassPanel(
                    padding: const EdgeInsets.all(22),
                    glowColor: AppColors.primaryContainer,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lock_reset,
                                color: AppColors.primaryContainer, size: 24),
                            const SizedBox(width: 10),
                            Text(
                              'Erişim Anahtarını Değiştir',
                              style: AppText.title(18,
                                  color: AppColors.primaryContainer,
                                  weight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Güvenliğin için önce mevcut şifreni doğrulamamız gerekiyor.',
                          style: AppText.body(13, color: AppColors.inkMuted),
                        ),
                        const SizedBox(height: 22),
                        if (_error != null) ...[
                          _ErrorBanner(message: _error!),
                          const SizedBox(height: 16),
                        ],
                        if (_success) ...[
                          const _SuccessBanner(
                              message: 'Şifren başarıyla güncellendi.'),
                          const SizedBox(height: 16),
                        ],
                        _LabeledField(
                          label: 'MEVCUT ŞİFRE',
                          child: NeonField(
                            controller: _currentCtrl,
                            leadingIcon: Icons.lock_outline,
                            hint: '••••••••',
                            obscure: _obscureCurrent,
                            suffix: _eyeButton(
                                _obscureCurrent,
                                () => setState(
                                    () => _obscureCurrent = !_obscureCurrent)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _LabeledField(
                          label: 'YENİ ŞİFRE',
                          child: NeonField(
                            controller: _newCtrl,
                            leadingIcon: Icons.vpn_key_outlined,
                            hint: 'En az 6 karakter',
                            obscure: _obscureNew,
                            suffix: _eyeButton(
                                _obscureNew,
                                () =>
                                    setState(() => _obscureNew = !_obscureNew)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _LabeledField(
                          label: 'YENİ ŞİFRE (TEKRAR)',
                          child: NeonField(
                            controller: _confirmCtrl,
                            leadingIcon: Icons.vpn_key_outlined,
                            hint: 'Yeniden gir',
                            obscure: _obscureConfirm,
                            suffix: _eyeButton(
                                _obscureConfirm,
                                () => setState(
                                    () => _obscureConfirm = !_obscureConfirm)),
                          ),
                        ),
                        const SizedBox(height: 28),
                        NeonButton(
                          label: 'ŞİFREYİ GÜNCELLE',
                          icon: Icons.check,
                          loading: _loading,
                          onTap: _submit,
                          height: 52,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eyeButton(bool obscured, VoidCallback toggle) {
    return IconButton(
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.inkDim,
        size: 20,
      ),
      onPressed: toggle,
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom:
              BorderSide(color: AppColors.primaryContainer.withOpacity(0.2)),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryContainer.withOpacity(0.08),
            blurRadius: 30,
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppColors.primaryContainer, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: AppText.label(13,
                        color: AppColors.primaryContainer,
                        weight: FontWeight.w700)
                    .copyWith(
                  shadows: neonGlow(AppColors.primaryContainer,
                      blur: 12, opacity: 0.8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppText.label(10,
                color: AppColors.primaryContainer.withOpacity(0.7),
                weight: FontWeight.w600)),
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

class _SuccessBanner extends StatelessWidget {
  final String message;
  const _SuccessBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.primary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child:
                Text(message, style: AppText.ink(13, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
