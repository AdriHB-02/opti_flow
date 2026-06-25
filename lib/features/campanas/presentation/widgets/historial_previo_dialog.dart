import 'package:flutter/material.dart';

import '../../domain/entities/campana_entity.dart';

enum HistorialDialogAction { empezarDesdeCero, importar, cancelar }

class HistorialPrevioDialog extends StatelessWidget {
  final List<CampanaEntity> campanasAnteriores;

  const HistorialPrevioDialog({super.key, required this.campanasAnteriores});

  static Future<HistorialDialogAction?> show(
    BuildContext context, {
    required List<CampanaEntity> campanasAnteriores,
  }) {
    return showDialog<HistorialDialogAction>(
      context: context,
      barrierDismissible: false,
      builder: (_) => HistorialPrevioDialog(
        campanasAnteriores: campanasAnteriores,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Historial previo detectado'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ya existen campañas anteriores para esta empresa y lugar:',
          ),
          const SizedBox(height: 12),
          ...campanasAnteriores.map(
            (c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text('• ${c.nombreEmpresa} — ${_formatDate(c.fechaInicio)}'),
            ),
          ),
          const SizedBox(height: 16),
          const Text('¿Qué deseas hacer?'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, HistorialDialogAction.cancelar),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, HistorialDialogAction.empezarDesdeCero),
          child: const Text('Empezar desde cero'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, HistorialDialogAction.importar),
          child: const Text('Importar pacientes'),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
