import 'package:flutter/material.dart';
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
        //   // Informações de progresso
        //   Padding(
        //     padding: const EdgeInsets.only(bottom: 12),
        //     child: Row(
        //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //       // crossAxisAlignment: CrossAxisAlignment.center,
        //       children: [
        //         Center(
        //           child: Column(
        //             crossAxisAlignment: CrossAxisAlignment.center,
        //             // mainAxisAlignment: MainAxisAlignment.center,
        //             children: [
        //               // Text(
        //               //   'Keyspace: ${progress!.keyspaceId}',
        //               //   style: const TextStyle(
        //               //     fontWeight: FontWeight.bold,
        //               //     fontSize: 12,
        //               //   ),
        //               // ),
        //               // const SizedBox(height: 4),
        //               // Text(
        //               //   '${progress!.testedBlocks.length} / ${progress!.totalBlocks} blocos',
        //               //   style: TextStyle(fontSize: 11, color: Colors.grey[600]),
        //               // ),
        //               Container(
        //                 padding: const EdgeInsets.symmetric(
        //                   horizontal: 12,
        //                   vertical: 6,
        //                 ),
        //                 decoration: const BoxDecoration(color: Colors.blue),
        //                 child: Text(
        //                   '${progress!.progressPercentage.toStringAsFixed(2)}%',
        //                   style: const TextStyle(
        //                     color: Colors.white,
        //                     fontWeight: FontWeight.bold,
        //                     fontSize: 14,
        //                   ),
        //                 ),
        //               ),
        //             ],
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),

        // Grid de progresso com legenda ao lado
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Grid
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

            // Legenda ao lado
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLegendItem(Colors.green, 'Não testado'),
                const SizedBox(height: 12),
                _buildLegendItem(Colors.red, 'Testado'),
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

/// Painter customizado para renderizar o heatmap
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
