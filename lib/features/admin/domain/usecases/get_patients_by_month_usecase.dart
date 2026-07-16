import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/repositories/i_auth_repository.dart';
import '../entities/patients_by_month.dart';

class GetPatientsByMonthUseCase
    extends UseCase<List<PatientsByMonth>, NoParams> {
  final IAuthRepository repository;

  GetPatientsByMonthUseCase(this.repository);

  @override
  Future<Either<Failure, List<PatientsByMonth>>> call(
    NoParams params,
  ) async {
    final result = await repository.getPacientesPorMes();
    return result.map(
      (list) => list
          .map(
            (map) => PatientsByMonth(
              mes: map['mes'] as String,
              cantidad: map['cantidad'] as int,
            ),
          )
          .toList(),
    );
  }
}
