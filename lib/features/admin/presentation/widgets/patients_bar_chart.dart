import 'package:flutter/material.dart';

import '../../domain/entities/patients_by_month.dart';

class PatientsBarChart extends StatelessWidget {
  final List<PatientsByMonth> data;

  const PatientsBarChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No hay datos disponibles'),
          ),
        ),
      );
    }

    final maxValue =
        data.map((e) => e.cantidad).fold<int>(0, (a, b) => a > b ? a : b);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pacientes atendidos por mes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: _buildBarChart(maxValue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(int maxValue) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartWidth = constraints.maxWidth;
        final chartHeight = constraints.maxHeight;
        final barWidth = (chartWidth / data.length) * 0.6;
        final spacing = (chartWidth / data.length) * 0.4;

        return CustomPaint(
          size: Size(chartWidth, chartHeight),
          painter: _BarChartPainter(
            data: data,
            maxValue: maxValue,
            barWidth: barWidth,
            spacing: spacing,
          ),
        );
      },
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<PatientsByMonth> data;
  final int maxValue;
  final double barWidth;
  final double spacing;

  _BarChartPainter({
    required this.data,
    required this.maxValue,
    required this.barWidth,
    required this.spacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    final bottomPadding = 30.0;
    final topPadding = 10.0;
    final chartHeight = size.height - bottomPadding - topPadding;

    for (int i = 0; i < 4; i++) {
      final y = topPadding + (chartHeight * i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    final effectiveMax = maxValue > 0 ? maxValue : 1;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final barHeight =
          (item.cantidad / effectiveMax) * chartHeight;

      final x = i * (barWidth + spacing) + spacing / 2;
      final y = topPadding + chartHeight - barHeight;

      final gradientPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.blue.shade300,
            Colors.blue.shade700,
          ],
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
        ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight));

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rrect, gradientPaint);

      if (item.cantidad > 0) {
        textPainter.text = TextSpan(
          text: '${item.cantidad}',
          style: const TextStyle(
            color: Colors.blue,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            x + (barWidth - textPainter.width) / 2,
            y - 18,
          ),
        );
      }

      final mesLabel = _formatMes(item.mes);
      textPainter.text = TextSpan(
        text: mesLabel,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 10,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          x + (barWidth - textPainter.width) / 2,
          topPadding + chartHeight + 8,
        ),
      );
    }
  }

  String _formatMes(String mes) {
    final parts = mes.split('-');
    if (parts.length != 2) return mes;
    final monthNames = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final monthIndex = int.tryParse(parts[1]) ?? 1;
    if (monthIndex < 1 || monthIndex > 12) return mes;
    return monthNames[monthIndex - 1];
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.maxValue != maxValue;
  }
}
