import 'package:audio_recording/widgets/control_button.dart';
import 'package:flutter/material.dart';

typedef RecordingCallback = Future<void> Function();
typedef TranscribeCallback = Future<void> Function();

class ControlPanel extends StatelessWidget {
  final bool isRecording;
  final bool showPreview;
  final bool isPlaying;
  final bool isLoading;
  final String timeText;

  final RecordingCallback onRecordToggle;
  final VoidCallback onCancel;
  final VoidCallback onPlayToggle;
  final TranscribeCallback onTranscribe;

  const ControlPanel({
    super.key,
    required this.isRecording,
    required this.showPreview,
    required this.isPlaying,
    required this.isLoading,
    required this.timeText,
    required this.onRecordToggle,
    required this.onCancel,
    required this.onPlayToggle,
    required this.onTranscribe,
  });

  @override
  Widget build(BuildContext context) {
    if (showPreview) {
      return Column(
        children: [
          Text(
            timeText,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ControlButton(
                icon: Icons.close,
                color: Colors.red,
                onPressed: onCancel,
                label: 'Bekor qilish',
              ),
              const SizedBox(width: 20),
              ControlButton(
                icon: isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.purple,
                size: 70,
                onPressed: onPlayToggle,
                label: isPlaying ? 'Pauza' : 'Ijro etish',
              ),
              const SizedBox(width: 20),
              ControlButton(
                icon: Icons.cloud_upload,
                color: Colors.green,
                onPressed: isLoading ? null : onTranscribe,
                label: 'Transkripsiya',
              ),
            ],
          ),
        ],
      );
    } else {
      return GestureDetector(
        onTap: onRecordToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRecording ? Colors.red.shade600 : Colors.purple,
            boxShadow: [
              BoxShadow(
                color: isRecording
                    ? Colors.red.withOpacity(0.5)
                    : Colors.purple.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 15,
              ),
            ],
          ),
          child: Icon(
            isRecording ? Icons.stop : Icons.mic,
            size: 60,
            color: Colors.white,
          ),
        ),
      );
    }
  }
}
