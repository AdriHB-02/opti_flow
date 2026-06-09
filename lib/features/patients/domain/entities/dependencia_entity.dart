import 'package:equatable/equatable.dart';

enum DependenciaTipo { local, empresa }

class DependenciaEntity extends Equatable {
  final String id;
  final DependenciaTipo tipo;
  final String? campanaId;
  final String? doctorId;
  final String nombre;

  const DependenciaEntity({
    required this.id,
    required this.tipo,
    this.campanaId,
    this.doctorId,
    required this.nombre,
  });

  @override
  List<Object?> get props => [
        id,
        tipo,
        campanaId,
        doctorId,
        nombre,
      ];
}
