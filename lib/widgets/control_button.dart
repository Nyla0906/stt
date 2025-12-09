import 'package:flutter/material.dart';

class ControlButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final String label;
  final double size;

  const ControlButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.label,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: color),
          iconSize: size,
          onPressed: onPressed,
        ),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}
