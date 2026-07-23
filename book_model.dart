/// PDF fayldan yaratilgan "audiokitob" haqidagi barcha ma'lumotlarni saqlaydigan model.
class BookModel {
  final String fileName;
  final String filePath;
  final int totalPages;
  int startPage;
  int endPage;
  String extractedText;
  bool isScanned; // true bo'lsa — OCR orqali o'qilgan (rasmli PDF)

  BookModel({
    required this.fileName,
    required this.filePath,
    required this.totalPages,
    this.startPage = 1,
    this.endPage = 1,
    this.extractedText = '',
    this.isScanned = false,
  });
}

/// TTS uchun tanlanadigan o'qish tezliklari
enum ReadingSpeed {
  x05(0.5, '0.5x'),
  x1(1.0, '1x'),
  x15(1.5, '1.5x'),
  x2(2.0, '2x');

  final double value;
  final String label;
  const ReadingSpeed(this.value, this.label);
}

/// Qo'llab-quvvatlanadigan tillar (TTS uchun til kodlari)
class TtsLanguage {
  final String code; // masalan: "uz-UZ"
  final String label; // masalan: "O'zbekcha"

  const TtsLanguage(this.code, this.label);

  static const List<TtsLanguage> supported = [
    TtsLanguage('uz-UZ', "O'zbekcha"),
    TtsLanguage('ru-RU', 'Русский'),
    TtsLanguage('en-US', 'English'),
    TtsLanguage('tr-TR', 'Türkçe'),
  ];
}
