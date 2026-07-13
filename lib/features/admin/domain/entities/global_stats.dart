import 'package:equatable/equatable.dart';

class GlobalStats extends Equatable {
  final int totalCampanasActivas;
  final int totalPacientes;
  final int totalDoctoresActivos;

  const GlobalStats({
    required this.totalCampanasActivas,
    required this.totalPacientes,
    required this.totalDoctoresActivos,
  });

  @override
  List<Object?> get props => [
        totalCampanasActivas,
        totalPacientes,
        totalDoctoresActivos,
      ];
}
