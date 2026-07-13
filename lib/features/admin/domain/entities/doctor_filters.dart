import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/user_entity.dart';

class DoctorFilters extends Equatable {
  final UserRole? rol;
  final String? empresaNombre;
  final DateTime? fechaDesde;
  final DateTime? fechaHasta;

  const DoctorFilters({
    this.rol,
    this.empresaNombre,
    this.fechaDesde,
    this.fechaHasta,
  });

  @override
  List<Object?> get props => [rol, empresaNombre, fechaDesde, fechaHasta];
}
