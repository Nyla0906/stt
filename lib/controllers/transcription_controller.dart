import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:audio_recording/configuration/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:audio_recording/services/logger.dart';
import 'package:audio_recording/services/stt_api_service.dart';
import 'package:audio_recording/services/voice_recorder_service.dart';

class TranscriptionController with ChangeNotifier {
  final VoiceRecorderService recorder;

  bool _isLoading = false;
  bool _showPreview = false;
  bool _isPlaying = false;
  String? _transcribedText;
  SttModel _selectedModel = SttModel.gemini;
  ApiEnvironment _selectedEnvironment = ApiEnvironment.muhammadjon;

  List<double> _waveform = [];
  Timer? _recordTimer;
  Timer? _playTimer;
  int _recordTicks = 0;
  double _playProgress = 0;

  // --- Constructor ---
  TranscriptionController(this.recorder) {
    recorder.init(); // Initialize the recorder service upon controller creation
    customLogger.i('TranscriptionController initialized.');
  }

  // --- Getters to expose State to UI ---
  bool get isLoading => _isLoading;

  bool get isRecording => recorder.isRecording; // Delegated to Service
  bool get showPreview => _showPreview;

  bool get isPlaying => _isPlaying;

  String? get transcribedText => _transcribedText;

  SttModel get selectedModel => _selectedModel;

  List<double> get waveform => _waveform;

  ApiEnvironment get selectedEnvironment => _selectedEnvironment;

  int get recordTicks => _recordTicks;

  double get playProgress => _playProgress;

  // --- Logic Methods ---

  void setSelectedModel(SttModel model) {
    _selectedModel = model;
    notifyListeners();
  }

  void setSelectedEnvironment(ApiEnvironment env) {
    _selectedEnvironment = env;
    notifyListeners();
    customLogger.d('API Environment set to: ${ApiConfig.getName(env)}');
  }

  Future<void> handleRecordToggle() async {
    if (!isRecording) {
      // START LOGIC
      _waveform.clear();
      _recordTicks = 0;
      _transcribedText = null;

      await recorder.start();

      if (recorder.isRecording) {
        _startRecordTimer();
        notifyListeners(); // Update isRecording state
        customLogger.i('Recording started successfully.');
      } else {
        customLogger.e(
          'Recording failed to start. Check permissions/device status.',
        );
      }
    } else {
      // STOP LOGIC
      String? path = await recorder.stop();
      _recordTimer?.cancel();

      // Update state together
      _showPreview = path != null;
      notifyListeners();

      if (_showPreview) {
        customLogger.i('Recording stopped. File path: ${recorder.filePath}');
      } else {
        customLogger.e(
          'Recording failed to produce a file. Preview dismissed.',
        );
      }
    }
    // Note: isRecording state changes are handled by the service's getter now.
  }

  void handleCancel() {
    recorder.stopPlayer();
    _playTimer?.cancel();

    recorder.clearRecording(); // Business logic call

    _showPreview = false;
    _isPlaying = false;
    _waveform.clear();
    _playProgress = 0;
    _transcribedText = null;
    notifyListeners();
    customLogger.w('Recording/Preview cancelled and state reset.');
  }

  Future<void> handlePlayToggle() async {
    if (_isPlaying) {
      // Pause playback
      recorder.stopPlayer();
      _playTimer?.cancel();
      _isPlaying = false;
      customLogger.i('Playback paused.');
    } else {
      // Start playback
      _startPlayTimer();
      await recorder.play(
        onFinish: () {
          _isPlaying = false;
          _playProgress = 0;
          notifyListeners();
          customLogger.i('Playback finished automatically.');
        },
      );
      _isPlaying = true;
      customLogger.i('Playback started from file: ${recorder.filePath}');
    }
    notifyListeners();
  }

  Future<void> sendAudioToBackend() async {
    if (recorder.filePath == null || !File(recorder.filePath!).existsSync()) {
      customLogger.w(
        'Attempted to send audio, but file path is null or file does not exist.',
      );
      return;
    }

    _isLoading = true;
    _transcribedText = null;
    notifyListeners();

    try {
      final String responseString = await SttApiService.sendAudioFile(
        recorder.filePath!,
        _selectedModel,
        _selectedEnvironment,
      );

      final Map<String, dynamic> jsonResponse = jsonDecode(responseString);

      // Extracting the confirmed transcription key
      final String? transcription = jsonResponse['transcription'] as String?;

      if (transcription == null || transcription.isEmpty) {
        customLogger.e(
          'Transcription key "transcription" was found, but result was null or empty.',
        );
        throw Exception('Transkripsiya natijasi bo\'sh.');
      }

      _transcribedText = transcription;
      customLogger.i('Transcription received: "$_transcribedText"');
    } catch (e, stackTrace) {
      customLogger.e(
        'Xato yuz berdi (Transcription Error): API call failed.',
        error: e,
        stackTrace: stackTrace,
      );
      _transcribedText = 'Transkripsiya xizmatida xato yuz berdi.';
    } finally {
      _isLoading = false;
      notifyListeners();
      customLogger.d('Transcription process completed.');
    }
  }

  // --- Private Timer Logic (Moved from Page) ---
  void _startRecordTimer() {
    _recordTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _recordTicks++;
      _waveform.add((Random().nextDouble() * 40) + 4);
      if (_waveform.length > 120) _waveform.removeAt(0);
      notifyListeners();
    });
  }

  void _startPlayTimer() {
    _playTimer?.cancel();
    final totalDurationInSeconds = _recordTicks / 10;

    _playTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _playProgress += (0.05 / totalDurationInSeconds);

      if (_playProgress >= 1) {
        _playProgress = 0;
        _isPlaying = false;
        _playTimer?.cancel();
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _playTimer?.cancel();
    recorder.dispose();
    customLogger.w('TranscriptionController disposed.');
    super.dispose();
  }
}
