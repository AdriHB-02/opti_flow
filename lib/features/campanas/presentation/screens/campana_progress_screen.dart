import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../patients/domain/entities/historia_clinica_entity.dart';
import '../../../patients/domain/usecases/get_historias_by_campana_usecase.dart';
import '../../data/services/pdf_report_service.dart';
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
  final GetHistoriasByCampanaUseCase _getHistoriasByCampana =
      GetIt.instance<GetHistoriasByCampanaUseCase>();

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  List<HistoriaClinicaEntity> _historias = [];
  bool _mapLoading = true;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    context.read<CampanaBloc>().add(LoadProgress(campanaId: widget.campanaId));
    _loadCareEventMarkers();
  }

  Future<void> _loadCareEventMarkers() async {
    setState(() => _mapLoading = true);

    final result = await _getHistoriasByCampana(
      GetHistoriasByCampanaParams(campanaId: widget.campanaId),
    );

    if (!mounted) return;

    result.fold(
      (_) {
        setState(() => _mapLoading = false);
      },
      (historias) {
        _historias = historias;
        _buildMarkersFromHistorias(historias);
        setState(() => _mapLoading = false);
      },
    );
  }

  Future<void> _generatePdf() async {
    final supabase = GetIt.instance<SupabaseClient>();
    final service = PdfReportService(supabase);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generando PDF...'),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await service.generateAndShare(widget.campanaId);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar PDF: $e')),
      );
    }
  }

  void _buildMarkersFromHistorias(List<HistoriaClinicaEntity> historias) {
    final markers = <Marker>{};
    final validPositions = <LatLng>[];

    for (final h in historias) {
      if (h.latitud == 0.0 && h.longitud == 0.0) continue;

      final position = LatLng(h.latitud, h.longitud);
      validPositions.add(position);

      final diagnostico = h.diagnosticoTexto ?? 'Sin diagnóstico';
      final fecha =
          '${h.fechaAtencion.day}/${h.fechaAtencion.month}/${h.fechaAtencion.year}';

      markers.add(
        Marker(
          markerId: MarkerId(h.id),
          position: position,
          infoWindow: InfoWindow(
            title: 'Atención $fecha',
            snippet: diagnostico,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    _markers
      ..clear()
      ..addAll(markers);

    if (validPositions.isNotEmpty && _mapReady) {
      _fitBounds(validPositions);
    }
  }

  void _fitBounds(List<LatLng> positions) {
    if (positions.length == 1) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(positions.first, 15),
      );
      return;
    }

    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final p in positions) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 80),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progreso de Campaña')),
      body: BlocBuilder<CampanaBloc, CampanaState>(
        builder: (context, state) {
          if (state is CampanaLoading && _historias.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CampanaError && _historias.isEmpty) {
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

          final progress =
              state is ProgressLoaded ? state.progress : <DoctorProgress>[];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildProgressSummary(progress),
                const SizedBox(height: 16),
                _buildProgressTable(progress),
                const SizedBox(height: 24),
                _buildMapSection(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _generatePdf(),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('GENERAR PDF'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressSummary(List<DoctorProgress> progress) {
    final total = progress.fold<int>(0, (sum, p) => sum + p.totalPacientes);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total pacientes', style: TextStyle(fontSize: 18)),
            Text('$total',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTable(List<DoctorProgress> progress) {
    if (progress.isEmpty) return const SizedBox.shrink();

    return DataTable(
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
    );
  }

  Widget _buildMapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: const [
            Icon(Icons.map, size: 20),
            SizedBox(width: 8),
            Text(
              'Ubicaciones de atención',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 300,
          child: _mapLoading
              ? const Card(
                  child: Center(child: CircularProgressIndicator()),
                )
              : Card(
                  clipBehavior: Clip.antiAlias,
                  child: _markers.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text(
                              'No hay ubicaciones GPS registradas para esta campaña.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : GoogleMap(
                          initialCameraPosition: const CameraPosition(
                            target: LatLng(19.4326, -99.1332),
                            zoom: 12,
                          ),
                          onMapCreated: (controller) {
                            _mapController = controller;
                            _mapReady = true;
                            if (_markers.isNotEmpty) {
                              final positions = _markers
                                  .map((m) => m.position)
                                  .toList();
                              _fitBounds(positions);
                            }
                          },
                          markers: _markers,
                          myLocationEnabled: false,
                          zoomControlsEnabled: true,
                          mapToolbarEnabled: false,
                        ),
                ),
        ),
      ],
    );
  }
}
