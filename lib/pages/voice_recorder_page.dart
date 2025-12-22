import 'package:audio_recording/configuration/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audio_recording/controllers/transcription_controller.dart';
import 'package:audio_recording/services/voice_recorder_service.dart';
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
              elevation: 0,
            ),
            backgroundColor: Colors.grey[50],
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Error Banner
                    if (controller.hasError && controller.errorMessage != null)
                      _buildErrorBanner(controller.errorMessage!),

                    const SizedBox(height: 16),

                    // API Environment Selector
                    _buildEnvironmentSelector(controller, context),

                    const SizedBox(height: 20),

                    // Model Selector Card
                    _buildModelSelectorCard(controller),

                    const SizedBox(height: 30),

                    // Recording Timer
                    if (controller.isRecording)
                      Center(
                        child: Column(
                          children: [
                            Text(
                              formatTime(controller.recordTicks),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade600,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.shade200,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Yozib olinmoqda',
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Waveform Visualizer
                    _buildWaveformCard(controller),

                    const SizedBox(height: 40),

                    // Control Panel
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

                    // Loading Indicator
                    if (controller.isLoading)
                      _buildLoadingIndicator(),

                    // Transcription Result
                    if (controller.transcribedText != null)
                      _buildTranscriptionResult(
                        controller.transcribedText!,
                        context,
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvironmentSelector(
      TranscriptionController controller,
      BuildContext context,
      ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: DropdownButtonFormField<ApiEnvironment>(
          decoration: InputDecoration(
            labelText: 'API Environment',
            labelStyle: TextStyle(
              color: Colors.purple.shade700,
              fontWeight: FontWeight.bold,
            ),
            prefixIcon: Icon(Icons.cloud_queue, color: Colors.purple.shade700),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          value: controller.selectedEnvironment,
          isExpanded: true,
          items: ApiEnvironment.values.map((env) {
            return DropdownMenuItem(
              value: env,
              child: Text(
                ApiConfig.getName(env),
                style: TextStyle(
                  color: env == controller.selectedEnvironment
                      ? Colors.purple.shade700
                      : Colors.black87,
                  fontWeight: env == controller.selectedEnvironment
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
          onChanged: controller.isRecording || controller.isLoading
              ? null
              : (env) {
            if (env != null) {
              controller.setSelectedEnvironment(env);
            }
          },
        ),
      ),
    );
  }

  Widget _buildModelSelectorCard(TranscriptionController controller) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.model_training, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  'Modelni tanlang',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (controller.availableModels.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(color: Colors.purple),
                      const SizedBox(height: 12),
                      Text(
                        'Modellar yuklanmoqda...',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ModelSelector(
                models: controller.availableModels,
                selectedModel: controller.selectedModelName,
                onChanged: controller.isRecording || controller.isLoading
                    ? null
                    : (name) {
                  if (name != null) {
                    controller.setSelectedModelName(name);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveformCard(TranscriptionController controller) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.purple.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        height: 120,
        padding: const EdgeInsets.all(16),
        child: controller.waveform.isEmpty
            ? Center(
          child: Text(
            'Ovoz to\'lqinlari bu yerda ko\'rinadi',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        )
            : CustomPaint(
          painter: WavePainter(
            controller.waveform,
            playProgress: controller.showPreview
                ? controller.playProgress
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            CircularProgressIndicator(
              color: Colors.purple,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              'Transkripsiya kutilmoqda...',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu bir necha soniya vaqt olishi mumkin',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptionResult(String text, BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  'Transkripsiya natijasi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.copy, color: Colors.purple.shade700),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: text));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Matn nusxalandi'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  tooltip: 'Nusxalash',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.shade100),
              ),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}