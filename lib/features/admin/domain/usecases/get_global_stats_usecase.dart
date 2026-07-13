import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/repositories/i_auth_repository.dart';
import '../entities/global_stats.dart';

class GetGlobalStatsUseCase extends UseCase<GlobalStats, NoParams> {
  final IAuthRepository repository;

  GetGlobalStatsUseCase(this.repository);

  @override
  Future<Either<Failure, GlobalStats>> call(NoParams params) async {
    final result = await repository.getGlobalStats();
    return result.map(
      (map) => GlobalStats(
        totalCampanasActivas: map['campanasActivas'] ?? 0,
        totalPacientes: map['totalPacientes'] ?? 0,
        totalDoctoresActivos: map['doctoresActivos'] ?? 0,
      ),
    );
  }
}
