import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/auth/data/datasources/remote_auth_data_source.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/domain/repositories/i_auth_repository.dart';
import 'features/auth/domain/usecases/biometric_login_usecase.dart';
import 'features/auth/domain/usecases/google_sign_in_usecase.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/domain/usecases/recuperar_password_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

import 'features/patients/data/datasources/local_patient_data_source.dart';
import 'features/patients/data/datasources/local_historia_data_source.dart';
import 'features/patients/data/datasources/local_dependencia_data_source.dart';
import 'features/patients/data/datasources/remote_patient_data_source.dart';
import 'features/patients/data/repositories/historia_repository.dart';
import 'features/patients/data/repositories/patient_repository.dart';
import 'features/patients/data/repositories/dependencia_repository.dart';
import 'features/patients/data/services/gps_service.dart';
import 'features/patients/data/services/camera_service.dart';
import 'features/patients/data/services/s3_upload_service.dart';
import 'features/patients/domain/repositories/i_historia_repository.dart';
import 'features/patients/domain/repositories/i_patient_repository.dart';
import 'features/patients/domain/repositories/i_dependencia_repository.dart';
import 'features/patients/domain/services/i_gps_service.dart';
import 'features/patients/domain/services/i_camera_service.dart';
import 'features/patients/domain/services/i_s3_upload_service.dart';
import 'features/patients/domain/usecases/get_dependencias_usecase.dart';
import 'features/patients/domain/usecases/get_historias_by_campana_usecase.dart';
import 'features/patients/domain/usecases/get_historias_by_paciente_usecase.dart';
import 'features/patients/domain/usecases/get_patients_usecase.dart';
import 'features/patients/domain/usecases/register_patient_usecase.dart';
import 'features/patients/domain/usecases/search_patient_usecase.dart';
import 'features/patients/presentation/bloc/patient_bloc.dart';
import 'features/patients/presentation/bloc/historia_bloc.dart';
import 'features/campanas/data/datasources/local_campana_data_source.dart';
import 'features/campanas/data/datasources/remote_campana_data_source.dart';
import 'features/campanas/data/repositories/campana_repository.dart';
import 'features/campanas/domain/repositories/i_campana_repository.dart';
import 'features/campanas/domain/usecases/assign_doctor_to_campana_usecase.dart';
import 'features/campanas/domain/usecases/create_campana_usecase.dart';
import 'features/campanas/domain/usecases/get_available_doctors_usecase.dart';
import 'features/campanas/domain/usecases/get_campana_progress_usecase.dart';
import 'features/campanas/domain/usecases/get_campanas_by_doctor_usecase.dart';
import 'features/campanas/domain/usecases/import_pacientes_reconsulta_usecase.dart';
import 'features/campanas/domain/services/i_geocoding_service.dart';
import 'features/campanas/data/services/geocoding_service.dart';
import 'features/campanas/presentation/bloc/campana_bloc.dart';

import 'features/admin/domain/usecases/get_all_doctors_usecase.dart';
import 'features/admin/domain/usecases/delete_doctor_account_usecase.dart';
import 'features/admin/domain/usecases/get_global_stats_usecase.dart';
import 'features/admin/domain/usecases/get_patients_by_month_usecase.dart';
import 'features/admin/presentation/bloc/admin_bloc.dart';

import 'features/sync/data/repositories/sync_repository.dart';
import 'features/sync/data/services/sync_service.dart';
import 'features/sync/domain/repositories/i_sync_repository.dart';
import 'features/sync/domain/services/connectivity_service.dart';
import 'features/sync/domain/services/i_sync_service.dart';
import 'features/sync/domain/strategies/i_sync_strategy.dart';
import 'features/sync/domain/strategies/last_write_wins_strategy.dart';
import 'features/sync/presentation/bloc/sync_bloc.dart';

