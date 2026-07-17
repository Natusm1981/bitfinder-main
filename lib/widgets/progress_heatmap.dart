import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/search_progress.dart';

/// Widget que renderiza o mapa de progresso visual (grid de pixels)
class ProgressHeatmap extends StatelessWidget {
  final SearchProgress? progress;
  final double size;
  final int gridSize;

  const ProgressHeatmap({
    super.key,
    this.progress,
    this.size = 200,
    this.gridSize = 200,
  });

  @override
  Widget build(BuildContext context) {
    if (progress == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'Nenhum progresso',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[700]!, width: 2),
              ),
              child: ClipRect(
                child: CustomPaint(
                  size: Size(size, size),
                  painter: _HeatmapPainter(
                    progress: progress!,
                    gridSize: gridSize,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem(
                  Colors.green,
                  AppLocalizations.of(context).untested,
                ),
                const SizedBox(height: 12),
                _buildLegendItem(
                  Colors.red,
                  AppLocalizations.of(context).tested,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.grey[600]!),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final SearchProgress progress;
  final int gridSize;

  _HeatmapPainter({required this.progress, required this.gridSize});

  @override
  void paint(Canvas canvas, Size size) {
    final pixelSize = size.width / gridSize;

    final redPaint =
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;

    final backgroundPaint =
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, backgroundPaint);
    for (final blockIndex in progress.testedBlocks) {
      final row = blockIndex ~/ gridSize;
      final col = blockIndex % gridSize;
      canvas.drawRect(
        Rect.fromLTWH(col * pixelSize, row * pixelSize, pixelSize, pixelSize),
        redPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_HeatmapPainter oldDelegate) {
    return progress != oldDelegate.progress;
  }
}
