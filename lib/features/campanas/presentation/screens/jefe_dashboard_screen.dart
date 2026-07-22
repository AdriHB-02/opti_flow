import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/entities/campana_entity.dart';
import '../../domain/usecases/get_campanas_by_doctor_usecase.dart';
import '../../../patients/presentation/widgets/shimmer_loading.dart';
import '../bloc/campana_bloc.dart';
import '../bloc/campana_state.dart';

class JefeDashboardScreen extends StatefulWidget {
  const JefeDashboardScreen({super.key});

  @override
  State<JefeDashboardScreen> createState() => _JefeDashboardScreenState();
}

class _JefeDashboardScreenState extends State<JefeDashboardScreen> {
  final GetCampanasByDoctorUseCase _getCampanas =
      GetIt.instance<GetCampanasByDoctorUseCase>();

  List<CampanaEntity> _campanas = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final session = await SessionManager.load();
    if (!mounted) return;
    final doctorId = session?['id'] as String?;
    if (doctorId == null) {
      setState(() {
        _error = 'Sesión no encontrada';
        _loading = false;
      });
      return;
    }
    final result = await _getCampanas(
      GetCampanasByDoctorParams(doctorId: doctorId),
    );
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() {
          _error = failure.message;
          _loading = false;
        });
      },
      (campanas) {
        setState(() {
          _campanas = campanas;
          _loading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CampanaBloc, CampanaState>(
      listener: (context, state) {
        if (state is CampanaCreated) {
          _loadData();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('OptiFlow - Jefe Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.map),
              tooltip: 'Mapa de campañas',
              onPressed: () => context.push(AppRouter.jefeMap),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthBloc>().add(const LogoutRequested()),
            ),
          ],
        ),
        body: _buildBody(),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push(AppRouter.jefeNewCampana),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const ShimmerLoading();

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: _campanas.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Center(child: Text('No hay campañas creadas')),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _campanas.length,
              itemBuilder: (context, index) {
                final campana = _campanas[index];
                return _buildCampanaCard(campana);
              },
            ),
    );
  }

  Widget _buildCampanaCard(CampanaEntity campana) {
    final estado = campana.estado == CampanaEstado.activa
        ? Colors.green
        : Colors.grey;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: estado.withValues(alpha: 0.2),
          child: Icon(Icons.campaign, color: estado),
        ),
        title: Text(campana.nombreEmpresa,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${campana.lugar} · ${campana.fechaInicio.day}/${campana.fechaInicio.month}/${campana.fechaInicio.year}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'assign':
                context.push(
                  '${AppRouter.jefeAssignDoctors}/${campana.id}',
                );
                break;
              case 'progress':
                context.push(
                  '${AppRouter.jefeCampanaProgress}/${campana.id}',
                );
                break;
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'assign', child: Text('Asignar doctores')),
            const PopupMenuItem(value: 'progress', child: Text('Ver progreso')),
          ],
        ),
      ),
    );
  }
}
