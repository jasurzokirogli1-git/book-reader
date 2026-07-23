import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/book_model.dart';
import '../services/pdf_service.dart';
import 'player_screen.dart';

class PageRangeScreen extends StatefulWidget {
  final BookModel book;
  const PageRangeScreen({super.key, required this.book});

  @override
  State<PageRangeScreen> createState() => _PageRangeScreenState();
}

class _PageRangeScreenState extends State<PageRangeScreen> {
  final PdfService _pdfService = PdfService();
  late RangeValues _range;
  bool _extracting = false;
  int _current = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _range = RangeValues(
      widget.book.startPage.toDouble(),
      widget.book.endPage.toDouble(),
    );
  }

  Future<void> _extractAndContinue() async {
    setState(() => _extracting = true);

    final startPage = _range.start.round();
    final endPage = _range.end.round();

    final text = await _pdfService.extractText(
      filePath: widget.book.filePath,
      startPage: startPage,
      endPage: endPage,
      onProgress: (cur, tot) {
        setState(() {
          _current = cur;
          _total = tot;
        });
      },
    );

    widget.book
      ..startPage = startPage
      ..endPage = endPage
      ..extractedText = text;

    setState(() => _extracting = false);

    if (!mounted) return;
    if (text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Matn topilmadi. Boshqa fayl tanlang.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlayerScreen(book: widget.book)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.book.fileName,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      body: _extracting
          ? _buildProgress()
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sahifalar oralig'ini tanlang",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Jami: ${widget.book.totalPages} sahifa',
                    style: GoogleFonts.inter(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _pageBadge('Boshlanish', _range.start.round()),
                            _pageBadge('Tugash', _range.end.round()),
                          ],
                        ),
                        RangeSlider(
                          values: _range,
                          min: 1,
                          max: widget.book.totalPages.toDouble(),
                          divisions: widget.book.totalPages > 1
                              ? widget.book.totalPages - 1
                              : 1,
                          activeColor: const Color(0xFF6C5CE7),
                          labels: RangeLabels(
                            _range.start.round().toString(),
                            _range.end.round().toString(),
                          ),
                          onChanged: (values) {
                            setState(() => _range = values);
                          },
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      onPressed: _extractAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C5CE7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        'Matnni ajratish va davom etish',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _pageBadge(String label, int page) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(color: Colors.grey[500], fontSize: 12)),
        Text(
          '$page',
          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    final progress = _total == 0 ? 0.0 : _current / _total;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              value: progress,
              color: const Color(0xFF6C5CE7),
            ),
            const SizedBox(height: 20),
            Text(
              'Matn ajratilmoqda: $_current / $_total sahifa\n(agar rasmli PDF bo\'lsa, OCR biroz vaqt oladi)',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
