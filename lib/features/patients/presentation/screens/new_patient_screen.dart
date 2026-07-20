import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/utils/session_manager.dart';
import '../../domain/entities/dependencia_entity.dart';
import '../../domain/services/i_gps_service.dart';
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

  final GetDependenciasUseCase _getDependencias =
      GetIt.instance<GetDependenciasUseCase>();
  final IGpsService _gpsService = GetIt.instance<IGpsService>();

  List<DependenciaEntity> _dependencias = [];
  DependenciaEntity? _selectedDependencia;
  bool _loadingDeps = true;
  String? _doctorId;

  double _capturedLat = 0.0;
  double _capturedLng = 0.0;
  bool _gpsLoading = true;
  bool _gpsAvailable = false;
  String? _gpsError;

  @override
  void initState() {
    super.initState();
    _loadDependencias();
    _captureGps();
  }

  Future<void> _captureGps() async {
    setState(() {
      _gpsLoading = true;
      _gpsError = null;
    });

    try {
      final hasPermission = await _gpsService.checkAndRequestPermission();
      if (!hasPermission) {
        if (!mounted) return;
        setState(() {
          _gpsLoading = false;
          _gpsAvailable = false;
        });
        _showPermissionDialog();
        return;
      }

      final location = await _gpsService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _capturedLat = location.lat;
        _capturedLng = location.lng;
        _gpsAvailable = true;
        _gpsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _gpsLoading = false;
        _gpsAvailable = false;
        _gpsError = 'Error al obtener ubicación';
      });
      _showPermissionDialog();
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.location_off, size: 48, color: Colors.orange),
        title: const Text('Permiso de ubicación requerido'),
        content: const Text(
          'OptiFlow necesita acceder a tu ubicación GPS para registrar '
          'el lugar donde se atiende al paciente. '
          'Sin este permiso, la ubicación se guardará como no disponible.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveWithoutGps();
            },
            child: const Text('Guardar sin GPS'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Geolocator.openAppSettings();
            },
            child: const Text('Abrir Configuración'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _captureGps();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _saveWithoutGps() {
    setState(() {
      _capturedLat = 0.0;
      _capturedLng = 0.0;
      _gpsAvailable = false;
    });
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
      nombreCompleto: _nameController.text.trim(),
      dependenciaId: _selectedDependencia!.id,
      doctorId: _doctorId ?? '',
      diagnosticoTexto: _diagnosticoController.text.trim(),
      latitud: _capturedLat,
      longitud: _capturedLng,
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
                          if (value == null) {
                            return 'Selecciona una dependencia';
                          }
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
                    const SizedBox(height: 16),
                    _buildGpsConfirmationCard(),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: state is PatientLoading ? null : _onSave,
                        child: state is PatientLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
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

  Widget _buildGpsConfirmationCard() {
    if (_gpsLoading) {
      return Card(
        color: Colors.blue.shade50,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Obteniendo ubicación GPS...'),
            ],
          ),
        ),
      );
    }

    if (_gpsAvailable) {
      return Card(
        color: Colors.green.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.location_on, color: Colors.green, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Ubicación capturada',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Latitud: ${_capturedLat.toStringAsFixed(6)}',
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                'Longitud: ${_capturedLng.toStringAsFixed(6)}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _captureGps,
                child: const Text(
                  'Actualizar ubicación',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_off, color: Colors.orange.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Sin ubicación GPS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
            if (_gpsError != null) ...[
              const SizedBox(height: 4),
              Text(
                _gpsError!,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ],
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _captureGps,
              child: const Text(
                'Reintentar captura de ubicación',
                style: TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
