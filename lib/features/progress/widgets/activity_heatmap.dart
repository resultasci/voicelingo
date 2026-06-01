import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// GitHub-tarzı 90 günlük (varsayılan) XP heatmap.
/// Hücre rengi günlük XP'ye göre 5 seviyeli; tıklayınca o günün XP'sini gösterir.
class ActivityHeatmap extends StatelessWidget {
  const ActivityHeatmap({
    super.key,
    required this.dailyXp,
    this.days = 90,
    this.onTap,
  });

  final Map<DateTime, int> dailyXp;
  final int days;
  final void Function(DateTime day, int xp)? onTap;

  @override
  Widget build(BuildContext context) {
    final today = _normalize(DateTime.now());
    final start = today.subtract(Duration(days: days - 1));
    // Pazartesi başlangıç için ofset
    final startWeekday = start.weekday; // 1=Mon..7=Sun
    final padding = startWeekday - 1;
    final totalCells = padding + days;
    final weeks = (totalCells / 7).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize =
            ((constraints.maxWidth - (weeks - 1) * 3) / weeks).clamp(8.0, 16.0);

        return SizedBox(
          height: cellSize * 7 + 6 * 3,
          child: Row(
            children: List.generate(weeks, (week) {
              return Padding(
                padding: EdgeInsets.only(right: week == weeks - 1 ? 0 : 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List.generate(7, (dow) {
                    final cellIndex = week * 7 + dow;
                    if (cellIndex < padding || cellIndex >= padding + days) {
                      // Boş hücre (padding ya da son hafta fazlalığı)
                      return Padding(
                        padding: EdgeInsets.only(top: dow == 0 ? 0 : 3),
                        child: SizedBox(width: cellSize, height: cellSize),
                      );
                    }
                    final dayIndex = cellIndex - padding;
                    final day = start.add(Duration(days: dayIndex));
                    final xp = dailyXp[_normalize(day)] ?? 0;
                    final color = _colorForXp(xp);

                    return Padding(
                      padding: EdgeInsets.only(top: dow == 0 ? 0 : 3),
                      child: GestureDetector(
                        onTap: onTap == null ? null : () => onTap!(day, xp),
                        child: Container(
                          width: cellSize,
                          height: cellSize,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: AppColors.inkDim.withOpacity(0.1),
                              width: 0.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  /// XP miktarına göre 5 seviyeli renk.
  Color _colorForXp(int xp) {
    if (xp == 0) return AppColors.inkDim.withOpacity(0.08);
    if (xp < 20) return AppColors.primaryContainer.withOpacity(0.25);
    if (xp < 50) return AppColors.primaryContainer.withOpacity(0.5);
    if (xp < 100) return AppColors.primaryContainer.withOpacity(0.75);
    return AppColors.primaryContainer;
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);
}

/// Heatmap legend — UI'da heatmap altında gösterilir.
class HeatmapLegend extends StatelessWidget {
  const HeatmapLegend({super.key, this.locale = 'tr'});
  final String locale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          locale == 'en' ? 'Less' : 'Az',
          style: AppText.label(10, color: AppColors.inkDim),
        ),
        const SizedBox(width: 6),
        for (final op in const [0.08, 0.25, 0.5, 0.75, 1.0])
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: op == 0.08
                    ? AppColors.inkDim.withOpacity(0.08)
                    : AppColors.primaryContainer.withOpacity(op),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        const SizedBox(width: 6),
        Text(
          locale == 'en' ? 'More' : 'Çok',
          style: AppText.label(10, color: AppColors.inkDim),
        ),
      ],
    );
  }
}
