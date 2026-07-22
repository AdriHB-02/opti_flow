import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/utils/session_manager.dart';
import '../../features/admin/presentation/bloc/admin_bloc.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/campanas/presentation/bloc/campana_bloc.dart';
import '../../features/campanas/presentation/screens/assign_doctors_screen.dart';
import '../../features/campanas/presentation/screens/campana_progress_screen.dart';
import '../../features/campanas/presentation/screens/jefe_dashboard_screen.dart';
import '../../features/campanas/presentation/screens/map_screen.dart';
import '../../features/campanas/presentation/screens/new_campana_screen.dart';
import '../../features/patients/presentation/screens/new_patient_screen.dart';
import '../../features/patients/presentation/screens/patient_detail_screen.dart';
import '../../features/patients/presentation/screens/patient_list_screen.dart';
import '../../features/patients/presentation/screens/user_dashboard_screen.dart';
import '../../injection_container.dart' as di;

class AppRouter {
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String adminDashboard = '/admin';
  static const String jefeDashboard = '/jefe';
  static const String jefeNewCampana = '/jefe/new-campana';
  static const String jefeMap = '/jefe/map';
  static const String jefeAssignDoctors = '/jefe/assign-doctors';
  static const String jefeCampanaProgress = '/jefe/campana-progress';
  static const String userDashboard = '/user';
  static const String patientList = '/user/patients';
  static const String newPatient = '/user/new-patient';
  static const String patientDetail = '/user/patient';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    routes: [
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: adminDashboard,
        name: 'adminDashboard',
        redirect: (context, state) async {
          final isAdmin = await SessionManager.isAdmin();
          if (!isAdmin) {
            return login;
          }
          return null;
        },
        builder: (context, state) => BlocProvider<AdminBloc>(
          create: (_) => di.sl<AdminBloc>(),
          child: const AdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: jefeDashboard,
        name: 'jefeDashboard',
        builder: (context, state) => BlocProvider<CampanaBloc>.value(
          value: di.sl<CampanaBloc>(),
          child: const JefeDashboardScreen(),
        ),
      ),
      GoRoute(
        path: jefeNewCampana,
        name: 'jefeNewCampana',
        builder: (context, state) => BlocProvider<CampanaBloc>.value(
          value: di.sl<CampanaBloc>(),
          child: const NewCampanaScreen(),
        ),
      ),
      GoRoute(
        path: jefeMap,
        name: 'jefeMap',
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: '$jefeAssignDoctors/:campanaId',
        name: 'jefeAssignDoctors',
        builder: (context, state) {
          final campanaId = state.pathParameters['campanaId']!;
          return BlocProvider<CampanaBloc>.value(
            value: di.sl<CampanaBloc>(),
            child: AssignDoctorsScreen(campanaId: campanaId),
          );
        },
      ),
      GoRoute(
        path: '$jefeCampanaProgress/:campanaId',
        name: 'jefeCampanaProgress',
        builder: (context, state) {
          final campanaId = state.pathParameters['campanaId']!;
          return BlocProvider<CampanaBloc>.value(
            value: di.sl<CampanaBloc>(),
            child: CampanaProgressScreen(campanaId: campanaId),
          );
        },
      ),
      GoRoute(
        path: userDashboard,
        name: 'userDashboard',
        builder: (context, state) => const UserDashboardScreen(),
      ),
      GoRoute(
        path: '$patientList/:depId',
        name: 'patientList',
        builder: (context, state) {
          final depId = state.pathParameters['depId']!;
          return PatientListScreen(dependenciaId: depId);
        },
      ),
      GoRoute(
        path: newPatient,
        name: 'newPatient',
        builder: (context, state) => const NewPatientScreen(),
      ),
      GoRoute(
        path: '$patientDetail/:id',
        name: 'patientDetail',
        builder: (context, state) {
          final patientId = state.pathParameters['id']!;
          final name = (state.extra as Map<String, dynamic>?)?['name'] as String?;
          return PatientDetailScreen(
            patientId: patientId,
            patientName: name,
          );
        },
      ),
    ],
  );
}
