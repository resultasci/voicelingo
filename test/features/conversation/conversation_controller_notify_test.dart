import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicelingo/core/audio/audio_recorder_service.dart';
import 'package:voicelingo/core/services/settings_service.dart';
import 'package:voicelingo/features/conversation/controllers/conversation_controller.dart';
import 'package:voicelingo/features/conversation/models/conversation_message.dart';

/// Platform kaydediciye hiç inmeyen sahte servis — izin yok der, böylece
/// startListening hata yoluna girer ve platform kanalına dokunulmaz.
class _NoPermissionRecorder extends AudioRecorderService {
  _NoPermissionRecorder() : super(AudioRecorder());

  @override
  Future<bool> hasPermission() async => false;
}

Future<ConversationController> makeController() async {
  SharedPreferences.setMockInitialValues({});
  final settings = SettingsService(await SharedPreferences.getInstance());
  final recorder = _NoPermissionRecorder();

  T read<T>(ProviderListenable<T> p) {
    if (identical(p, audioRecorderServiceProvider)) return recorder as T;
    if (identical(p, settingsServiceProvider)) return settings as T;
    throw UnimplementedError('test fake read: beklenmeyen provider $p');
  }

  return ConversationController(
    read: read,
    invalidate: (_) {},
    scenario: null,
    isEmbedded: true,
    greetingText: () => '',
    replyFailedText: () => '',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Controller dispose'u lazy TtsSpeaker'ı yaratıp stop çağırır; AudioRecorder
    // kurucusu da kendi kanalında 'create' yollar. Mock'lanmazsa unawaited
    // MissingPluginException testi düşürür.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        const MethodChannel('flutter_tts'), (_) async => null);
    messenger.setMockMethodCallHandler(
        const MethodChannel('com.llfbandit.record/messages'),
        (_) async => null);
  });

  group('bildirim kanalı ayrımı', () {
    test('setHandsFree yalnız genel kanalı tetikler', () async {
      final c = await makeController();
      var statusFired = 0;
      var generalFired = 0;
      c.statusNotifier.addListener(() => statusFired++);
      c.addListener(() => generalFired++);

      c.setHandsFree(true);

      expect(generalFired, 1);
      expect(statusFired, 0);
      c.dispose();
    });

    test(
        'izinsiz startListening yalnız status kanalını tetikler; '
        'errorCode bildirim anında okunabilir', () async {
      final c = await makeController();
      var statusFired = 0;
      var generalFired = 0;
      ConvError? codeAtNotify;
      c.statusNotifier.addListener(() {
        statusFired++;
        codeAtNotify = c.errorCode;
      });
      c.addListener(() => generalFired++);

      await c.startListening();

      expect(c.status, ConvStatus.error);
      expect(statusFired, 1);
      expect(generalFired, 0);
      expect(codeAtNotify, ConvError.micPermission);
      c.dispose();
    });

    test('status zaten error iken ikinci hata genel kanaldan duyurulur',
        () async {
      final c = await makeController();
      await c.startListening(); // idle → error
      var statusFired = 0;
      var generalFired = 0;
      c.statusNotifier.addListener(() => statusFired++);
      c.addListener(() => generalFired++);

      await c.startListening(); // error → error (ValueNotifier susar)

      expect(statusFired, 0);
      expect(generalFired, 1);
      c.dispose();
    });

    test('dispose sonrası status set no-op (throw etmez)', () async {
      final c = await makeController();
      c.dispose();
      await c.startListening();
      expect(c.status, ConvStatus.idle);
    });
  });
}
