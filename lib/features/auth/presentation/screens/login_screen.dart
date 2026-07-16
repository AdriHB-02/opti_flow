import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:opti_flow/core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/utils/session_manager.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _localAuth = LocalAuthentication();
  bool _obscurePassword = true;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    try {
      final available = await _localAuth.canCheckBiometrics;
      if (mounted) setState(() => _biometricAvailable = available);
    } catch (e) {
      debugPrint('[Biometric] canCheckBiometrics falló: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLogin() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          LoginRequested(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ),
        );
  }

  void _onBiometricLogin() {
    context.read<AuthBloc>().add(const BiometricLoginRequested());
  }

  void _onGoogleSignIn() {
    context.read<AuthBloc>().add(const GoogleSignInRequested());
  }

  void _navigateByRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        context.go(AppRouter.adminDashboard);
      case UserRole.jefe:
        context.go(AppRouter.jefeDashboard);
      case UserRole.user:
        context.go(AppRouter.userDashboard);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Correo requerido';
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Correo inválido';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Contraseña requerida';
    if (value.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          SessionManager.save(
            id: state.user.id,
            nombre: state.user.nombre,
            email: state.user.email,
            rol: state.user.rol.name.toUpperCase(),
            activo: state.user.activo,
          );
          _navigateByRole(state.user.rol);
        }
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.network(
                        AppConstants.loginLogoUrl,
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => Icon(Icons.image, size: 80, color: Theme.of(context).colorScheme.primary),
                      ),
                      Text('OptiFlow',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo electrónico',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: const Icon(Icons.lock_outlined),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: state is AuthLoading ? null : _onLogin,
                          child: state is AuthLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Text('Iniciar sesión'),
                        ),
                      ),
                      if (_biometricAvailable) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed:
                                state is AuthLoading ? null : _onBiometricLogin,
                            icon: const Icon(Icons.fingerprint),
                            label: const Text('Huella digital'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'o continúa con',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed:
                              state is AuthLoading ? null : _onGoogleSignIn,
                          icon: const Icon(Icons.g_mobiledata, size: 24),
                          label: const Text('Continuar con Google'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => context.push(AppRouter.forgotPassword),
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
