// Assumed location: lib/services/voice_recorder_service.dart

import 'dart:io';
import 'dart:ui';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();
  String? filePath;
  bool _isRecorderInitialized = false;

  bool get isRecording => _recorder.isRecording; // Added getter

  Future<void> init() async {
    await _recorder.openRecorder();
    await _player.openPlayer();
    _isRecorderInitialized = true;
  }

  Future<void> dispose() async {
    await _recorder.closeRecorder();
    await _player.closePlayer();
    _isRecorderInitialized = false;
  }

  Future<void> start() async {
    if (!_isRecorderInitialized) {
      throw Exception('Recorder not initialized');
    }

    var status = await Permission.microphone.status;

    if (!status.isGranted) {
      status = await Permission.microphone.request();
    }

    if (!status.isGranted) {
      print("❌ Microphone permission denied. Cannot record.");
      if (status.isPermanentlyDenied) {
        openAppSettings();
        print("💡 Permission permanently denied. Directing user to settings.");
      }
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    filePath =
        '${directory.path}/flutter_audio_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _recorder.startRecorder(toFile: filePath, codec: Codec.pcm16WAV);
  }

  Future<String?> stop() async {
    if (!_recorder.isRecording) return null;
    await _recorder.stopRecorder();

    if (filePath != null && File(filePath!).existsSync()) {
      return filePath;
    }
    return null;
  }

  Future<void> play({required VoidCallback onFinish}) async {
    if (filePath == null || !File(filePath!).existsSync()) {
      print("Audio file does not exist");
      return;
    }
    await _player.startPlayer(fromURI: filePath, whenFinished: onFinish);
  }

  Future<void> stopPlayer() async {
    if (_player.isPlaying) {
      await _player.stopPlayer();
    }
  }

  Future<void> clearRecording() async {
    if (filePath != null) {
      final file = File(filePath!);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
        }
      }
      filePath = null;
    }
  }
}
