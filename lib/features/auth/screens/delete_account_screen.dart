import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../providers/account_provider.dart';
import '../services/account_service.dart';
import '../../../core/theme/app_theme.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _confirmCtrl = TextEditingController();
  bool _exporting = false;
  bool _deleting = false;
  String? _error;
  String? _info;
  bool _understood = false;

  // The confirmation word is localized (e.g. "SİL" / "DELETE").
  String get _confirmWord => AppL10n.of(context).del_confirmWord;

  @override
  void initState() {
    super.initState();
    _confirmCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool get _canDelete =>
      _understood &&
      _confirmCtrl.text.trim().toUpperCase() == _confirmWord.toUpperCase() &&
      !_deleting &&
      !_exporting;

  Future<void> _onExportFirst() async {
    setState(() {
      _exporting = true;
      _error = null;
      _info = null;
    });
    try {
      await ref.read(accountServiceProvider).exportAndShare();
      if (!mounted) return;
      setState(() => _info = AppL10n.of(context).del_exported);
    } on AccountException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = AppL10n.of(context).del_exportFailed);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _onDelete() async {
    final ok = await _finalConfirm();
    if (!ok) return;
    setState(() {
      _deleting = true;
      _error = null;
      _info = null;
    });
    try {
      await ref.read(accountServiceProvider).deleteAccount();
      // Sign-out happens inside the service; AuthGate will route back to login.
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    } on AccountException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _deleting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = AppL10n.of(context).del_deleteFailed;
        _deleting = false;
      });
    }
  }

  Future<bool> _finalConfirm() async {
    final l = AppL10n.of(context);
    final c = context.c;
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: !_deleting,
      enableDrag: !_deleting,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: GlassPanel(
          padding: const EdgeInsets.all(24),
          glowColor: c.error,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SectionLabel(l.del_finalConfirm, color: c.error),
              const SizedBox(height: 14),
              Text(
                l.del_finalWarning,
                textAlign: TextAlign.center,
                style: AppText.title(18,
                    color: c.primary, weight: FontWeight.w600),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: l.common_cancel,
                      onTap: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NeonButton(
                      label: l.del_deleteAccount,
                      icon: Icons.delete_forever,
                      color: c.error,
                      onTap: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return result == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.bg,
      body: CosmicBackground(
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildExportPanel(),
                      const SizedBox(height: 16),
                      _buildDeletePanel(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExportPanel() {
    final l = AppL10n.of(context);
    final c = context.c;
    return GlassPanel(
      padding: const EdgeInsets.all(22),
      glowColor: c.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.download_for_offline_outlined,
                  color: c.primaryContainer, size: 22),
              const SizedBox(width: 10),
              Text(l.del_downloadTitle,
                  style: AppText.title(18,
                      color: c.primaryContainer, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l.del_downloadBody,
            style: AppText.body(13, color: c.inkMuted),
          ),
          const SizedBox(height: 18),
          if (_info != null) ...[
            _Banner(
              text: _info!,
              color: c.primary,
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 12),
          ],
          GhostButton(
            label: _exporting ? l.conv_preparing : l.del_exportBtn,
            icon: Icons.share_outlined,
            color: c.primaryContainer,
            onTap: _exporting ? null : _onExportFirst,
          ),
        ],
      ),
    );
  }

  Widget _buildDeletePanel() {
    final l = AppL10n.of(context);
    final c = context.c;
    return GlassPanel(
      padding: const EdgeInsets.all(22),
      glowColor: c.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: c.error, size: 22),
              const SizedBox(width: 10),
              Text(l.del_deleteAccount,
                  style: AppText.title(18,
                      color: c.error, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l.del_deleteIntro,
            style: AppText.body(13, color: c.inkMuted),
          ),
          const SizedBox(height: 12),
          ..._bullet(l.del_bullet1),
          ..._bullet(l.del_bullet2),
          ..._bullet(l.del_bullet3),
          ..._bullet(l.del_bullet4),
          const SizedBox(height: 16),
          if (_error != null) ...[
            _Banner(
              text: _error!,
              color: c.error,
              icon: Icons.error_outline,
            ),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: c.errorContainer.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.error.withOpacity(0.4)),
            ),
            child: InkWell(
              onTap: () => setState(() => _understood = !_understood),
              child: Row(
                children: [
                  _Checkbox(value: _understood),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l.del_understood,
                      style: AppText.ink(13, color: c.inkMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.del_typeToConfirm(_confirmWord),
            style: AppText.label(10,
                color: c.error.withOpacity(0.85), weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          NeonField(
            controller: _confirmCtrl,
            hint: _confirmWord,
            leadingIcon: Icons.keyboard_outlined,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 22),
          NeonButton(
            label: _deleting ? l.del_deleting : l.del_deletePermanent,
            icon: Icons.delete_forever,
            color: c.error,
            loading: _deleting,
            onTap: _canDelete ? _onDelete : null,
            height: 54,
          ),
        ],
      ),
    );
  }

  List<Widget> _bullet(String text) => [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 8),
                child: Icon(Icons.circle, size: 5, color: context.c.error),
              ),
              Expanded(
                child:
                    Text(text, style: AppText.ink(13.5, color: context.c.ink)),
              ),
            ],
          ),
        ),
      ];
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.error.withOpacity(0.2)),
        ),
        boxShadow: [
          BoxShadow(color: c.error.withOpacity(0.08), blurRadius: 30),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: c.error, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Center(
              child: Text(
                AppL10n.of(context).del_title,
                style:
                    AppText.label(13, color: c.error, weight: FontWeight.w700)
                        .copyWith(
                  shadows: neonGlow(c.error, blur: 12, opacity: 0.8),
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

class _Banner extends StatelessWidget {
  final String text;
  final Color color;
  final IconData icon;

  const _Banner({required this.text, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: AppText.ink(13, color: color)),
          ),
        ],
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool value;
  const _Checkbox({required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: value ? c.error.withOpacity(0.85) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: value ? c.error : c.inkDim, width: 1.5),
      ),
      child:
          value ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
    );
  }
}
