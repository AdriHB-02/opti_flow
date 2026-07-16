import 'package:equatable/equatable.dart';

class PatientsByMonth extends Equatable {
  final String mes;
  final int cantidad;

  const PatientsByMonth({
    required this.mes,
    required this.cantidad,
  });

  @override
  List<Object?> get props => [mes, cantidad];
}
