import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/database/database_config.dart';
import 'core/router/app_router.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_state.dart' as auth;
import 'injection_container.dart' as di;
import 'package:flutter_dotenv/flutter_dotenv.dart';


void main() async {
  await dotenv.load();
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
  configureDatabase();
  await di.init();
  runApp(const OptiFlowApp());
}

class OptiFlowApp extends StatelessWidget {
  const OptiFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => di.sl<AuthBloc>()),
      ],
      child: BlocListener<AuthBloc, auth.AuthState>(
        listener: (context, state) {
          if (state is auth.AuthInitial) {
            AppRouter.router.go(AppRouter.login);
          }
        },
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false, 
          title: 'OptiFlow',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          ),
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
