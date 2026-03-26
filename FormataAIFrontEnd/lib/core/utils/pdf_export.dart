import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Gera PDF a partir de texto e abre o compartilhamento nativo.
Future<void> exportarParaPdf({
  required String conteudo,
  String titulo = 'Documento FormataAI',
}) async {
  final doc = pw.Document();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      header: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titulo,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Divider(thickness: 0.5),
          pw.SizedBox(height: 12),
        ],
      ),
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'FormataAI',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
        ],
      ),
      build: (context) => [
        pw.Text(
          conteudo,
          style: const pw.TextStyle(fontSize: 12, lineSpacing: 4),
        ),
      ],
    ),
  );

  final bytes = await doc.save();
  final dir = await getTemporaryDirectory();
  final fileName = titulo.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_');
  final file = File('${dir.path}/$fileName.pdf');
  await file.writeAsBytes(bytes);

  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)]),
  );
}
