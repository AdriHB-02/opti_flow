import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../constants/app_constants.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static Database? _database;
  static Future<Database>? _dbFuture;

  Future<Database> get database {
    if (_database != null) return Future.value(_database);
    if (_dbFuture != null) return _dbFuture!;
    _dbFuture = _initDatabase();
    return _dbFuture!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.dbName);

    try {
      final db = await openDatabase(
        path,
        version: AppConstants.dbVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
      _database = db;
      return db;
    } on DatabaseException catch (e) {
      debugPrint('[DB] Error abriendo BD, recreando: $e');
      _dbFuture = null;
      await deleteDatabase(path);
      return _initDatabase();
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${AppConstants.tableDoctores} (
        id TEXT PRIMARY KEY NOT NULL,
        nombre TEXT NOT NULL,
        email TEXT NOT NULL,
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
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
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
        FOREIGN KEY (doctor_id) REFERENCES ${AppConstants.tableDoctores}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${AppConstants.tableSyncLog} (
        id TEXT PRIMARY KEY NOT NULL,
        doctor_id TEXT NOT NULL,
        tabla_afectada TEXT NOT NULL,
        registro_id TEXT NOT NULL,
        operacion TEXT NOT NULL CHECK(operacion IN ('INSERT', 'UPDATE', 'DELETE')),
        fecha_local TEXT NOT NULL,
        sincronizado INTEGER NOT NULL DEFAULT 0,
        fecha_sync TEXT,
        intentos INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (doctor_id) REFERENCES ${AppConstants.tableDoctores}(id)
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

    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    await db.execute('''
      CREATE INDEX idx_pacientes_dependencia_id
      ON ${AppConstants.tablePacientes} (dependencia_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_historias_clinicas_paciente_id
      ON ${AppConstants.tableHistoriasClinicas} (paciente_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_campanas_creado_por
      ON ${AppConstants.tableCampanas} (creado_por)
    ''');
    await db.execute('''
      CREATE INDEX idx_campanas_empresa_id
      ON ${AppConstants.tableCampanas} (empresa_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_historias_clinicas_campana_id
      ON ${AppConstants.tableHistoriasClinicas} (campana_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_pagos_doctor_id
      ON ${AppConstants.tablePagos} (doctor_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_sync_log_sync_filter
      ON ${AppConstants.tableSyncLog} (sincronizado, doctor_id, tabla_afectada)
    ''');
    await db.execute('''
      CREATE INDEX idx_sync_log_tabla_afectada
      ON ${AppConstants.tableSyncLog} (tabla_afectada)
    ''');
    await db.execute('''
      CREATE INDEX idx_sync_log_doctor_id
      ON ${AppConstants.tableSyncLog} (doctor_id)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < 2) {
        await _migrateV1toV2(db);
      }
      if (oldVersion < 3) {
        await _migrateV2toV3(db);
      }
      if (oldVersion < 4) {
        await _migrateV3toV4(db);
      }
      if (oldVersion < 5) {
        await _migrateV4toV5(db);
      }
    } catch (e) {
      debugPrint('[DB] Migración v$oldVersion→v$newVersion falló: $e');
      rethrow;
    }
  }

  Future<void> _migrateV1toV2(Database db) async {
    try {
      await db.execute('ALTER TABLE ${AppConstants.tableDoctores} DROP COLUMN password_hash');
    } catch (_) {
      debugPrint('[DB] password_hash ya eliminado o SQLite <3.35 — ignorando');
    }

    await db.execute('''
      ALTER TABLE ${AppConstants.tableEmpresas}
      ADD COLUMN updated_at TEXT NOT NULL DEFAULT '1970-01-01T00:00:00.000'
    ''');

    await db.execute('''
      ALTER TABLE ${AppConstants.tableSyncLog}
      ADD COLUMN doctor_id TEXT NOT NULL DEFAULT 'unknown'
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_campanas_creado_por
      ON ${AppConstants.tableCampanas} (creado_por)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_campanas_empresa_id
      ON ${AppConstants.tableCampanas} (empresa_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_historias_clinicas_campana_id
      ON ${AppConstants.tableHistoriasClinicas} (campana_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_pagos_doctor_id
      ON ${AppConstants.tablePagos} (doctor_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sync_log_tabla_afectada
      ON ${AppConstants.tableSyncLog} (tabla_afectada)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sync_log_doctor_id
      ON ${AppConstants.tableSyncLog} (doctor_id)
    ''');
  }

  Future<void> _migrateV2toV3(Database db) async {
    await db.execute('''
      UPDATE ${AppConstants.tableEmpresas}
      SET updated_at = '1970-01-01T00:00:00.000'
      WHERE updated_at = '' OR updated_at IS NULL
    ''');

    await db.execute('''
      UPDATE ${AppConstants.tableSyncLog}
      SET doctor_id = 'unknown'
      WHERE doctor_id = '' OR doctor_id IS NULL
    ''');

    await db.execute('''
      DROP INDEX IF EXISTS idx_sync_log_sincronizado
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_sync_log_sync_filter
      ON ${AppConstants.tableSyncLog} (sincronizado, doctor_id, tabla_afectada)
    ''');
  }

  Future<void> _migrateV3toV4(Database db) async {
    await db.execute('''
      ALTER TABLE ${AppConstants.tableSyncLog}
      ADD COLUMN intentos INTEGER NOT NULL DEFAULT 0
    ''');
  }

  Future<void> _migrateV4toV5(Database db) async {
    await db.execute('''
      ALTER TABLE ${AppConstants.tableHistoriasClinicas}
      RENAME TO historias_clinicas_v4_old
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
        FOREIGN KEY (doctor_id) REFERENCES ${AppConstants.tableDoctores}(id)
      )
    ''');
    await db.execute('''
      INSERT INTO ${AppConstants.tableHistoriasClinicas} (
        id, paciente_id, campana_id, diagnostico_texto, imagen_url,
        latitud, longitud, fecha_atencion, doctor_id, historia_anterior_id,
        sincronizado, created_at
      )
      SELECT id, paciente_id, campana_id, diagnostico_texto, imagen_url,
        latitud, longitud, fecha_atencion, doctor_id, historia_anterior_id,
        sincronizado, created_at
      FROM historias_clinicas_v4_old
    ''');
    await db.execute('DROP TABLE historias_clinicas_v4_old');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_historias_clinicas_paciente_id
      ON ${AppConstants.tableHistoriasClinicas} (paciente_id)
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_historias_clinicas_campana_id
      ON ${AppConstants.tableHistoriasClinicas} (campana_id)
    ''');
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(AppConstants.tableSyncLog);
      await txn.delete(AppConstants.tableHistoriasClinicas);
      await txn.delete(AppConstants.tablePacientes);
      await txn.delete(AppConstants.tableDoctorCampana);
      await txn.delete(AppConstants.tableCampanas);
      await txn.delete(AppConstants.tableDependencias);
      await txn.delete(AppConstants.tablePagos);
      await txn.delete(AppConstants.tableEmpresas);
      await txn.delete(AppConstants.tableDoctores);
    });
  }

  Future<void> batchInsert(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    final db = await database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final row in rows) {
        batch.insert(table, row);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<Map<String, dynamic>?> getRecordById(
    String table,
    String recordId,
  ) async {
    final db = await database;
    final maps = await db.query(
      table,
      where: 'id = ?',
      whereArgs: [recordId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<void> insertSyncLogEntry(Map<String, dynamic> syncLogMap) async {
    final db = await database;
    await db.insert(
      AppConstants.tableSyncLog,
      syncLogMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
    }
    _database = null;
    _dbFuture = null;
  }
}
