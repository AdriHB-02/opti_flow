import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/session_manager.dart';
import '../../domain/entities/campana_entity.dart';
import '../../domain/usecases/create_campana_usecase.dart';
import '../bloc/campana_bloc.dart';
import '../bloc/campana_event.dart';
import '../bloc/campana_state.dart';
import '../widgets/historial_previo_dialog.dart';

class NewCampanaScreen extends StatefulWidget {
  const NewCampanaScreen({super.key});

  @override
  State<NewCampanaScreen> createState() => _NewCampanaScreenState();
}

class _NewCampanaScreenState extends State<NewCampanaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  final _empresaIdController = TextEditingController();
  final _nombreEmpresaController = TextEditingController();
  final _lugarController = TextEditingController();

  DateTime _fechaInicio = DateTime.now();
  DateTime _fechaFin = DateTime.now().add(const Duration(days: 30));
  bool _creando = false;

  List<CampanaEntity>? _campanasAnteriores;

  @override
  void dispose() {
    _empresaIdController.dispose();
    _nombreEmpresaController.dispose();
    _lugarController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isInicio ? _fechaInicio : _fechaFin,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() {
        if (isInicio) {
          _fechaInicio = picked;
        } else {
          _fechaFin = picked;
        }
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _creando = true);

    _submitAsync();
  }

  Future<void> _submitAsync() async {
    final session = await SessionManager.load();
    if (!mounted) return;
    final creadoPor = session?['id'] as String?;
    if (creadoPor == null) {
      setState(() => _creando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión no encontrada')),
      );
      return;
    }

    final params = CreateCampanaParams(
      id: _uuid.v4(),
      empresaId: _empresaIdController.text.trim(),
      nombreEmpresa: _nombreEmpresaController.text.trim(),
      lugar: _lugarController.text.trim(),
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
      creadoPor: creadoPor,
    );

    if (!mounted) return;
    context.read<CampanaBloc>().add(CreateCampana(params: params));
  }

  void _handleHistorial() async {
    final action = await HistorialPrevioDialog.show(
      context,
      campanasAnteriores: _campanasAnteriores!,
    );

    if (!mounted) return;

    if (action == null || action == HistorialDialogAction.cancelar) {
      setState(() => _creando = false);
      return;
    }

    final session = await SessionManager.load();
    if (!mounted) return;
    final creadoPor = session?['id'] as String?;
    if (creadoPor == null) {
      setState(() => _creando = false);
      return;
    }

    final params = CreateCampanaParams(
      id: _uuid.v4(),
      empresaId: _empresaIdController.text.trim(),
      nombreEmpresa: _nombreEmpresaController.text.trim(),
      lugar: _lugarController.text.trim(),
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
      creadoPor: creadoPor,
      ignorarHistorial: true,
    );

    if (!mounted) return;
    context.read<CampanaBloc>().add(CreateCampana(params: params));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CampanaBloc, CampanaState>(
      listener: (context, state) {
        if (state is HistorialPrevioDetectado) {
          _campanasAnteriores = state.campanasAnteriores;
          _handleHistorial();
        } else if (state is CampanaCreated) {
          setState(() => _creando = false);
          final extra = _campanasAnteriores;
          _campanasAnteriores = null;
          context.pushReplacement(
            '${AppRouter.jefeAssignDoctors}/${state.campana.id}',
            extra: extra,
          );
        } else if (state is ReconsultaImportada) {
          setState(() => _creando = false);
          context.pushReplacement(AppRouter.jefeDashboard);
        } else if (state is CampanaError) {
          setState(() => _creando = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Nueva Campaña')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _empresaIdController,
                    decoration: const InputDecoration(
                      labelText: 'ID de Empresa',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 50,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nombreEmpresaController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de Empresa',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 100,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _lugarController,
                    decoration: const InputDecoration(
                      labelText: 'Lugar',
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 100,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de inicio',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        '${_fechaInicio.day}/${_fechaInicio.month}/${_fechaInicio.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de fin',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(
                        '${_fechaFin.day}/${_fechaFin.month}/${_fechaFin.year}',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _creando || state is CampanaLoading ? null : _submit,
                    child: state is CampanaLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Crear Campaña'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
