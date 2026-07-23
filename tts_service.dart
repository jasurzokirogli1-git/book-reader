import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';

enum TtsState { playing, paused, stopped }

/// Matnni ovozli o'qish xizmati. flutter_tts kutubxonasi asosida.
/// - Tezlikni boshqarish (0.5x - 2x)
/// - Tilni tanlash (uz-UZ va boshqalar)
/// - Play / Pause / Stop / Skip (paragraf bo'yicha oldinga-orqaga)
/// - Fon rejimida ishlash (Android foreground service, iOS background audio)
class TtsService extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();

  TtsState state = TtsState.stopped;
  String _fullText = '';
  List<String> _chunks = []; // matn paragraflarga bo'lingan holda
  int _currentChunkIndex = 0;
  double _rate = 0.5; // flutter_tts uchun 0.0-1.0 oralig'i (o'rtacha tezlik)
  String _language = 'uz-UZ';

  double get progress => _chunks.isEmpty ? 0 : _currentChunkIndex / _chunks.length;
  int get currentChunk => _currentChunkIndex;
  int get totalChunks => _chunks.length;
  String get language => _language;

  TtsService() {
    _init();
  }

  Future<void> _init() async {
    // Fon rejimida ishlashi uchun (Android'da IOS_BACKGROUND / foreground service)
    await _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(() {
      state = TtsState.playing;
      notifyListeners();
    });

    _tts.setCompletionHandler(() {
      _playNextChunk();
    });

    _tts.setCancelHandler(() {
      state = TtsState.stopped;
      notifyListeners();
    });

    _tts.setPauseHandler(() {
      state = TtsState.paused;
      notifyListeners();
    });

    _tts.setErrorHandler((msg) {
      debugPrint('TTS xatolik: $msg');
    });
  }

  /// Mavjud tillar ro'yxatini tekshirish (ixtiyoriy diagnostika uchun)
  Future<List<dynamic>> getAvailableLanguages() => _tts.getLanguages;

  /// Matnni yuklash: uni paragraflarga (chunk) bo'lib beradi, shunda
  /// "keyingisi/oldingisi" tugmalari paragraf bo'yicha o'tkazadi.
  void loadText(String text) {
    _fullText = text;
    _chunks = _splitIntoChunks(text);
    _currentChunkIndex = 0;
  }

  List<String> _splitIntoChunks(String text) {
    // Matnni gap/abzats chegaralari bo'yicha, ~250 belgigacha bo'laklarga bo'lish
    final rawParagraphs = text
        .split(RegExp(r'\n+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final List<String> chunks = [];
    for (final p in rawParagraphs) {
      if (p.length <= 300) {
        chunks.add(p);
      } else {
        // Uzun paragrafni gaplar bo'yicha bo'lib chiqamiz
        final sentences = p.split(RegExp(r'(?<=[.!?])\s+'));
        String buffer = '';
        for (final s in sentences) {
          if ((buffer + s).length > 300) {
            if (buffer.isNotEmpty) chunks.add(buffer.trim());
            buffer = s;
          } else {
            buffer += ' $s';
          }
        }
        if (buffer.trim().isNotEmpty) chunks.add(buffer.trim());
      }
    }
    return chunks.isEmpty ? [text] : chunks;
  }

  Future<void> setLanguage(String langCode) async {
    _language = langCode;
    await _tts.setLanguage(langCode);
    notifyListeners();
  }

  /// speedMultiplier: 0.5, 1.0, 1.5, 2.0 kabi qiymatlar
  Future<void> setSpeed(double speedMultiplier) async {
    // flutter_tts rate 0.0–1.0 oralig'ida, shu sababli nisbatan o'lchaymiz
    _rate = (0.5 * speedMultiplier).clamp(0.1, 1.0);
    await _tts.setSpeechRate(_rate);
    notifyListeners();
  }

  Future<void> play() async {
    if (_chunks.isEmpty) return;
    await _tts.setLanguage(_language);
    await _tts.setSpeechRate(_rate);
    await _speakCurrentChunk();
  }

  Future<void> _speakCurrentChunk() async {
    if (_currentChunkIndex >= _chunks.length) {
      state = TtsState.stopped;
      notifyListeners();
      return;
    }
    await _tts.speak(_chunks[_currentChunkIndex]);
  }

  Future<void> _playNextChunk() async {
    if (_currentChunkIndex < _chunks.length - 1) {
      _currentChunkIndex++;
      notifyListeners();
      await _speakCurrentChunk();
    } else {
      state = TtsState.stopped;
      notifyListeners();
    }
  }

  Future<void> pause() async {
    await _tts.pause();
    state = TtsState.paused;
    notifyListeners();
  }

  Future<void> resume() async {
    // flutter_tts'da haqiqiy "resume" yo'q — hozirgi chunk'dan qayta boshlaymiz
    await _speakCurrentChunk();
  }

  Future<void> stop() async {
    await _tts.stop();
    _currentChunkIndex = 0;
    state = TtsState.stopped;
    notifyListeners();
  }

  /// Keyingi paragrafga o'tish
  Future<void> skipForward() async {
    await _tts.stop();
    if (_currentChunkIndex < _chunks.length - 1) {
      _currentChunkIndex++;
    }
    notifyListeners();
    await _speakCurrentChunk();
  }

  /// Oldingi paragrafga qaytish
  Future<void> skipBackward() async {
    await _tts.stop();
    if (_currentChunkIndex > 0) {
      _currentChunkIndex--;
    }
    notifyListeners();
    await _speakCurrentChunk();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }
}
