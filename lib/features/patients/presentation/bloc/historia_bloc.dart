import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/get_historias_by_paciente_usecase.dart';
import 'historia_event.dart';
import 'historia_state.dart';

class HistoriaBloc extends Bloc<HistoriaEvent, HistoriaState> {
  final GetHistoriasByPacienteUseCase _getHistoriasByPacienteUseCase;

  HistoriaBloc({
    required GetHistoriasByPacienteUseCase getHistoriasByPacienteUseCase,
  })  : _getHistoriasByPacienteUseCase = getHistoriasByPacienteUseCase,
        super(const HistoriaInitial()) {
    on<LoadHistorias>(_onLoadHistorias);
  }

  Future<void> _onLoadHistorias(
    LoadHistorias event,
    Emitter<HistoriaState> emit,
  ) async {
    emit(const HistoriaLoading());
    final result = await _getHistoriasByPacienteUseCase(
      GetHistoriasParams(pacienteId: event.pacienteId),
    );
    emit(result.fold(
      (failure) => HistoriaError(failure.message),
      (historias) => HistoriasLoaded(historias: historias),
    ));
  }
}
