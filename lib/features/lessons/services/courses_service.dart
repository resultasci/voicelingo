import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/cached_repository.dart';
import '../../../core/storage/hive_boxes.dart';
import '../../../features/profile/providers/profile_provider.dart';
import '../models/course.dart';

/// Course / Unit / Lesson + progress için repository.
///
/// Hot path: ders ağacının tamamı tek RPC ile gelir (`get_content_tree`).
/// Eski 3 ayrı sorgu (`courses`, `units`, `lessons`) artık yok; her birinin
/// per-id getter'ı tree üzerinden lokal lookup yapar.
class CoursesService {
  CoursesService(this._db);
  final SupabaseClient _db;

  /// Tek-RPC + read-through Hive cache. Tree haftalarca değişmez → 7 gün TTL.
  Future<List<Course>> _tree({String language = 'en'}) async {
    final box = Hive.box<Map>(HiveBoxes.contentTree);
    return CachedRepository.getOrFetch<List<Course>>(
      box: box,
      key: 'tree_$language',
      fromJson: _treeFromJson,
      toJson: _treeToJson,
      maxAge: const Duration(days: 7),
      fetchRemote: () async {
        final res = await _db.rpc(
          'get_content_tree',
          params: {'p_language': language},
        );
        if (res is! List) return const <Course>[];
        final courses = <Course>[];
        for (final raw in res) {
          if (raw is! Map) continue;
          final m = Map<String, dynamic>.from(raw);
          final units = <CourseUnit>[];
          final lessonsByUnit = <String, List<Lesson>>{};
          final unitsRaw = m['units'];
          if (unitsRaw is List) {
            for (final ur in unitsRaw) {
              if (ur is! Map) continue;
              final um = Map<String, dynamic>.from(ur);
              units.add(CourseUnit.fromMap(um));
              final ll = um['lessons'];
              if (ll is List) {
                lessonsByUnit[um['id'] as String] = ll
                    .whereType<Map>()
                    .map((e) => Lesson.fromMap(Map<String, dynamic>.from(e)))
                    .toList();
              }
            }
          }
          courses.add(_CourseWithTree(
            base: Course.fromMap(m),
            units: units,
            lessonsByUnit: lessonsByUnit,
          ));
        }
        return courses;
      },
    );
  }

  /// Cache serialize: We persist whatever RPC returned (already JSONB-shaped).
  /// Re-fetch trips through `_treeFromJson` below.
  static List<Course> _treeFromJson(Map<String, dynamic> json) {
    final list = json['courses'];
    if (list is! List) return const <Course>[];
    return list.whereType<Map>().map((raw) {
      final m = Map<String, dynamic>.from(raw);
      final units = <CourseUnit>[];
      final lessonsByUnit = <String, List<Lesson>>{};
      final ur = m['units'];
      if (ur is List) {
        for (final u in ur) {
          if (u is! Map) continue;
          final um = Map<String, dynamic>.from(u);
          units.add(CourseUnit.fromMap(um));
          final ll = um['lessons'];
          if (ll is List) {
            lessonsByUnit[um['id'] as String] = ll
                .whereType<Map>()
                .map((e) => Lesson.fromMap(Map<String, dynamic>.from(e)))
                .toList();
          }
        }
      }
      return _CourseWithTree(
        base: Course.fromMap(m),
        units: units,
        lessonsByUnit: lessonsByUnit,
      );
    }).toList();
  }

  static Map<String, dynamic> _treeToJson(List<Course> courses) {
    return {
      'courses': courses.map((c) {
        if (c is _CourseWithTree) {
          return {
            'id': c.id,
            'language': c.language,
            'level': c.level,
            'order_index': c.orderIndex,
            'units': c.units
                .map((u) => {
                      'id': u.id,
                      'course_id': u.courseId,
                      'order_index': u.orderIndex,
                      'title_tr': u.titleTr,
                      'title_en': u.titleEn,
                      'theme': u.theme,
                      'prerequisite_unit_id': u.prerequisiteUnitId,
                      'lessons': (c.lessonsByUnit[u.id] ?? const [])
                          .map((l) => {
                                'id': l.id,
                                'unit_id': l.unitId,
                                'order_index': l.orderIndex,
                                'type': l.type.code,
                                'title_tr': l.titleTr,
                                'title_en': l.titleEn,
                                'content': l.content,
                                'xp_reward': l.xpReward,
                              })
                          .toList(),
                    })
                .toList(),
          };
        }
        return <String, dynamic>{};
      }).toList(),
    };
  }

  Future<List<Course>> listCourses() => _tree();

