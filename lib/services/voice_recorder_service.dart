import 'dart:io';
import 'dart:ui';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  String? filePath;

  Future<void> init() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
    await _player.openPlayer();

    final dir = await getApplicationDocumentsDirectory();
    filePath = '${dir.path}/voice.aac';
  }

  Future<void> start() async {
    await _recorder.startRecorder(
      toFile: filePath,
      codec: Codec.aacADTS,
    );
  }

  Future<void> stop() async {
    await _recorder.stopRecorder();
  }

  Future<void> play({required VoidCallback onFinish}) async {
    if (filePath == null || !File(filePath!).existsSync()) return;

    await _player.startPlayer(
      fromURI: filePath,
      whenFinished: onFinish,
    );
  }

  void stopPlayer() {
    _player.stopPlayer();
  }

  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
  }
}
