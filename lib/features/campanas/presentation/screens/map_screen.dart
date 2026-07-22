import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/utils/session_manager.dart';
import '../../domain/entities/campana_entity.dart';
import '../../domain/services/i_geocoding_service.dart';
import '../../domain/usecases/get_campanas_by_doctor_usecase.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final GetCampanasByDoctorUseCase _getCampanas =
      GetIt.instance<GetCampanasByDoctorUseCase>();
  final IGeocodingService _geocodingService =
      GetIt.instance<IGeocodingService>();

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _loading = true;
  String? _error;
  bool _mapReady = false;

  static const _defaultPosition = CameraPosition(
    target: LatLng(19.4326, -99.1332),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    setState(() {
      _loading = true;
      _error = null;
    });

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
      (campanas) async {
        await _buildMarkers(campanas);
        if (!mounted) return;
        setState(() => _loading = false);
      },
    );
  }

  Future<void> _buildMarkers(List<CampanaEntity> campanas) async {
    final markers = <Marker>{};
    final validPositions = <LatLng>[];

    for (var i = 0; i < campanas.length; i++) {
      final campana = campanas[i];
      final location = await _geocodingService.locationFromAddress(
        '${campana.nombreEmpresa}, ${campana.lugar}',
      );

      if (!mounted) return;

      if (location != null) {
        final position = LatLng(location.lat, location.lng);
        validPositions.add(position);

        final estado = campana.estado == CampanaEstado.activa
            ? 'Activa'
            : 'Finalizada';

        markers.add(
          Marker(
            markerId: MarkerId(campana.id),
            position: position,
            infoWindow: InfoWindow(
              title: campana.nombreEmpresa,
              snippet:
                  '${campana.lugar}\n$estado · '
                  '${campana.fechaInicio.day}/${campana.fechaInicio.month}/${campana.fechaInicio.year}',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              campana.estado == CampanaEstado.activa
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueRed,
            ),
          ),
        );
      }
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
        CameraUpdate.newLatLngZoom(positions.first, 14),
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
      appBar: AppBar(title: const Text('Mapa de Campañas')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCampaigns,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: _defaultPosition,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        _mapReady = true;
                      },
                      markers: _markers,
                      myLocationEnabled: false,
                      zoomControlsEnabled: true,
                      mapToolbarEnabled: true,
                    ),
                    if (_markers.isEmpty)
                      const Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'No se encontraron ubicaciones para las campañas.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