  Future<List<CourseUnit>> listUnits(String courseId) async {
    final tree = await _tree();
    final c = tree
        .whereType<_CourseWithTree>()
        .where((c) => c.id == courseId)
        .firstOrNull;
    return c?.units ?? const [];
  }

  Future<List<Lesson>> listLessons(String unitId) async {
    final tree = await _tree();
    for (final c in tree.whereType<_CourseWithTree>()) {
      final l = c.lessonsByUnit[unitId];
      if (l != null) return l;
    }
    return const [];
  }

  /// Kullanıcının tüm ders ilerlemesi (lesson_id → progress). Progress
  /// kullanıcıya özel + sık değişir → cache yok.
  Future<Map<String, UserLessonProgress>> listProgress() async {
    final user = _db.auth.currentUser;
    if (user == null) return const {};
    final data = await _db
        .from('user_lesson_progress')
        .select(
            'user_id,lesson_id,status,stars,best_score,attempts,last_attempt_at,next_review_at')
        .eq('user_id', user.id);
    final result = <String, UserLessonProgress>{};
    for (final row in (data as List)) {
      final p = UserLessonProgress.fromMap(row as Map<String, dynamic>);
      result[p.lessonId] = p;
    }
    return result;
  }

  /// Ders tamamlama RPC çağrısı. Status, stars, XP otomatik DB tarafında.
  Future<LessonCompletionResult> completeLesson({
    required String lessonId,
    required int score,
  }) async {
    final res = await _db.rpc('complete_lesson', params: {
      'p_lesson_id': lessonId,
      'p_score': score,
    });
    if (res is! Map<String, dynamic>) {
      return const LessonCompletionResult(ok: false, error: 'invalid_response');
    }
    if (res['ok'] != true) {
      return LessonCompletionResult(ok: false, error: res['error'] as String?);
    }
    // XP/streak DB tarafında değişti — profil cache'i taze veri çeksin.
    await bustProfileCache();
    return LessonCompletionResult(
      ok: true,
      status: res['status'] as String?,
      stars: (res['stars'] as num?)?.toInt(),
      xpAwarded: (res['xp_awarded'] as num?)?.toInt() ?? 0,
      firstCompletion: res['first_completion'] as bool? ?? false,
    );
  }

  /// Bir unit'in açık olup olmadığını hesapla (prerequisite tamam mı?).
  bool isUnitUnlocked(
    CourseUnit unit,
    List<CourseUnit> allUnits,
    Map<String, UserLessonProgress> progress,
    Map<String, List<Lesson>> lessonsByUnit,
  ) {
    final prereqId = unit.prerequisiteUnitId;
    if (prereqId == null) return true;
    final prereqLessons = lessonsByUnit[prereqId] ?? const [];
    if (prereqLessons.isEmpty) return true;
    return prereqLessons.every((l) {
      final p = progress[l.id];
      return p?.status == LessonStatus.completed ||
          p?.status == LessonStatus.mastered;
    });
  }
}

/// Internal Course subclass carrying the eagerly-loaded tree so per-id
/// lookups don't need extra round-trips. Public API stays Course.
class _CourseWithTree extends Course {
  final List<CourseUnit> units;
  final Map<String, List<Lesson>> lessonsByUnit;
  _CourseWithTree({
    required Course base,
    required this.units,
    required this.lessonsByUnit,
  }) : super(
          id: base.id,
          language: base.language,
          level: base.level,
          orderIndex: base.orderIndex,
        );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final it = iterator;
    return it.moveNext() ? it.current : null;
  }
}

class LessonCompletionResult {
  final bool ok;
  final String? error;
  final String? status;
  final int? stars;
  final int xpAwarded;
  final bool firstCompletion;

  const LessonCompletionResult({
    required this.ok,
    this.error,
    this.status,
    this.stars,
    this.xpAwarded = 0,
    this.firstCompletion = false,
  });
}

final coursesServiceProvider = Provider<CoursesService>((ref) {
  return CoursesService(Supabase.instance.client);
});

// =============================================================================
// Reactive providers
// =============================================================================

final coursesListProvider = FutureProvider<List<Course>>((ref) async {
  return ref.watch(coursesServiceProvider).listCourses();
});

final unitsForCourseProvider =
    FutureProvider.autoDispose.family<List<CourseUnit>, String>(
  (ref, courseId) => ref.watch(coursesServiceProvider).listUnits(courseId),
);

final lessonsForUnitProvider =
    FutureProvider.autoDispose.family<List<Lesson>, String>(
  (ref, unitId) => ref.watch(coursesServiceProvider).listLessons(unitId),
);

final lessonProgressMapProvider =
    FutureProvider.autoDispose<Map<String, UserLessonProgress>>((ref) async {
  return ref.watch(coursesServiceProvider).listProgress();
});
