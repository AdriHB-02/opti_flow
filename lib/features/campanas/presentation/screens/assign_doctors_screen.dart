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

  @override
  void initState() {
    super.initState();
    _loadDoctors();
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

  void _asignar() {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un doctor')),
      );
      return;
    }
    setState(() => _asignando = true);

    for (final doctorId in _selectedIds) {
      context.read<CampanaBloc>().add(
            AssignDoctor(
              campanaId: widget.campanaId,
              doctorId: doctorId,
            ),
          );
    }

    setState(() => _asignando = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selectedIds.length} doctor(es) asignado(s)')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CampanaBloc, CampanaState>(
      listener: (context, state) {
        if (state is CampanaError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Asignar Doctores')),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _asignando ? null : _asignar,
          icon: _asignando
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text('Asignar (${_selectedIds.length})'),
        ),
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

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _doctors.length,
      itemBuilder: (context, index) {
        final doctor = _doctors[index];
        final selected = _selectedIds.contains(doctor.id);
        return CheckboxListTile(
          title: Text(doctor.nombre),
          subtitle: Text(doctor.email),
          value: selected,
          onChanged: (val) {
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
    );
  }
}
