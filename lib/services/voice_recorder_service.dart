import 'dart:ui';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  String? filePath;

  Future<void> init() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
  }

  Future<void> dispose() async {
    await _recorder.closeRecorder();
    await _player.closePlayer();
  }

  Future<void> start() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception('Microphone permission not granted');
    }
    final directory = await getApplicationDocumentsDirectory();
    filePath =
        '${directory.path}/flutter_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.startRecorder(toFile: filePath, codec: Codec.pcm16WAV);
  }

  Future<String?> stop() async {
    await _recorder.stopRecorder();
    return filePath;
  }

  Future<void> play({required VoidCallback onFinish}) async {
    if (filePath != null) {
      await _player.startPlayer(fromURI: filePath, whenFinished: onFinish);
    }
  }

  Future<void> stopPlayer() async {
    if (_player.isPlaying) {
      await _player.stopPlayer();
    }
  }
}
