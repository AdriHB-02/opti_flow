import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';
import '../widgets/patients_bar_chart.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminBloc>().add(const LoadStats());
    context.read<AdminBloc>().add(const LoadPatientsByMonth());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas Globales'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<AdminBloc>().add(const LoadStats());
          context.read<AdminBloc>().add(const LoadPatientsByMonth());
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Resumen General'),
              const SizedBox(height: 12),
              _buildStatCards(),
              const SizedBox(height: 24),
              _buildSectionTitle('Pacientes por Mes'),
              const SizedBox(height: 12),
              _buildChartSection(),
            ],
          ),
        ),
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

  Widget _buildStatCards() {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        final ready = state is AdminReady ? state : null;

        if (ready != null && ready.statsLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (ready?.stats != null) {
          final stats = ready!.stats!;
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.campaign,
                      title: 'Campañas\nActivas',
                      value: '${stats.totalCampanasActivas}',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.people,
                      title: 'Total\nPacientes',
                      value: '${stats.totalPacientes}',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.medical_services,
                      title: 'Doctores\nActivos',
                      value: '${stats.totalDoctoresActivos}',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()),
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.campaign,
                    title: 'Campañas\nActivas',
                    value: '—',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.people,
                    title: 'Total\nPacientes',
                    value: '—',
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.medical_services,
                    title: 'Doctores\nActivos',
                    value: '—',
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartSection() {
    return BlocBuilder<AdminBloc, AdminState>(
      builder: (context, state) {
        final ready = state is AdminReady ? state : null;

        if (ready != null && ready.patientsLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (ready?.patientsByMonth != null) {
          return PatientsBarChart(data: ready!.patientsByMonth!);
        }

        return const Card(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text('Cargando datos del gráfico...'),
            ),
          ),
        );
      },
    );
  }
}
