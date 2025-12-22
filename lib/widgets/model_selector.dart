import 'package:flutter/material.dart';

class ModelSelector extends StatelessWidget {
  final List<String> models;
  final String? selectedModel;
  final ValueChanged<String?>? onChanged;
  final bool enabled;

  const ModelSelector({
    super.key,
    required this.models,
    required this.selectedModel,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (models.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: models.map((model) => _buildModelTile(model)).toList(),
    );
  }

  Widget _buildModelTile(String model) {
    final isSelected = model == selectedModel;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.purple.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? Colors.purple.shade300 : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        title: Text(
          model.toUpperCase(),
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: enabled
                ? (isSelected ? Colors.purple.shade700 : Colors.black87)
                : Colors.grey,
          ),
        ),
        leading: Radio<String>(
          value: model,
          groupValue: selectedModel,
          onChanged: enabled ? onChanged : null,
          activeColor: Colors.purple,
        ),
        onTap: enabled ? () => onChanged?.call(model) : null,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        enabled: enabled,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Modellar mavjud emas',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Iltimos, internetga ulanganingizni tekshiring',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
