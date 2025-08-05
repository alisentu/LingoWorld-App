// lib/screens/main_quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lingoworld/models/question.dart';
import 'package:lingoworld/services/quiz_service.dart';
import 'package:lingoworld/services/gemini_explain_service.dart';

class MainQuizScreen extends StatefulWidget {
  final String language;
  final String level;

  const MainQuizScreen({
    super.key,
    required this.language,
    required this.level,
  });

  @override
  State<MainQuizScreen> createState() => _MainQuizScreenState();
}

class _MainQuizScreenState extends State<MainQuizScreen> {
  final QuizService _quizService = QuizService();
  final GeminiExplainService _explainService = GeminiExplainService();
  late Future<List<Question>> _questionsFuture;
  int _currentQuestionIndex = 0;
  int _score = 0;
  bool _isAnswered = false;
  String? _selectedOption;
  String? _explanation;
  bool _isLoadingExplanation = false;

  @override
  void initState() {
    super.initState();
    _questionsFuture = _quizService.fetchQuizQuestions(
      widget.language,
      widget.level,
    );
  }

  void _checkAnswer(
    String selectedAnswer,
    String correctAnswer,
    Question question,
  ) async {
    if (_isAnswered) return;

    setState(() {
      _isAnswered = true;
      _selectedOption = selectedAnswer;
    });

    if (selectedAnswer.toLowerCase().trim() ==
        correctAnswer.toLowerCase().trim()) {
      setState(() {
        _score++;
        _showSnackbar('Doğru cevap!', Colors.green);
        _explanation = "Tebrikler! Doğru cevap verdiniz.";
      });
    } else {
      _showSnackbar('Yanlış cevap!', Colors.red);

      setState(() {
        _isLoadingExplanation = true;
      });

      final explanation = await _explainService.getExplanation(
        language: widget.language,
        level: widget.level,
        question: question.text,
        correctAnswer: correctAnswer,
        userAnswer: selectedAnswer,
      );

      setState(() {
        _explanation = explanation;
        _isLoadingExplanation = false;
      });
    }
  }

  void _nextQuestion() {
    setState(() {
      _isAnswered = false;
      _selectedOption = null;
      _explanation = null;
      if (_currentQuestionIndex < 9) {
        _currentQuestionIndex++;
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
            'Toplam skorunuz: $_score / 10',
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

  Widget _buildQuestionWidget(Question question) {
    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        return Column(
          children: [
            Text(
              question.text,
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A4A4A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ...?question.options?.map((option) {
              Color buttonColor = Colors.white;
              Color foregroundColor = const Color(0xFF4A4A4A);
              Color borderColor = const Color(0xFF4A4A4A);

              if (_isAnswered) {
                if (option.toLowerCase().trim() ==
                    question.correctAnswer.toLowerCase().trim()) {
                  buttonColor = Colors.green.shade500;
                  borderColor = Colors.green.shade800;
                  foregroundColor = Colors.white;
                } else if (option.toLowerCase().trim() ==
                    _selectedOption?.toLowerCase().trim()) {
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
                  onPressed:
                      _isAnswered
                          ? null
                          : () => _checkAnswer(
                            option,
                            question.correctAnswer,
                            question,
                          ),
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
        );

      case QuestionType.fillInTheBlank:
      case QuestionType.translation:
        final TextEditingController answerController = TextEditingController();
        return Column(
          children: [
            Text(
              question.text,
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF4A4A4A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: answerController,
              style: GoogleFonts.montserrat(color: Colors.black, fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Cevabınızı buraya yazın',
                labelText: 'Cevap Kutusu',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.grey, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(
                    color: Colors.black45,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Colors.blue, width: 2.0),
                ),
                filled: true,
                fillColor: Colors.grey.shade200,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 15,
                  horizontal: 15,
                ),
              ),
              enabled: !_isAnswered,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  _isAnswered
                      ? null
                      : () {
                        _checkAnswer(
                          answerController.text,
                          question.correctAnswer,
                          question,
                        );
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A4A4A),
                foregroundColor: Colors.white,
              ),
              child: const Text('Cevapla'),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: FutureBuilder<List<Question>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Sınav için yeterli soru bulunamadı.'),
            );
          }

          final questions = snapshot.data!;
          final currentQuestion = questions[_currentQuestionIndex];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${widget.language} ${widget.level} Seviye Sınavı',
                    style: GoogleFonts.montserrat(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4A4A4A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildQuestionWidget(currentQuestion),
                          if (_isAnswered) const SizedBox(height: 20),
                          if (_isAnswered)
                            if (_isLoadingExplanation)
                              const CircularProgressIndicator()
                            else
                              Text(
                                _explanation ?? '',
                                style: GoogleFonts.montserrat(
                                  fontSize: 16,
                                  color: const Color(0xFF4A4A4A),
                                ),
                                textAlign: TextAlign.center,
                              ),
                          if (_isAnswered) const SizedBox(height: 20),
                          if (_isAnswered)
                            ElevatedButton(
                              onPressed: _nextQuestion,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Sonraki Soru'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      'Soru ${_currentQuestionIndex + 1} / 10',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
