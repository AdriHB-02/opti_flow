import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/session_manager.dart';
import '../../domain/entities/dependencia_entity.dart';
import '../../domain/usecases/get_dependencias_usecase.dart';
import '../../domain/usecases/register_patient_usecase.dart';
import '../bloc/patient_bloc.dart';
import '../bloc/patient_event.dart';
import '../bloc/patient_state.dart';

class NewPatientScreen extends StatefulWidget {
  const NewPatientScreen({super.key});

  @override
  State<NewPatientScreen> createState() => _NewPatientScreenState();
}

class _NewPatientScreenState extends State<NewPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _diagnosticoController = TextEditingController();
  final _uuid = const Uuid();

  final GetDependenciasUseCase _getDependencias =
      GetIt.instance<GetDependenciasUseCase>();

  List<DependenciaEntity> _dependencias = [];
  DependenciaEntity? _selectedDependencia;
  bool _loadingDeps = true;
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    _loadDependencias();
  }

  Future<void> _loadDependencias() async {
    final session = await SessionManager.load();
    if (!mounted) return;
    final doctorId = session?['id'] as String?;
    if (doctorId == null) {
      setState(() => _loadingDeps = false);
      return;
    }
    _doctorId = doctorId;

    final result = await _getDependencias(
      GetDependenciasParams(doctorId: doctorId),
    );

    if (!mounted) return;

    result.fold(
      (_) {
        setState(() => _loadingDeps = false);
      },
      (deps) {
        setState(() {
          _dependencias = deps;
          _loadingDeps = false;
        });
      },
    );
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDependencia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una dependencia')),
      );
      return;
    }

    final params = RegisterPatientParams(
      patientId: _uuid.v4(),
      nombreCompleto: _nameController.text.trim(),
      dependenciaId: _selectedDependencia!.id,
      doctorId: _doctorId ?? '',
      historiaId: _uuid.v4(),
      diagnosticoTexto: _diagnosticoController.text.trim(),
      fechaAtencion: DateTime.now(),
    );

    context.read<PatientBloc>().add(SavePatient(input: params));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _diagnosticoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<PatientBloc>(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Nuevo Paciente')),
        body: BlocConsumer<PatientBloc, PatientState>(
          listener: (context, state) {
            if (state is PatientSaved) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Paciente registrado')),
              );
              context.pop();
            }
            if (state is PatientError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre completo',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nombre requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    if (_loadingDeps)
                      const LinearProgressIndicator()
                    else
                      DropdownButtonFormField<DependenciaEntity>(
                        initialValue: _selectedDependencia,
                        decoration: const InputDecoration(
                          labelText: 'Dependencia',
                          prefixIcon: Icon(Icons.business),
                          border: OutlineInputBorder(),
                        ),
                        items: _dependencias.map((dep) {
                          return DropdownMenuItem(
                            value: dep,
                            child: Text(dep.nombre),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedDependencia = value);
                        },
                        validator: (value) {
                          if (value == null) return 'Selecciona una dependencia';
                          return null;
                        },
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _diagnosticoController,
                      decoration: const InputDecoration(
                        labelText: 'Diagnóstico',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: state is PatientLoading ? null : _onSave,
                        child: state is PatientLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Text('Guardar Paciente'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
