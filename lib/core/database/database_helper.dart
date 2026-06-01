import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../constants/app_constants.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    return openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableDoctores} (
        id TEXT PRIMARY KEY NOT NULL,
        nombre TEXT NOT NULL,
        email TEXT NOT NULL,
        password_hash TEXT NOT NULL,
        rol TEXT NOT NULL CHECK(rol IN ('ADMIN', 'JEFE', 'USER')),
        dependencia_local_id TEXT,
        activo INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableEmpresas} (
        id TEXT PRIMARY KEY NOT NULL,
        nombre TEXT NOT NULL,
        lugar TEXT NOT NULL,
        activa INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableCampanas} (
        id TEXT PRIMARY KEY NOT NULL,
        empresa_id TEXT NOT NULL,
        nombre_empresa TEXT NOT NULL,
        lugar TEXT NOT NULL,
        fecha_inicio TEXT NOT NULL,
        fecha_fin TEXT NOT NULL,
        creado_por TEXT NOT NULL,
        estado TEXT NOT NULL CHECK(estado IN ('ACTIVA', 'FINALIZADA')),
        created_at TEXT NOT NULL,
        FOREIGN KEY (empresa_id) REFERENCES ${AppConstants.tableEmpresas}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableDoctorCampana} (
        id TEXT PRIMARY KEY NOT NULL,
        doctor_id TEXT NOT NULL,
        campana_id TEXT NOT NULL,
        asignado_en TEXT NOT NULL,
        FOREIGN KEY (doctor_id) REFERENCES ${AppConstants.tableDoctores}(id),
        FOREIGN KEY (campana_id) REFERENCES ${AppConstants.tableCampanas}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableDependencias} (
        id TEXT PRIMARY KEY NOT NULL,
        tipo TEXT NOT NULL CHECK(tipo IN ('LOCAL', 'EMPRESA')),
        campana_id TEXT,
        doctor_id TEXT,
        nombre TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tablePacientes} (
        id TEXT PRIMARY KEY NOT NULL,
        nombre_completo TEXT NOT NULL,
        dependencia_id TEXT NOT NULL,
        doctor_id TEXT NOT NULL,
        es_reconsulta INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (dependencia_id) REFERENCES ${AppConstants.tableDependencias}(id),
        FOREIGN KEY (doctor_id) REFERENCES ${AppConstants.tableDoctores}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableHistoriasClinicas} (
        id TEXT PRIMARY KEY NOT NULL,
        paciente_id TEXT NOT NULL,
        campana_id TEXT,
        diagnostico_texto TEXT,
        imagen_url TEXT,
        latitud REAL NOT NULL,
        longitud REAL NOT NULL,
        fecha_atencion TEXT NOT NULL,
        doctor_id TEXT NOT NULL,
        historia_anterior_id TEXT,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (paciente_id) REFERENCES ${AppConstants.tablePacientes}(id),
        FOREIGN KEY (campana_id) REFERENCES ${AppConstants.tableCampanas}(id),
        FOREIGN KEY (doctor_id) REFERENCES ${AppConstants.tableDoctores}(id),
        FOREIGN KEY (historia_anterior_id) REFERENCES ${AppConstants.tableHistoriasClinicas}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableSyncLog} (
        id TEXT PRIMARY KEY NOT NULL,
        tabla_afectada TEXT NOT NULL,
        registro_id TEXT NOT NULL,
        operacion TEXT NOT NULL CHECK(operacion IN ('INSERT', 'UPDATE', 'DELETE')),
        fecha_local TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        fecha_sync TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tablePagos} (
        id TEXT PRIMARY KEY NOT NULL,
        doctor_id TEXT NOT NULL,
        proveedor TEXT NOT NULL CHECK(proveedor IN ('STRIPE', 'MERCADOPAGO')),
        referencia_pago TEXT NOT NULL,
        monto REAL NOT NULL,
        estado TEXT NOT NULL CHECK(estado IN ('PENDIENTE', 'COMPLETADO', 'FALLIDO')),
        fecha_pago TEXT NOT NULL,
        FOREIGN KEY (doctor_id) REFERENCES ${AppConstants.tableDoctores}(id)
      )
    ''');

    // ── Índices ──
    await db.execute('''
      CREATE INDEX idx_pacientes_dependencia_id
      ON ${AppConstants.tablePacientes} (dependencia_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_historias_clinicas_paciente_id
      ON ${AppConstants.tableHistoriasClinicas} (paciente_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_sync_log_sincronizado
      ON ${AppConstants.tableSyncLog} (sincronizado)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Migraciones futuras se agregarán aquí.
  }
}
