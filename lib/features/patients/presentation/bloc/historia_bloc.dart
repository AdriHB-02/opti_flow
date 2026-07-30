import 'package:flutter/foundation.dart';
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
    debugPrint('[HistoriaBloc] LoadHistorias pacienteId=${event.pacienteId} doctorId=${event.doctorId}');
    emit(const HistoriaLoading());
    final result = await _getHistoriasByPacienteUseCase(
      GetHistoriasParams(
        pacienteId: event.pacienteId,
        doctorId: event.doctorId,
      ),
    );
    debugPrint('[HistoriaBloc] Result: $result');
    emit(result.fold(
      (failure) {
        debugPrint('[HistoriaBloc] Failure: ${failure.message}');
        return HistoriaError(failure.message);
      },
      (historias) {
        debugPrint('[HistoriaBloc] Success: ${historias.length} historias');
        return HistoriasLoaded(historias: historias);
      },
    ));
  }
}
