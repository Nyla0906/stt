import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

// Logger Import
import 'package:logger/logger.dart'; // <--- Ensure this is imported

import 'package:audio_recording/services/stt_api_service.dart';
import 'package:audio_recording/services/voice_recorder_service.dart';
import 'package:audio_recording/widgets/control_panel.dart';
import 'package:audio_recording/widgets/model_selector.dart';
import 'package:audio_recording/widgets/wave_painter.dart';
import 'package:flutter/material.dart';

// --- Initialize the Logger instance ---
var appLogger = Logger(
  printer: PrettyPrinter(
    methodCount: 0, // Hide method call stack for clean messages
    errorMethodCount: 5, // Show stacktrace on errors
    colors: true,
    printEmojis: true,
    printTime: false,
  ),
);
// ------------------------------------


class VoiceRecorderPage extends StatefulWidget {
  const VoiceRecorderPage({super.key});

  @override
  State<VoiceRecorderPage> createState() => _VoiceRecorderPageState();
}

class _VoiceRecorderPageState extends State<VoiceRecorderPage> {
  final recorder = VoiceRecorderService();

  bool isRecording = false;
  bool showPreview = false;
  bool isPlaying = false;
  bool isLoading = false;

  List<double> waveform = [];
  Timer? recordTimer;
  Timer? playTimer;

  int recordTicks = 0;
  double playProgress = 0;

  String? transcribedText;
  SttModel selectedModel = SttModel.gemini;

  @override
  void initState() {
    super.initState();
    recorder.init();
    appLogger.i('VoiceRecorderPage initialized.'); // Log initialization
  }

  @override
  void dispose() {
    recordTimer?.cancel();
    playTimer?.cancel();
    recorder.dispose();
    appLogger.w('VoiceRecorderPage disposed.'); // Log disposal
    super.dispose();
  }

  // --- Handlers with Logging ---

  Future<void> _handleRecordToggle() async {
    if (!isRecording) {
      // Start recording
      waveform.clear();
      recordTicks = 0;
      transcribedText = null;
      await recorder.start();
      startRecordTimer();
      appLogger.i('Recording started.'); // Log success
    } else {
      // Stop recording
      await recorder.stop();
      recordTimer?.cancel();
      setState(() => showPreview = true);
      appLogger.i('Recording stopped. File path: ${recorder.filePath}'); // Log file path
    }
    setState(() => isRecording = !isRecording);
  }

  void _handleCancel() {
    recorder.stopPlayer();
    playTimer?.cancel();
    setState(() {
      showPreview = false;
      isPlaying = false;
      waveform.clear();
      playProgress = 0;
      transcribedText = null;
    });
    appLogger.w('Recording/Preview cancelled and state reset.'); // Log cancellation
  }

  Future<void> _handlePlayToggle() async {
    if (isPlaying) {
      // Pause playback
      recorder.stopPlayer();
      playTimer?.cancel();
      setState(() => isPlaying = false);
      appLogger.i('Playback paused.');
    } else {
      // Start playback
      startPlayTimer();
      await recorder.play(
        onFinish: () {
          setState(() {
            isPlaying = false;
            playProgress = 0;
          });
          appLogger.i('Playback finished automatically.');
        },
      );
      setState(() => isPlaying = true);
      appLogger.i('Playback started from file: ${recorder.filePath}');
    }
  }

  // --- Backend Communication with Logging ---

  Future<void> sendAudioToBackend() async {
    if (recorder.filePath == null || !File(recorder.filePath!).existsSync()) {
      appLogger.w('Attempted to send audio, but file path is null or file does not exist.');
      return;
    }

    setState(() {
      isLoading = true;
      transcribedText = null;
    });

    try {
      final String responseString = await SttApiService.sendAudioFile(
        recorder.filePath!,
        selectedModel,
      );
      final Map<String, dynamic> jsonResponse = jsonDecode(responseString);

      final String transcription = jsonResponse['text'];

      appLogger.d('API Response received successfully.');
      appLogger.i('Transcription received: "$transcription"'); // Log success

      setState(() {
        transcribedText = transcription;
      });
    } catch (e, stackTrace) {
      // Use appLogger.e for detailed, beautiful error logging
      appLogger.e('Xato yuz berdi (Transcription Error): API call failed.', error: e, stackTrace: stackTrace);
      setState(() {
        transcribedText = 'Transkripsiya xizmatida xato yuz berdi.';
      });
    } finally {
      setState(() => isLoading = false);
      appLogger.d('Transcription process completed.');
    }
  }

  // --- Timer and format functions (unchanged) ---
  void startRecordTimer() {
    recordTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        recordTicks++;
        waveform.add((Random().nextDouble() * 40) + 4);
        if (waveform.length > 120) waveform.removeAt(0);
      });
    });
  }

  void startPlayTimer() {
    playTimer?.cancel();
    final totalDurationInSeconds = recordTicks / 10;

    playTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      setState(() {
        playProgress += (0.05 / totalDurationInSeconds);

        if (playProgress >= 1) {
          playProgress = 0;
          isPlaying = false;
          playTimer?.cancel();
        }
      });
    });
  }

  String formatTime(int ticks) {
    final seconds = ticks ~/ 10;
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // --- Build Method (unchanged from your refactored version) ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ovozli Yozuv va Transkripsiya',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 1. Model Selector
              ModelSelector(
                selectedModel: selectedModel,
                onChanged: (model) {
                  if (model != null) {
                    setState(() => selectedModel = model);
                  }
                },
              ),

              const SizedBox(height: 30),

              // 2. Recording Time/Remaining Time Display
              if (isRecording)
                Text(
                  formatTime(recordTicks),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              const SizedBox(height: 20),

              // 3. Waveform Display
              Container(
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.purple.shade100, width: 2),
                ),
                height: 100,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: CustomPaint(
                  painter: WavePainter(
                    waveform,
                    playProgress: showPreview ? playProgress : null,
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // 4. Extracted Control Panel Widget!
              ControlPanel(
                isRecording: isRecording,
                showPreview: showPreview,
                isPlaying: isPlaying,
                isLoading: isLoading,
                timeText: formatTime(
                  (recordTicks * (1 - playProgress)).toInt(),
                ),
                onRecordToggle: _handleRecordToggle,
                onCancel: _handleCancel,
                onPlayToggle: _handlePlayToggle,
                onTranscribe: sendAudioToBackend,
              ),

              const SizedBox(height: 30),

              // 5. Loading/Result Area
              if (isLoading)
                const Column(
                  children: [
                    CircularProgressIndicator(color: Colors.purple),
                    SizedBox(height: 10),
                    Text(
                      'Transkripsiya kutilmoqda...',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),

              if (transcribedText != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Text(
                      transcribedText!,
                      textAlign: TextAlign.start,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}