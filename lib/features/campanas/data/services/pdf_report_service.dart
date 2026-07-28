import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PdfReportService {
  final SupabaseClient _supabaseClient;

  PdfReportService(this._supabaseClient);

  Future<void> generateAndShare(String campanaId) async {
    final pdfBytes = await _buildPdf(campanaId);
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'reporte_campana.pdf',
    );
  }

  Future<Uint8List> _buildPdf(String campanaId) async {
    final campana = await _supabaseClient
        .from('campanas')
        .select()
        .eq('id', campanaId)
        .single();

    final historias = await _supabaseClient
        .from('historias_clinicas')
        .select('paciente_id, diagnostico_texto, doctor_id')
        .eq('campana_id', campanaId);

    final pacienteIds = historias
        .map((h) => h['paciente_id'] as String)
        .toSet()
        .toList();
    final pacientesData = await _supabaseClient
        .from('pacientes')
        .select('id, nombre_completo')
        .inFilter('id', pacienteIds);
    final pacienteMap = {
      for (final p in pacientesData)
        p['id'] as String: p['nombre_completo'] as String
    };

    final doctorIds = historias
        .map((h) => h['doctor_id'] as String)
        .toSet()
        .toList();
    final doctoresData = await _supabaseClient
        .from('doctores')
        .select('id, nombre')
        .inFilter('id', doctorIds);
    final doctorMap = {
      for (final d in doctoresData) d['id'] as String: d['nombre'] as String
    };

    pw.MemoryImage? logoImage;
    try {
      final logoResponse = await http.get(
        Uri.parse(
          'https://lyepgpxldaskfhtqzerz.supabase.co/storage/v1/object/public/logos/OptiFlow.jpeg',
        ),
      );
      if (logoResponse.statusCode == 200) {
        logoImage = pw.MemoryImage(logoResponse.bodyBytes);
      }
    } catch (e) {
      debugPrint('[PdfReportService] Error descargando logo: $e');
    }

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _buildHeader(logoImage, campana),
          pw.SizedBox(height: 24),
          _buildTable(historias, pacienteMap, doctorMap),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(
    pw.MemoryImage? logoImage,
    Map<String, dynamic> campana,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        if (logoImage != null) pw.Image(logoImage, height: 60),
        pw.SizedBox(height: 16),
        pw.Text(
          'Reporte de Campaña',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _infoRow('Empresa', campana['nombre_empresa']),
                pw.SizedBox(height: 4),
                _infoRow('Campaña', campana['nombre_empresa']),
                pw.SizedBox(height: 4),
                _infoRow('Lugar', campana['lugar']),
              ],
            ),
          ],
        ),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _infoRow(String label, dynamic value) {
    return pw.Row(
      children: [
        pw.Text(
          '$label: ',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(value?.toString() ?? ''),
      ],
    );
  }

  pw.Widget _buildTable(
    List<dynamic> historias,
    Map<String, String> pacienteMap,
    Map<String, String> doctorMap,
  ) {
    if (historias.isEmpty) {
      return pw.Text('No hay datos de atención para esta campaña.');
    }

    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _headerCell('Paciente'),
            _headerCell('Diagnóstico'),
            _headerCell('Doctor'),
          ],
        ),
        ...historias.map((h) {
          final pacienteId = h['paciente_id'] as String;
          final doctorId = h['doctor_id'] as String;
          return pw.TableRow(
            children: [
              _dataCell(pacienteMap[pacienteId] ?? 'Desconocido'),
              _dataCell(
                h['diagnostico_texto'] as String? ?? 'Sin diagnóstico',
              ),
              _dataCell(doctorMap[doctorId] ?? 'Desconocido'),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  pw.Widget _dataCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 10)),
    );
  }
}
