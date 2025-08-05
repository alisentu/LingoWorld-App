// lib/screens/pdf_vocabulary_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';

class PdfVocabularyScreen extends StatefulWidget {
  final String targetLanguage;

  const PdfVocabularyScreen({super.key, required this.targetLanguage});

  @override
  State<PdfVocabularyScreen> createState() => _PdfVocabularyScreenState();
}

class _PdfVocabularyScreenState extends State<PdfVocabularyScreen> {
  late final GenerativeModel _model;
  bool _isLoading = true;
  String _errorMessage = '';
  String? _pdfFilePath;

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: dotenv.env['GEMINI_API_KEY']!,
    );
    _checkExistingPdf();
  }

  Future<void> _checkExistingPdf() async {
    final directory = await getTemporaryDirectory();
    final fileName =
        '${widget.targetLanguage.toLowerCase()}_kelime_listesi.pdf';
    final file = File('${directory.path}/$fileName');

    if (await file.exists()) {
      setState(() {
        _isLoading = false;
        _pdfFilePath = file.path;
      });
    } else {
      _generateAndSavePdf();
    }
  }

  Future<void> _generateAndSavePdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final prompt = """
    You are a language learning assistant. Your task is to generate a list of exactly 8 common vocabulary words for a beginner in the ${widget.targetLanguage} language. Each entry must have four keys: "word", "meaning", "sentence", and "translation".
    
    Format your entire response strictly as a JSON list of objects, without any additional text or explanation before or after.
    
    Example:
    [
      {
        "word": "word1",
        "meaning": "çeviri1",
        "sentence": "sentence1",
        "translation": "çeviri1"
      },
      {
        "word": "word2",
        "meaning": "çeviri2",
        "sentence": "sentence2",
        "translation": "çeviri2"
      }
    ]
    
    Generate only the list. The list must contain exactly 25 items.
    """;

      final response = await _model.generateContent([Content.text(prompt)]);
      final aiResponse = response.text;

      if (aiResponse == null || aiResponse.isEmpty) {
        _setErrorMessage('Yapay zekadan yanıt alınamadı.');
        return;
      }

      String cleanedResponse = aiResponse;
      final jsonStartIndex = aiResponse.indexOf('[');
      final jsonEndIndex = aiResponse.lastIndexOf(']');

      if (jsonStartIndex != -1 && jsonEndIndex != -1) {
        cleanedResponse = aiResponse.substring(
          jsonStartIndex,
          jsonEndIndex + 1,
        );
      } else {
        _setErrorMessage(
          'Yapay zeka yanıtı geçerli bir JSON listesi içermiyor.',
        );
        return;
      }

      final jsonResponse = jsonDecode(cleanedResponse);
      final vocabularyList = List<Map<String, String>>.from(
        jsonResponse.map(
          (item) => {
            "word": item["word"] as String,
            "meaning": item["meaning"] as String,
            "sentence": item["sentence"] as String,
            "translation": item["translation"] as String,
          },
        ),
      );

      final pdf = pw.Document();
      final fontData = await rootBundle.load(
        "assets/fonts/NotoSans-VariableFont_wdth,wght.ttf",
      );
      final ttf = pw.Font.ttf(fontData);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '${widget.targetLanguage} - Türkçe Kelime Listesi',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    font: ttf,
                  ),
                ),
                pw.SizedBox(height: 20),
                ...vocabularyList.map((item) {
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Kelime: ${item["word"]!}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          font: ttf,
                        ),
                      ),
                      pw.Text(
                        'Türkçesi: ${item["meaning"]!}',
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.Text(
                        'Örnek Cümle: ${item["sentence"]!}',
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.Text(
                        'Cümle Çevirisi: ${item["translation"]!}',
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.SizedBox(height: 10),
                    ],
                  );
                }),
              ],
            );
          },
        ),
      );

      final directory = await getTemporaryDirectory();
      final fileName =
          '${widget.targetLanguage.toLowerCase()}_kelime_listesi.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      setState(() {
        _isLoading = false;
        _pdfFilePath = file.path;
      });
    } catch (e) {
      _setErrorMessage('Bir hata oluştu: $e');
    }
  }

  Future<void> _openPdf() async {
    if (_pdfFilePath != null) {
      await OpenFilex.open(_pdfFilePath!);
    }
  }

  void _setErrorMessage(String message) {
    setState(() {
      _isLoading = false;
      _errorMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.targetLanguage} Kelime Listesi',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child:
            _isLoading
                ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      'Kelime listesi oluşturuluyor...',
                      style: GoogleFonts.montserrat(),
                    ),
                  ],
                )
                : _errorMessage.isNotEmpty
                ? Text(
                  _errorMessage,
                  style: GoogleFonts.montserrat(color: Colors.red),
                  textAlign: TextAlign.center,
                )
                : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Kelime listesi hazır!',
                      style: GoogleFonts.montserrat(fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _openPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text('PDF\'i Aç', style: GoogleFonts.montserrat()),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
      ),
    );
  }
}
