import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/utils/session_manager.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/entities/dependencia_entity.dart';
import '../../domain/usecases/get_dependencias_usecase.dart';
import '../widgets/shimmer_loading.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final GetDependenciasUseCase _getDependencias =
      GetIt.instance<GetDependenciasUseCase>();

  List<DependenciaEntity> _dependencias = [];
  bool _loading = true;
  String? _error;
  String? _localDependenciaId;
  List<DependenciaEntity> _empresas = [];

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
    final result = await _getDependencias(
      GetDependenciasParams(doctorId: doctorId),
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _error = failure.message;
          _loading = false;
        });
      },
      (dependencias) {
        final local = dependencias.where((d) => d.tipo == DependenciaTipo.local).toList();
        final empresas = dependencias.where((d) => d.tipo == DependenciaTipo.empresa).toList();
        setState(() {
          _dependencias = dependencias;
          _localDependenciaId = local.isNotEmpty ? local.first.id : null;
          _empresas = empresas;
          _loading = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OptiFlow - User Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(const LogoutRequested()),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRouter.newPatient),
        child: const Icon(Icons.person_add),
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
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_localDependenciaId != null)
            _buildLocalCard(),
          if (_empresas.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Empresas asignadas',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ..._empresas.map(_buildEmpresaTile),
          ],
          if (_dependencias.isEmpty)
            const Center(child: Text('No tienes dependencias asignadas')),
        ],
      ),
    );
  }

  Widget _buildLocalCard() {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.store)),
        title: const Text('Consultorio LOCAL',
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Gestiona pacientes de tu consultorio'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          if (_localDependenciaId != null) {
            context.push('${AppRouter.patientList}/$_localDependenciaId');
          }
        },
      ),
    );
  }

  Widget _buildEmpresaTile(DependenciaEntity empresa) {
    final enCampana = empresa.campanaId != null;
    return Card(
      elevation: 1,
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.business)),
        title: Text(empresa.nombre),
        subtitle: enCampana
            ? const Row(
                children: [
                  Icon(Icons.check_circle, size: 14, color: Colors.green),
                  SizedBox(width: 4),
                  Text('Campaña activa',
                      style: TextStyle(color: Colors.green, fontSize: 12)),
                ],
              )
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          context.push('${AppRouter.patientList}/${empresa.id}');
        },
      ),
    );
  }
}
