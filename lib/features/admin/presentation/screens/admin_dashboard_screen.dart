import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/doctor_user.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';
import 'doctor_list_screen.dart';
import 'stats_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const LoadDoctors());
    context.read<AdminBloc>().add(const LoadStats());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OptiFlow - Admin'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: BlocBuilder<AdminBloc, AdminState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<AdminBloc>().add(const LoadDoctors());
              context.read<AdminBloc>().add(const LoadStats());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Gestión de Doctores'),
                  const SizedBox(height: 8),
                  _buildDoctorsSection(state),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Empresas'),
                  const SizedBox(height: 8),
                  _buildCompaniesSection(state),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Estadísticas'),
                  const SizedBox(height: 8),
                  _buildStatsSection(state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDoctorsSection(AdminState state) {
    if (state is AdminLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (state is AdminError) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              state.message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      );
    }

    int doctorCount = 0;
    List<UserEntity> recentDoctors = [];

    if (state is DoctorsLoaded) {
      doctorCount = state.doctors.length;
      recentDoctors = state.doctors.take(3).toList();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, color: Colors.blue, size: 32),
                const SizedBox(width: 12),
                Text(
                  '$doctorCount doctores registrados',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (recentDoctors.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...recentDoctors.map(
                (doctor) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor:
                        _roleColor(doctor.rol).withValues(alpha: 0.2),
                    child: Icon(
                      Icons.person,
                      color: _roleColor(doctor.rol),
                      size: 20,
                    ),
                  ),
                  title: Text(doctor.nombre),
                  subtitle: Text(
                    '${_roleLabel(doctor.rol)} · ${doctor.email}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlocProvider<AdminBloc>.value(
                        value: context.read<AdminBloc>(),
                        child: const DoctorListScreen(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Ver listado completo'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompaniesSection(AdminState state) {
    List<String> empresas = [];

    if (state is DoctorsLoaded) {
      final Set<String> seen = {};
      for (final doctor in state.doctors) {
        // Empresas are extracted from doctor context; in a real scenario
        // they'd come from a dedicated endpoint. For now we show the count.
        if (doctor is DoctorUser && doctor.dependenciaLocalId.isNotEmpty) {
          final empresaName = doctor.dependenciaLocalId;
          if (seen.add(empresaName)) {
            empresas.add(empresaName);
          }
        }
      }
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.business, color: Colors.teal, size: 32),
                const SizedBox(width: 12),
                Text(
                  '${empresas.length} empresas activas',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (empresas.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: empresas
                    .map(
                      (e) => Chip(
                        label: Text(e, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.teal.withValues(alpha: 0.1),
                      ),
                    )
                    .toList(),
              ),
            ] else ...[
              const SizedBox(height: 12),
              const Text(
                'No hay empresas registradas aún',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(AdminState state) {
    if (state is StatsLoaded) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  _buildStatItem(
                    Icons.campaign,
                    '${state.stats.totalCampanasActivas}',
                    'Campañas',
                    Colors.orange,
                  ),
                  _buildStatItem(
                    Icons.people,
                    '${state.stats.totalPacientes}',
                    'Pacientes',
                    Colors.blue,
                  ),
                  _buildStatItem(
                    Icons.medical_services,
                    '${state.stats.totalDoctoresActivos}',
                    'Doctores\nActivos',
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider<AdminBloc>.value(
                          value: context.read<AdminBloc>(),
                          child: const StatsScreen(),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('Ver estadísticas detalladas'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (state is AdminLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildStatItem(
                  Icons.campaign,
                  '—',
                  'Campañas',
                  Colors.orange,
                ),
                _buildStatItem(
                  Icons.people,
                  '—',
                  'Pacientes',
                  Colors.blue,
                ),
                _buildStatItem(
                  Icons.medical_services,
                  '—',
                  'Doctores\nActivos',
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Color _roleColor(UserRole rol) {
    switch (rol) {
      case UserRole.admin:
        return Colors.red;
      case UserRole.jefe:
        return Colors.orange;
      case UserRole.user:
        return Colors.blue;
    }
  }

  String _roleLabel(UserRole rol) {
    switch (rol) {
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.jefe:
        return 'JEFE';
      case UserRole.user:
        return 'USER';
    }
  }
}
