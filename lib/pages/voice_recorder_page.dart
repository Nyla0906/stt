import 'package:audio_recording/configuration/api_config.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Add provider to your pubspec.yaml
import 'package:audio_recording/controllers/transcription_controller.dart';
import 'package:audio_recording/services/voice_recorder_service.dart'; // Still needed for instantiation
import 'package:audio_recording/widgets/control_panel.dart';
import 'package:audio_recording/widgets/model_selector.dart';
import 'package:audio_recording/widgets/wave_painter.dart';

class VoiceRecorderPage extends StatelessWidget {
  const VoiceRecorderPage({super.key});

  String formatTime(int ticks) {
    final seconds = ticks ~/ 10;
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TranscriptionController(VoiceRecorderService()),

      child: Consumer<TranscriptionController>(
        builder: (context, controller, child) {
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
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15.0),
                      child: DropdownButtonFormField<ApiEnvironment>(
                        decoration: InputDecoration(
                          labelText: 'API Environment',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                        ),
                        value: controller.selectedEnvironment,
                        items: ApiEnvironment.values
                            .map(
                              (env) => DropdownMenuItem(
                                value: env,
                                child: Text(ApiConfig.getName(env)),
                              ),
                            )
                            .toList(),
                        onChanged: (env) {
                          if (env != null) {
                            controller.setSelectedEnvironment(env);
                          }
                        },
                      ),
                    ),

                    // 1. Model Selector
                    ModelSelector(
                      selectedModel: controller.selectedModel,
                      // Call controller method to update state
                      onChanged: (model) {
                        if (model != null) {
                          controller.setSelectedModel(model);
                        }
                      },
                    ),

                    const SizedBox(height: 30),

                    // 2. Recording Time/Remaining Time Display
                    if (controller.isRecording)
                      Text(
                        formatTime(controller.recordTicks),
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
                        border: Border.all(
                          color: Colors.purple.shade100,
                          width: 2,
                        ),
                      ),
                      height: 100,
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: CustomPaint(
                        painter: WavePainter(
                          controller.waveform,
                          playProgress: controller.showPreview
                              ? controller.playProgress
                              : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 50),

                    // 4. Control Panel (calls controller methods)
                    ControlPanel(
                      isRecording: controller.isRecording,
                      showPreview: controller.showPreview,
                      isPlaying: controller.isPlaying,
                      isLoading: controller.isLoading,
                      timeText: formatTime(
                        (controller.recordTicks * (1 - controller.playProgress))
                            .toInt(),
                      ),
                      onRecordToggle: controller.handleRecordToggle,
                      onCancel: controller.handleCancel,
                      onPlayToggle: controller.handlePlayToggle,
                      onTranscribe: controller.sendAudioToBackend,
                    ),

                    const SizedBox(height: 30),

                    // 5. Loading/Result Area
                    if (controller.isLoading)
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

                    if (controller.transcribedText != null)
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
                            controller.transcribedText!,
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
        },
      ),
    );
  }
}
