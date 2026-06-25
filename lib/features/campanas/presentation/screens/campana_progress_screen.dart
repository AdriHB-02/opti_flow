import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/doctor_progress.dart';
import '../bloc/campana_bloc.dart';
import '../bloc/campana_event.dart';
import '../bloc/campana_state.dart';

class CampanaProgressScreen extends StatefulWidget {
  final String campanaId;

  const CampanaProgressScreen({super.key, required this.campanaId});

  @override
  State<CampanaProgressScreen> createState() => _CampanaProgressScreenState();
}

class _CampanaProgressScreenState extends State<CampanaProgressScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CampanaBloc>().add(LoadProgress(campanaId: widget.campanaId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progreso de Campaña')),
      body: BlocBuilder<CampanaBloc, CampanaState>(
        builder: (context, state) {
          if (state is CampanaLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProgressLoaded) {
            return _buildProgressTable(state.progress);
          }

          if (state is CampanaError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<CampanaBloc>()
                        .add(LoadProgress(campanaId: widget.campanaId)),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('Cargando...'));
        },
      ),
    );
  }

  Widget _buildProgressTable(List<DoctorProgress> progress) {
    final total = progress.fold<int>(0, (sum, p) => sum + p.totalPacientes);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total pacientes',
                      style: TextStyle(fontSize: 18)),
                  Text('$total',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          DataTable(
            columns: const [
              DataColumn(label: Text('Doctor')),
              DataColumn(label: Text('Pacientes'), numeric: true),
            ],
            rows: progress
                .map(
                  (p) => DataRow(cells: [
                    DataCell(Text(p.doctorNombre)),
                    DataCell(Text('${p.totalPacientes}')),
                  ]),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
