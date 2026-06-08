import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import 'widgets/dashboard_scaffold.dart';

class AppRouter {
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String adminDashboard = '/admin';
  static const String jefeDashboard = '/jefe';
  static const String userDashboard = '/user';

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
        builder: (context, state) => const DashboardScaffold(
          title: 'OptiFlow - User Dashboard',
        ),
      ),
    ],
  );
}
