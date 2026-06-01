import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

/// Mikrofon izni state + akışı için ince wrapper.
///
/// Plain `permission_handler` kullanılabilir; bu servisin amacı:
///   - Test edilebilir bir interface sunmak (mock'lanabilir)
///   - "Reddedildi - kalıcı" durumunda Settings'e yönlendirmek için ortak
///     bir helper sağlamak
class AudioPermissionService {
  Future<MicPermissionStatus> check() async {
    final status = await Permission.microphone.status;
    return _map(status);
  }

  Future<MicPermissionStatus> request() async {
    final status = await Permission.microphone.request();
    return _map(status);
  }

  /// "Reddedildi - kalıcı" durumunda app settings sayfasını aç.
  /// Çağrıldığında her zaman true döner; gerçek başarıyı user davranışından anlarız.
  Future<bool> openSettings() => openAppSettings();

  MicPermissionStatus _map(PermissionStatus status) {
    if (status.isGranted) return MicPermissionStatus.granted;
    if (status.isPermanentlyDenied) {
      return MicPermissionStatus.permanentlyDenied;
    }
    if (status.isRestricted) return MicPermissionStatus.restricted;
    return MicPermissionStatus.denied;
  }
}

enum MicPermissionStatus {
  /// Kullanılabilir — recorder.start() güvenle çağrılabilir.
  granted,

  /// Henüz istenmedi veya reddedildi (tekrar istenebilir).
  denied,

  /// "Bir daha sorma" işaretlendi; tek çözüm Settings'e yönlendirmek.
  permanentlyDenied,

  /// iOS parental control / MDM kısıtlaması; kullanıcı çözemez.
  restricted,
}

final audioPermissionServiceProvider = Provider<AudioPermissionService>((ref) {
  return AudioPermissionService();
});
