import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors/app_exception.dart';
import '../core/storage/hive_boxes.dart';

class AccountService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _functionName = 'account-admin';

  Future<Map<String, dynamic>> exportData() async {
    final res = await _supabase.functions.invoke(
      '$_functionName/export',
      method: HttpMethod.post,
    );
    if (res.status >= 400 || res.data == null) {
      final msg = (res.data is Map && res.data['error'] is String)
          ? res.data['error'] as String
          : 'Veriler dışa aktarılamadı (HTTP ${res.status}).';
      throw AccountException(msg);
    }
    if (res.data is! Map<String, dynamic>) {
      throw const AccountException('Beklenmeyen sunucu yanıtı.');
    }
    return res.data as Map<String, dynamic>;
  }

  Future<File> exportToFile() async {
    final data = await exportData();
    final pretty = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/voicelingo-export-$ts.json');
    await file.writeAsString(pretty, flush: true);
    return file;
  }

  Future<void> exportAndShare() async {
    final file = await exportToFile();
    final xFile = XFile(file.path, mimeType: 'application/json');
    await SharePlus.instance.share(ShareParams(
      files: [xFile],
      subject: 'Voicelingo veri dışa aktarımı',
      text: 'Voicelingo hesabına ait tüm veriler bu dosyada.',
    ));
  }

  Future<void> deleteAccount() async {
    final res = await _supabase.functions.invoke(
      '$_functionName/delete',
      method: HttpMethod.post,
    );
    if (res.status >= 400) {
      final msg = (res.data is Map && res.data['error'] is String)
          ? res.data['error'] as String
          : 'Hesap silinemedi (HTTP ${res.status}).';
      throw AccountException(msg);
    }
    await _supabase.auth.signOut();
    // Hesap silindi — cihazdaki kullanıcı verisi de kalkmalı.
    try {
      await HiveBoxes.clearUserData();
    } catch (_) {}
  }
}

class AccountException extends AppException {
  const AccountException(super.message) : super(code: 'account_error');
}
