import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/historia_clinica_entity.dart';
import '../bloc/historia_bloc.dart';
import '../bloc/historia_event.dart';
import '../bloc/historia_state.dart';
import '../widgets/shimmer_loading.dart';

class PatientDetailScreen extends StatefulWidget {
  final String patientId;
  final String? patientName;

  const PatientDetailScreen({
    super.key,
    required this.patientId,
    this.patientName,
  });

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  @override
  void initState() {
    super.initState();
    context
        .read<HistoriaBloc>()
        .add(LoadHistorias(pacienteId: widget.patientId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patientName ?? 'Detalle del Paciente'),
      ),
      body: BlocBuilder<HistoriaBloc, HistoriaState>(
        builder: (context, state) {
          if (state is HistoriaLoading) {
            return const ShimmerLoading();
          }

          if (state is HistoriasLoaded) {
            final historias = state.historias;
            if (historias.isEmpty) {
              return const Center(
                child: Text('No hay historias clínicas registradas'),
              );
            }
            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<HistoriaBloc>()
                    .add(LoadHistorias(pacienteId: widget.patientId));
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: historias.length,
                itemBuilder: (context, index) {
                  return _HistoriaCard(historia: historias[index]);
                },
              ),
            );
          }

          if (state is HistoriaError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.message,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context
                          .read<HistoriaBloc>()
                          .add(LoadHistorias(pacienteId: widget.patientId));
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _HistoriaCard extends StatelessWidget {
  final HistoriaClinicaEntity historia;

  const _HistoriaCard({required this.historia});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  historia.fechaAtencion.toIso8601String().substring(0, 10),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Icon(
                  historia.sincronizado ? Icons.cloud_done : Icons.cloud_off,
                  size: 20,
                  color: historia.sincronizado ? Colors.blue : Colors.grey,
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (historia.diagnosticoTexto != null &&
                historia.diagnosticoTexto!.isNotEmpty) ...[
              Text(
                historia.diagnosticoTexto!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${historia.latitud.toStringAsFixed(4)}, '
                  '${historia.longitud.toStringAsFixed(4)}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                const Spacer(),
                if (historia.historiaAnteriorId != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Reconsulta',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
