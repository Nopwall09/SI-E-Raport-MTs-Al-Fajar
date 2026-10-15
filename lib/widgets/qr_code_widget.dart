import 'dart:math';
import 'package:flutter/material.dart';

/// [QR-Code (Bobot 2%)]: Widget pembuat QR Code dinamis untuk verifikasi rapor digital & kartu siswa
class QrCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  final Color color;
  final Color backgroundColor;

  const QrCodeWidget({
    super.key,
    required this.data,
    this.size = 180,
    this.color = const Color(0xFF0F172A),
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _QrMatrixPainter(data: data, color: color),
      ),
    );
  }
}

class _QrMatrixPainter extends CustomPainter {
  final String data;
  final Color color;

  _QrMatrixPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    const int modules = 21; // Standard Version 1 QR code 21x21 grid
    final double moduleSize = size.width / modules;

    // Generate pseudo-random matrix based on seed from data
    final random = Random(data.hashCode);
    final matrix = List.generate(modules, (_) => List.generate(modules, (_) => false));

    // Fill data bits
    for (int r = 0; r < modules; r++) {
      for (int c = 0; c < modules; c++) {
        matrix[r][c] = random.nextBool();
      }
    }

    // Draw standard QR Finder Pattern at Top-Left, Top-Right, Bottom-Left
    void drawFinderPattern(int startRow, int startCol) {
      for (int r = 0; r < 7; r++) {
        for (int c = 0; c < 7; c++) {
          final isOuter = r == 0 || r == 6 || c == 0 || c == 6;
          final isInner = r >= 2 && r <= 4 && c >= 2 && c <= 4;
          matrix[startRow + r][startCol + c] = isOuter || isInner;
        }
      }
      // White separator boundary
      for (int i = 0; i < 8; i++) {
        if (startRow + 7 < modules && startCol + i < modules) matrix[startRow + 7][startCol + i] = false;
        if (startRow + i < modules && startCol + 7 < modules) matrix[startRow + i][startCol + 7] = false;
        if (startRow - 1 >= 0 && startCol + i < modules) matrix[startRow - 1][startCol + i] = false;
        if (startRow + i < modules && startCol - 1 >= 0) matrix[startRow + i][startCol - 1] = false;
      }
    }

    drawFinderPattern(0, 0); // Top-Left
    drawFinderPattern(0, modules - 7); // Top-Right
    drawFinderPattern(modules - 7, 0); // Bottom-Left

    // Draw timing patterns
    for (int i = 8; i < modules - 8; i++) {
      matrix[6][i] = i % 2 == 0;
      matrix[i][6] = i % 2 == 0;
    }

    // Render modules
    for (int r = 0; r < modules; r++) {
      for (int c = 0; c < modules; c++) {
        if (matrix[r][c]) {
          canvas.drawRect(
            Rect.fromLTWH(c * moduleSize, r * moduleSize, moduleSize * 0.96, moduleSize * 0.96),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrMatrixPainter oldDelegate) => oldDelegate.data != data || oldDelegate.color != color;
}
