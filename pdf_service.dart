import 'dart:io';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'ocr_service.dart';

/// PDF fayllar bilan ishlash: sahifalar sonini aniqlash, matn ajratib olish,
/// va agar PDF skanerlangan (rasmli) bo'lsa — OCR orqali matnga aylantirish.
class PdfService {
  final OcrService _ocrService = OcrService();

  /// PDF fayldagi umumiy sahifalar sonini qaytaradi
  Future<int> getPageCount(String filePath) async {
    final bytes = await File(filePath).readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final int count = document.pages.count;
    document.dispose();
    return count;
  }

  /// Berilgan sahifalar oralig'idan (startPage-endPage, 1-based) matnni ajratib oladi.
  /// Agar oddiy usulda matn topilmasa (skanerlangan sahifa), avtomatik OCR ishga tushadi.
  ///
  /// [onProgress] — har bir sahifa qayta ishlanganda chaqiriladi (progress bar uchun)
  Future<String> extractText({
    required String filePath,
    required int startPage,
    required int endPage,
    void Function(int current, int total)? onProgress,
  }) async {
    final bytes = await File(filePath).readAsBytes();
    final PdfDocument document = PdfDocument(inputBytes: bytes);
    final PdfTextExtractor extractor = PdfTextExtractor(document);

    final int total = endPage - startPage + 1;
    final StringBuffer buffer = StringBuffer();

    // pdfx orqali sahifalarni tasvir sifatida ochish uchun (faqat kerak bo'lganda)
    pdfx.PdfDocument? renderDoc;

    for (int i = startPage; i <= endPage; i++) {
      onProgress?.call(i - startPage + 1, total);

      String pageText = '';
      try {
        // Sahifa indeksi Syncfusion'da 0-based
        pageText = extractor.extractText(startPageIndex: i - 1, endPageIndex: i - 1).trim();
      } catch (_) {
        pageText = '';
      }

      // Agar matn juda kam yoki bo'sh bo'lsa — bu sahifa skanerlangan (rasm) deb hisoblanadi
      if (pageText.length < 15) {
        renderDoc ??= await pdfx.PdfDocument.openFile(filePath);
        final ocrText = await _ocrPage(renderDoc, i);
        pageText = ocrText;
      }

      buffer.writeln(pageText);
      buffer.writeln(); // sahifalar orasida bo'sh qator
    }

    await renderDoc?.close();
    document.dispose();

    return buffer.toString().trim();
  }

  /// Bitta sahifani rasmga aylantirib, OCR orqali matn chiqaradi
  Future<String> _ocrPage(pdfx.PdfDocument renderDoc, int pageNumber) async {
    final page = await renderDoc.getPage(pageNumber);
    final pageImage = await page.render(
      width: page.width * 2,   // aniqlik uchun 2x kattalashtirish
      height: page.height * 2,
      format: pdfx.PdfPageImageFormat.png,
    );
    await page.close();

    if (pageImage == null) return '';

    final Uint8List bytes = pageImage.bytes;
    final text = await _ocrService.recognizeTextFromBytes(bytes);
    return text;
  }
}
