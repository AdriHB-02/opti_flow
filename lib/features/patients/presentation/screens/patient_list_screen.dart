import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/session_manager.dart';
import '../../domain/entities/patient_entity.dart';
import '../bloc/patient_bloc.dart';
import '../bloc/patient_event.dart';
import '../bloc/patient_state.dart';
import '../widgets/shimmer_loading.dart';

class PatientListScreen extends StatefulWidget {
  final String dependenciaId;

  const PatientListScreen({super.key, required this.dependenciaId});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  String? _doctorId;

  @override
  void initState() {
    super.initState();
    _initDoctorId();
  }

  Future<void> _initDoctorId() async {
    final session = await SessionManager.load();
    if (!mounted) return;
    final doctorId = session?['id'] as String? ?? '';
    setState(() => _doctorId = doctorId);
    _loadPatients();
  }

  void _loadPatients() {
    if (_doctorId == null) return;
    context.read<PatientBloc>().add(
          LoadPatients(
            dependenciaId: widget.dependenciaId,
            doctorId: _doctorId!,
          ),
        );
  }

  void _onSearch(String query) {
    if (_doctorId == null) return;
    if (query.trim().isEmpty) {
      _loadPatients();
    } else {
      context.read<PatientBloc>().add(
            SearchPatient(
              query: query,
              dependenciaId: widget.dependenciaId,
              doctorId: _doctorId!,
            ),
          );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<PatientBloc>(),
      child: Scaffold(
        appBar: AppBar(
          title: _showSearch
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Buscar paciente...',
                    border: InputBorder.none,
                  ),
                  onChanged: _onSearch,
                )
              : const Text('Pacientes'),
          actions: [
            IconButton(
              icon: Icon(_showSearch ? Icons.close : Icons.search),
              onPressed: () {
                setState(() {
                  _showSearch = !_showSearch;
                  if (!_showSearch) {
                    _searchController.clear();
                    _loadPatients();
                  }
                });
              },
            ),
          ],
        ),
        body: BlocConsumer<PatientBloc, PatientState>(
          listener: (context, state) {
            if (state is PatientError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is PatientLoading) {
              return const ShimmerLoading();
            }

            if (state is PatientsLoaded) {
              final patients = state.patients;
              if (patients.isEmpty) {
                return const Center(
                  child: Text('No hay pacientes registrados'),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  _loadPatients();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    return _PatientTile(patient: patients[index]);
                  },
                ),
              );
            }

            if (state is PatientError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message,
                        style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadPatients,
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  final PatientEntity patient;

  const _PatientTile({required this.patient});

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(patient.nombreCompleto.isNotEmpty
              ? patient.nombreCompleto[0].toUpperCase()
              : '?'),
        ),
        title: Text(patient.nombreCompleto,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: patient.esReconsulta
                    ? Colors.orange.shade100
                    : Colors.green.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                patient.esReconsulta ? 'Reconsulta' : 'Nuevo',
                style: TextStyle(
                  fontSize: 11,
                  color: patient.esReconsulta
                      ? Colors.orange.shade800
                      : Colors.green.shade800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(_formatDate(patient.createdAt),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_done, size: 18, color: Colors.blue),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
        onTap: () {
          context.push(
            '${AppRouter.patientDetail}/${patient.id}',
            extra: {'name': patient.nombreCompleto},
          );
        },
      ),
    );
  }
}
