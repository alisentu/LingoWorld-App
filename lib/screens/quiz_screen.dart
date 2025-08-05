// lib/screens/quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizScreen extends StatefulWidget {
  final List<Map<String, String>> words;

  const QuizScreen({super.key, required this.words});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Map<String, String>> _shuffledWords;
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  late List<String> _options;
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    _shuffledWords = List.from(widget.words)..shuffle();
    _generateOptions();
  }

  void _generateOptions() {
    if (_shuffledWords.isEmpty) return;

    final correctAnswer = _shuffledWords[_currentQuestionIndex]['meaning']!;

    final List<String> allMeanings =
        widget.words
            .map((e) => e['meaning']!)
            .where((meaning) => meaning != correctAnswer)
            .toList();
    allMeanings.shuffle();

    _options = [correctAnswer];
    _options.addAll(allMeanings.take(3));
    _options.shuffle();
  }

  void _checkAnswer(String selectedAnswer) {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _selectedOption = selectedAnswer;
      if (selectedAnswer == _shuffledWords[_currentQuestionIndex]['meaning']) {
        _score++;
        _showSnackbar('Doğru cevap!', Colors.green);
      } else {
        _showSnackbar('Yanlış cevap!', Colors.red);
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    setState(() {
      _isAnswered = false;
      _selectedOption = null;
      if (_currentQuestionIndex < _shuffledWords.length - 1) {
        _currentQuestionIndex++;
        _generateOptions();
      } else {
        _showResults();
      }
    });
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Sınav Bitti!',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Toplam skorunuz: $_score / ${_shuffledWords.length}',
            style: GoogleFonts.montserrat(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Tamam'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_shuffledWords.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sınav'), centerTitle: true),
        body: const Center(
          child: Text('Sınav için yeterli kelime bulunamadı.'),
        ),
      );
    }

    final currentWordData = _shuffledWords[_currentQuestionIndex];
    final questionWord = currentWordData['word'] ?? 'Kelime bulunamadı';
    final correctAnswer = currentWordData['meaning']!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sınav'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                'Skor: $_score',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4A4A4A),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      'Aşağıdaki kelimenin Türkçe karşılığı nedir?',
                      style: GoogleFonts.montserrat(
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      questionWord,
                      style: GoogleFonts.montserrat(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4A4A4A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            ..._options.map((option) {
              Color buttonColor = Colors.white;
              Color foregroundColor = const Color(0xFF4A4A4A);
              Color borderColor = const Color(0xFF4A4A4A);

              if (_isAnswered) {
                if (option == correctAnswer) {
                  buttonColor = Colors.green.shade500;
                  borderColor = Colors.green.shade800;
                  foregroundColor = Colors.white;
                } else if (option == _selectedOption) {
                  buttonColor = Colors.red.shade500;
                  borderColor = Colors.red.shade800;
                  foregroundColor = Colors.white;
                } else {
                  buttonColor = Colors.grey.shade300;
                  borderColor = Colors.grey.shade400;
                  foregroundColor = Colors.grey.shade600;
                }
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: _isAnswered ? null : () => _checkAnswer(option),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: foregroundColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: borderColor, width: 1),
                    ),
                    elevation: 2,
                    disabledBackgroundColor: buttonColor,
                    disabledForegroundColor: foregroundColor,
                  ),
                  child: Text(
                    option,
                    style: GoogleFonts.montserrat(fontSize: 18),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
