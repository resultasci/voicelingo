import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/locale_provider.dart';
import '../../../providers/profile_provider.dart';
import '../../../theme/app_theme.dart';
import '../models/dynamic_scenario.dart';
import '../services/scenarios_service.dart';

/// Kullanıcı doğal dilde senaryo tarif eder; AI yapılandırılmış senaryo
/// döndürür; kullanıcı önizler, kaydeder veya doğrudan başlatır.
class ScenarioBuilderScreen extends ConsumerStatefulWidget {
  const ScenarioBuilderScreen({super.key});

  @override
  ConsumerState<ScenarioBuilderScreen> createState() =>
      _ScenarioBuilderScreenState();
}

class _ScenarioBuilderScreenState extends ConsumerState<ScenarioBuilderScreen> {
  final _descCtrl = TextEditingController();
  String _category = 'daily_life';
  ScenarioDifficulty _difficulty = ScenarioDifficulty.medium;
  bool _generating = false;
  DynamicScenario? _draft;
  String? _error;

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final desc = _descCtrl.text.trim();
    if (desc.isEmpty) return;
    setState(() {
      _generating = true;
      _error = null;
      _draft = null;
    });
    try {
      final svc = ref.read(scenariosServiceProvider);
      final cefr = ref.read(profileProvider).value?.cefrLevel ?? 'A2';
      final draft = await svc.generate(
        description: desc,
        category: _category,
        difficulty: _difficulty,
        userLevel: cefr,
      );
      if (!mounted) return;
      setState(() => _draft = draft);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _save() async {
    final draft = _draft;
    if (draft == null) return;
    setState(() => _generating = true);
    try {
      final svc = ref.read(scenariosServiceProvider);
      await svc.save(draft);
      ref.invalidate(myScenariosProvider);
      ref.invalidate(visibleScenariosProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider).languageCode;
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.ink,
        title: Text(
          locale == 'en' ? 'Create scenario' : 'Senaryo yarat',
          style: AppText.title(17,
              color: AppColors.primaryContainer, weight: FontWeight.w700),
        ),
      ),
      body: CosmicBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Text(
                locale == 'en' ? 'Describe a scene' : 'Bir sahne tarif et',
                style: AppText.label(11,
                    color: AppColors.primaryContainer, weight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                maxLength: 280,
                decoration: InputDecoration(
                  hintText: locale == 'en'
                      ? 'e.g. "Job interview for a senior Flutter role"'
                      : 'ör: "Berberde saç kesimi"',
                  hintStyle: AppText.body(13, color: AppColors.inkDim),
                  filled: true,
                  fillColor: AppColors.bgCard.withOpacity(0.55),
                  border: _border(false),
                  enabledBorder: _border(false),
                  focusedBorder: _border(true),
                ),
                style: AppText.title(15,
                    color: AppColors.ink, weight: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              Text(
                locale == 'en' ? 'Category' : 'Kategori',
                style: AppText.label(11,
                    color: AppColors.primaryContainer, weight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _CategoryRow(
                selected: _category,
                onSelect: (c) => setState(() => _category = c),
                locale: locale,
              ),
              const SizedBox(height: 18),
              Text(
                locale == 'en' ? 'Difficulty' : 'Zorluk',
                style: AppText.label(11,
                    color: AppColors.primaryContainer, weight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _DifficultyRow(
                selected: _difficulty,
                onSelect: (d) => setState(() => _difficulty = d),
                locale: locale,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryContainer,
                    foregroundColor: AppColors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _generating || _descCtrl.text.trim().isEmpty
                      ? null
                      : _generate,
                  icon: _generating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome, size: 18),
                  label: Text(
                    locale == 'en' ? 'Generate' : 'Oluştur',
                    style: AppText.label(13,
                        color: AppColors.onPrimary, weight: FontWeight.w700),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    border: Border.all(color: AppColors.error.withOpacity(0.4)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: AppText.body(12, color: AppColors.error),
                  ),
                ),
              ],
              if (_draft != null) ...[
                const SizedBox(height: 20),
                _Preview(draft: _draft!, locale: locale),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _generating ? null : _generate,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color:
                                  AppColors.primaryContainer.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          locale == 'en' ? 'Regenerate' : 'Yeniden üret',
                          style: AppText.label(13,
                              color: AppColors.primaryContainer,
                              weight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primaryContainer,
                          foregroundColor: AppColors.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _generating ? null : _save,
                        child: Text(
                          locale == 'en' ? 'Save & start' : 'Kaydet & başla',
                          style: AppText.label(13,
                              color: AppColors.onPrimary,
                              weight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  OutlineInputBorder _border(bool focused) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: focused
              ? AppColors.primaryContainer
              : AppColors.inkDim.withOpacity(0.2),
          width: focused ? 2 : 1,
        ),
      );
}

// =============================================================================
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.selected,
    required this.onSelect,
    required this.locale,
  });
  final String selected;
  final ValueChanged<String> onSelect;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'daily_life',
        Icons.local_cafe_outlined,
        locale == 'en' ? 'Daily' : 'Gündelik'
      ),
      ('work', Icons.work_outline, locale == 'en' ? 'Work' : 'İş'),
      (
        'travel',
        Icons.flight_takeoff_outlined,
        locale == 'en' ? 'Travel' : 'Seyahat'
      ),
      (
        'health',
        Icons.medical_services_outlined,
        locale == 'en' ? 'Health' : 'Sağlık'
      ),
      (
        'education',
        Icons.school_outlined,
        locale == 'en' ? 'Education' : 'Eğitim'
      ),
      (
        'other',
        Icons.theater_comedy_outlined,
        locale == 'en' ? 'Other' : 'Diğer'
      ),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((tuple) {
        final (code, icon, label) = tuple;
        final isSelected = code == selected;
        return InkWell(
          onTap: () => onSelect(code),
          borderRadius: BorderRadius.circular(999),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryContainer.withOpacity(0.2)
                  : AppColors.bgCard.withOpacity(0.5),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected
                    ? AppColors.primaryContainer
                    : AppColors.inkDim.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 16,
                    color: isSelected
                        ? AppColors.primaryContainer
                        : AppColors.inkDim),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppText.label(11,
                      color: isSelected
                          ? AppColors.primaryContainer
                          : AppColors.inkDim,
                      weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DifficultyRow extends StatelessWidget {
  const _DifficultyRow({
    required this.selected,
    required this.onSelect,
    required this.locale,
  });
  final ScenarioDifficulty selected;
  final ValueChanged<ScenarioDifficulty> onSelect;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ScenarioDifficulty.values.map((d) {
        final isSelected = d == selected;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => onSelect(d),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryContainer.withOpacity(0.2)
                      : AppColors.bgCard.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryContainer
                        : AppColors.inkDim.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  d.label(locale),
                  style: AppText.label(12,
                      color: isSelected
                          ? AppColors.primaryContainer
                          : AppColors.ink,
                      weight: FontWeight.w700),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.draft, required this.locale});
  final DynamicScenario draft;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryContainer.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            draft.title(locale),
            style: AppText.title(18,
                color: AppColors.ink, weight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            draft.setting,
            style: AppText.body(13, color: AppColors.inkMuted)
                .copyWith(height: 1.4),
          ),
          const SizedBox(height: 12),
          _Line(
              label: locale == 'en' ? 'AI plays' : 'AI rolü',
              value: draft.aiRole),
          _Line(
              label: locale == 'en' ? 'You play' : 'Senin rolün',
              value: draft.userRole),
          if (draft.starterLine != null && draft.starterLine!.isNotEmpty)
            _Line(
                label: locale == 'en' ? 'Starts with' : 'Başlangıç',
                value: '"${draft.starterLine!}"'),
          if (draft.objectives.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              locale == 'en' ? 'Goals' : 'Hedefler',
              style: AppText.label(10,
                  color: AppColors.primaryContainer, weight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: draft.objectives
                  .map((o) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.tertiary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppColors.tertiary.withOpacity(0.4)),
                        ),
                        child: Text(
                          o,
                          style: AppText.label(10,
                              color: AppColors.tertiary,
                              weight: FontWeight.w700),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$label: ',
              style: AppText.label(11,
                  color: AppColors.primaryContainer, weight: FontWeight.w700),
            ),
            TextSpan(
              text: value,
              style: AppText.body(12, color: AppColors.ink),
            ),
          ],
        ),
      ),
    );
  }
}
