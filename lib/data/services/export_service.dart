import 'dart:typed_data';
import 'package:injectable/injectable.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:screenshot/screenshot.dart';

@lazySingleton
class ExportService {
  final ScreenshotController screenshotController = ScreenshotController();

  Future<void> exportToPng(String boardName) async {
    final Uint8List? image = await screenshotController.capture();
    if (image == null) return;

    // We use Printing to handle the platform-specific "Save/Share" dialog
    // It works well across iOS and Android for both images and PDFs.
    await Printing.sharePdf(
      bytes: image,
      filename: '$boardName.png',
    );
  }

  Future<void> exportToPdf(String boardName) async {
    final Uint8List? image = await screenshotController.capture();
    if (image == null) return;

    final pdf = pw.Document();
    final pdfImage = pw.MemoryImage(image);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: '$boardName.pdf',
    );
  }
}
