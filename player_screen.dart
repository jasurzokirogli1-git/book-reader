import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/book_model.dart';
import '../services/tts_service.dart';

class PlayerScreen extends StatefulWidget {
  final BookModel book;
  const PlayerScreen({super.key, required this.book});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late TtsService _tts;
  ReadingSpeed _speed = ReadingSpeed.x1;
  String _language = 'uz-UZ';

  @override
  void initState() {
    super.initState();
    _tts = TtsService();
    _tts.loadText(widget.book.extractedText);
    _tts.setLanguage(_language);
    _tts.setSpeed(_speed.value);
  }

  @override
  void dispose() {
    _tts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _tts,
      child: Scaffold(
        backgroundColor: const Color(0xFF1E1B4B),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            widget.book.fileName,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
          ),
        ),
        body: Consumer<TtsService>(
          builder: (context, tts, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.06),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          size: 90,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    '${widget.book.startPage}-${widget.book.endPage}-sahifalar',
                    style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: tts.progress,
                    backgroundColor: Colors.white12,
                    color: const Color(0xFF6C5CE7),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bo\'lak: ${tts.currentChunk + 1} / ${tts.totalChunks}',
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 28),

                  // --- Tezlik va til tanlash ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _dropdownSpeed(tts),
                      _dropdownLanguage(tts),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // --- Play / Pause / Skip tugmalari ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _controlButton(
                        icon: Icons.replay_10_rounded,
                        onTap: tts.skipBackward,
                        size: 32,
                      ),
                      _playPauseButton(tts),
                      _controlButton(
                        icon: Icons.forward_10_rounded,
                        onTap: tts.skipForward,
                        size: 32,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _playPauseButton(TtsService tts) {
    final isPlaying = tts.state == TtsState.playing;
    return GestureDetector(
      onTap: () {
        if (isPlaying) {
          tts.pause();
        } else if (tts.state == TtsState.paused) {
          tts.resume();
        } else {
          tts.play();
        }
      },
      child: Container(
        width: 76,
        height: 76,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF6C5CE7),
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required VoidCallback onTap,
    required double size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white70, size: size),
    );
  }

  Widget _dropdownSpeed(TtsService tts) {
    return DropdownButton<ReadingSpeed>(
      value: _speed,
      dropdownColor: const Color(0xFF2A2760),
      underline: const SizedBox(),
      icon: const Icon(Icons.speed_rounded, color: Colors.white54),
      style: GoogleFonts.inter(color: Colors.white),
      items: ReadingSpeed.values
          .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _speed = value);
        tts.setSpeed(value.value);
      },
    );
  }

  Widget _dropdownLanguage(TtsService tts) {
    return DropdownButton<String>(
      value: _language,
      dropdownColor: const Color(0xFF2A2760),
      underline: const SizedBox(),
      icon: const Icon(Icons.language_rounded, color: Colors.white54),
      style: GoogleFonts.inter(color: Colors.white),
      items: TtsLanguage.supported
          .map((l) => DropdownMenuItem(value: l.code, child: Text(l.label)))
          .toList(),
      onChanged: (value) {
        if (value == null) return;
        setState(() => _language = value);
        tts.setLanguage(value);
      },
    );
  }
}
