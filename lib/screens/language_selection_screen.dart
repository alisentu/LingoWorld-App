// lib/screens/language_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lingoworld/services/gemini_service.dart';
import 'package:lingoworld/services/language_manager.dart';
import 'package:lingoworld/screens/home_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String? _selectedLanguageEnglishName;
  late Box _settingsBox;
  late GeminiService _geminiService;
  bool _isLoadingWords = false;

  final Map<String, String> _languageEnglishToCode = {
    'English': 'en',
    'German': 'de',
    'French': 'fr',
    'Spanish': 'es',
    'Italian': 'it',
    'Japanese': 'ja',
    'Chinese': 'zh',
    'Korean': 'ko',
    'Russian': 'ru',
  };

  final List<String> _availableLanguageEnglishNames = [
    'English',
    'German',
    'French',
    'Spanish',
    'Italian',
    'Japanese',
    'Chinese',
    'Korean',
    'Russian',
  ];

  final Map<String, String> _languageDisplayNames = {
    'English': 'İngilizce',
    'German': 'Almanca',
    'French': 'Fransızca',
    'Spanish': 'İspanyolca',
    'Italian': 'İtalyanca',
    'Japanese': 'Japonca',
    'Chinese': 'Çince',
    'Korean': 'Korece',
    'Russian': 'Rusça',
  };

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settingsBox');
    _geminiService = GeminiService();
    _loadSelectedLanguage();
  }

  void _loadSelectedLanguage() {
    setState(() {
      final storedLang = _settingsBox.get('targetLanguage');
      if (storedLang != null &&
          _availableLanguageEnglishNames.contains(storedLang)) {
        _selectedLanguageEnglishName = storedLang;
        final languageCode = _languageEnglishToCode[storedLang];
        if (languageCode != null) {
          LanguageManager().setLanguageCode(languageCode);
        }
      }
    });
  }

  Future<void> _saveLanguageAndNavigate() async {
    if (_selectedLanguageEnglishName != null) {
      await _settingsBox.put('targetLanguage', _selectedLanguageEnglishName);

      final languageCode =
          _languageEnglishToCode[_selectedLanguageEnglishName!];
      if (languageCode != null) {
        LanguageManager().setLanguageCode(languageCode);
      }

      setState(() {
        _isLoadingWords = true;
      });

      await _fetchAndSaveCommonWords();

      setState(() {
        _isLoadingWords = false;
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen bir dil seçin.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchAndSaveCommonWords() async {
    try {
      final targetLanguage = _selectedLanguageEnglishName!;
      final savedWords = _geminiService.getSavedWords();
      final lastFetchedLanguage = _geminiService.getLastFetchedLanguage();

      if (savedWords.isEmpty || lastFetchedLanguage != targetLanguage) {
        print(
          'LanguageSelectionScreen: Gemini\'den kelimeler çekiliyor: $targetLanguage için...',
        );
        final words = await _geminiService.getWords(targetLanguage);

        if (words.isNotEmpty) {
          await _geminiService.saveWords(words, targetLanguage);
          print(
            'LanguageSelectionScreen: Kelimeler başarıyla çekildi ve kaydedildi: ${words.length} adet',
          );
        } else {
          print(
            'LanguageSelectionScreen: Gemini\'den kelime alınamadı. Lütfen internet bağlantınızı kontrol edin veya daha sonra tekrar deneyin.',
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Kelime listesi yüklenirken bir hata oluştu veya kelime bulunamadı.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 5),
            ),
          );
        }
      } else {
        print(
          'LanguageSelectionScreen: Hedef dil ($targetLanguage) için kelimeler zaten mevcut. Tekrar çekilmedi.',
        );
      }
    } catch (e) {
      print('LanguageSelectionScreen: Kelime çekme veya kaydetme hatası: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kelime listesi yüklenirken kritik bir hata oluştu: $e',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 7),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hedef Dilinizi Seçin', style: GoogleFonts.montserrat()),
        backgroundColor: const Color(0xFF4A4A4A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Hangi dili öğrenmek istersiniz?',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _availableLanguageEnglishNames.length,
                itemBuilder: (context, index) {
                  final languageEnglishName =
                      _availableLanguageEnglishNames[index];
                  final languageDisplayName =
                      _languageDisplayNames[languageEnglishName] ??
                      languageEnglishName;

                  return Card(
                    elevation:
                        _selectedLanguageEnglishName == languageEnglishName
                            ? 8
                            : 2,
                    color:
                        _selectedLanguageEnglishName == languageEnglishName
                            ? Colors.blue.shade100
                            : Colors.white,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(
                        languageDisplayName,
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              _selectedLanguageEnglishName ==
                                      languageEnglishName
                                  ? Colors.blue.shade900
                                  : Colors.black87,
                        ),
                      ),
                      trailing:
                          _selectedLanguageEnglishName == languageEnglishName
                              ? const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              )
                              : null,
                      onTap: () {
                        setState(() {
                          _selectedLanguageEnglishName = languageEnglishName;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoadingWords ? null : _saveLanguageAndNavigate,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor:
                    _isLoadingWords ? Colors.grey : const Color(0xFF4A4A4A),
                foregroundColor: Colors.white,
              ),
              child:
                  _isLoadingWords
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                        'Dili Kaydet',
                        style: GoogleFonts.montserrat(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
