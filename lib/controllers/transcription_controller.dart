import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audio_recording/configuration/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:audio_recording/services/logger.dart';
import 'package:audio_recording/services/stt_api_service.dart';
import 'package:audio_recording/services/voice_recorder_service.dart';
import 'package:permission_handler/permission_handler.dart';

enum TranscriptionState {
  idle,
  recording,
  preview,
  playing,
  transcribing,
  error,
}

class TranscriptionController with ChangeNotifier {
  final VoiceRecorderService recorder;

  TranscriptionState _state = TranscriptionState.idle;
  String? _transcribedText;
  String? _errorMessage;

  List<String> _availableModels = [];
  String? _selectedModelName;
  ApiEnvironment _selectedEnvironment = ApiEnvironment.muhammadjon;

  List<double> _waveform = [];
  Timer? _recordTimer;
  Timer? _playTimer;
  int _recordTicks = 0;
  double _playProgress = 0;

  static const int _maxWaveformPoints = 120;
  static const int _recordTimerMs = 100;
  static const int _playTimerMs = 50;

  TranscriptionController(this.recorder) {
    _initialize();
  }

  // Getters
  TranscriptionState get state => _state;

  bool get isLoading => _state == TranscriptionState.transcribing;

  bool get isRecording => _state == TranscriptionState.recording;

  bool get showPreview =>
      _state == TranscriptionState.preview ||
          _state == TranscriptionState.playing;

  bool get isPlaying => _state == TranscriptionState.playing;

  bool get hasError => _state == TranscriptionState.error;

  String? get transcribedText => _transcribedText;

  String? get errorMessage => _errorMessage;

  List<String> get availableModels => _availableModels;

  String? get selectedModelName => _selectedModelName;

  List<double> get waveform => _waveform;

  ApiEnvironment get selectedEnvironment => _selectedEnvironment;

  int get recordTicks => _recordTicks;

  double get playProgress => _playProgress;

  Future<void> _initialize() async {
    try {
      await recorder.init();
      await fetchModels();
    } catch (e) {
      _handleError('Initialization failed', e);
    }
  }

  Future<bool> _requestPermission() async {
    var status = await Permission.microphone.status;

    if (status.isPermanentlyDenied) {
      customLogger.w("Permission permanently denied. Opening settings...");
      final opened = await openAppSettings();
      if (opened) {
        _handleError(
          'Permission required',
          'Please enable microphone access in Settings, then try again',
        );
      }
      return false;
    }

    if (!status.isGranted) {
      status = await Permission.microphone.request();

      if (status.isDenied) {
        customLogger.w("Permission denied by user");
        return false;
      }

      if (status.isPermanentlyDenied) {
        customLogger.w("Permission permanently denied");
        return false;
      }
    }
    return status.isGranted;
  }

  /// Fetch available models from the API
  Future<void> fetchModels() async {
    _setState(TranscriptionState.transcribing);

    try {
      _availableModels = await SttApiService.getModels(_selectedEnvironment);

      if (_availableModels.isEmpty) {
        customLogger.w('No models available from API');
        _errorMessage = 'No models available. Please check your connection.';
      } else {
        _selectedModelName = _availableModels.first;
        _errorMessage = null;
      }

      _setState(TranscriptionState.idle);
    } catch (e) {
      _handleError('Failed to fetch models', e);
    }
  }

  void setSelectedModelName(String name) {
    if (!_availableModels.contains(name)) {
      customLogger.w('Selected model $name not in available models');
      return;
    }
    _selectedModelName = name;
    notifyListeners();
    customLogger.d('Model selected: $name');
  }

  /// Update API environment and refetch models
  Future<void> setSelectedEnvironment(ApiEnvironment env) async {
    if (_selectedEnvironment == env) return;

    _selectedEnvironment = env;
    customLogger.d('API Environment changed to: ${ApiConfig.getName(env)}');

    _clearState();
    await fetchModels();
  }

