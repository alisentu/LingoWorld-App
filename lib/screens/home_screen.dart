// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lingoworld/models/user.dart';
import 'package:lingoworld/screens/login_screen.dart';
import 'package:lingoworld/screens/word_cards_screen.dart';
import 'package:lingoworld/screens/language_selection_screen.dart';
import 'package:lingoworld/screens/youtube_screen.dart';
import 'package:lingoworld/screens/youtube_music_screen.dart';
import 'package:lingoworld/screens/ai_tutor_screen.dart';
import 'package:lingoworld/screens/pdf_vocabulary_screen.dart';
import 'package:lingoworld/screens/main_quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userEmail = '';
  late Box _settingsBox;
  String _targetLanguageEnglishName = '';
  String _targetLanguageDisplayName = 'Yükleniyor...';

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

  final List<String> _levels = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];

  String _selectedLevel = 'A1';

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settingsBox');
    _loadUserData();
    _loadTargetLanguage();
  }

  void _loadUserData() {
    final userBox = Hive.box<User>('userBox');
    final rememberedEmail = _settingsBox.get('rememberedEmail');

    if (rememberedEmail != null && rememberedEmail is String) {
      final currentUser = userBox.get(rememberedEmail);
      if (currentUser != null) {
        setState(() {
          _userEmail = currentUser.email;
        });
      }
    }
  }

  void _loadTargetLanguage() {
    final storedLangEnglishName = _settingsBox.get('targetLanguage');
    if (storedLangEnglishName != null) {
      setState(() {
        _targetLanguageEnglishName = storedLangEnglishName;
        _targetLanguageDisplayName =
            _languageDisplayNames[storedLangEnglishName] ??
            storedLangEnglishName;
      });
    } else {
      setState(() {
        _targetLanguageDisplayName = 'Dil Seçilmedi';
      });
    }
  }

  void _logout() async {
    await _settingsBox.delete('rememberMeFlag');
    await _settingsBox.delete('rememberedEmail');

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Başarıyla çıkış yapıldı."),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  void _navigateToYoutube() {
    if (_targetLanguageEnglishName.isEmpty) {
      _showLanguageSelectionSnackBar();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => YoutubeScreen()),
      );
    }
  }

  void _navigateToYoutubeMusic() {
    if (_targetLanguageEnglishName.isEmpty) {
      _showLanguageSelectionSnackBar();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => YoutubeMusicScreen()),
      );
    }
  }

  void _navigateToAiTutor() {
    if (_targetLanguageEnglishName.isEmpty) {
      _showLanguageSelectionSnackBar();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) =>
                  AiTutorScreen(targetLanguage: _targetLanguageEnglishName),
        ),
      );
    }
  }

  void _navigateToPdfVocabulary() {
    if (_targetLanguageEnglishName.isEmpty) {
      _showLanguageSelectionSnackBar();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => PdfVocabularyScreen(
                targetLanguage: _targetLanguageEnglishName,
              ),
        ),
      );
    }
  }

  // quiz sistemi için fonksiyon
  void _startMainQuiz() {
    if (_targetLanguageEnglishName.isEmpty) {
      _showLanguageSelectionSnackBar();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => MainQuizScreen(
                language: _targetLanguageEnglishName,
                level: _selectedLevel,
              ),
        ),
      );
    }
  }

  void _showLanguageSelectionSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lütfen önce bir hedef dil seçin.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _toggleTheme() {
    final currentIsDarkMode = _settingsBox.get(
      'isDarkMode',
      defaultValue: false,
    );
    _settingsBox.put('isDarkMode', !currentIsDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    List<Widget> gridCards = [
      _buildFeatureCard(
        context,
        title: 'En Çok Kullanılan Kelimeler',
        icon: Icons.flash_on,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const WordCardsScreen()),
          );
        },
        color: const Color(0xFF4CAF50),
      ),
      // quiz sistemi kartı
      _buildFeatureCard(
        context,
        title: 'Seviye Sınavı',
        icon: Icons.assignment,
        onTap: () {
          _showLevelSelectionDialog();
        },
        color: Colors.deepOrange.shade400,
      ),
      _buildFeatureCard(
        context,
        title: 'Yapay Zeka Öğretmen',
        icon: Icons.chat_bubble_outline,
        onTap: _navigateToAiTutor,
        color: Colors.teal.shade400,
      ),
      _buildFeatureCard(
        context,
        title: 'Youtube Öğretici İçerikler',
        icon: Icons.school,
        onTap: _navigateToYoutube,
        color: Colors.red.shade600,
      ),
      _buildFeatureCard(
        context,
        title: 'Öğretici Müzikler',
        icon: Icons.music_note,
        onTap: _navigateToYoutubeMusic,
        color: Colors.purple.shade400,
      ),
      _buildFeatureCard(
        context,
        title: 'Kelime Listesi PDF',
        icon: Icons.picture_as_pdf,
        onTap: _navigateToPdfVocabulary,
        color: Colors.blue.shade400,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'LingoWorld',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _toggleTheme,
            tooltip: isDarkMode ? 'Açık Tema' : 'Karanlık Tema',
          ),
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _logout,
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoş Geldiniz,',
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _userEmail.isNotEmpty
                          ? _userEmail.split('@')[0]
                          : 'Kullanıcı',
                      style: GoogleFonts.montserrat(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Divider(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withAlpha((0.2 * 255).round()),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Hedef Diliniz:',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha((0.7 * 255).round()),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _targetLanguageDisplayName,
                      style: GoogleFonts.montserrat(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const LanguageSelectionScreen(),
                            ),
                          ).then((_) => _loadTargetLanguage());
                        },
                        icon: const Icon(Icons.language_outlined),
                        label: Text(
                          'Dili Değiştir',
                          style: GoogleFonts.montserrat(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.secondary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: gridCards,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLevelSelectionDialog() {
    if (_targetLanguageEnglishName.isEmpty) {
      _showLanguageSelectionSnackBar();
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        String tempSelectedLevel = _selectedLevel;
        return AlertDialog(
          title: Text(
            'Seviye Seçimi',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButtonFormField<String>(
                value: tempSelectedLevel,
                items:
                    _levels.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      tempSelectedLevel = newValue;
                    });
                  }
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'İptal',
                style: GoogleFonts.montserrat(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedLevel = tempSelectedLevel;
                });
                Navigator.of(context).pop();
                _startMainQuiz();
              },
              child: Text(
                'Başlat',
                style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: color.withAlpha((0.9 * 255).round()),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
