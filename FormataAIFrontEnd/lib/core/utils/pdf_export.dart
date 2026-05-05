import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Gera os bytes do PDF ABNT e salva em arquivo temporário.
Future<File> _gerarArquivoPdfAbnt({
  required String conteudo,
  required String titulo,
}) async {
  final doc = pw.Document();

  // ABNT: A4, margens 3cm esq/sup, 2cm dir/inf
  const pageFormat = PdfPageFormat.a4;
  const marginLeft = 3.0 * PdfPageFormat.cm;
  const marginTop = 3.0 * PdfPageFormat.cm;
  const marginRight = 2.0 * PdfPageFormat.cm;
  const marginBottom = 2.0 * PdfPageFormat.cm;

  // Fontes
  final fontNormal = pw.Font.times();
  final fontBold = pw.Font.timesBold();
  final fontItalic = pw.Font.timesItalic();

  const double fontSize = 12;
  const double lineSpacing = 1.5;

  // Data formatada para a capa
  final now = DateTime.now();
  const meses = [
    'janeiro',
    'fevereiro',
    'março',
    'abril',
    'maio',
    'junho',
    'julho',
    'agosto',
    'setembro',
    'outubro',
    'novembro',
    'dezembro',
  ];
  final dataFormatada =
      '${now.day.toString().padLeft(2, '0')} de ${meses[now.month - 1]} de ${now.year}';

  // ── Capa ABNT ─────────────────────────────────────────────────────────────
  doc.addPage(
    pw.Page(
      pageFormat: pageFormat,
      margin: pw.EdgeInsets.fromLTRB(
        marginLeft,
        marginTop,
        marginRight,
        marginBottom,
      ),
      build: (ctx) => pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Instituição (topo)
          pw.Text(
            'FormataAI',
            style: pw.TextStyle(font: fontBold, fontSize: 14),
            textAlign: pw.TextAlign.center,
          ),

          // Título (centro)
          pw.Column(
            children: [
              pw.Text(
                titulo.toUpperCase(),
                style: pw.TextStyle(font: fontBold, fontSize: 14),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),

          // Local e data (rodapé da capa)
          pw.Column(
            children: [
              pw.Text(
                'Brasil',
                style: pw.TextStyle(font: fontNormal, fontSize: fontSize),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                dataFormatada,
                style: pw.TextStyle(font: fontNormal, fontSize: fontSize),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    ),
  );

  // ── Corpo do documento ────────────────────────────────────────────────────
  // Divide o conteúdo em parágrafos e seções
  final linhas = conteudo.split('\n');

  doc.addPage(
    pw.MultiPage(
      pageFormat: pageFormat,
      margin: pw.EdgeInsets.fromLTRB(
        marginLeft,
        marginTop,
        marginRight,
        marginBottom,
      ),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          '${ctx.pageNumber}',
          style: pw.TextStyle(
            font: fontNormal,
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
      ),
      build: (ctx) {
        final widgets = <pw.Widget>[];

        for (final linha in linhas) {
          final trimmed = linha.trim();
          if (trimmed.isEmpty) {
            widgets.add(pw.SizedBox(height: fontSize * lineSpacing));
            continue;
          }

          // Detecta título de seção (linha curta, sem ponto no final, tudo maiúsculo ou começa com número)
          final isSecao = _isTituloSecao(trimmed);

          if (isSecao) {
            widgets.add(pw.SizedBox(height: 12));
            widgets.add(
              pw.Text(
                trimmed.toUpperCase(),
                style: pw.TextStyle(font: fontBold, fontSize: fontSize),
              ),
            );
            widgets.add(pw.SizedBox(height: 6));
          } else {
            // Parágrafo normal: recuo de 1,25cm na primeira linha
            widgets.add(
              pw.Padding(
                padding: const pw.EdgeInsets.only(
                  left: 1.25 * PdfPageFormat.cm,
                ),
                child: pw.Text(
                  trimmed,
                  style: pw.TextStyle(font: fontNormal, fontSize: fontSize),
                  textAlign: pw.TextAlign.justify,
                  softWrap: true,
                ),
              ),
            );
            widgets.add(pw.SizedBox(height: fontSize * (lineSpacing - 1)));
          }
        }

        return widgets;
      },
    ),
  );

  final bytes = await doc.save();
  final dir = await getTemporaryDirectory();
  final fileName = titulo
      .replaceAll(RegExp(r'[^\w\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '_')
      .toLowerCase();
  final file = File('${dir.path}/$fileName.pdf');
  await file.writeAsBytes(bytes);
  return file;
}

/// Salva o PDF no armazenamento externo do app (visível no gerenciador de arquivos).
/// Retorna o caminho do arquivo salvo para exibir ao usuário.
Future<String> baixarPdfAbnt({
  required String conteudo,
  required String titulo,
}) async {
  final tempFile = await _gerarArquivoPdfAbnt(
    conteudo: conteudo,
    titulo: titulo,
  );

  // Tenta salvar no armazenamento externo do app (sem permissão extra necessária)
  final externalDir = await getExternalStorageDirectory();
  final destDir = externalDir ?? await getApplicationDocumentsDirectory();

  final fileName = titulo
      .replaceAll(RegExp(r'[^\w\s-]'), '')
      .replaceAll(RegExp(r'\s+'), '_')
      .toLowerCase();
  final destFile = File('${destDir.path}/$fileName.pdf');
  await tempFile.copy(destFile.path);
  return destFile.path;
}

/// Compartilha o PDF via share sheet nativo.
Future<void> compartilharPdfAbnt({
  required String conteudo,
  required String titulo,
}) async {
  final file = await _gerarArquivoPdfAbnt(conteudo: conteudo, titulo: titulo);
  await SharePlus.instance.share(
    ShareParams(files: [XFile(file.path)], subject: titulo),
  );
}

bool _isTituloSecao(String texto) {
  if (texto.length > 80) return false;
  if (!texto.endsWith('.') && !texto.endsWith(',') && !texto.endsWith(';')) {
    // Linha curta sem pontuação de encerramento — provavelmente título
    final palavras = texto.split(' ').length;
    if (palavras <= 8) return true;
  }
  // Ou começa com número seguido de ponto/espaço (ex: "1. Introdução")
  if (RegExp(r'^\d+[\.\s]').hasMatch(texto)) return true;
  return false;
}

/// Versão simples para outros formatos (mantida para compatibilidade).
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
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
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
  final fileName = titulo
      .replaceAll(RegExp(r'[^\w\s-]'), '')
      .replaceAll(' ', '_');
  final file = File('${dir.path}/$fileName.pdf');
  await file.writeAsBytes(bytes);

  await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
}
