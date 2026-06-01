import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static const String login = '/login';
  static const String adminDashboard = '/admin';
  static const String jefeDashboard = '/jefe';
  static const String userDashboard = '/user';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    routes: [
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('OptiFlow - Login')),
        ),
      ),
      GoRoute(
        path: adminDashboard,
        name: 'adminDashboard',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('OptiFlow - Admin Dashboard')),
        ),
      ),
      GoRoute(
        path: jefeDashboard,
        name: 'jefeDashboard',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('OptiFlow - Jefe Dashboard')),
        ),
      ),
      GoRoute(
        path: userDashboard,
        name: 'userDashboard',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('OptiFlow - User Dashboard')),
        ),
      ),
    ],
  );
}
