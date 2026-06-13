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
import 'features/patients/data/repositories/historia_repository.dart';
import 'features/patients/data/repositories/patient_repository.dart';
import 'features/patients/domain/repositories/i_historia_repository.dart';
import 'features/patients/domain/repositories/i_patient_repository.dart';
import 'features/campanas/data/datasources/local_campana_data_source.dart';
import 'features/campanas/data/repositories/campana_repository.dart';
import 'features/campanas/domain/repositories/i_campana_repository.dart';

import 'core/database/database_helper.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Supabase ──
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

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

  // ── Use Cases ──
  sl.registerLazySingleton<LoginUseCase>(() => LoginUseCase(sl()));
  sl.registerLazySingleton<LogoutUseCase>(() => LogoutUseCase(sl()));
  sl.registerLazySingleton<BiometricLoginUseCase>(() => BiometricLoginUseCase(sl()));
  sl.registerLazySingleton<RecuperarPasswordUseCase>(
    () => RecuperarPasswordUseCase(sl()),
  );

  // ── BLoCs ──
  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      biometricLoginUseCase: sl(),
    ),
  );

  // ── Database ──
  await DatabaseHelper().database;
}
