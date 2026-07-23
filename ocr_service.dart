import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

/// Skanerlangan (rasmli) PDF sahifalaridan matn tanib olish (OCR).
/// Google ML Kit - qurilma ichida (offline) ishlaydi, internet talab qilmaydi.
class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Rasm baytlaridan (PNG/JPEG) matnni tanib oladi
  Future<String> recognizeTextFromBytes(Uint8List bytes) async {
    // ML Kit vaqtinchalik faylga yozishni talab qiladi
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      '${tempDir.path}/ocr_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await tempFile.writeAsBytes(bytes);

    try {
      final inputImage = InputImage.fromFile(tempFile);
      final RecognizedText result = await _recognizer.processImage(inputImage);
      return result.text;
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  void dispose() {
    _recognizer.close();
  }
}

/// ESLATMA: O'zbek tilidagi lotin/kirill matnlar uchun ML Kit'ning "latin" skripti
/// asosan yetarli (o'zbek lotin alifbosi lotin harflariga asoslangan). Agar kirill
/// alifbosidagi PDF'lar bilan ishlash kerak bo'lsa, TextRecognitionScript.latin
/// o'rniga qo'shimcha til paketini ulash tavsiya etiladi.
