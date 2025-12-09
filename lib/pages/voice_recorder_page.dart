import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/stt_api_service.dart';
import '../services/voice_recorder_service.dart';
import '../widgets/wave_painter.dart';

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

  @override
  void initState() {
    super.initState();
    recorder.init();
  }

  @override
  void dispose() {
    recordTimer?.cancel();
    playTimer?.cancel();
    recorder.dispose();
    super.dispose();
  }

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
    playTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        playProgress += 0.02;
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

  Future<void> sendAudioToBackend() async {
    if (recorder.filePath == null || !File(recorder.filePath!).existsSync()) return;

    setState(() => isLoading = true);

    try {
      final result = await SttApiService.sendAudioFile(recorder.filePath!);

      setState(() {
        transcribedText = result;
      });
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isRecording)
                Text(
                  formatTime(recordTicks),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                height: 100,
                width: double.infinity,
                child: CustomPaint(
                  painter: WavePainter(
                    waveform,
                    playProgress: showPreview ? playProgress : null,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              if (!showPreview)
                GestureDetector(
                  onTap: () async {
                    if (!isRecording) {
                      waveform.clear();
                      recordTicks = 0;
                      await recorder.start();
                      startRecordTimer();
                    } else {
                      await recorder.stop();
                      recordTimer?.cancel();
                      setState(() => showPreview = true);
                    }
                    setState(() => isRecording = !isRecording);
                  },
                  child: CircleAvatar(
                    radius: 70,
                    backgroundColor:
                    isRecording ? Colors.red : Colors.purple.shade200,
                    child: Icon(
                      isRecording ? Icons.stop : Icons.mic,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),

              if (showPreview) ...[
                const SizedBox(height: 30),
                Text(
                  formatTime((playProgress * recordTicks).toInt()),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      iconSize: 48,
                      onPressed: () {
                        recorder.stopPlayer();
                        setState(() {
                          showPreview = false;
                          waveform.clear();
                          playProgress = 0;
                          transcribedText = null;
                        });
                      },
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.purple,
                      ),
                      iconSize: 60,
                      onPressed: () async {
                        if (isPlaying) {
                          recorder.stopPlayer();
                          playTimer?.cancel();
                          setState(() => isPlaying = false);
                        } else {
                          startPlayTimer();
                          await recorder.play(onFinish: () {
                            setState(() => isPlaying = false);
                          });
                          setState(() => isPlaying = true);
                        }
                      },
                    ),
                    const SizedBox(width: 20),
                    IconButton(
                      icon:
                      const Icon(Icons.check_circle, color: Colors.green),
                      iconSize: 48,
                      onPressed: sendAudioToBackend,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (isLoading)
                  const CircularProgressIndicator(),

                if (transcribedText != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      transcribedText!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
