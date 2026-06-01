import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cihazın çevrimiçi/çevrimdışı durumunu izleyen servis.
///
/// `connectivity_plus` Connectivity check'i veriyor ama "WiFi'ye bağlı ama
/// internet yok" durumunu tespit edemiyor. Şimdilik bu kabul ediliyor (Faz 10'da
/// `internet_connection_checker` ile genişletilebilir).
class ConnectivityService {
  ConnectivityService(this._connectivity);
  final Connectivity _connectivity;

  Stream<bool> onStatusChange() =>
      _connectivity.onConnectivityChanged.map((results) => _isOnline(results));

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  bool _isOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    return results.any((r) => r != ConnectivityResult.none);
  }
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(Connectivity());
});

/// Reactive online/offline state. Banner'lar, button enable/disable için.
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  final svc = ref.watch(connectivityServiceProvider);
  return svc.onStatusChange();
});
