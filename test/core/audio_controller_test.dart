import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toney_music/toney_core.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioController', () {
    const channelName = 'audio_engine_test';
    final methodChannel = MethodChannel(channelName);
    late AudioController controller;
    final recordedCalls = <MethodCall>[];

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    setUp(() {
      recordedCalls.clear();
      messenger.setMockMethodCallHandler(methodChannel, (call) async {
        recordedCalls.add(call);
        return null;
      });
      controller = AudioController(channel: methodChannel);
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(methodChannel, null);
      controller.dispose();
    });

    test('load updates hasFile flag and invokes channel', () async {
      await controller.load('/tmp/audio.flac');

      expect(recordedCalls.map((c) => c.method), contains('load'));
      expect(controller.state.value.hasFile, isTrue);
      expect(controller.state.value.isBusy, isFalse);
    });

    test('play toggles playing flag', () async {
      await controller.play();
      expect(recordedCalls.last.method, 'play');
      expect(controller.state.value.isPlaying, isTrue);

      await controller.pause();
      expect(recordedCalls.last.method, 'pause');
      expect(controller.state.value.isPlaying, isFalse);
    });

    test('playAt loads from queue and updates state', () async {
      final metadata = SongMetadata.unknown('Test Song');
      final track = PlaybackTrack(path: '/tmp/test.flac', metadata: metadata);
      controller.setQueue([track]);

      await controller.playAt(0);

      expect(
        recordedCalls.map((call) => call.method),
        containsAll(['load', 'play']),
      );
      expect(controller.state.value.currentIndex, 0);
      expect(controller.state.value.queue.length, 1);
    });

    test('setVolume emits to stream and invokes channel', () async {
      expectLater(controller.volumeStream, emitsInOrder([0.5, 0.8]));

      await controller.setVolume(0.5);
      expect(recordedCalls.last.method, 'setVolume');
      expect(recordedCalls.last.arguments, {'value': 0.5});

      await controller.setVolume(0.8);
      expect(recordedCalls.last.method, 'setVolume');
      expect(recordedCalls.last.arguments, {'value': 0.8});
    });
  });
}
