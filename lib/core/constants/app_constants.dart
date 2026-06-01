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
  static const int dbVersion = 1;

  // ── Supabase (placeholder — set in .env) ──
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );

  // ── AWS S3 (placeholder) ──
  static const String awsBucket = String.fromEnvironment(
    'AWS_BUCKET',
    defaultValue: 'optiflow-images',
  );

  // ── Google Maps (placeholder) ──
  static const String mapsApiKey = String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: 'your-maps-api-key',
  );
}
