import 'dart:io';
import 'dart:ui';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class RecorderException implements Exception {
  final String message;
  final dynamic originalError;

  RecorderException(this.message, {this.originalError});

  @override
  String toString() => 'RecorderException: $message';
}

class VoiceRecorderService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  String? filePath;
  bool _isRecorderInitialized = false;
  bool _isPlayerInitialized = false;

  // Getters
  bool get isRecording => _recorder.isRecording;

  bool get isPlaying => _player.isPlaying;

  bool get isInitialized => _isRecorderInitialized && _isPlayerInitialized;

  /// Initialize recorder and player
  Future<void> init() async {
    try {
      if (_isRecorderInitialized && _isPlayerInitialized) {
        print('🔄 Already initialized, skipping...');
        return;
      }

      print('🎤 Initializing VoiceRecorderService...');

      await _recorder.openRecorder();
      _isRecorderInitialized = true;
      print('✅ Recorder initialized');

      await _player.openPlayer();
      _isPlayerInitialized = true;
      print('✅ Player initialized');

      print('✅ VoiceRecorderService initialized successfully');
    } catch (e) {
      _isRecorderInitialized = false;
      _isPlayerInitialized = false;
      print('❌ Initialization failed: $e');
      throw RecorderException(
        'Failed to initialize recorder',
        originalError: e,
      );
    }
  }

  /// Dispose recorder and player
  Future<void> dispose() async {
    try {
      print('🧹 Disposing VoiceRecorderService...');

      if (_isRecorderInitialized) {
        await _recorder.closeRecorder();
        _isRecorderInitialized = false;
        print('✅ Recorder closed');
      }

      if (_isPlayerInitialized) {
        await _player.closePlayer();
        _isPlayerInitialized = false;
        print('✅ Player closed');
      }

      // Clean up file if exists
      await clearRecording();
    } catch (e) {
      print('⚠️ Error during disposal: $e');
    }
  }

  /// Start recording audio
  Future<void> start() async {
    if (!_isRecorderInitialized) {
      throw RecorderException('Recorder not initialized. Call init() first.');
    }

    if (_recorder.isRecording) {
      print('⚠️ Already recording');
      return;
    }

    // Request microphone permission
    final hasPermission = await _requestMicrophonePermission();
    if (!hasPermission) {
      throw RecorderException('Microphone permission denied');
    }

    try {
      // Generate unique file path
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      filePath = '${directory.path}/recording_$timestamp.wav';

      print('🎙️ Starting recording: $filePath');

      await _recorder.startRecorder(toFile: filePath, codec: Codec.pcm16WAV);

      if (_recorder.isRecording) {
        print('✅ Recording started successfully');
      } else {
        throw RecorderException('Recording failed to start');
      }
    } catch (e) {
      filePath = null;
      print('❌ Recording start failed: $e');
      throw RecorderException('Failed to start recording', originalError: e);
    }
  }

  /// Stop recording audio
  Future<String?> stop() async {
    if (!_recorder.isRecording) {
      print('⚠️ Not currently recording');
      return null;
    }

    try {
      print('⏹️ Stopping recording...');

      await _recorder.stopRecorder();

      // Verify file was created
      if (filePath != null && File(filePath!).existsSync()) {
        final fileSize = await File(filePath!).length();
        print('✅ Recording stopped. File size: ${fileSize} bytes');

        if (fileSize == 0) {
          print('⚠️ Warning: Recorded file is empty');
          await clearRecording();
          throw RecorderException('Recorded file is empty');
        }

        return filePath;
      } else {
        print('❌ Recording file was not created');
        filePath = null;
        throw RecorderException('Recording file was not created');
      }
    } catch (e) {
      print('❌ Stop recording failed: $e');
      filePath = null;
      throw RecorderException('Failed to stop recording', originalError: e);
    }
  }

  /// Play recorded audio
  Future<void> play({required VoidCallback onFinish}) async {
    if (!_isPlayerInitialized) {
      throw RecorderException('Player not initialized');
    }

    if (filePath == null) {
      throw RecorderException('No audio file to play');
    }

    if (!File(filePath!).existsSync()) {
      throw RecorderException('Audio file does not exist: $filePath');
    }

    if (_player.isPlaying) {
      print('⚠️ Already playing');
      return;
    }

    try {
      print('▶️ Starting playback: $filePath');

      await _player.startPlayer(
        fromURI: filePath,
        whenFinished: () {
          print('✅ Playback finished');
          onFinish();
        },
      );

      print('✅ Playback started');
    } catch (e) {
      print('❌ Playback failed: $e');
      throw RecorderException('Failed to play audio', originalError: e);
    }
  }

  /// Stop audio playback
  Future<void> stopPlayer() async {
    if (!_player.isPlaying) {
      return;
    }

    try {
      print('⏸️ Stopping playback...');
      await _player.stopPlayer();
      print('✅ Playback stopped');
    } catch (e) {
      print('⚠️ Error stopping player: $e');
      // Don't throw, just log
    }
  }

  /// Clear recorded audio file
  Future<void> clearRecording() async {
    if (filePath == null) {
      return;
    }

    try {
      final file = File(filePath!);

      if (await file.exists()) {
        await file.delete();
        print('🗑️ Deleted recording file: $filePath');
      }

      filePath = null;
    } catch (e) {
      print('⚠️ Error deleting file: $e');
      filePath = null;
    }
  }

  /// Request microphone permission
  Future<bool> _requestMicrophonePermission() async {
    var status = await Permission.microphone.status;

    if (status.isGranted) {
      print('✅ Microphone permission already granted');
      return true;
    }

    if (status.isDenied) {
      print('📋 Requesting microphone permission...');
      status = await Permission.microphone.request();
    }

    if (status.isGranted) {
      print('✅ Microphone permission granted');
      return true;
    }

    if (status.isPermanentlyDenied) {
      print('❌ Microphone permission permanently denied');
      print('💡 Opening app settings...');
      await openAppSettings();
    } else {
      print('❌ Microphone permission denied');
    }

    return false;
  }

  /// Get recording duration in seconds
  Future<double?> getRecordingDuration() async {
    if (filePath == null || !File(filePath!).existsSync()) {
      return null;
    }

    try {
      // This would require additional implementation
      // For now, return null
      return null;
    } catch (e) {
      print('⚠️ Error getting duration: $e');
      return null;
    }
  }

  /// Check if file is valid audio
  Future<bool> isValidAudioFile(String path) async {
    try {
      final file = File(path);

      if (!await file.exists()) {
        return false;
      }

      final size = await file.length();

      // Check minimum file size (at least 1KB)
      if (size < 1024) {
        print('⚠️ Audio file too small: $size bytes');
        return false;
      }

      // Check file extension
      final extension = path.split('.').last.toLowerCase();
      final validExtensions = ['wav', 'mp3', 'm4a', 'aac', 'ogg'];

      if (!validExtensions.contains(extension)) {
        print('⚠️ Invalid audio extension: $extension');
        return false;
      }

      return true;
    } catch (e) {
      print('⚠️ Error validating audio file: $e');
      return false;
    }
  }
}
