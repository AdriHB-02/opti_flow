import 'package:flutter_dotenv/flutter_dotenv.dart';


class AppConstants {
  AppConstants._();
  
  // ── SQLite table names ──
  static const String tableDoctores = 'doctores';
  static const String tableEmpresas = 'empresas';
  static const String tableCampanas = 'campanas';
  static const String tableDoctorCampana = 'doctor_campana';
  static const String tableDependencias = 'dependencias';
  static const String tablePacientes = 'pacientes';
  static const String tableHistoriasClinicas = 'historias_clinicas';
  static const String tableSyncLog = 'sync_log';
  static const String tablePagos = 'pagos';

  // ── SQLite database ──
  static const String dbName = 'optiflow_local.db';
  static const int dbVersion = 4;

  static final loginLogoUrl = dotenv.get('LOGIN_LOGO_URL', fallback: 'https://your-project.supabase.co/storage/v1/object/public/logos/your-logo.png');
  static final supabaseUrl = dotenv.get('SUPABASE_URL', fallback: 'https://your-project.supabase.co/rest/v1');
  static final supabaseAnonKey = dotenv.get('SUPABASE_ANON_KEY', fallback: 'your-anon-key');

  // ── Google OAuth 2.0 ──
  static final googleWebClientId = dotenv.get('GOOGLE_WEB_CLIENT_ID', fallback: '');
  static final googleIosClientId = dotenv.get('GOOGLE_IOS_CLIENT_ID', fallback: '');

  // ── Sync config ──
  static const int maxSyncRetries = 3;

  // ── Google Maps (placeholder) ──
  static const String mapsApiKey = String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: 'your-maps-api-key',
  );
}