  /// Stop recording
  Future<void> _stopRecording() async {
    try {
      final path = await recorder.stop();
      _recordTimer?.cancel();

      if (path != null) {
        _setState(TranscriptionState.preview);
        customLogger.i('Recording stopped. File path: $path');
      } else {
        _handleError('Recording failed', 'No file was created');
      }
    } catch (e) {
      _handleError('Failed to stop recording', e);
    }
  }
  /// Toggle recording on/off
  Future<void> handleRecordToggle() async {
    if (isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  /// Start recording
  Future<void> _startRecording() async {
    try {
      bool hasPermission = await _requestPermission();
      if (!hasPermission) {
        var status = await Permission.microphone.status;
        if (status.isPermanentlyDenied) {
          _handleError(
            'Microphone access required',
            'Please enable microphone in Settings and tap the record button again',
          );
        } else {
          _handleError(
            'Microphone permission denied',
            'Please grant microphone access to record audio',
          );
        }
        return; // <-- This was missing! Exit early if no permission
      }

      _clearRecordingData();

      await recorder.start();

      if (recorder.isRecording) {
        _setState(TranscriptionState.recording);
        _startRecordTimer();
        customLogger.i('Recording started successfully');
      } else {
        _handleError(
          'Recording failed to start',
          'Check permissions and device status',
        );
      }
    } catch (e) {
      _handleError('Failed to start recording', e);
    }
  }

    /// Cancel current recording/preview
    void handleCancel() {
    _stopPlayback();
    recorder.clearRecording();
    _clearState();
    customLogger.w('Recording cancelled and state reset');
    }

    /// Toggle playback
    Future<void> handlePlayToggle() async {
    if (isPlaying) {
    await _pausePlayback();
    } else {
    await _startPlayback();
    }
    }

    /// Start audio playback
    Future<void> _startPlayback() async {
    try {
    _startPlayTimer();

    await recorder.play(
    onFinish: () {
    _stopPlayback();
    customLogger.i('Playback finished automatically');
    },
    );

    _setState(TranscriptionState.playing);
    customLogger.i('Playback started');
    } catch (e) {
    _handleError('Failed to start playback', e);
    }
    }

    /// Pause audio playback
    Future<void> _pausePlayback() async {
    try {
    recorder.stopPlayer();
    _playTimer?.cancel();
    _setState(TranscriptionState.preview);
    customLogger.i('Playback paused');
    } catch (e) {
    _handleError('Failed to pause playback', e);
    }
    }

    /// Stop playback completely
    void _stopPlayback() {
    recorder.stopPlayer();
    _playTimer?.cancel();
    _playProgress = 0;
    _setState(TranscriptionState.preview);
    }

    /// Send audio file to backend for transcription
    Future<void> sendAudioToBackend() async {
    if (recorder.filePath == null) {
    _handleError('No audio file', 'Please record audio first');
    return;
    }

    if (_selectedModelName == null) {
    _handleError('No model selected', 'Please select a model');
    return;
    }

    _setState(TranscriptionState.transcribing);
    _transcribedText = null;

    try {
    final responseString = await SttApiService.sendAudioFile(
    recorder.filePath!,
    _selectedModelName!,
    _selectedEnvironment,
    );

    final jsonResponse = jsonDecode(responseString);
    _transcribedText = jsonResponse['transcription'];

    if (_transcribedText == null || _transcribedText!.isEmpty) {
    _transcribedText = 'No transcription returned';
    }

    _setState(TranscriptionState.preview);
    customLogger.i('Transcription completed successfully');
    } catch (e) {
    _handleError('Transcription failed', e);
    _transcribedText = 'Xato yuz berdi: ${e.toString()}';
    _setState(TranscriptionState.preview);
    }
    }

    /// Start recording timer for waveform visualization
    void _startRecordTimer() {
    _recordTimer?.cancel();
    _recordTimer = Timer.periodic(
    const Duration(milliseconds: _recordTimerMs),
    (_) {
    _recordTicks++;
    _updateWaveform();
    notifyListeners();
    },
    );
    }

    /// Start playback timer for progress tracking
    void _startPlayTimer() {
    _playTimer?.cancel();
    final totalDurationInSeconds = _recordTicks / 10;

    if (totalDurationInSeconds <= 0) return;

    _playTimer = Timer.periodic(const Duration(milliseconds: _playTimerMs), (
    _,
    ) {
    _playProgress += (_playTimerMs / 1000) / totalDurationInSeconds;

    if (_playProgress >= 1.0) {
    _stopPlayback();
    }
    notifyListeners();
    });
    }

    /// Update waveform with new data point
    void _updateWaveform() {
    final amplitude = (Random().nextDouble() * 40) + 4;
    _waveform.add(amplitude);

    if (_waveform.length > _maxWaveformPoints) {
    _waveform.removeAt(0);
    }
    }

    /// Clear recording-related data
    void _clearRecordingData() {
    _waveform.clear();
    _recordTicks = 0;
    _transcribedText = null;
    _errorMessage = null;
    }

    /// Clear all state
    void _clearState() {
    _stopPlayback();
    _recordTimer?.cancel();
    _clearRecordingData();
    _playProgress = 0;
    _setState(TranscriptionState.idle);
    }

    /// Update state and notify listeners
    void _setState(TranscriptionState newState) {
    _state = newState;
    notifyListeners();
    }

    /// Handle errors consistently
    void _handleError(String message, dynamic error) {
    customLogger.e(message, error: error);
    _errorMessage = '$message: ${error.toString()}';
    _setState(TranscriptionState.error);

    // Auto-clear error after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
    if (_state == TranscriptionState.error) {
    _errorMessage = null;
    _setState(TranscriptionState.idle);
    }
    });
    }

    @override
    void dispose() {
    _recordTimer?.cancel();
    _playTimer?.cancel();
    recorder.dispose();
    customLogger.w('TranscriptionController disposed');
    super.dispose();
    }
  }
