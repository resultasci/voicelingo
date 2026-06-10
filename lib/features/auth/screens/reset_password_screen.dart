import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../auth_validators.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';

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
    final l = AppL10n.of(context);
    final next = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (next.isEmpty || confirm.isEmpty) {
      setState(() => _error = l.auth_validation_fillAll);
      return;
    }
    if (next.length < authPasswordMinLength) {
      setState(() => _error = l.auth_err_passwordMin6);
      return;
    }
    if (next != confirm) {
      setState(() => _error = l.rp_mismatch);
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
    final l = AppL10n.of(context);
    final s = raw.toLowerCase();
    if (s.contains('same password') ||
        s.contains('new password should be different')) {
      return l.cp_mustDiffer;
    }
    if (s.contains('weak password')) {
      return l.cp_weak;
    }
    if (s.contains('expired') || s.contains('invalid token')) {
      return l.rp_expired;
    }
    if (s.contains('network') || s.contains('socket')) {
      return l.auth_err_noInternet;
    }
    return l.cp_updateFailed;
  }

  Future<void> _finish() async {
    await ref.read(authServiceProvider).signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.bg,
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
              child: Icon(Icons.vpn_key_outlined,
                  color: c.primaryContainer, size: 30),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            l.rp_title,
            textAlign: TextAlign.center,
            style: AppText.hero(26, color: c.primary, weight: FontWeight.w700)
                .copyWith(
              shadows: neonGlow(c.primary, blur: 12),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            l.rp_subtitle,
            textAlign: TextAlign.center,
            style: AppText.body(13, color: c.inkMuted),
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[
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
                    child:
                        Text(_error!, style: AppText.ink(13, color: c.error)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(l.cp_new,
              style: AppText.label(10,
                  color: c.inkMuted, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          NeonField(
            controller: _newCtrl,
            leadingIcon: Icons.lock_outline,
            hint: l.cp_min6Hint,
            obscure: _obscureNew,
            suffix: IconButton(
              icon: Icon(
                _obscureNew
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: c.inkDim,
                size: 20,
              ),
              onPressed: () => setState(() => _obscureNew = !_obscureNew),
            ),
          ),
          const SizedBox(height: 16),
          Text(l.cp_newRepeat,
              style: AppText.label(10,
                  color: c.inkMuted, weight: FontWeight.w600)),
          const SizedBox(height: 8),
          NeonField(
            controller: _confirmCtrl,
            leadingIcon: Icons.lock_outline,
            hint: l.cp_reenterHint,
            obscure: _obscureConfirm,
            suffix: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: c.inkDim,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
          const SizedBox(height: 28),
          NeonButton(
            label: l.rp_saveBtn,
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
    final l = AppL10n.of(context);
    final c = context.c;
    return GlassPanel(
      padding: const EdgeInsets.all(32),
      glowColor: c.primary,
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
                color: c.primary.withOpacity(0.18),
                border: Border.all(color: c.primary.withOpacity(0.6)),
                boxShadow: [
                  BoxShadow(
                    color: c.primary.withOpacity(0.4),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Icon(Icons.check_rounded, color: c.primary, size: 32),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l.rp_successTitle,
            textAlign: TextAlign.center,
            style: AppText.hero(26, color: c.primary, weight: FontWeight.w700)
                .copyWith(
              shadows: neonGlow(c.primary, blur: 12),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            l.rp_successBody,
            textAlign: TextAlign.center,
            style: AppText.body(13, color: c.inkMuted),
          ),
          const SizedBox(height: 28),
          NeonButton(
            label: l.rp_backBtn,
            icon: Icons.login,
            onTap: _finish,
            height: 52,
          ),
        ],
      ),
    );
  }
}
