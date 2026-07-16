import 'package:flutter/material.dart';

class DeleteAccountDialog extends StatefulWidget {
  final String doctorName;

  const DeleteAccountDialog({super.key, required this.doctorName});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final TextEditingController _motivoController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: Colors.red,
        size: 48,
      ),
      title: const Text(
        'Eliminar Cuenta',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas eliminar la cuenta de ${widget.doctorName}?',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Text(
              'Esta acción es irreversible. Se eliminarán todos los datos asociados.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _motivoController,
              decoration: const InputDecoration(
                labelText: 'Motivo de eliminación *',
                hintText: 'Ingresa el motivo obligatorio',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El motivo es obligatorio';
                }
                if (value.trim().length < 5) {
                  return 'El motivo debe tener al menos 5 caracteres';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(true);
            }
          },
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}
