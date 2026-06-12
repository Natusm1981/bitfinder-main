import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/keyspace_grid.dart';
import '../providers/grid_provider.dart';

class KeyspaceHeatmap extends StatelessWidget {
  final double size;

  const KeyspaceHeatmap({super.key, this.size = 200});

  @override
  Widget build(BuildContext context) {
    return Consumer<GridProvider>(
      builder: (context, provider, child) {
        final grid = provider.currentGrid;

        if (grid == null) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[700]!),
            ),
            child: const Center(
              child: Text(
                'Aguardando busca...',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return Column(
          children: [
            // Título e estatísticas
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🗺️ Mapa de Cobertura',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${(grid.progress * 100).toStringAsFixed(4)}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Grid visual
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 2),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CustomPaint(
                  size: Size(size, size),
                  painter: _HeatmapPainter(grid),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Legenda
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green, 'Não testado'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.red, 'Testado'),
              ],
            ),

            const SizedBox(height: 8),

            // Estatísticas
            Text(
              '${grid.testedCount} / ${grid.gridSize * grid.gridSize} blocos',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white70,
                fontFamily: 'monospace',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.white38),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.white70),
        ),
      ],
    );
  }
}

class _HeatmapPainter extends CustomPainter {
  final KeyspaceGrid grid;

  _HeatmapPainter(this.grid);

  @override
  void paint(Canvas canvas, Size size) {
    final pixelSize = size.width / grid.gridSize;

    for (int y = 0; y < grid.gridSize; y++) {
      for (int x = 0; x < grid.gridSize; x++) {
        final index = y * grid.gridSize + x;
        final isTested = grid.testedBlocks[index];

        final paint =
            Paint()
              ..color = isTested ? Colors.red.shade600 : Colors.green.shade600
              ..style = PaintingStyle.fill;

        canvas.drawRect(
          Rect.fromLTWH(x * pixelSize, y * pixelSize, pixelSize, pixelSize),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HeatmapPainter oldDelegate) => true;
}