import 'core/database/database_helper.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Supabase ──
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // ── Database ──
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper());
  await sl<DatabaseHelper>().database;

  // ── Sync Strategy ──
  sl.registerLazySingleton<ISyncStrategy>(() => LastWriteWinsStrategy());

  // ── GPS Service ──
  sl.registerLazySingleton<IGpsService>(() => GpsService());

  // ── Camera Service ──
  sl.registerLazySingleton<ICameraService>(() => CameraService());

  // ── S3 Upload Service ──
  sl.registerLazySingleton<IS3UploadService>(() => S3UploadService());

  // ── Geocoding Service ──
  sl.registerLazySingleton<IGeocodingService>(() => GeocodingService());

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
  sl.registerLazySingleton<RemotePatientDataSource>(
    () => RemotePatientDataSource(supabaseClient: sl()),
  );
  sl.registerLazySingleton<RemoteCampanaDataSource>(
    () => RemoteCampanaDataSource(supabaseClient: sl()),
  );

  // ── Repositories ──
  sl.registerLazySingleton<IAuthRepository>(
    () => AuthRepository(remoteDataSource: sl(), databaseHelper: sl()),
  );
  sl.registerLazySingleton<IPatientRepository>(
    () => PatientRepository(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<IHistoriaRepository>(
    () => HistoriaRepository(localDataSource: sl()),
  );
  sl.registerLazySingleton<ICampanaRepository>(
    () => CampanaRepository(
      localDataSource: sl(),
      remoteDataSource: sl(),
    ),
  );
  sl.registerLazySingleton<IDependenciaRepository>(
    () => DependenciaRepository(localDataSource: sl()),
  );
  sl.registerLazySingleton<ISyncRepository>(
    () => SyncRepository(databaseHelper: sl()),
  );

  // ── Sync Service ──
  sl.registerLazySingleton<ISyncService>(
    () => SyncService(
      syncRepository: sl(),
      supabaseClient: sl(),
      syncStrategy: sl(),
    ),
  );
  sl.registerLazySingleton<ConnectivityService>(
    () => ConnectivityService(syncService: sl()),
  );

  // ── Use Cases ──
  sl.registerLazySingleton<LoginUseCase>(() => LoginUseCase(sl()));
  sl.registerLazySingleton<LogoutUseCase>(() => LogoutUseCase(sl()));
  sl.registerLazySingleton<BiometricLoginUseCase>(() => BiometricLoginUseCase(sl()));
  sl.registerLazySingleton<GoogleSignInUseCase>(() => GoogleSignInUseCase(sl()));
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
      gpsService: sl(),
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
  sl.registerLazySingleton<GetHistoriasByCampanaUseCase>(
    () => GetHistoriasByCampanaUseCase(sl()),
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
  sl.registerLazySingleton<GetCampanasByDoctorUseCase>(
    () => GetCampanasByDoctorUseCase(sl()),
  );

  // ── Admin Use Cases ──
  sl.registerLazySingleton<GetAllDoctorsUseCase>(
    () => GetAllDoctorsUseCase(sl()),
  );
  sl.registerLazySingleton<DeleteDoctorAccountUseCase>(
    () => DeleteDoctorAccountUseCase(sl()),
  );
  sl.registerLazySingleton<GetGlobalStatsUseCase>(
    () => GetGlobalStatsUseCase(sl()),
  );
  sl.registerLazySingleton<GetPatientsByMonthUseCase>(
    () => GetPatientsByMonthUseCase(sl()),
  );

  // ── BLoCs ──
  sl.registerFactory<AdminBloc>(
    () => AdminBloc(
      getAllDoctorsUseCase: sl(),
      deleteDoctorAccountUseCase: sl(),
      getGlobalStatsUseCase: sl(),
      getPatientsByMonthUseCase: sl(),
    ),
  );

  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      biometricLoginUseCase: sl(),
      googleSignInUseCase: sl(),
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

  sl.registerLazySingleton<CampanaBloc>(
    () => CampanaBloc(
      createCampanaUseCase: sl(),
      assignDoctorToCampanaUseCase: sl(),
      getCampanaProgressUseCase: sl(),
      importPacientesReconsultaUseCase: sl(),
      getCampanasByDoctorUseCase: sl(),
    ),
  );

  // ── Sync BLoC ──
  sl.registerFactory<SyncBloc>(
    () => SyncBloc(
      syncService: sl(),
      connectivityService: sl(),
    ),
  );
}
