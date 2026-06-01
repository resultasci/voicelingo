import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../providers/auth_provider.dart';
import '../../../theme/app_theme.dart';

/// Shown when the user opens a Supabase password-recovery deep link.
/// At this point Supabase has already exchanged the code for a session, so
/// `auth.updateUser(password: ...)` will succeed.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  bool _success = false;
  String? _error;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final next = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (next.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Tüm alanları doldur.');
      return;
    }
    if (next.length < 6) {
      setState(() => _error = 'Şifre en az 6 karakter olmalı.');
      return;
    }
    if (next != confirm) {
      setState(() => _error = 'Şifreler eşleşmiyor.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).updatePassword(next);
      if (!mounted) return;
      setState(() => _success = true);
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
    if (l.contains('same password') ||
        l.contains('new password should be different')) {
      return 'Yeni şifre eskisinden farklı olmalı.';
    }
    if (l.contains('weak password')) {
      return 'Şifre çok zayıf, daha güçlü bir şifre seç.';
    }
    if (l.contains('expired') || l.contains('invalid token')) {
      return 'Bağlantının süresi dolmuş. Yeniden talep et.';
    }
    if (l.contains('network') || l.contains('socket')) {
      return 'İnternet bağlantısı yok.';
    }
    return 'Şifre güncellenemedi. Tekrar dene.';
  }

  Future<void> _finish() async {
    await ref.read(authServiceProvider).signOut();
  }

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
                child: SingleChildScrollView(
                  child: _success ? _buildSuccess() : _buildForm(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
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
              child: const Icon(Icons.vpn_key_outlined,
                  color: AppColors.primaryContainer, size: 30),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Yeni Şifre Belirle',
            textAlign: TextAlign.center,
            style: AppText.hero(26,
                    color: AppColors.primary, weight: FontWeight.w700)
                .copyWith(
              shadows: neonGlow(AppColors.primary, blur: 12),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bağlantı doğrulandı. Hesabın için yeni bir şifre seç.',
            textAlign: TextAlign.center,
            style: AppText.body(13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[
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
                    child: Text(_error!,
                        style: AppText.ink(13, color: AppColors.error)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text('YENİ ŞİFRE',
              style: AppText.label(10,
                  color: AppColors.inkMuted, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          NeonField(
            controller: _newCtrl,
            leadingIcon: Icons.lock_outline,
            hint: 'En az 6 karakter',
            obscure: _obscureNew,
            suffix: IconButton(
              icon: Icon(
                _obscureNew
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.inkDim,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
          const SizedBox(height: 16),
          Text('YENİ ŞİFRE (TEKRAR)',
              style: AppText.label(10,
                  color: AppColors.inkMuted, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          NeonField(
            controller: _confirmCtrl,
            leadingIcon: Icons.lock_outline,
            hint: 'Yeniden gir',
            obscure: _obscureConfirm,
            suffix: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.inkDim,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          const SizedBox(height: 28),
          NeonButton(
            label: 'ŞİFREYİ KAYDET',
            icon: Icons.check,
            loading: _loading,
            onTap: _submit,
            height: 54,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return GlassPanel(
      padding: const EdgeInsets.all(32),
      glowColor: AppColors.primary,
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
                color: AppColors.primary.withOpacity(0.18),
                border: Border.all(color: AppColors.primary.withOpacity(0.6)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: AppColors.primary, size: 32),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Şifren güncellendi',
            textAlign: TextAlign.center,
            style: AppText.hero(26,
                    color: AppColors.primary, weight: FontWeight.w700)
                .copyWith(
              shadows: neonGlow(AppColors.primary, blur: 12),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Yeni şifrenle giriş yapabilirsin.',
            textAlign: TextAlign.center,
            style: AppText.body(13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 28),
          NeonButton(
            label: 'GİRİŞ EKRANINA DÖN',
            icon: Icons.login,
            onTap: _finish,
            height: 52,
          ),
        ],
      ),
    );
  }
}
