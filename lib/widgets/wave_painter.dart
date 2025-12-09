import 'package:flutter/material.dart';

class WavePainter extends CustomPainter {
  final List<double> data;
  final double? playProgress;

  WavePainter(this.data, {this.playProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;

    for (int i = 0; i < data.length; i++) {
      final x = i * (size.width / data.length);
      final played =
          playProgress != null && i / data.length < playProgress!;

      final paint = Paint()
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color =
        played ? Colors.purple : Colors.purple.withOpacity(0.25);

      canvas.drawLine(
        Offset(x, mid - data[i]),
        Offset(x, mid + data[i]),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
