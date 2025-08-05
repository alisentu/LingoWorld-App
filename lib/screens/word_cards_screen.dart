import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lingoworld/services/gemini_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lingoworld/screens/quiz_screen.dart';

class WordCardsScreen extends StatefulWidget {
  const WordCardsScreen({super.key});

  @override
  State<WordCardsScreen> createState() => _WordCardsScreenState();
}

class _WordCardsScreenState extends State<WordCardsScreen> {
  final GeminiService _geminiService = GeminiService();
  late Box _settingsBox;
  List<Map<String, String>> _words = [];
  String _targetLanguage = 'English';
  bool _isLoading = true;
  int _currentPage = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    print('WordCardsScreen: initState çalıştı.');
    _settingsBox = Hive.box('settingsBox');
    _pageController = PageController();
    _loadWords();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadWords() async {
    setState(() {
      _isLoading = true;
      _words = [];
    });

    _targetLanguage = _settingsBox.get('targetLanguage') ?? 'English';
    print(
      'WordCardsScreen: _loadWords başlatıldı. Hedef dil: $_targetLanguage',
    );

    List<Map<String, String>> fetchedWords = _geminiService.getSavedWords();
    final String? lastFetchedLanguage = _geminiService.getLastFetchedLanguage();

    if (fetchedWords.isEmpty || lastFetchedLanguage != _targetLanguage) {
      print(
        'WordCardsScreen: $_targetLanguage için yeni kelimeler çekiliyor (veya dil değişti).',
      );
      try {
        fetchedWords = await _geminiService.getWords(_targetLanguage);
        if (fetchedWords.isNotEmpty) {
          await _geminiService.saveWords(fetchedWords, _targetLanguage);
          print(
            'WordCardsScreen: Gemini\'den ${fetchedWords.length} kelime çekildi ve kaydedildi.',
          );
        } else {
          print(
            'WordCardsScreen: Gemini\'den boş kelime listesi geldi. İnternet bağlantısını kontrol edin.',
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Kelime listesi yüklenirken bir sorun oluştu veya kelime bulunamadı.',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        print('WordCardsScreen: Kelime çekerken kritik hata oluştu: $e');
        if (!mounted) return;
        String errorMessage =
            'Kelime listesi yüklenirken bir hata oluştu. Lütfen tekrar deneyin.';
        if (e.toString().contains('overloaded')) {
          errorMessage =
              'Sunucu meşgul. Lütfen birkaç dakika sonra tekrar deneyin.';
        } else if (e.toString().contains('SocketException') ||
            e.toString().contains('Network is unreachable')) {
          errorMessage =
              'İnternet bağlantınızda sorun var gibi görünüyor. Lütfen kontrol edin.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 7),
          ),
        );
      }
    } else {
      print(
        'WordCardsScreen: Hive\'dan kaydedilmiş $_targetLanguage kelimeleri yükleniyor (dil değişmedi).',
      );
    }

    setState(() {
      _words = fetchedWords;
      _isLoading = false;
      if (_words.isNotEmpty) {
        _currentPage = 0;
      }
    });

    if (_words.isNotEmpty) {
      print(
        'WordCardsScreen: Gösterilecek toplam kelime sayısı: ${_words.length}',
      );
    } else {
      print(
        'WordCardsScreen: Gösterilecek kelime bulunamadı. Lütfen dil seçtiğinizden emin olun.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'LingoWorld',
          style: TextStyle(
            color: Theme.of(context).textTheme.displayLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _words.isEmpty
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.sentiment_dissatisfied,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Gösterilecek kelime bulunamadı. Lütfen dil seçtiğinizden emin olun veya internet bağlantınızı kontrol edip tekrar deneyin.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () {
                          _loadWords();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tekrar Dene'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A4A4A),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _words.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final wordData = _words[index];
                        return WordCard(
                          wordData: wordData,
                          targetLanguage: _targetLanguage,
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      '${_currentPage + 1} / ${_words.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  // Sınav butonu
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: ElevatedButton(
                      onPressed:
                          _words.isNotEmpty
                              ? () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder:
                                        (context) => QuizScreen(words: _words),
                                  ),
                                );
                              }
                              : null, // Kelime yoksa butonu devre dışı bırak
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A4A4A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                      ),
                      child: const Text('Sınavı Başlat'),
                    ),
                  ),
                ],
              ),
    );
  }
}

// Güncellenmiş Kelime Kartı
class WordCard extends StatefulWidget {
  final Map<String, String> wordData;
  final String targetLanguage;

  const WordCard({
    super.key,
    required this.wordData,
    required this.targetLanguage,
  });

  @override
  State<WordCard> createState() => _WordCardState();
}

class _WordCardState extends State<WordCard> {
  bool _showMeaning = false;
  bool _showExampleTranslation = false;

  late FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();
    _setLanguage();
  }

  Future _setLanguage() async {
    String ttsLangCode;
    switch (widget.targetLanguage) {
      case 'English':
        ttsLangCode = 'en-US';
        break;
      case 'Spanish':
        ttsLangCode = 'es-ES';
        break;
      case 'German':
        ttsLangCode = 'de-DE';
        break;
      case 'French':
        ttsLangCode = 'fr-FR';
        break;
      default:
        ttsLangCode = 'en-US';
        break;
    }
    await flutterTts.setLanguage(ttsLangCode);
  }

  Future _speak(String text) async {
    await flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showMeaning = !_showMeaning;
          _showExampleTranslation = !_showExampleTranslation;
        });
      },
      child: Card(
        margin: const EdgeInsets.all(20),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Kelime ve Anlamı
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (
                        Widget child,
                        Animation<double> animation,
                      ) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child:
                          _showMeaning
                              ? Text(
                                widget.wordData['meaning'] ??
                                    'Anlam Bulunamadı',
                                key: const ValueKey<bool>(true),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4A4A4A),
                                ),
                              )
                              : Text(
                                widget.wordData['word'] ?? 'Kelime Bulunamadı',
                                key: const ValueKey<bool>(false),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.montserrat(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF4A4A4A),
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Seslendirme butonu
                  IconButton(
                    icon: Icon(
                      Icons.volume_up,
                      color: Colors.grey[700],
                      size: 30,
                    ),
                    onPressed: () {
                      final textToSpeak =
                          _showMeaning
                              ? widget.wordData['word']
                              : widget.wordData['word'];
                      if (textToSpeak != null) {
                        _speak(textToSpeak);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Örnek Cümle ve Anlamı
              Flexible(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return ScaleTransition(scale: animation, child: child);
                  },
                  child:
                      _showExampleTranslation
                          ? Text(
                            'Örnek: "${widget.wordData['example_translation'] ?? 'Çeviri Bulunamadı'}"',
                            key: const ValueKey<bool>(true),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                            ),
                          )
                          : Text(
                            'Örnek: "${widget.wordData['example'] ?? 'Örnek Cümle Bulunamadı'}"',
                            key: const ValueKey<bool>(false),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey[700],
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 10),
              // Örnek cümle seslendirme butonu
              IconButton(
                icon: Icon(Icons.volume_up, color: Colors.grey[700]),
                onPressed: () {
                  final textToSpeak =
                      _showExampleTranslation
                          ? widget.wordData['example']
                          : widget.wordData['example'];
                  if (textToSpeak != null) {
                    _speak(textToSpeak);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
