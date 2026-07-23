import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/book_model.dart';
import '../services/pdf_service.dart';
import 'page_range_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PdfService _pdfService = PdfService();
  bool _loading = false;

  Future<void> _pickPdf() async {
    // Android 13+ / iOS uchun fayllarga ruxsat so'rash
    await Permission.storage.request();

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.single.path == null) return;

    setState(() => _loading = true);
    try {
      final path = result.files.single.path!;
      final pageCount = await _pdfService.getPageCount(path);

      final book = BookModel(
        fileName: result.files.single.name,
        filePath: path,
        totalPages: pageCount,
        startPage: 1,
        endPage: pageCount,
      );

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PageRangeScreen(book: book)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF ochishda xatolik: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'PDF AudioBook',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E1B4B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'PDF kitobingizni ovozli kitobga aylantiring',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Center(
                child: Icon(
                  Icons.headphones_rounded,
                  size: 120,
                  color: const Color(0xFF6C5CE7).withOpacity(0.15),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 58,
                child: ElevatedButton.icon(
                  onPressed: _loading ? null : _pickPdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  icon: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.upload_file_rounded, color: Colors.white),
                  label: Text(
                    _loading ? 'Yuklanmoqda...' : 'PDF faylni tanlash',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
