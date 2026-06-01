import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/account_provider.dart';
import '../../../services/account_service.dart';
import '../../../theme/app_theme.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  static const _confirmWord = 'SİL';

  final _confirmCtrl = TextEditingController();
  bool _exporting = false;
  bool _deleting = false;
  String? _error;
  String? _info;
  bool _understood = false;

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
      _confirmCtrl.text.trim().toUpperCase() == _confirmWord &&
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
      setState(() => _info = 'Verilerin dışa aktarıldı.');
    } on AccountException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Veriler dışa aktarılamadı.');
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
        _error = 'Hesap silinemedi. Tekrar dene.';
        _deleting = false;
      });
    }
  }

  Future<bool> _finalConfirm() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: !_deleting,
      enableDrag: !_deleting,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: GlassPanel(
          padding: const EdgeInsets.all(24),
          glowColor: AppColors.error,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SectionLabel('Son Onay', color: AppColors.error),
              const SizedBox(height: 14),
              Text(
                'Hesabını ve tüm verilerini kalıcı olarak silmek üzeresin. Bu işlem geri alınamaz.',
                textAlign: TextAlign.center,
                style: AppText.title(18,
                    color: AppColors.primary, weight: FontWeight.w600),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: 'Vazgeç',
                      onTap: () => Navigator.pop(ctx, false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: NeonButton(
                      label: 'Hesabı Sil',
                      icon: Icons.delete_forever,
                      color: AppColors.error,
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
      backgroundColor: AppColors.bg,
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
    return GlassPanel(
      padding: const EdgeInsets.all(22),
      glowColor: AppColors.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.download_for_offline_outlined,
                  color: AppColors.primaryContainer, size: 22),
              const SizedBox(width: 10),
              Text('Verilerini İndir',
                  style: AppText.title(18,
                      color: AppColors.primaryContainer,
                      weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Silmeden önce tüm verilerini (profil, kelimeler, pratik oturumları, mesajlar) JSON formatında indirip saklayabilirsin.',
            style: AppText.body(13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 18),
          if (_info != null) ...[
            _Banner(
              text: _info!,
              color: AppColors.primary,
              icon: Icons.check_circle_outline,
            ),
            const SizedBox(height: 12),
          ],
          GhostButton(
            label: _exporting ? 'Hazırlanıyor…' : 'Verilerimi Dışa Aktar',
            icon: Icons.share_outlined,
            color: AppColors.primaryContainer,
            onTap: _exporting ? null : _onExportFirst,
          ),
        ],
      ),
    );
  }

  Widget _buildDeletePanel() {
    return GlassPanel(
      padding: const EdgeInsets.all(22),
      glowColor: AppColors.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.error, size: 22),
              const SizedBox(width: 10),
              Text('Hesabı Sil',
                  style: AppText.title(18,
                      color: AppColors.error, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Bu işlem geri alınamaz. Hesabını sildiğinde aşağıdaki tüm veriler kalıcı olarak silinir:',
            style: AppText.body(13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 12),
          ..._bullet('Profil ve kullanıcı adın'),
          ..._bullet('Kelime hazinen ve tekrar geçmişin'),
          ..._bullet('Tüm pratik oturumların ve sohbet kayıtların'),
          ..._bullet('Kazandığın XP, seviye ve seri günler'),
          const SizedBox(height: 16),
          if (_error != null) ...[
            _Banner(
              text: _error!,
              color: AppColors.error,
              icon: Icons.error_outline,
            ),
            const SizedBox(height: 12),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.errorContainer.withOpacity(0.18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.error.withOpacity(0.4)),
            ),
            child: InkWell(
              onTap: () => setState(() => _understood = !_understood),
              child: Row(
                children: [
                  _Checkbox(value: _understood),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Bu işlemin geri alınamaz olduğunu anladım.',
                      style: AppText.ink(13, color: AppColors.inkMuted),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ONAYLAMAK İÇİN "$_confirmWord" YAZ',
            style: AppText.label(10,
                color: AppColors.error.withOpacity(0.85),
                weight: FontWeight.w700),
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
            label: _deleting ? 'Siliniyor…' : 'HESABIMI KALICI OLARAK SİL',
            icon: Icons.delete_forever,
            color: AppColors.error,
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
              const Padding(
                padding: EdgeInsets.only(top: 6, right: 8),
                child: Icon(Icons.circle, size: 5, color: AppColors.error),
              ),
              Expanded(
                child:
                    Text(text, style: AppText.ink(13.5, color: AppColors.ink)),
              ),
            ],
          ),
        ),
      ];
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.error.withOpacity(0.2)),
        ),
        boxShadow: [
          BoxShadow(color: AppColors.error.withOpacity(0.08), blurRadius: 30),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon:
                const Icon(Icons.arrow_back, color: AppColors.error, size: 22),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Center(
              child: Text(
                'HESABI SİL',
                style: AppText.label(13,
                        color: AppColors.error, weight: FontWeight.w700)
                    .copyWith(
                  shadows: neonGlow(AppColors.error, blur: 12, opacity: 0.8),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: value ? AppColors.error.withOpacity(0.85) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
            color: value ? AppColors.error : AppColors.inkDim, width: 1.5),
      ),
      child:
          value ? const Icon(Icons.check, size: 14, color: Colors.black) : null,
    );
  }
}
