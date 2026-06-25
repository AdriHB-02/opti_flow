import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/usecases/get_available_doctors_usecase.dart';
import '../bloc/campana_bloc.dart';
import '../bloc/campana_event.dart';
import '../bloc/campana_state.dart';

class AssignDoctorsScreen extends StatefulWidget {
  final String campanaId;

  const AssignDoctorsScreen({super.key, required this.campanaId});

  @override
  State<AssignDoctorsScreen> createState() => _AssignDoctorsScreenState();
}

class _AssignDoctorsScreenState extends State<AssignDoctorsScreen> {
  final GetAvailableDoctorsUseCase _getDoctors =
      GetIt.instance<GetAvailableDoctorsUseCase>();

  List<UserEntity> _doctors = [];
  final Set<String> _selectedIds = {};
  bool _loading = true;
  String? _error;
  bool _asignando = false;
  String? _progressMessage;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    final result = await _getDoctors(
      GetAvailableDoctorsParams(campanaId: widget.campanaId),
    );
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() {
          _error = failure.message;
          _loading = false;
        });
      },
      (doctors) {
        setState(() {
          _doctors = doctors;
          _loading = false;
        });
      },
    );
  }

  Future<void> _asignar() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un doctor')),
      );
      return;
    }

    final bloc = context.read<CampanaBloc>();
    final ids = List<String>.from(_selectedIds);
    int successCount = 0;
    final List<String> errors = [];

    setState(() {
      _asignando = true;
      _progressMessage = 'Asignando 0/${ids.length}...';
    });

    for (int i = 0; i < ids.length; i++) {
      if (!mounted) return;
      setState(() => _progressMessage = 'Asignando ${i + 1}/${ids.length}...');

      final completer = Completer<CampanaState>();
      StreamSubscription? sub;
      sub = bloc.stream.listen((state) {
        if (!completer.isCompleted &&
            (state is DoctorAssigned || state is CampanaError)) {
          completer.complete(state);
          sub?.cancel();
        }
      });

      bloc.add(AssignDoctor(campanaId: widget.campanaId, doctorId: ids[i]));

      final result = await completer.future
          .timeout(const Duration(seconds: 15));

      if (result is DoctorAssigned) {
        successCount++;
      } else if (result is CampanaError) {
        errors.add(ids[i]);
      }
    }

    if (!mounted) return;
    setState(() {
      _asignando = false;
      _progressMessage = null;
    });

    if (errors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$successCount doctor(es) asignado(s) correctamente')),
      );
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$successCount asignados, ${errors.length} fallos'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Asignar Doctores')),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _asignando ? null : () => _asignar(),
        icon: _asignando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check),
        label: Text(_asignando ? 'Asignando...' : 'Asignar (${_selectedIds.length})'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadDoctors, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (_doctors.isEmpty) {
      return const Center(child: Text('No hay doctores disponibles'));
    }

    return Column(
      children: [
        if (_asignando && _progressMessage != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(_progressMessage!,
                style: const TextStyle(color: Colors.teal)),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _doctors.length,
            itemBuilder: (context, index) {
              final doctor = _doctors[index];
              final selected = _selectedIds.contains(doctor.id);
              final disabled = _asignando;
              return CheckboxListTile(
                title: Text(doctor.nombre),
                subtitle: Text(doctor.email),
                value: selected,
                onChanged: disabled
                    ? null
                    : (val) {
                        setState(() {
                          if (val == true) {
                            _selectedIds.add(doctor.id);
                          } else {
                            _selectedIds.remove(doctor.id);
                          }
                        });
                      },
              );
            },
          ),
        ),
      ],
    );
  }
}
