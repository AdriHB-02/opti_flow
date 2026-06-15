import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'package:opti_flow/core/database/database_helper.dart';
import 'package:opti_flow/core/constants/app_constants.dart';
import 'package:opti_flow/features/patients/data/datasources/local_patient_data_source.dart';
import 'package:opti_flow/features/patients/data/repositories/patient_repository.dart';
import 'package:opti_flow/features/patients/data/repositories/historia_repository.dart';
import 'package:opti_flow/features/patients/domain/entities/patient_entity.dart';
import 'package:opti_flow/features/patients/domain/entities/historia_clinica_entity.dart';
import 'package:opti_flow/features/patients/data/datasources/local_historia_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late DatabaseHelper dbHelper;
  late LocalPatientDataSource patientDataSource;
  late LocalHistoriaDataSource historiaDataSource;
  late PatientRepository patientRepository;
  late HistoriaRepository historiaRepository;

  final testDoctorId = const Uuid().v4();
  final testDependenciaId = const Uuid().v4();
  final testPacienteId = const Uuid().v4();
  final testCampanaId = const Uuid().v4();
  final now = DateTime.now();

  setUp(() async {
    await DatabaseHelper().close();
    final dbPath = await getDatabasesPath();
    await deleteDatabase('$dbPath/${AppConstants.dbName}');

    dbHelper = DatabaseHelper();
    await dbHelper.database;

    patientDataSource = LocalPatientDataSource(databaseHelper: dbHelper);
    historiaDataSource = LocalHistoriaDataSource(databaseHelper: dbHelper);
    patientRepository = PatientRepository(localDataSource: patientDataSource);
    historiaRepository = HistoriaRepository(localDataSource: historiaDataSource);

    final db = await dbHelper.database;

    await db.insert(AppConstants.tableDoctores, {
      'id': testDoctorId,
      'nombre': 'Dr. Test',
      'email': 'test@optiflow.com',
      'rol': 'USER',
      'activo': 1,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    await db.insert(AppConstants.tableDependencias, {
      'id': testDependenciaId,
      'tipo': 'LOCAL',
      'campana_id': null,
      'doctor_id': testDoctorId,
      'nombre': 'Consulta Local',
    });

    await db.insert(AppConstants.tableEmpresas, {
      'id': 'emp-test-1',
      'nombre': 'Empresa Test',
      'lugar': 'Lugar Test',
      'activa': 1,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });

    await db.insert(AppConstants.tableCampanas, {
      'id': testCampanaId,
      'empresa_id': 'emp-test-1',
      'nombre_empresa': 'Empresa Test',
      'lugar': 'Lugar Test',
      'fecha_inicio': now.toIso8601String(),
      'fecha_fin': now.add(const Duration(days: 30)).toIso8601String(),
      'creado_por': testDoctorId,
      'estado': 'ACTIVA',
      'created_at': now.toIso8601String(),
    });

    await patientRepository.savePatient(PatientEntity(
      id: testPacienteId,
      nombreCompleto: 'Paciente Base',
      dependenciaId: testDependenciaId,
      doctorId: testDoctorId,
      esReconsulta: false,
      createdAt: now,
      updatedAt: now,
    ));
  });

  group('DOM-S3-18: PatientRepository (integración BD real)', () {
    test('insertPatient → getPatients → read back successfully', () async {
      final patient = PatientEntity(
        id: testPacienteId,
        nombreCompleto: 'Juan Pérez',
        dependenciaId: testDependenciaId,
        doctorId: testDoctorId,
        esReconsulta: false,
        createdAt: now,
        updatedAt: now,
      );

      final saveResult = await patientRepository.savePatient(patient);
      final loadedResult = await patientRepository.getPatients(testDependenciaId);

      expect(saveResult.isRight(), true);
      expect(loadedResult.isRight(), true);

      final patients = loadedResult.getOrElse(() => []);
      expect(patients.length, 1);
      expect(patients.first.id, testPacienteId);
      expect(patients.first.nombreCompleto, 'Juan Pérez');
      expect(patients.first.esReconsulta, false);
    });

    test('searchByName returns matching patients', () async {
      final patient = PatientEntity(
        id: testPacienteId,
        nombreCompleto: 'María García',
        dependenciaId: testDependenciaId,
        doctorId: testDoctorId,
        esReconsulta: false,
        createdAt: now,
        updatedAt: now,
      );

      await patientRepository.savePatient(patient);
      final result = await patientRepository.searchByName('María', testDependenciaId);
      final resultNoMatch = await patientRepository.searchByName('Pedro', testDependenciaId);

      expect(result.isRight(), true);
      expect(resultNoMatch.isRight(), true);
      expect(result.getOrElse(() => []).length, 1);
      expect(resultNoMatch.getOrElse(() => []).length, 0);
    });

    test('getPatientById returns the patient', () async {
      final patient = PatientEntity(
        id: testPacienteId,
        nombreCompleto: 'Carlos López',
        dependenciaId: testDependenciaId,
        doctorId: testDoctorId,
        esReconsulta: true,
        createdAt: now,
        updatedAt: now,
      );

      await patientRepository.savePatient(patient);
      final found = await patientRepository.getPatientById(testPacienteId);
      final notFound = await patientRepository.getPatientById('non-existent');

      expect(found.isRight(), true);
      expect(found.getOrElse(() => patient).nombreCompleto, 'Carlos López');
      expect(found.getOrElse(() => patient).esReconsulta, true);
      expect(notFound.isLeft(), true);
    });
  });

  group('DOM-S3-19: HistoriaRepository (integración BD real)', () {
    test('saveHistoria → getHistoriasByPaciente → read back', () async {
      final historia = HistoriaClinicaEntity(
        id: const Uuid().v4(),
        pacienteId: testPacienteId,
        campanaId: null,
        diagnosticoTexto: 'Miopía leve',
        imagenUrl: null,
        latitud: 19.4326,
        longitud: -99.1332,
        fechaAtencion: now,
        doctorId: testDoctorId,
        historiaAnteriorId: null,
        sincronizado: false,
        createdAt: now,
      );

      final saveResult = await historiaRepository.saveHistoria(historia);
      final loadedResult = await historiaRepository.getHistoriasByPaciente(testPacienteId);

      expect(saveResult.isRight(), true);
      expect(loadedResult.isRight(), true);

      final historias = loadedResult.getOrElse(() => []);
      expect(historias.length, 1);
      expect(historias.first.diagnosticoTexto, 'Miopía leve');
      expect(historias.first.latitud, 19.4326);
    });

    test('getHistoriaAnterior returns null when no previous historia', () async {
      final result = await historiaRepository.getHistoriaAnterior(
        testPacienteId,
        testCampanaId,
      );
      expect(result.isRight(), true);
      expect(result.getOrElse(() => null), isNull);
    });

    test('getHistoriaAnterior returns the last historia for the campaign', () async {
      final historiaAnterior = HistoriaClinicaEntity(
        id: const Uuid().v4(),
        pacienteId: testPacienteId,
        campanaId: testCampanaId,
        diagnosticoTexto: 'Diagnóstico 2024',
        imagenUrl: null,
        latitud: 19.43,
        longitud: -99.13,
        fechaAtencion: now.subtract(const Duration(days: 365)),
        doctorId: testDoctorId,
        historiaAnteriorId: null,
        sincronizado: true,
        createdAt: now.subtract(const Duration(days: 365)),
      );

      final historiaReciente = HistoriaClinicaEntity(
        id: const Uuid().v4(),
        pacienteId: testPacienteId,
        campanaId: testCampanaId,
        diagnosticoTexto: 'Diagnóstico 2025',
        imagenUrl: null,
        latitud: 19.43,
        longitud: -99.13,
        fechaAtencion: now,
        doctorId: testDoctorId,
        historiaAnteriorId: null,
        sincronizado: true,
        createdAt: now,
      );

      await historiaRepository.saveHistoria(historiaAnterior);
      await historiaRepository.saveHistoria(historiaReciente);

      final result = await historiaRepository.getHistoriaAnterior(
        testPacienteId,
        testCampanaId,
      );

      expect(result.isRight(), true);
      expect(result.getOrElse(() => null), isNotNull);
      expect(result.getOrElse(() => historiaAnterior)!.diagnosticoTexto,
          'Diagnóstico 2025');
    });
  });
}
