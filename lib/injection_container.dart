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

import 'core/database/database_helper.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ── Supabase ──
  sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);

  // ── Data Sources ──
  sl.registerLazySingleton<RemoteAuthDataSource>(
    () => RemoteAuthDataSource(supabaseClient: sl()),
  );

  // ── Repositories ──
  sl.registerLazySingleton<IAuthRepository>(
    () => AuthRepository(remoteDataSource: sl()),
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
