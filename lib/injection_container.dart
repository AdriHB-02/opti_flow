import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/data/datasources/remote_auth_data_source.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/domain/repositories/i_auth_repository.dart';
import 'features/auth/domain/usecases/biometric_login_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/recuperar_password_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

import 'features/patients/data/datasources/local_patient_data_source.dart';
import 'features/patients/data/datasources/local_historia_data_source.dart';
import 'features/patients/data/datasources/local_dependencia_data_source.dart';
import 'features/patients/data/repositories/historia_repository.dart';
import 'features/patients/data/repositories/patient_repository.dart';
import 'features/patients/data/repositories/dependencia_repository.dart';
import 'features/patients/domain/repositories/i_historia_repository.dart';
import 'features/patients/domain/repositories/i_patient_repository.dart';
import 'features/patients/domain/repositories/i_dependencia_repository.dart';
import 'features/patients/domain/usecases/get_dependencias_usecase.dart';
import 'features/patients/domain/usecases/get_historias_by_paciente_usecase.dart';
import 'features/patients/domain/usecases/get_patients_usecase.dart';
import 'features/patients/domain/usecases/register_patient_usecase.dart';
import 'features/patients/domain/usecases/search_patient_usecase.dart';
import 'features/patients/presentation/bloc/patient_bloc.dart';
import 'features/patients/presentation/bloc/historia_bloc.dart';
import 'features/campanas/data/datasources/local_campana_data_source.dart';
import 'features/campanas/data/repositories/campana_repository.dart';
import 'features/campanas/domain/repositories/i_campana_repository.dart';
import 'features/campanas/domain/usecases/assign_doctor_to_campana_usecase.dart';
import 'features/campanas/domain/usecases/create_campana_usecase.dart';
import 'features/campanas/domain/usecases/get_available_doctors_usecase.dart';
import 'features/campanas/domain/usecases/get_campana_progress_usecase.dart';
import 'features/campanas/domain/usecases/import_pacientes_reconsulta_usecase.dart';

import 'core/database/database_helper.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Supabase ──
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // ── Database ──
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
  await sl<DatabaseHelper>().database;

  // ── Data Sources ──
  sl.registerLazySingleton<RemoteAuthDataSource>(
    () => RemoteAuthDataSource(supabaseClient: sl()),
  );
  sl.registerLazySingleton<LocalPatientDataSource>(
    () => LocalPatientDataSource(databaseHelper: sl()),
  );
  sl.registerLazySingleton<LocalHistoriaDataSource>(
    () => LocalHistoriaDataSource(databaseHelper: sl()),
  );
  sl.registerLazySingleton<LocalCampanaDataSource>(
    () => LocalCampanaDataSource(databaseHelper: sl()),
  );
  sl.registerLazySingleton<LocalDependenciaDataSource>(
    () => LocalDependenciaDataSource(databaseHelper: sl()),
  );

  // ── Repositories ──
  sl.registerLazySingleton<IAuthRepository>(
    () => AuthRepository(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<IPatientRepository>(
    () => PatientRepository(localDataSource: sl()),
  );
  sl.registerLazySingleton<IHistoriaRepository>(
    () => HistoriaRepository(localDataSource: sl()),
  );
  sl.registerLazySingleton<ICampanaRepository>(
    () => CampanaRepository(localDataSource: sl()),
  );
  sl.registerLazySingleton<IDependenciaRepository>(
    () => DependenciaRepository(localDataSource: sl()),
  );

  // ── Use Cases ──
  sl.registerLazySingleton<LoginUseCase>(() => LoginUseCase(sl()));
  sl.registerLazySingleton<LogoutUseCase>(() => LogoutUseCase(sl()));
  sl.registerLazySingleton<BiometricLoginUseCase>(() => BiometricLoginUseCase(sl()));
  sl.registerLazySingleton<RecuperarPasswordUseCase>(
    () => RecuperarPasswordUseCase(sl()),
  );

  // Patient use cases
  sl.registerLazySingleton<GetPatientsUseCase>(
    () => GetPatientsUseCase(sl()),
  );
  sl.registerLazySingleton<RegisterPatientUseCase>(
    () => RegisterPatientUseCase(
      patientRepository: sl(),
      historiaRepository: sl(),
    ),
  );
  sl.registerLazySingleton<SearchPatientUseCase>(
    () => SearchPatientUseCase(sl()),
  );
  sl.registerLazySingleton<GetDependenciasUseCase>(
    () => GetDependenciasUseCase(sl()),
  );
  sl.registerLazySingleton<GetHistoriasByPacienteUseCase>(
    () => GetHistoriasByPacienteUseCase(sl()),
  );

  // ── Campaña Use Cases ──
  sl.registerLazySingleton<CreateCampanaUseCase>(
    () => CreateCampanaUseCase(sl()),
  );
  sl.registerLazySingleton<AssignDoctorToCampanaUseCase>(
    () => AssignDoctorToCampanaUseCase(sl()),
  );
  sl.registerLazySingleton<GetCampanaProgressUseCase>(
    () => GetCampanaProgressUseCase(sl()),
  );
  sl.registerLazySingleton<ImportPacientesReconsultaUseCase>(
    () => ImportPacientesReconsultaUseCase(
      patientRepository: sl(),
      campanaRepository: sl(),
    ),
  );
  sl.registerLazySingleton<GetAvailableDoctorsUseCase>(
    () => GetAvailableDoctorsUseCase(sl()),
  );

  // ── BLoCs ──
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      biometricLoginUseCase: sl(),
    ),
  );

  sl.registerFactory<PatientBloc>(
    () => PatientBloc(
      getPatientsUseCase: sl(),
      registerPatientUseCase: sl(),
      searchPatientUseCase: sl(),
    ),
  );

  sl.registerFactory<HistoriaBloc>(
    () => HistoriaBloc(getHistoriasByPacienteUseCase: sl()),
  );
}
