import 'package:audio_recording/services/stt_api_service.dart';
import 'package:flutter/material.dart';

class ModelSelector extends StatelessWidget {
  final SttModel selectedModel;
  final ValueChanged<SttModel?> onChanged;

  const ModelSelector({
    super.key,
    required this.selectedModel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transkripsiya Modelini tanlang:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          ...SttModel.values.map((model) {
            String title = '';
            switch (model) {
              case SttModel.gemini:
                title = 'Gemini Flash (Kritik Tahlil)';
                break;
              case SttModel.grok:
                title = 'Grok';
                break;
              case SttModel.elevenLabs:
                title = 'Elevan Labs';
                break;
            }
            return ListTile(
              title: Text(title, style: TextStyle(fontSize: 14)),
              leading: Radio<SttModel>(
                value: model,
                groupValue: selectedModel,
                onChanged: onChanged,
              ),
              onTap: () => onChanged(model),
              // ListTile bosilganda ham ishga tushirish
              dense: true,
              contentPadding: EdgeInsets.zero,
            );
          }).toList(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
