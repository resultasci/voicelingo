import 'app_exception.dart';

/// Either-tipi `Result<T>` — başarı veya başarısızlık.
///
/// Throw/catch yerine bu sealed class'ı dönüş tipi olarak kullan; çağrıyı
/// yapan fonksiyon her iki ucu da derleme zamanında ele almak zorunda kalır.
///
/// Örnek:
/// ```dart
/// final Result<UserProfile> r = await repo.loadProfile();
/// switch (r) {
///   case Success(value: final p):    use(p);
///   case Failure(error: final e):    show(e.message);
/// }
/// ```
sealed class Result<T> {
  const Result();

  /// Başarı kısayolu.
  factory Result.success(T value) = Success<T>;

  /// Başarısızlık kısayolu.
  factory Result.failure(AppException error) = Failure<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get valueOrNull => switch (this) {
        Success(value: final v) => v,
        Failure() => null,
      };

  AppException? get errorOrNull => switch (this) {
        Success() => null,
        Failure(error: final e) => e,
      };

  /// Başarı durumunda [transform] uygula; başarısızlığı olduğu gibi geçir.
  Result<R> map<R>(R Function(T) transform) => switch (this) {
        Success(value: final v) => Result.success(transform(v)),
        Failure(error: final e) => Result.failure(e),
      };
}

final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

final class Failure<T> extends Result<T> {
  final AppException error;
  const Failure(this.error);
}
