import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/patients/presentation/screens/new_patient_screen.dart';
import '../../features/patients/presentation/screens/patient_detail_screen.dart';
import '../../features/patients/presentation/screens/patient_list_screen.dart';
import '../../features/patients/presentation/screens/user_dashboard_screen.dart';
import 'widgets/dashboard_scaffold.dart';

class AppRouter {
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String adminDashboard = '/admin';
  static const String jefeDashboard = '/jefe';
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
        builder: (context, state) => const DashboardScaffold(
          title: 'OptiFlow - Admin Dashboard',
        ),
      ),
      GoRoute(
        path: jefeDashboard,
        name: 'jefeDashboard',
        builder: (context, state) => const DashboardScaffold(
          title: 'OptiFlow - Jefe Dashboard',
        ),
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
