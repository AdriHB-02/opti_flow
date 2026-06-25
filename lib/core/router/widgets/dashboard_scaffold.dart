import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_event.dart';

class DashboardScaffold extends StatelessWidget {
  final String title;

  const DashboardScaffold({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text(title)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<AuthBloc>().add(const LogoutRequested()),
        child: const Icon(Icons.logout),
      ),
    );
  }
}
